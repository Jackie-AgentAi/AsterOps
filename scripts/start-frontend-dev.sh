#!/bin/bash

# LLMOps前端开发启动脚本
# 启动前端开发服务器，不依赖Docker构建

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
echo "║                LLMOps 前端开发启动                          ║"
echo "║              管理后台 + 用户门户 + 移动端                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# 检查Node.js环境
check_nodejs() {
    echo -e "${BLUE}[1/4]${NC} 检查Node.js环境..."
    
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

# 安装前端依赖
install_dependencies() {
    echo -e "${BLUE}[2/4]${NC} 安装前端依赖..."
    
    # 安装管理后台依赖
    if [ -d "frontend/admin-dashboard" ] && [ -f "frontend/admin-dashboard/package.json" ]; then
        echo "   📦 安装管理后台依赖..."
        cd frontend/admin-dashboard
        if [ ! -d "node_modules" ]; then
            npm install --silent
        else
            echo "   ✅ 管理后台依赖已存在"
        fi
        cd ../..
    fi
    
    # 安装用户门户依赖
    if [ -d "frontend/user-portal" ] && [ -f "frontend/user-portal/package.json" ]; then
        echo "   📦 安装用户门户依赖..."
        cd frontend/user-portal
        if [ ! -d "node_modules" ]; then
            npm install --silent
        else
            echo "   ✅ 用户门户依赖已存在"
        fi
        cd ../..
    fi
    
    # 安装移动端依赖
    if [ -d "frontend/mobile-app" ] && [ -f "frontend/mobile-app/package.json" ]; then
        echo "   📦 安装移动端依赖..."
        cd frontend/mobile-app
        if [ ! -d "node_modules" ]; then
            npm install --silent
        else
            echo "   ✅ 移动端依赖已存在"
        fi
        cd ../..
    fi
    
    echo -e "${GREEN}✅ 前端依赖安装完成${NC}"
}

# 启动前端开发服务
start_frontend() {
    echo -e "${BLUE}[3/4]${NC} 启动前端开发服务..."
    
    local app=${1:-"admin"}
    
    case $app in
        "admin")
            echo "   🎨 启动管理后台开发模式..."
            if [ -d "frontend/admin-dashboard" ]; then
                cd frontend/admin-dashboard
                echo "   📱 管理后台将在 http://localhost:3000 启动"
                echo "   🔗 API地址: http://localhost:8081"
                echo ""
                echo -e "${YELLOW}按 Ctrl+C 停止开发服务器${NC}"
                echo ""
                npm run dev
            else
                echo -e "${RED}❌ 管理后台目录不存在${NC}"
                exit 1
            fi
            ;;
        "portal")
            echo "   🎨 启动用户门户开发模式..."
            if [ -d "frontend/user-portal" ]; then
                cd frontend/user-portal
                echo "   📱 用户门户将在 http://localhost:3001 启动"
                echo "   🔗 API地址: http://localhost:8081"
                echo ""
                echo -e "${YELLOW}按 Ctrl+C 停止开发服务器${NC}"
                echo ""
                npm run dev
            else
                echo -e "${RED}❌ 用户门户目录不存在${NC}"
                exit 1
            fi
            ;;
        "mobile")
            echo "   🎨 启动移动端开发模式..."
            if [ -d "frontend/mobile-app" ]; then
                cd frontend/mobile-app
                echo "   📱 移动端将在 http://localhost:3002 启动"
                echo "   🔗 API地址: http://localhost:8081"
                echo ""
                echo -e "${YELLOW}按 Ctrl+C 停止开发服务器${NC}"
                echo ""
                npm run dev
            else
                echo -e "${RED}❌ 移动端目录不存在${NC}"
                exit 1
            fi
            ;;
        "all")
            echo "   🎨 启动所有前端应用开发模式..."
            if command -v concurrently &> /dev/null; then
                echo "   📱 管理后台: http://localhost:3000"
                echo "   📱 用户门户: http://localhost:3001"
                echo "   📱 移动端:   http://localhost:3002"
                echo "   🔗 API地址: http://localhost:8081"
                echo ""
                echo -e "${YELLOW}按 Ctrl+C 停止所有开发服务器${NC}"
                echo ""
                concurrently \
                    "cd frontend/admin-dashboard && npm run dev" \
                    "cd frontend/user-portal && npm run dev" \
                    "cd frontend/mobile-app && npm run dev"
            else
                echo -e "${YELLOW}⚠️  concurrently未安装，请手动启动各个应用${NC}"
                echo ""
                echo -e "${BLUE}手动启动命令:${NC}"
                echo "  管理后台: cd frontend/admin-dashboard && npm run dev"
                echo "  用户门户: cd frontend/user-portal && npm run dev"
                echo "  移动端:   cd frontend/mobile-app && npm run dev"
                echo ""
                echo -e "${BLUE}安装concurrently:${NC}"
                echo "  npm install -g concurrently"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}❌ 未知应用: $app${NC}"
            echo "支持的应用: admin, portal, mobile, all"
            exit 1
            ;;
    esac
}

# 显示帮助信息
show_help() {
    echo "LLMOps前端开发启动脚本"
    echo ""
    echo "用法: $0 [应用] [选项]"
    echo ""
    echo "应用:"
    echo "  admin      启动管理后台 (默认)"
    echo "  portal     启动用户门户"
    echo "  mobile     启动移动端"
    echo "  all        启动所有前端应用"
    echo ""
    echo "选项:"
    echo "  --help     显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                    # 启动管理后台"
    echo "  $0 portal             # 启动用户门户"
    echo "  $0 all                # 启动所有前端应用"
    echo ""
    echo "注意:"
    echo "  - 确保后端服务已启动 (运行 ./scripts/start-backend-only.sh)"
    echo "  - 前端开发服务器支持热重载"
    echo "  - 按 Ctrl+C 停止开发服务器"
}

# 检查后端服务
check_backend() {
    echo -e "${BLUE}[4/4]${NC} 检查后端服务..."
    
    if curl -f -s "http://localhost:8081/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 后端服务运行正常${NC}"
    else
        echo -e "${YELLOW}⚠️  后端服务未运行或异常${NC}"
        echo -e "${BLUE}请先启动后端服务:${NC}"
        echo "  ./scripts/start-backend-only.sh"
        echo ""
        read -p "是否继续启动前端? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 主函数
main() {
    local app="admin"
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
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
    install_dependencies
    check_backend
    start_frontend "$app"
}

# 捕获中断信号
trap 'echo ""; echo -e "${YELLOW}收到中断信号，正在停止前端开发服务器...${NC}"; exit 0' INT

# 执行主函数
main "$@"