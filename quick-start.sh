#!/bin/bash

# LLMOps平台快速启动脚本
# 使用Docker Compose启动前后端所有服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                LLMOps 运营管理平台                          ║"
echo "║                    快速启动脚本                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# 检查Docker环境
echo -e "${BLUE}[1/5]${NC} 检查Docker环境..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ 错误: Docker未安装，请先安装Docker${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ 错误: Docker Compose未安装，请先安装Docker Compose${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}❌ 错误: Docker服务未运行，请启动Docker服务${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker环境检查通过${NC}"

# 配置阿里云镜像源（可选）
if [ "$1" = "--aliyun" ]; then
    echo -e "${BLUE}配置阿里云镜像源...${NC}"
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo -e "${GREEN}✅ 阿里云镜像源配置完成${NC}"
fi

# 停止现有服务
echo -e "${BLUE}[2/5]${NC} 停止现有服务..."
docker-compose down 2>/dev/null || true
echo -e "${GREEN}✅ 现有服务已停止${NC}"

# 创建必要目录
echo -e "${BLUE}[3/5]${NC} 创建必要目录..."
mkdir -p logs data/{postgres,redis,minio,consul,grafana,prometheus}
echo -e "${GREEN}✅ 目录创建完成${NC}"

# 启动所有服务
echo -e "${BLUE}[4/5]${NC} 启动所有服务..."
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

# 等待服务就绪并运行健康检查
echo -e "${BLUE}[5/5]${NC} 等待服务就绪并运行健康检查..."
sleep 20

# 运行健康检查
if [ -f "./scripts/health-check-all.sh" ]; then
    echo "🔍 运行健康检查..."
    ./scripts/health-check-all.sh
else
    echo "⚠️  健康检查脚本不存在，跳过检查"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                        启动完成！                           ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 显示服务状态
echo -e "${BLUE}📊 服务状态:${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                        访问地址                            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}🌐 前端应用:${NC}     http://localhost:3000"
echo -e "${BLUE}🔗 Nginx代理:${NC}    http://localhost:80"
echo ""
echo -e "${YELLOW}📡 后端API服务:${NC}"
echo -e "   👤 用户服务:     http://localhost:8081"
echo -e "   📁 项目服务:     http://localhost:8082"
echo -e "   🤖 模型服务:     http://localhost:8083"
echo -e "   ⚡ 推理服务:     http://localhost:8084"
echo -e "   💰 成本服务:     http://localhost:8085"
echo -e "   📊 监控服务:     http://localhost:8086"
echo ""
echo -e "${PURPLE}🔧 基础设施服务:${NC}"
echo -e "   🗄️  PostgreSQL:  localhost:5432"
echo -e "   🔄 Redis:        localhost:6379"
echo -e "   🔍 Consul:       http://localhost:8500"
echo -e "   📦 MinIO:        http://localhost:9001"
echo ""
echo -e "${CYAN}📈 监控系统:${NC}"
echo -e "   📊 Prometheus:   http://localhost:9090"
echo -e "   📈 Grafana:      http://localhost:3001"
echo ""

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                        管理命令                            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}查看日志:${NC}       docker-compose logs -f [服务名]"
echo -e "${BLUE}停止服务:${NC}       docker-compose down"
echo -e "${BLUE}重启服务:${NC}       docker-compose restart [服务名]"
echo -e "${BLUE}查看状态:${NC}       docker-compose ps"
echo -e "${BLUE}健康检查:${NC}       ./scripts/health-check-all.sh"
echo -e "${BLUE}API测试:${NC}        ./scripts/api-test.sh"
echo ""

# 如果指定了--logs参数，显示日志
if [ "$1" = "--logs" ]; then
    echo -e "${BLUE}📋 显示服务日志 (按 Ctrl+C 退出)...${NC}"
    echo ""
    docker-compose logs -f --tail=50
fi

echo -e "${GREEN}✨ 享受使用LLMOps平台！${NC}"

