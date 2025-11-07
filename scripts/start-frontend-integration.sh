#!/bin/bash

# LLMOps前端后端集成启动脚本

set -e

echo "🚀 启动LLMOps前端后端集成环境..."

# 检查Docker和Docker Compose
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装，请先安装Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose未安装，请先安装Docker Compose"
    exit 1
fi

# 检查端口占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        echo "❌ 端口 $port 已被占用，请先释放端口"
        exit 1
    fi
}

echo "🔍 检查端口占用..."
check_port 3000
check_port 8080
check_port 8081
check_port 8082
check_port 8083
check_port 8084
check_port 8085
check_port 8086
check_port 5432
check_port 6379
check_port 8500
check_port 9000
check_port 9001

echo "✅ 端口检查通过"

# 创建必要的目录
echo "📁 创建必要的目录..."
mkdir -p logs
mkdir -p data/postgres
mkdir -p data/redis
mkdir -p data/minio

# 设置权限
chmod 755 logs
chmod 755 data/postgres
chmod 755 data/redis
chmod 755 data/minio

# 启动服务
echo "🐳 启动Docker服务..."

# 先启动基础设施服务
echo "📦 启动基础设施服务..."
docker-compose -f docker-compose.frontend.yml up -d postgres redis consul minio

# 等待基础设施服务启动
echo "⏳ 等待基础设施服务启动..."
sleep 30

# 启动微服务
echo "🔧 启动微服务..."
docker-compose -f docker-compose.frontend.yml up -d user-service project-service model-service inference-service cost-service monitoring-service

# 等待微服务启动
echo "⏳ 等待微服务启动..."
sleep 30

# 启动API网关
echo "🌐 启动API网关..."
docker-compose -f docker-compose.frontend.yml up -d api-gateway

# 等待API网关启动
echo "⏳ 等待API网关启动..."
sleep 10

# 启动前端
echo "🎨 启动前端应用..."
docker-compose -f docker-compose.frontend.yml up -d frontend

# 等待所有服务启动
echo "⏳ 等待所有服务启动..."
sleep 30

# 健康检查
echo "🏥 执行健康检查..."

# 检查API网关
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ API网关健康检查通过"
else
    echo "❌ API网关健康检查失败"
fi

# 检查前端
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ 前端应用健康检查通过"
else
    echo "❌ 前端应用健康检查失败"
fi

# 显示服务状态
echo "📊 服务状态:"
docker-compose -f docker-compose.frontend.yml ps

echo ""
echo "🎉 LLMOps前端后端集成环境启动完成!"
echo ""
echo "📋 服务访问地址:"
echo "  🌐 前端应用: http://localhost:3000"
echo "  🔗 API网关: http://localhost:8080"
echo "  👤 用户服务: http://localhost:8081"
echo "  📁 项目服务: http://localhost:8082"
echo "  🤖 模型服务: http://localhost:8083"
echo "  ⚡ 推理服务: http://localhost:8084"
echo "  💰 成本服务: http://localhost:8085"
echo "  📊 监控服务: http://localhost:8086"
echo "  🗄️  PostgreSQL: localhost:5432"
echo "  🔄 Redis: localhost:6379"
echo "  🔍 Consul: http://localhost:8500"
echo "  📦 MinIO: http://localhost:9001"
echo ""
echo "🔧 管理命令:"
echo "  查看日志: docker-compose -f docker-compose.frontend.yml logs -f [服务名]"
echo "  停止服务: docker-compose -f docker-compose.frontend.yml down"
echo "  重启服务: docker-compose -f docker-compose.frontend.yml restart [服务名]"
echo ""
echo "📝 日志文件位置: ./logs/"
echo ""

# 启动日志监控
echo "📋 启动日志监控..."
docker-compose -f docker-compose.frontend.yml logs -f --tail=50
