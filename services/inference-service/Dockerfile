# 推理服务 Dockerfile
FROM nvidia/cuda:11.8-devel-ubuntu20.04

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    python3.9 \
    python3.9-pip \
    python3.9-dev \
    gcc \
    g++ \
    libpq-dev \
    libmagic1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 设置Python3.9为默认版本
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1
RUN update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# 复制依赖文件
COPY requirements.txt .

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 创建非root用户
RUN useradd --create-home --shell /bin/bash appuser && \
    chown -R appuser:appuser /app

# 创建必要的目录
RUN mkdir -p /app/models /app/cache /app/logs && \
    chown -R appuser:appuser /app/models /app/cache /app/logs

# 切换到非root用户
USER appuser

# 暴露端口
EXPOSE 8084

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8084/health || exit 1

# 启动应用
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8084"]



