#!/bin/bash

# LLMOps平台前端开发脚本
# 用于开发、构建、部署前端应用

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查前端开发依赖..."
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js 未安装"
        exit 1
    fi
    
    # 检查npm
    if ! command -v npm &> /dev/null; then
        log_error "npm 未安装"
        exit 1
    fi
    
    # 检查Vue CLI
    if ! command -v vue &> /dev/null; then
        log_warning "Vue CLI 未安装，将使用Vite"
    fi
    
    log_success "依赖检查通过"
}

# 安装依赖
install_dependencies() {
    log_info "安装前端依赖..."
    
    # 安装管理后台依赖
    if [ -d "frontend/admin-dashboard" ]; then
        log_info "安装管理后台依赖..."
        cd frontend/admin-dashboard
        npm install
        cd ../..
    fi
    
    # 安装用户门户依赖
    if [ -d "frontend/user-portal" ]; then
        log_info "安装用户门户依赖..."
        cd frontend/user-portal
        npm install
        cd ../..
    fi
    
    # 安装移动端依赖
    if [ -d "frontend/mobile-app" ]; then
        log_info "安装移动端依赖..."
        cd frontend/mobile-app
        npm install
        cd ../..
    fi
    
    log_success "依赖安装完成"
}

# 开发模式
start_dev() {
    local app=$1
    
    case $app in
        "admin")
            log_info "启动管理后台开发模式..."
            cd frontend/admin-dashboard
            npm run dev
            ;;
        "portal")
            log_info "启动用户门户开发模式..."
            cd frontend/user-portal
            npm run dev
            ;;
        "mobile")
            log_info "启动移动端开发模式..."
            cd frontend/mobile-app
            npm run dev
            ;;
        "all")
            log_info "启动所有前端应用开发模式..."
            # 使用concurrently同时启动多个应用
            if command -v concurrently &> /dev/null; then
                concurrently \
                    "cd frontend/admin-dashboard && npm run dev" \
                    "cd frontend/user-portal && npm run dev" \
                    "cd frontend/mobile-app && npm run dev"
            else
                log_warning "concurrently 未安装，请手动启动各个应用"
            fi
            ;;
        *)
            log_error "未知应用: $app"
            exit 1
            ;;
    esac
}

# 构建应用
build_app() {
    local app=$1
    
    case $app in
        "admin")
            log_info "构建管理后台..."
            cd frontend/admin-dashboard
            npm run build
            cd ../..
            ;;
        "portal")
            log_info "构建用户门户..."
            cd frontend/user-portal
            npm run build
            cd ../..
            ;;
        "mobile")
            log_info "构建移动端应用..."
            cd frontend/mobile-app
            npm run build
            cd ../..
            ;;
        "all")
            log_info "构建所有前端应用..."
            build_app "admin"
            build_app "portal"
            build_app "mobile"
            ;;
        *)
            log_error "未知应用: $app"
            exit 1
            ;;
    esac
    
    log_success "构建完成"
}

# 代码检查
lint_code() {
    local app=$1
    
    case $app in
        "admin")
            log_info "检查管理后台代码..."
            cd frontend/admin-dashboard
            npm run lint
            cd ../..
            ;;
        "portal")
            log_info "检查用户门户代码..."
            cd frontend/user-portal
            npm run lint
            cd ../..
            ;;
        "mobile")
            log_info "检查移动端代码..."
            cd frontend/mobile-app
            npm run lint
            cd ../..
            ;;
        "all")
            log_info "检查所有前端代码..."
            lint_code "admin"
            lint_code "portal"
            lint_code "mobile"
            ;;
        *)
            log_error "未知应用: $app"
            exit 1
            ;;
    esac
    
    log_success "代码检查完成"
}

# 类型检查
type_check() {
    local app=$1
    
    case $app in
        "admin")
            log_info "检查管理后台类型..."
            cd frontend/admin-dashboard
            npm run type-check
            cd ../..
            ;;
        "portal")
            log_info "检查用户门户类型..."
            cd frontend/user-portal
            npm run type-check
            cd ../..
            ;;
        "mobile")
            log_info "检查移动端类型..."
            cd frontend/mobile-app
            npm run type-check
            cd ../..
            ;;
        "all")
            log_info "检查所有前端类型..."
            type_check "admin"
            type_check "portal"
            type_check "mobile"
            ;;
        *)
            log_error "未知应用: $app"
            exit 1
            ;;
    esac
    
    log_success "类型检查完成"
}

# 部署应用
deploy_app() {
    local app=$1
    local env=$2
    
    case $app in
        "admin")
            log_info "部署管理后台到 $env 环境..."
            build_app "admin"
            # 实现部署逻辑
            ;;
        "portal")
            log_info "部署用户门户到 $env 环境..."
            build_app "portal"
            # 实现部署逻辑
            ;;
        "mobile")
            log_info "部署移动端到 $env 环境..."
            build_app "mobile"
            # 实现部署逻辑
            ;;
        "all")
            log_info "部署所有前端应用到 $env 环境..."
            deploy_app "admin" "$env"
            deploy_app "portal" "$env"
            deploy_app "mobile" "$env"
            ;;
        *)
            log_error "未知应用: $app"
            exit 1
            ;;
    esac
    
    log_success "部署完成"
}

# 创建新组件
create_component() {
    local app=$1
    local name=$2
    
    case $app in
        "admin")
            log_info "在管理后台创建组件: $name"
            cd frontend/admin-dashboard
            # 实现组件创建逻辑
            cd ../..
            ;;
        "portal")
            log_info "在用户门户创建组件: $name"
            cd frontend/user-portal
            # 实现组件创建逻辑
            cd ../..
            ;;
        "mobile")
            log_info "在移动端创建组件: $name"
            cd frontend/mobile-app
            # 实现组件创建逻辑
            cd ../..
            ;;
        *)
            log_error "未知应用: $app"
            exit 1
            ;;
    esac
    
    log_success "组件创建完成"
}

# 显示帮助
show_help() {
    echo "LLMOps平台前端开发脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  install                   安装依赖"
    echo "  dev <app>                 启动开发模式"
    echo "  build <app>               构建应用"
    echo "  lint <app>                代码检查"
    echo "  type-check <app>          类型检查"
    echo "  deploy <app> <env>        部署应用"
    echo "  create <app> <name>       创建组件"
    echo "  help                     显示帮助信息"
    echo ""
    echo "应用类型:"
    echo "  admin     管理后台"
    echo "  portal    用户门户"
    echo "  mobile    移动端"
    echo "  all       所有应用"
    echo ""
    echo "环境类型:"
    echo "  dev       开发环境"
    echo "  test      测试环境"
    echo "  prod      生产环境"
    echo ""
    echo "示例:"
    echo "  $0 install                # 安装依赖"
    echo "  $0 dev admin              # 启动管理后台开发"
    echo "  $0 build all              # 构建所有应用"
    echo "  $0 deploy admin prod      # 部署管理后台到生产环境"
}

# 主函数
main() {
    case "${1:-help}" in
        install)
            check_dependencies
            install_dependencies
            ;;
        dev)
            start_dev "${2:-all}"
            ;;
        build)
            build_app "${2:-all}"
            ;;
        lint)
            lint_code "${2:-all}"
            ;;
        type-check)
            type_check "${2:-all}"
            ;;
        deploy)
            deploy_app "${2:-all}" "${3:-dev}"
            ;;
        create)
            create_component "${2:-admin}" "${3:-NewComponent}"
            ;;
        help)
            show_help
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"



