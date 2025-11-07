#!/bin/bash

# 网络诊断脚本
# 用于诊断admin-frontend网络访问问题

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

# 获取服务器IP
get_server_ip() {
    log_info "获取服务器网络信息..."
    
    echo "🌐 网络接口信息："
    ip addr show | grep -E "(inet |UP)"
    echo ""
    
    echo "🔍 当前服务器IP地址："
    hostname -I
    echo ""
}

# 检查端口绑定
check_port_binding() {
    log_info "检查端口绑定..."
    
    echo "📡 端口3000绑定状态："
    netstat -tulpn | grep :3000
    echo ""
    
    echo "🐳 Docker端口映射："
    docker port asterops-admin-frontend-1 2>/dev/null || echo "容器未运行"
    echo ""
}

# 检查服务状态
check_service_status() {
    log_info "检查服务状态..."
    
    echo "📊 Docker服务状态："
    docker-compose -f docker-compose.admin.yml ps admin-frontend
    echo ""
    
    echo "🔍 容器详细信息："
    docker inspect asterops-admin-frontend-1 --format='{{.State.Status}}' 2>/dev/null || echo "容器未找到"
    echo ""
}

# 测试本地访问
test_local_access() {
    log_info "测试本地访问..."
    
    echo "🏠 本地访问测试："
    curl -I http://localhost:3000 2>/dev/null && log_success "localhost:3000 访问正常" || log_error "localhost:3000 访问失败"
    echo ""
    
    echo "🏠 127.0.0.1访问测试："
    curl -I http://127.0.0.1:3000 2>/dev/null && log_success "127.0.0.1:3000 访问正常" || log_error "127.0.0.1:3000 访问失败"
    echo ""
}

# 测试外部IP访问
test_external_access() {
    log_info "测试外部IP访问..."
    
    # 获取所有IP地址
    local ips=$(hostname -I)
    
    for ip in $ips; do
        echo "🌍 测试IP: $ip:3000"
        if curl -I http://$ip:3000 --connect-timeout 5 2>/dev/null; then
            log_success "$ip:3000 访问正常"
        else
            log_warning "$ip:3000 访问失败"
        fi
        echo ""
    done
}

# 检查防火墙
check_firewall() {
    log_info "检查防火墙状态..."
    
    echo "🔥 UFW状态："
    ufw status 2>/dev/null || echo "UFW未安装或未启用"
    echo ""
    
    echo "🔥 iptables规则："
    iptables -L -n | grep 3000 || echo "没有找到3000端口的iptables规则"
    echo ""
    
    echo "🔥 firewalld状态："
    systemctl status firewalld 2>/dev/null || echo "firewalld未安装"
    echo ""
}

# 检查网络连接
check_network_connectivity() {
    log_info "检查网络连接..."
    
    echo "🔗 网络接口状态："
    ip link show
    echo ""
    
    echo "🔗 路由表："
    ip route show
    echo ""
    
    echo "🔗 ARP表："
    arp -a | head -10
    echo ""
}

# 检查Docker网络
check_docker_network() {
    log_info "检查Docker网络..."
    
    echo "🐳 Docker网络列表："
    docker network ls
    echo ""
    
    echo "🐳 项目网络详情："
    docker network inspect asterops_llmops-network 2>/dev/null || echo "网络未找到"
    echo ""
    
    echo "🐳 容器网络配置："
    docker inspect asterops-admin-frontend-1 --format='{{.NetworkSettings.Networks}}' 2>/dev/null || echo "容器未找到"
    echo ""
}

# 提供解决方案
provide_solutions() {
    log_info "提供解决方案..."
    
    echo "=========================================="
    echo "🛠️  可能的解决方案："
    echo "=========================================="
    echo ""
    echo "1. 检查网络连接："
    echo "   - 确认客户端与服务器在同一网络"
    echo "   - 检查路由器/交换机配置"
    echo "   - 验证网络路由"
    echo ""
    echo "2. 检查防火墙："
    echo "   sudo ufw allow 3000"
    echo "   sudo iptables -A INPUT -p tcp --dport 3000 -j ACCEPT"
    echo ""
    echo "3. 检查Docker网络："
    echo "   docker network create --driver bridge llmops-network"
    echo "   docker-compose -f docker-compose.admin.yml down && docker-compose -f docker-compose.admin.yml up -d"
    echo ""
    echo "4. 使用不同端口："
    echo "   修改docker-compose.admin.yml中的端口映射"
    echo "   ports:"
    echo "     - \"8080:80\"  # 改为8080端口"
    echo ""
    echo "5. 检查服务绑定："
    echo "   确保服务绑定到0.0.0.0而不是127.0.0.1"
    echo ""
    echo "6. 网络诊断命令："
    echo "   telnet 172.16.10.3 3000"
    echo "   nmap -p 3000 172.16.10.3"
    echo "   traceroute 172.16.10.3"
    echo ""
}

# 主函数
main() {
    echo "=========================================="
    echo "🔍 Admin Frontend 网络诊断工具"
    echo "=========================================="
    echo ""
    
    get_server_ip
    check_port_binding
    check_service_status
    test_local_access
    test_external_access
    check_firewall
    check_network_connectivity
    check_docker_network
    provide_solutions
    
    log_info "诊断完成！请根据上述信息排查问题。"
}

# 运行主函数
main "$@"
