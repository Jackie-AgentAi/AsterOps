#!/bin/bash

# LLMOps开发环境启动脚本
# 启动开发模式的前后端服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                LLMOps 开发环境启动                          ║"
echo "║              前端开发 + 后端服务 + 基础设施                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# 检查Node.js环境
check_nodejs() {
    echo -e "${BLUE}[1/7]${NC} 检查Node.js环境..."
    
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js未安装，请先安装Node.js${NC}"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ npm未安装，请先安装npm${NC}"
        exit 1
    fi
    
    local node_version=$(node --version)
    local npm_version=$(npm --version)
    echo -e "${GREEN}✅ Node.js: $node_version, npm: $npm_version${NC}"
}

# 检查Docker环境
check_docker() {
    echo -e "${BLUE}[2/7]${NC} 检查Docker环境..."
    
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
    
    echo -e "${GREEN}✅ Docker环境正常${NC}"
}

# 安装前端依赖
install_frontend_deps() {
    echo -e "${BLUE}[3/7]${NC} 安装前端依赖..."
    
    # 安装管理后台依赖
    if [ -d "frontend/admin-dashboard" ] && [ -f "frontend/admin-dashboard/package.json" ]; then
        echo "   📦 安装管理后台依赖..."
        cd frontend/admin-dashboard
        npm install --silent
        cd ../..
    fi
    
    # 安装用户门户依赖
    if [ -d "frontend/user-portal" ] && [ -f "frontend/user-portal/package.json" ]; then
        echo "   📦 安装用户门户依赖..."
        cd frontend/user-portal
        npm install --silent
        cd ../..
    fi
    
    # 安装移动端依赖
    if [ -d "frontend/mobile-app" ] && [ -f "frontend/mobile-app/package.json" ]; then
        echo "   📦 安装移动端依赖..."
        cd frontend/mobile-app
        npm install --silent
        cd ../..
    fi
    
    echo -e "${GREEN}✅ 前端依赖安装完成${NC}"
}

# 启动基础设施服务
start_infrastructure() {
    echo -e "${BLUE}[4/7]${NC} 启动基础设施服务..."
    
    # 停止现有服务
    docker-compose down 2>/dev/null || true
    
    # 创建必要目录
    mkdir -p logs data/{postgres,redis,minio,consul,grafana,prometheus}
    
    # 启动基础设施
    echo "   📦 启动PostgreSQL、Redis、Consul、MinIO..."
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
    
    echo -e "${GREEN}✅ 基础设施服务启动完成${NC}"
}

# 启动后端服务
start_backend() {
    echo -e "${BLUE}[5/7]${NC} 启动后端服务..."
    
    echo "   🔧 启动微服务..."
    docker-compose up -d user-service project-service model-service inference-service cost-service monitoring-service
    
    echo "   📊 启动监控服务..."
    docker-compose up -d prometheus grafana
    
    # 等待后端服务启动
    echo "   ⏳ 等待后端服务启动..."
    sleep 20
    
    echo -e "${GREEN}✅ 后端服务启动完成${NC}"
}

