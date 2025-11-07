#!/bin/bash

# Admin Frontend 访问测试脚本

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

# 测试服务状态
test_service_status() {
    log_info "检查服务状态..."
    
    if docker-compose -f docker-compose.admin.yml ps admin-frontend | grep -q "Up.*healthy"; then
        log_success "admin-frontend服务运行正常"
    else
        log_error "admin-frontend服务未正常运行"
        return 1
    fi
    
    if docker-compose -f docker-compose.admin.yml ps api-gateway | grep -q "Up.*healthy"; then
        log_success "api-gateway服务运行正常"
    else
        log_warning "api-gateway服务可能未正常运行"
    fi
}

# 测试端口访问
test_port_access() {
    log_info "测试端口访问..."
    
    # 测试本地访问
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
        log_success "localhost:3000 访问正常"
    else
        log_error "localhost:3000 访问失败"
        return 1
    fi
    
    # 测试外部IP访问
    local server_ips=$(hostname -I)
    for ip in $server_ips; do
        if [[ $ip =~ ^172\.16\.10\. ]]; then
            log_info "测试IP: $ip:3000"
            if curl -s -o /dev/null -w "%{http_code}" http://$ip:3000 --connect-timeout 5 | grep -q "200"; then
                log_success "$ip:3000 访问正常"
            else
                log_warning "$ip:3000 访问失败"
            fi
        fi
    done
}

# 测试API连接
test_api_connection() {
    log_info "测试API连接..."
    
    # 测试API Gateway
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8087/health | grep -q "200"; then
        log_success "API Gateway健康检查正常"
    else
        log_warning "API Gateway健康检查失败"
    fi
    
    # 测试admin-frontend健康检查
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health | grep -q "200"; then
        log_success "Admin Frontend健康检查正常"
    else
        log_warning "Admin Frontend健康检查失败"
    fi
}

# 显示访问信息
show_access_info() {
    log_info "访问信息："
    echo ""
    echo "🌐 主要访问地址："
    echo "   Admin Frontend: http://172.16.10.3:3000"
    echo "   API Gateway: http://172.16.10.3:8087"
    echo ""
    echo "🔍 其他可用IP："
    local server_ips=$(hostname -I)
    for ip in $server_ips; do
        if [[ ! $ip =~ ^172\.22\.|^172\.17\.|^172\.20\.|^172\.21\. ]]; then
            echo "   http://$ip:3000"
        fi
    done
    echo ""
    echo "📊 监控地址："
    echo "   Consul UI: http://172.16.10.3:8500"
    echo ""
}

# 主函数
main() {
    echo "=========================================="
    echo "🧪 Admin Frontend 访问测试"
    echo "=========================================="
    echo ""
    
    test_service_status
    test_port_access
    test_api_connection
    show_access_info
    
    log_success "测试完成！现在可以访问 http://172.16.10.3:3000"
}

# 运行主函数
main "$@"
