# TaskBoard · Cloud Seminar Assignment


```mermaid
flowchart LR
  B[Blob Storage static website\nHTML/CSS/JS] -->|HTTPS + CORS| A[Azure Container App\nFastAPI CRUD]
  A -->|REDIS_URL secret| R[Azure Cache for Redis]
```