# 启动前端开发服务
start_frontend_dev() {
    echo -e "${BLUE}[6/7]${NC} 启动前端开发服务..."
    
    local app=${1:-"admin"}
    
    case $app in
        "admin")
            echo "   🎨 启动管理后台开发模式..."
            if [ -d "frontend/admin-dashboard" ]; then
                cd frontend/admin-dashboard
                echo "   📱 管理后台将在 http://localhost:3000 启动"
                npm run dev &
                cd ../..
            fi
            ;;
        "portal")
            echo "   🎨 启动用户门户开发模式..."
            if [ -d "frontend/user-portal" ]; then
                cd frontend/user-portal
                echo "   📱 用户门户将在 http://localhost:3001 启动"
                npm run dev &
                cd ../..
            fi
            ;;
        "mobile")
            echo "   🎨 启动移动端开发模式..."
            if [ -d "frontend/mobile-app" ]; then
                cd frontend/mobile-app
                echo "   📱 移动端将在 http://localhost:3002 启动"
                npm run dev &
                cd ../..
            fi
            ;;
        "all")
            echo "   🎨 启动所有前端应用开发模式..."
            if command -v concurrently &> /dev/null; then
                concurrently \
                    "cd frontend/admin-dashboard && npm run dev" \
                    "cd frontend/user-portal && npm run dev" \
                    "cd frontend/mobile-app && npm run dev" &
            else
                echo -e "${YELLOW}⚠️  concurrently未安装，请手动启动各个应用${NC}"
                echo "   管理后台: cd frontend/admin-dashboard && npm run dev"
                echo "   用户门户: cd frontend/user-portal && npm run dev"
                echo "   移动端:   cd frontend/mobile-app && npm run dev"
            fi
            ;;
        *)
            echo -e "${YELLOW}⚠️  未知应用: $app，启动管理后台${NC}"
            start_frontend_dev "admin"
            ;;
    esac
    
    echo -e "${GREEN}✅ 前端开发服务启动完成${NC}"
}

# 显示开发环境信息
show_dev_info() {
    echo -e "${BLUE}[7/7]${NC} 显示开发环境信息..."
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    开发环境就绪！                          ║${NC}"
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
    echo -e "${BLUE}🎨 前端开发服务:${NC}"
    echo -e "   📱 管理后台:     http://localhost:3000"
    echo -e "   📱 用户门户:     http://localhost:3001"
    echo -e "   📱 移动端:       http://localhost:3002"
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
    echo -e "${GREEN}║                        开发命令                            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}前端开发:${NC}"
    echo "  管理后台: cd frontend/admin-dashboard && npm run dev"
    echo "  用户门户: cd frontend/user-portal && npm run dev"
    echo "  移动端:   cd frontend/mobile-app && npm run dev"
    echo ""
    echo -e "${BLUE}后端开发:${NC}"
    echo "  查看日志: docker-compose logs -f [服务名]"
    echo "  重启服务: docker-compose restart [服务名]"
    echo "  停止服务: docker-compose down"
    echo ""
    echo -e "${BLUE}测试命令:${NC}"
    echo "  健康检查: ./scripts/health-check-all.sh"
    echo "  API测试:  ./scripts/api-test.sh"
    echo "  前端测试: ./scripts/frontend-dev.sh test"
    echo ""
}

# 显示帮助信息
show_help() {
    echo "LLMOps开发环境启动脚本"
    echo ""
    echo "用法: $0 [选项] [应用]"
    echo ""
    echo "选项:"
    echo "  --help     显示帮助信息"
    echo "  --logs     启动后显示日志"
    echo ""
    echo "应用:"
    echo "  admin      启动管理后台 (默认)"
    echo "  portal     启动用户门户"
    echo "  mobile     启动移动端"
    echo "  all        启动所有前端应用"
    echo ""
    echo "示例:"
    echo "  $0                    # 启动管理后台开发环境"
    echo "  $0 portal             # 启动用户门户开发环境"
    echo "  $0 all --logs         # 启动所有前端应用并显示日志"
}

# 主函数
main() {
    local app="admin"
    local show_logs=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
                ;;
            --logs)
                show_logs=true
                shift
                ;;
            admin|portal|mobile|all)
                app="$1"
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
    check_nodejs
    check_docker
    install_frontend_deps
    start_infrastructure
    start_backend
    start_frontend_dev "$app"
    show_dev_info
    
    # 如果指定了--logs参数，显示日志
    if [ "$show_logs" = true ]; then
        echo -e "${BLUE}📋 显示服务日志 (按 Ctrl+C 退出)...${NC}"
        echo ""
        docker-compose logs -f --tail=50
    fi
    
    echo ""
    echo -e "${GREEN}🎉 开发环境启动完成！开始愉快的开发吧！${NC}"
    echo ""
}

# 捕获中断信号
trap 'echo ""; echo -e "${YELLOW}收到中断信号，正在停止服务...${NC}"; docker-compose down; exit 0' INT

# 执行主函数
main "$@"