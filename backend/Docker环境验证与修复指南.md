# Docker 环境验证与修复指南

## 一、问题根因分析

### 1. Docker 感叹号 / 未就绪

**根本原因**：Docker 能启动，但在部分环境下会显示「未就绪」或感叹号，常见情况有：

| 原因 | 说明 |
|------|------|
| **网络连接 Docker Hub 失败** | 国内访问 `registry-1.docker.io` 经常超时或 EOF，导致拉取元数据失败 |
| **代理配置** | Docker 配置了 HTTP/HTTPS 代理（如 `http.docker.internal:3128`），若代理不可用会连不上 |
| **镜像加速未配置** | 未配置国内 registry-mirrors，直接访问 Docker Hub 易失败 |

你遇到的错误 `load metadata for docker.io/library/python` / `failed to do request: Head "https://registry-1.docker.io/...": EOF` 正是无法访问 Docker Hub 的表现。

### 2. 为什么重启 / 镜像加速 / 重置都没彻底解决？

- **镜像加速**：必须在 Docker Desktop 的 Engine JSON 里正确填写 `registry-mirrors` 并 Apply，仅改 `daemon.json` 可能没被 Docker Desktop 加载
- **代理**：如果系统或 Docker 设了代理，会优先走代理，镜像源配置可能不起作用
- **重置**：会清空自定义配置，镜像加速需重新配置

---

## 二、修复步骤（按顺序执行）

### 步骤 1：配置国内镜像加速

> 重要：Mac 上必须通过 **Docker Desktop 图形界面** 修改，否则可能不生效。`~/.docker/daemon.json` 可能被 Docker Desktop 覆盖。

1. 打开 **Docker Desktop** → 右上角 ⚙️ **Settings**
2. 左侧选择 **Docker Engine**
3. 在 JSON 中加入 `registry-mirrors`（保留原有 `builder` 等）：

```json
{
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": false,
  "registry-mirrors": [
    "https://docker.xuanyuan.me",
    "https://docker.m.daocloud.io",
    "https://docker.1ms.run"
  ]
}
```

4. 点击 **Apply & Restart**，等待 Docker 完全启动

### 步骤 2：检查并关闭代理（如非必需）

若步骤 1 后仍拉取失败，可尝试关闭代理：

1. **Docker Desktop** → **Settings** → **Resources** → **Proxies**
2. 关闭 **Manual proxy configuration**
3. 或在 **System Preferences** 中检查网络代理，确认没有误配

### 步骤 3：验证镜像拉取

终端执行：

```bash
docker pull python:3.11-slim
```

若成功，说明镜像源已生效。

### 步骤 4：在项目目录执行构建

进入 backend 目录：

```bash
cd "/Users/houyuexian/Downloads/小狗钱钱app开发/code/backend"
docker build -t qianqian-backend .
```

---

## 三、本地 Docker 容器启动

项目依赖 MySQL，可用 `docker-compose` 一键启动应用+数据库：

```bash
cd "/Users/houyuexian/Downloads/小狗钱钱app开发/code/backend"

# 复制环境变量（首次）
cp .env.example .env
# 编辑 .env，确保 MYSQL_HOST=mysql（容器名）

# 构建并启动
docker compose up -d

# 查看日志
docker compose logs -f app
```

启动后访问：`http://localhost:5001`、`http://localhost:5001/health`

---

## 四、镜像推送与腾讯云部署

### 推送至 Docker Hub

```bash
# 登录
docker login

# 打标签（将 your-dockerhub-username 换成你的用户名）
docker tag qianqian-backend:latest your-dockerhub-username/qianqian-backend:latest

# 推送
docker push your-dockerhub-username/qianqian-backend:latest
```

### 腾讯云部署

1. **腾讯云轻量/云服务器** 安装 Docker：
   ```bash
   curl -fsSL https://get.docker.com | sh
   sudo systemctl enable docker && sudo systemctl start docker
   ```

2. **拉取镜像**：
   ```bash
   docker pull your-dockerhub-username/qianqian-backend:latest
   ```

3. **准备环境变量**（`prod.env`）：
   ```
   MYSQL_HOST=你的MySQL地址
   MYSQL_PORT=3306
   MYSQL_USER=qianqian
   MYSQL_PASSWORD=你的密码
   MYSQL_DATABASE=qianqian_diary
   SECRET_KEY=生产环境随机长字符串
   JWT_SECRET_KEY=同上
   CORS_ORIGINS=https://你的前端域名
   COS_SECRET_ID=...
   COS_SECRET_KEY=...
   COS_BUCKET=...
   COS_REGION=ap-shanghai
   ```

4. **运行容器**：
   ```bash
   docker run -d \
     --name qianqian-backend \
     --env-file prod.env \
     -p 5001:5001 \
     --restart unless-stopped \
     your-dockerhub-username/qianqian-backend:latest
   ```

5. **安全组**：在腾讯云控制台放行 5001 端口（如需要对外访问）。

更详细的部署说明见 `部署指南.md`。
