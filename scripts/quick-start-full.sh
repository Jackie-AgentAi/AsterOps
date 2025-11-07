#!/bin/bash

# LLMOps快速全栈启动脚本
# 一键启动前后端所有服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                LLMOps 快速全栈启动                          ║"
echo "║              前端 + 后端 + 基础设施 + 监控                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# 检查Docker环境
echo -e "${BLUE}[1/6]${NC} 检查Docker环境..."
if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker或Docker Compose未安装${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker环境正常${NC}"

# 停止现有服务
echo -e "${BLUE}[2/6]${NC} 停止现有服务..."
docker-compose down 2>/dev/null || true
echo -e "${GREEN}✅ 现有服务已停止${NC}"

# 创建必要目录
echo -e "${BLUE}[3/6]${NC} 创建必要目录..."
mkdir -p logs data/{postgres,redis,minio,consul,grafana,prometheus}
echo -e "${GREEN}✅ 目录创建完成${NC}"

# 启动所有服务
echo -e "${BLUE}[4/6]${NC} 启动所有服务..."
echo "   📦 启动基础设施服务..."
docker-compose up -d postgres redis consul minio

echo "   ⏳ 等待基础设施服务启动..."
sleep 15

echo "   🔧 启动微服务..."
docker-compose up -d user-service project-service model-service inference-service cost-service monitoring-service

echo "   📊 启动监控服务..."
docker-compose up -d prometheus grafana

echo "   🎨 启动前端服务..."
docker-compose up -d frontend nginx

echo -e "${GREEN}✅ 所有服务已启动${NC}"

# 等待服务就绪
echo -e "${BLUE}[5/6]${NC} 等待服务就绪..."
sleep 20
echo -e "${GREEN}✅ 服务就绪检查完成${NC}"

# 显示服务状态
echo -e "${BLUE}[6/6]${NC} 显示服务状态..."
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                        服务状态                            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                        访问地址                            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}🌐 前端应用:${NC}     http://localhost:3000"
echo -e "${BLUE}🔗 Nginx代理:${NC}    http://localhost:80"
echo ""
echo -e "${YELLOW}📡 后端API:${NC}"
echo -e "   👤 用户服务:     http://localhost:8081"
echo -e "   📁 项目服务:     http://localhost:8082"
echo -e "   🤖 模型服务:     http://localhost:8083"
echo -e "   ⚡ 推理服务:     http://localhost:8084"
echo -e "   💰 成本服务:     http://localhost:8085"
echo -e "   📊 监控服务:     http://localhost:8086"
echo ""
echo -e "${BLUE}🔧 基础设施:${NC}"
echo -e "   🗄️  PostgreSQL:  localhost:5432"
echo -e "   🔄 Redis:        localhost:6379"
echo -e "   🔍 Consul:       http://localhost:8500"
echo -e "   📦 MinIO:        http://localhost:9001"
echo ""
echo -e "${BLUE}📈 监控系统:${NC}"
echo -e "   📊 Prometheus:   http://localhost:9090"
echo -e "   📈 Grafana:      http://localhost:3001"
echo ""

# 运行健康检查
echo -e "${BLUE}🏥 运行健康检查...${NC}"
healthy_count=0
total_count=0

# 检查API服务
for port in 8081 8082 8083 8084 8085 8086; do
    total_count=$((total_count + 1))
    if curl -f -s "http://localhost:$port/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 端口 $port 服务正常${NC}"
        healthy_count=$((healthy_count + 1))
    else
        echo -e "${YELLOW}⚠️  端口 $port 服务异常${NC}"
    fi
done

# 检查前端
total_count=$((total_count + 1))
if curl -f -s "http://localhost:3000" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 前端应用正常${NC}"
    healthy_count=$((healthy_count + 1))
else
    echo -e "${YELLOW}⚠️  前端应用异常${NC}"
fi

echo ""
echo -e "${GREEN}🎉 启动完成！健康服务: $healthy_count/$total_count${NC}"
echo ""
echo -e "${BLUE}管理命令:${NC}"
echo "  查看日志: docker-compose logs -f [服务名]"
echo "  停止服务: docker-compose down"
echo "  重启服务: docker-compose restart [服务名]"
echo "  健康检查: ./scripts/health-check-all.sh"
echo "  API测试:  ./scripts/api-test.sh"
echo ""

# 如果指定了--logs参数，显示日志
if [ "$1" = "--logs" ]; then
    echo -e "${BLUE}📋 显示服务日志 (按 Ctrl+C 退出)...${NC}"
    echo ""
    docker-compose logs -f --tail=50
fi