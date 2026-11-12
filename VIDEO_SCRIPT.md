# 2–3 分钟视频脚本

视频提交时替换尖括号中的内容：`<FRONTEND_URL>`、`<API_URL>`、`<REPO_URL>`。

**0:00–0:25｜应用端到端演示**

“这是我的 TaskBoard 三服务应用。前端位于 Blob Storage 静态网站：`<FRONTEND_URL>`。我新增一条任务，页面调用 Container App API：`<API_URL>/api/tasks`，API 把记录写入 Redis。刷新页面后任务仍然存在，说明三个服务已经连通。”

**0:25–1:05｜CRUD 和 API**

“我现在勾选任务，前端发送 PATCH；再删除任务，发送 DELETE。API 的 Swagger 页面在 `<API_URL>/docs`，健康检查在 `<API_URL>/api/health`。代码仓库是 `<REPO_URL>`，包含两个 Dockerfile、Docker Compose 和测试。”

**1:05–1:35｜云资源控制台**

“这是 Azure Resource Group。这里是 Container App，它暴露 8000 端口并运行 FastAPI 镜像；这里是 Blob Storage 的 Static website；这里是 Azure Cache for Redis。Container App 的 `REDIS_URL` 来自平台 secret，代码和镜像里没有连接串。”

**1:35–2:00｜遇到的问题和解决**

“我遇到的问题是前端部署后浏览器的跨域请求被拦截。解决方法是把静态网站域名放入 API 的 `ALLOWED_ORIGINS` 环境变量，并让前端的 `config.js` 使用 Container App 的公网 URL。重新部署后，POST、PATCH、DELETE 都能从公网前端完成。”

**2:00–2:25｜生产环境改进**

“生产环境我会使用私有容器仓库和固定镜像版本，给 Redis 和 API 加私有网络与更细的访问控制，增加结构化日志、指标、告警、限流和认证，并用 CI/CD 做自动部署与回滚。演示完成后我会删除云资源，避免产生费用。”
