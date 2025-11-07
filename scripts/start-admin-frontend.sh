#!/bin/bash

# LLMOps Admin Frontend 启动脚本
# 用于通过docker-compose运行管理后台前端

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

# 检查Docker和Docker Compose
check_dependencies() {
    log_info "检查依赖环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装Docker Compose"
        exit 1
    fi
    
    log_success "依赖环境检查通过"
}

# 检查项目目录
check_project_directory() {
    log_info "检查项目目录..."
    
    if [ ! -f "docker-compose.yml" ]; then
        log_error "未找到docker-compose.yml文件，请确保在项目根目录运行此脚本"
        exit 1
    fi
    
    if [ ! -d "frontend/admin-dashboard" ]; then
        log_error "未找到admin-dashboard目录"
        exit 1
    fi
    
    log_success "项目目录检查通过"
}

# 构建admin-frontend镜像
build_admin_frontend() {
    log_info "构建admin-frontend镜像..."
    
    # 检查Dockerfile是否存在
    if [ ! -f "frontend/admin-dashboard/Dockerfile" ]; then
        log_error "未找到frontend/admin-dashboard/Dockerfile"
        exit 1
    fi
    
    # 构建镜像
    docker-compose build admin-frontend
    
    if [ $? -eq 0 ]; then
        log_success "admin-frontend镜像构建成功"
    else
        log_error "admin-frontend镜像构建失败"
        exit 1
    fi
}

# 启动admin-frontend服务
start_admin_frontend() {
    log_info "启动admin-frontend服务..."
    
    # 启动admin-frontend及其依赖服务
    docker-compose up -d api-gateway admin-frontend
    
    if [ $? -eq 0 ]; then
        log_success "admin-frontend服务启动成功"
    else
        log_error "admin-frontend服务启动失败"
        exit 1
    fi
}

# 检查服务状态
check_service_status() {
    log_info "检查服务状态..."
    
    # 等待服务启动
    sleep 10
    
    # 检查admin-frontend健康状态
    if docker-compose ps admin-frontend | grep -q "Up"; then
        log_success "admin-frontend服务运行正常"
    else
        log_warning "admin-frontend服务可能未正常启动"
    fi
    
    # 检查api-gateway健康状态
    if docker-compose ps api-gateway | grep -q "Up"; then
        log_success "api-gateway服务运行正常"
    else
        log_warning "api-gateway服务可能未正常启动"
    fi
}

# 显示访问信息
show_access_info() {
    log_info "服务访问信息："
    echo ""
    echo "🌐 Admin Frontend: http://localhost:3000"
    echo "🔗 API Gateway: http://localhost:8087"
    echo "📊 健康检查: http://localhost:3000/health"
    echo ""
    echo "📝 查看日志命令："
    echo "   docker-compose logs -f admin-frontend"
    echo "   docker-compose logs -f api-gateway"
    echo ""
    echo "🛑 停止服务命令："
    echo "   docker-compose down"
    echo ""
}

# 主函数
main() {
    echo "=========================================="
    echo "🚀 LLMOps Admin Frontend 启动脚本"
    echo "=========================================="
    echo ""
    
    check_dependencies
    check_project_directory
    build_admin_frontend
    start_admin_frontend
    check_service_status
    show_access_info
    
    log_success "Admin Frontend 启动完成！"
}

# 运行主函数
main "$@"
