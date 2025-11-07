#!/bin/bash

# LLMOps全栈启动脚本
# 同时启动前后端服务

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
echo "║              后端服务 + 前端开发 + 监控                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# 显示帮助信息
show_help() {
    echo "LLMOps全栈启动脚本"
    echo ""
    echo "用法: $0 [选项] [前端应用]"
    echo ""
    echo "选项:"
    echo "  --backend-only    只启动后端服务"
    echo "  --frontend-only   只启动前端服务"
    echo "  --logs            启动后显示日志"
    echo "  --help            显示帮助信息"
    echo ""
    echo "前端应用:"
    echo "  admin      启动管理后台 (默认)"
    echo "  portal     启动用户门户"
    echo "  mobile     启动移动端"
    echo "  all        启动所有前端应用"
    echo ""
    echo "示例:"
    echo "  $0                           # 启动后端 + 管理后台"
    echo "  $0 portal                    # 启动后端 + 用户门户"
    echo "  $0 all --logs                # 启动后端 + 所有前端 + 显示日志"
    echo "  $0 --backend-only            # 只启动后端服务"
    echo "  $0 --frontend-only admin     # 只启动管理后台"
}

# 启动后端服务
start_backend() {
    echo -e "${BLUE}[1/3]${NC} 启动后端服务..."
    
    if [ -f "./scripts/start-backend-only.sh" ]; then
        echo "   🔧 运行后端启动脚本..."
        ./scripts/start-backend-only.sh
    else
        echo -e "${RED}❌ 后端启动脚本不存在${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 后端服务启动完成${NC}"
}

# 启动前端服务
start_frontend() {
    local app=${1:-"admin"}
    
    echo -e "${BLUE}[2/3]${NC} 启动前端服务..."
    
    if [ -f "./scripts/start-frontend-dev.sh" ]; then
        echo "   🎨 运行前端启动脚本..."
        echo "   📱 前端应用: $app"
        echo ""
        echo -e "${YELLOW}前端开发服务器将在新终端中启动...${NC}"
        echo ""
        
        # 在新终端中启动前端
        if command -v gnome-terminal &> /dev/null; then
            gnome-terminal --title="LLMOps前端-$app" -- bash -c "cd $(pwd) && ./scripts/start-frontend-dev.sh $app; exec bash"
        elif command -v xterm &> /dev/null; then
            xterm -title "LLMOps前端-$app" -e "cd $(pwd) && ./scripts/start-frontend-dev.sh $app; exec bash" &
        elif command -v konsole &> /dev/null; then
            konsole --title "LLMOps前端-$app" -e "cd $(pwd) && ./scripts/start-frontend-dev.sh $app; exec bash" &
        else
            echo -e "${YELLOW}⚠️  未找到终端模拟器，请手动启动前端:${NC}"
            echo "  ./scripts/start-frontend-dev.sh $app"
            echo ""
            echo -e "${BLUE}或者在新终端中运行:${NC}"
            echo "  cd $(pwd)"
            echo "  ./scripts/start-frontend-dev.sh $app"
        fi
    else
        echo -e "${RED}❌ 前端启动脚本不存在${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 前端服务启动完成${NC}"
}

# 显示服务信息
show_info() {
    echo -e "${BLUE}[3/3]${NC} 显示服务信息..."
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                        服务状态                            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 显示Docker服务状态
    if command -v docker-compose &> /dev/null; then
        docker-compose ps
    fi
    
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
    echo -e "${GREEN}║                        管理命令                            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}后端管理:${NC}"
    echo "  查看日志: docker-compose logs -f [服务名]"
    echo "  停止服务: docker-compose down"
    echo "  重启服务: docker-compose restart [服务名]"
    echo "  健康检查: ./scripts/health-check-all.sh"
    echo ""
    echo -e "${BLUE}前端管理:${NC}"
    echo "  启动前端: ./scripts/start-frontend-dev.sh [应用]"
    echo "  停止前端: 在终端中按 Ctrl+C"
    echo "  前端测试: ./scripts/frontend-dev.sh test"
    echo ""
    echo -e "${BLUE}全栈管理:${NC}"
    echo "  启动全栈: ./scripts/start-all.sh [应用]"
    echo "  只启动后端: ./scripts/start-all.sh --backend-only"
    echo "  只启动前端: ./scripts/start-all.sh --frontend-only [应用]"
    echo ""
}

# 显示日志
show_logs() {
    if [ "$1" = "--logs" ]; then
        echo -e "${BLUE}📋 显示后端服务日志 (按 Ctrl+C 退出)...${NC}"
        echo ""
        docker-compose logs -f --tail=50
    fi
}

# 主函数
main() {
    local backend_only=false
    local frontend_only=false
    local show_logs_flag=false
    local app="admin"
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
                ;;
            --backend-only)
                backend_only=true
                shift
                ;;
            --frontend-only)
                frontend_only=true
                shift
                ;;
            --logs)
                show_logs_flag=true
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
    if [ "$frontend_only" = true ]; then
        echo -e "${BLUE}只启动前端服务...${NC}"
        start_frontend "$app"
    elif [ "$backend_only" = true ]; then
        echo -e "${BLUE}只启动后端服务...${NC}"
        start_backend
    else
        echo -e "${BLUE}启动全栈服务...${NC}"
        start_backend
        start_frontend "$app"
    fi
    
    show_info
    
    # 显示日志
    if [ "$show_logs_flag" = true ]; then
        show_logs --logs
    fi
    
    echo ""
    echo -e "${GREEN}🎉 LLMOps全栈环境启动完成！${NC}"
    echo ""
    echo -e "${YELLOW}提示:${NC}"
    echo "  - 前端开发服务器支持热重载"
    echo "  - 修改前端代码会自动刷新页面"
    echo "  - 后端API服务已就绪，可以开始开发"
    echo "  - 使用 Ctrl+C 停止服务"
    echo ""
}

# 捕获中断信号
trap 'echo ""; echo -e "${YELLOW}收到中断信号，正在停止服务...${NC}"; docker-compose down; exit 0' INT

# 执行主函数
main "$@"