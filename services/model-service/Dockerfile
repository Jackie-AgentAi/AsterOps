# 模型管理服务 Dockerfile
FROM python:3.9-slim AS builder

# 设置工作目录
WORKDIR /app

# 配置apt使用国内镜像源（可选，如果网络慢）
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true

# 安装系统依赖（合并RUN命令减少层数）
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libpq-dev \
    libmagic1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 配置pip使用国内镜像源加速
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn && \
    pip install --upgrade pip setuptools wheel

# 复制依赖文件（先复制依赖文件以利用Docker缓存）
COPY requirements.txt .

# 安装Python依赖（利用缓存，使用预编译wheel加速）
RUN pip install --no-cache-dir --prefer-binary -r requirements.txt || \
    pip install --no-cache-dir -r requirements.txt

# 最终阶段
FROM python:3.9-slim

WORKDIR /app

# 只安装运行时依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    libmagic1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 从builder阶段复制已安装的Python包
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# 复制应用代码
COPY . .

# 创建非root用户
RUN useradd --create-home --shell /bin/bash appuser && \
    chown -R appuser:appuser /app

# 切换到非root用户
USER appuser

# 暴露端口
EXPOSE 8083

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8083/health || exit 1

# 启动应用（使用完整实现）
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8083"]



