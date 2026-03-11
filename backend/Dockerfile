# Qianqian Diary 后端 - 生产用 Dockerfile
FROM python:3.11-slim

WORKDIR /app

# 安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# 复制应用代码
COPY . .

# 启动脚本：先初始化数据库再启动应用
COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

# 非 root 用户运行（可选，增强安全）
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 5001

ENV FLASK_APP=app.py
ENV FLASK_HOST=0.0.0.0
ENV FLASK_PORT=5001

ENTRYPOINT ["/app/docker-entrypoint.sh"]
