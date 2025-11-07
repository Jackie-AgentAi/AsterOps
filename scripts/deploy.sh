#!/bin/bash

# LLMOps平台部署脚本
set -e

echo "=== LLMOps平台部署脚本 ==="
echo "时间: $(date)"
echo ""

# 检查Docker和Docker Compose
echo "1. 检查环境..."
if ! command -v docker &> /dev/null; then
    echo "错误: Docker未安装"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "错误: Docker Compose未安装"
    exit 1
fi

echo "Docker和Docker Compose已安装"

# 停止现有服务
echo "2. 停止现有服务..."
docker-compose down || true

# 清理旧镜像（可选）
if [ "$1" = "--clean" ]; then
    echo "清理旧镜像..."
    docker system prune -f || true
fi

# 启动基础设施服务
echo "3. 启动基础设施服务..."
docker-compose up -d postgres redis consul

# 等待基础设施服务启动
echo "等待基础设施服务启动..."
sleep 10

# 检查基础设施服务状态
echo "检查基础设施服务状态..."
until docker exec asterops-postgres-1 pg_isready -U user; do
    echo "等待PostgreSQL启动..."
    sleep 2
done

echo "PostgreSQL已就绪"

# 启动微服务
echo "4. 启动微服务..."
docker-compose up -d user-service project-service model-service inference-service cost-service monitoring-service

# 等待微服务启动
echo "等待微服务启动..."
sleep 15

# 运行健康检查
echo "5. 运行健康检查..."
./scripts/health-check-all.sh

# 运行API测试
echo "6. 运行API测试..."
./scripts/api-test.sh

echo ""
echo "=== 部署完成 ==="
echo "访问地址:"
echo "- 项目管理服务: http://localhost:8082"
echo "- 用户服务: http://localhost:8081"
echo "- 模型服务: http://localhost:8083"
echo "- 推理服务: http://localhost:8084"
echo "- 成本服务: http://localhost:8085"
echo "- 监控服务: http://localhost:8086"
echo "- Prometheus: http://localhost:9090"
echo "- Grafana: http://localhost:3000"
echo "- Consul: http://localhost:8500"