#!/bin/bash

# LLMOps全栈启动脚本 - 使用阿里源
# 同时启动前后端服务，使用阿里云镜像源加速

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
echo "║                LLMOps 全栈启动脚本                          ║"
echo "║              使用阿里云镜像源加速构建                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# 配置阿里云镜像源
setup_aliyun_mirrors() {
    echo -e "${BLUE}[1/6]${NC} 配置阿里云镜像源..."
    
    # 创建Docker daemon配置
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF
    
    # 重启Docker服务
    echo "   🔄 重启Docker服务..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    
    echo -e "${GREEN}✅ 阿里云镜像源配置完成${NC}"
}

# 检查环境
check_environment() {
    echo -e "${BLUE}[2/6]${NC} 检查环境..."
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker未安装，请先安装Docker${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose未安装，请先安装Docker Compose${NC}"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker服务未运行，请启动Docker服务${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 环境检查通过${NC}"
}

# 停止现有服务
stop_existing_services() {
    echo -e "${BLUE}[3/6]${NC} 停止现有服务..."
    
    docker-compose down 2>/dev/null || true
    
    # 清理未使用的镜像和容器
    echo "   🧹 清理Docker资源..."
    docker system prune -f || true
    
    echo -e "${GREEN}✅ 现有服务已停止${NC}"
}

# 创建必要目录
create_directories() {
    echo -e "${BLUE}[4/6]${NC} 创建必要目录..."
    
    local dirs=(
        "logs"
        "data/postgres"
        "data/redis"
        "data/minio"
        "data/consul"
        "data/grafana"
        "data/prometheus"
        "frontend/admin-dashboard/dist"
        "frontend/user-portal/dist"
        "frontend/mobile-app/dist"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        chmod 755 "$dir"
    done
    
    echo -e "${GREEN}✅ 目录创建完成${NC}"
}

# 启动所有服务
start_all_services() {
    echo -e "${BLUE}[5/6]${NC} 启动所有服务..."
    
    # 启动基础设施服务
    echo "   📦 启动基础设施服务..."
    docker-compose up -d postgres redis consul minio
    
    # 等待数据库启动
    echo "   ⏳ 等待PostgreSQL启动..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker exec $(docker-compose ps -q postgres) pg_isready -U llmops -d llmops >/dev/null 2>&1; then
            echo -e "${GREEN}✅ PostgreSQL已就绪${NC}"
            break
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${RED}❌ PostgreSQL启动超时${NC}"
        exit 1
    fi
    
    # 启动后端服务
    echo "   🔧 启动后端服务..."
    docker-compose up -d user-service project-service model-service inference-service cost-service monitoring-service
    
    # 启动监控服务
    echo "   📊 启动监控服务..."
    docker-compose up -d prometheus grafana
    
    # 启动前端服务
    echo "   🎨 启动前端服务..."
    docker-compose up -d admin-frontend user-portal-frontend mobile-frontend
    
    # 启动Nginx代理
    echo "   🌐 启动Nginx代理..."
    docker-compose up -d nginx
    
    # 等待所有服务启动
    echo "   ⏳ 等待所有服务启动..."
    sleep 30
    
    echo -e "${GREEN}✅ 所有服务已启动${NC}"
}

# 运行健康检查和显示状态
health_check_and_status() {
    echo -e "${BLUE}[6/6]${NC} 运行健康检查和显示状态..."
    
    # 运行健康检查
    echo "🏥 运行健康检查..."
    local healthy_count=0
    local total_count=0
    
    # 检查后端API服务
    local api_services=(
        "8081:用户服务"
        "8082:项目服务"
        "8083:模型服务"
        "8084:推理服务"
        "8085:成本服务"
        "8086:监控服务"
    )
    
    for service in "${api_services[@]}"; do
        local port=$(echo "$service" | cut -d: -f1)
        local name=$(echo "$service" | cut -d: -f2)
        total_count=$((total_count + 1))
        
        if curl -f -s "http://localhost:$port/health" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ $name 健康检查通过${NC}"
            healthy_count=$((healthy_count + 1))
        else
            echo -e "${YELLOW}⚠️  $name 健康检查失败${NC}"
        fi
    done
    
    # 检查前端服务
    local frontend_services=(
        "3000:管理后台"
        "3001:用户门户"
        "3002:移动端"
    )
    
    for service in "${frontend_services[@]}"; do
        local port=$(echo "$service" | cut -d: -f1)
        local name=$(echo "$service" | cut -d: -f2)
        total_count=$((total_count + 1))
        
        if curl -f -s "http://localhost:$port/health" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ $name 健康检查通过${NC}"
            healthy_count=$((healthy_count + 1))
        else
            echo -e "${YELLOW}⚠️  $name 健康检查失败${NC}"
        fi
    done
    
    # 检查监控服务
    if curl -f -s "http://localhost:9090/-/healthy" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Prometheus健康检查通过${NC}"
        healthy_count=$((healthy_count + 1))
        total_count=$((total_count + 1))
    else
        echo -e "${YELLOW}⚠️  Prometheus健康检查失败${NC}"
        total_count=$((total_count + 1))
    fi
    
    if curl -f -s "http://localhost:3001/api/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Grafana健康检查通过${NC}"
        healthy_count=$((healthy_count + 1))
        total_count=$((total_count + 1))
    else
        echo -e "${YELLOW}⚠️  Grafana健康检查失败${NC}"
        total_count=$((total_count + 1))
    fi
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                        服务状态                            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    docker-compose ps
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                        访问地址                            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}🌐 前端应用:${NC}"
    echo -e "   📱 管理后台:     http://localhost:3000"
    echo -e "   📱 用户门户:     http://localhost:3001"
    echo -e "   📱 移动端:       http://localhost:3002"
    echo -e "   🔗 Nginx代理:    http://localhost:80"
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
    echo -e "${BLUE}📈 监控系统:${NC}"
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
    
    echo -e "${GREEN}🎉 启动完成！健康服务: $healthy_count/$total_count${NC}"
    echo ""
}

# 显示帮助信息
show_help() {
    echo "LLMOps全栈启动脚本 - 使用阿里云镜像源"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --no-mirror    跳过镜像源配置"
    echo "  --logs         启动后显示日志"
    echo "  --help         显示帮助信息"
    echo ""
    echo "特性:"
    echo "  - 使用阿里云Docker镜像源加速下载"
    echo "  - 使用阿里云npm镜像源加速前端构建"
    echo "  - 自动配置Docker daemon"
    echo "  - 完整的健康检查"
    echo ""
    echo "示例:"
    echo "  $0                    # 使用阿里源启动"
    echo "  $0 --no-mirror        # 跳过镜像源配置"
    echo "  $0 --logs             # 启动并显示日志"
}

# 主函数
main() {
    local skip_mirror=false
    local show_logs=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
                ;;
            --no-mirror)
                skip_mirror=true
                shift
                ;;
            --logs)
                show_logs=true
                shift
                ;;
            *)
                echo -e "${RED}未知选项: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 执行启动流程
    if [ "$skip_mirror" = false ]; then
        setup_aliyun_mirrors
    fi
    
    check_environment
    stop_existing_services
    create_directories
    start_all_services
    health_check_and_status
    
    # 显示日志
    if [ "$show_logs" = true ]; then
        echo -e "${BLUE}📋 显示服务日志 (按 Ctrl+C 退出)...${NC}"
        echo ""
        docker-compose logs -f --tail=50
    fi
    
    echo ""
    echo -e "${GREEN}✨ 享受使用LLMOps平台！${NC}"
    echo ""
}

# 捕获中断信号
trap 'echo ""; echo -e "${YELLOW}收到中断信号，正在停止服务...${NC}"; docker-compose down; exit 0' INT

# 执行主函数
main "$@"