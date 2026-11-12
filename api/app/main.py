"""Small CRUD API for the Cloud Seminar 3-service assignment."""
from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from typing import Optional
from uuid import uuid4

import redis
from fastapi import FastAPI, HTTPException, Response, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def model_data(model: BaseModel) -> dict:
    """Support both Pydantic v1 and v2."""
    return model.model_dump() if hasattr(model, "model_dump") else model.dict()


class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=120)


class TaskUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=120)
    completed: Optional[bool] = None


class Task(BaseModel):
    id: str
    title: str
    completed: bool
    created_at: str
    updated_at: str


def create_app(redis_client=None) -> FastAPI:
    app = FastAPI(title="TaskBoard API", version="1.0.0")
    origins = [x.strip() for x in os.getenv("ALLOWED_ORIGINS", "http://localhost:8080").split(",") if x.strip()]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins if origins else ["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    client = redis_client or redis.Redis.from_url(
        os.getenv("REDIS_URL", "redis://localhost:6379/0"), decode_responses=True
    )
    app.state.redis = client
    index_key = "taskboard:index"

    @app.on_event("startup")
    def verify_redis() -> None:
        client.ping()

    def read_task(task_id: str) -> Optional[Task]:
        raw = client.get(f"task:{task_id}")
        return Task(**json.loads(raw)) if raw else None

    @app.get("/", tags=["system"])
    def root() -> dict:
        return {"service": "taskboard-api", "docs": "/docs"}

    @app.get("/api/health", tags=["system"])
    def health() -> dict:
        client.ping()
        return {"status": "ok", "redis": "ok"}

    @app.get("/api/tasks", response_model=list[Task], tags=["tasks"])
    def list_tasks() -> list[Task]:
        task_ids = client.smembers(index_key)
        tasks = [task for task in (read_task(task_id) for task_id in task_ids) if task]
        return sorted(tasks, key=lambda task: task.created_at, reverse=True)

    @app.post("/api/tasks", response_model=Task, status_code=status.HTTP_201_CREATED, tags=["tasks"])
    def create_task(payload: TaskCreate) -> Task:
        now = utc_now()
        task = Task(id=uuid4().hex[:8], title=payload.title.strip(), completed=False, created_at=now, updated_at=now)
        client.set(f"task:{task.id}", json.dumps(model_data(task)))
        client.sadd(index_key, task.id)
        return task

    @app.get("/api/tasks/{task_id}", response_model=Task, tags=["tasks"])
    def get_task(task_id: str) -> Task:
        task = read_task(task_id)
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")
        return task

    @app.patch("/api/tasks/{task_id}", response_model=Task, tags=["tasks"])
    def update_task(task_id: str, payload: TaskUpdate) -> Task:
        existing = read_task(task_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Task not found")
        changes = model_data(payload)
        data = model_data(existing)
        if changes.get("title") is not None:
            data["title"] = changes["title"].strip()
        if changes.get("completed") is not None:
            data["completed"] = changes["completed"]
        data["updated_at"] = utc_now()
        updated = Task(**data)
        client.set(f"task:{task_id}", json.dumps(model_data(updated)))
        return updated

    @app.delete(
        "/api/tasks/{task_id}",
        response_model=None,
        status_code=status.HTTP_204_NO_CONTENT,
        tags=["tasks"],
    )
    def delete_task(task_id: str) -> Response:
        if not read_task(task_id):
            raise HTTPException(status_code=404, detail="Task not found")
        client.delete(f"task:{task_id}")
        client.srem(index_key, task_id)
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    return app


app = create_app()
