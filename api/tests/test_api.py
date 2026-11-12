from fastapi.testclient import TestClient
import fakeredis

from app.main import create_app


def client():
    store = fakeredis.FakeRedis(decode_responses=True)
    return TestClient(create_app(store))


def test_task_crud_round_trip():
    with client() as api:
        created = api.post("/api/tasks", json={"title": "Ship assignment"})
        assert created.status_code == 201
        task = created.json()
        task_id = task["id"]

        listed = api.get("/api/tasks")
        assert listed.status_code == 200
        assert listed.json()[0]["title"] == "Ship assignment"

        updated = api.patch(f"/api/tasks/{task_id}", json={"completed": True})
        assert updated.status_code == 200
        assert updated.json()["completed"] is True

        deleted = api.delete(f"/api/tasks/{task_id}")
        assert deleted.status_code == 204
        assert api.get(f"/api/tasks/{task_id}").status_code == 404
