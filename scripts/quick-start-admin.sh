#!/bin/bash

# LLMOps Admin Frontend 快速启动脚本
# 使用专门的docker-compose.admin.yml文件

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

# 启动服务
start_services() {
    log_info "启动Admin Frontend服务..."
    
    # 使用专门的docker-compose文件
    docker-compose -f docker-compose.admin.yml up -d
    
    if [ $? -eq 0 ]; then
        log_success "服务启动成功"
    else
        log_error "服务启动失败"
        exit 1
    fi
}

# 检查服务状态
check_services() {
    log_info "检查服务状态..."
    
    # 等待服务启动
    sleep 15
    
    # 检查服务状态
    echo ""
    echo "📊 服务状态："
    docker-compose -f docker-compose.admin.yml ps
    
    echo ""
    log_info "等待服务完全启动..."
    sleep 10
}

# 显示访问信息
show_access_info() {
    echo ""
    echo "=========================================="
    echo "🎉 Admin Frontend 启动完成！"
    echo "=========================================="
    echo ""
    echo "🌐 访问地址："
    echo "   Admin Frontend: http://localhost:3000"
    echo "   API Gateway: http://localhost:8087"
    echo "   Consul UI: http://localhost:8500"
    echo ""
    echo "📝 常用命令："
    echo "   查看日志: docker-compose -f docker-compose.admin.yml logs -f"
    echo "   停止服务: docker-compose -f docker-compose.admin.yml down"
    echo "   重启服务: docker-compose -f docker-compose.admin.yml restart"
    echo ""
    echo "🔍 健康检查："
    echo "   curl http://localhost:3000/health"
    echo "   curl http://localhost:8087/health"
    echo ""
}

# 主函数
main() {
    echo "=========================================="
    echo "🚀 LLMOps Admin Frontend 快速启动"
    echo "=========================================="
    echo ""
    
    check_dependencies
    start_services
    check_services
    show_access_info
    
    log_success "启动完成！现在可以访问 http://localhost:3000"
}

# 运行主函数
main "$@"
