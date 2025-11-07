# 监控服务 Dockerfile
FROM python:3.9-slim

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# 设置工作目录
WORKDIR /app

# 使用阿里云镜像源加速apt（如果sources.list存在）
RUN if [ -f /etc/apt/sources.list ]; then \
        sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && \
        sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list; \
    fi

# 安装系统依赖（合并RUN命令减少层数）
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpq-dev \
    libmagic1 \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 创建非root用户和必要目录（合并操作）
RUN useradd --create-home --shell /bin/bash appuser && \
    mkdir -p /app/data /app/logs /app/configs

# 复制依赖文件（先复制依赖文件，利用Docker缓存）
COPY requirements-simple.txt requirements.txt

# 使用阿里云PyPI镜像源加速pip安装
RUN pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/ && \
    pip config set global.trusted-host mirrors.aliyun.com && \
    pip install --no-cache-dir -r requirements.txt

# 复制应用代码（放在最后，避免代码变更影响依赖缓存）
COPY . .

# 设置目录权限
RUN chown -R appuser:appuser /app

# 切换到非root用户
USER appuser

# 暴露端口
EXPOSE 8086

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8086/health || exit 1

# 启动应用
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8086"]



