# Local validation evidence

This is supplementary evidence for the local Compose run. The final assignment evidence must use the public cloud URL and Azure portal screenshots.

- Docker Engine runs through Colima.
- Docker Compose version 5.7.1.
- `redis` container is healthy and responds to `redis-cli ping` with `PONG`.
- `api` responds to `/api/health` with `{"status":"ok","redis":"ok"}`.
- `api` completes POST, PATCH, and DELETE task requests against the Compose Redis service.
- `frontend` returns HTTP 200 through Nginx on port 8080.
- Browser testing completed a task create and delete flow through the frontend.

## Final cloud evidence to add

- `01-resource-group.png`
- `02-container-app.png`
- `03-redis-and-storage.png`
- The recorded video URL
- The deployed frontend URL
