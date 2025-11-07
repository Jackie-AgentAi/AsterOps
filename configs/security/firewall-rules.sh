#!/bin/bash

# 防火墙安全规则配置
# 生产环境网络安全加固

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请以root用户运行此脚本"
        exit 1
    fi
}

# 安装iptables
install_iptables() {
    log "检查iptables安装..."
    
    if ! command -v iptables &> /dev/null; then
        log "安装iptables..."
        apt-get update
        apt-get install -y iptables iptables-persistent
        log_success "iptables安装完成"
    else
        log_success "iptables已安装"
    fi
}

# 备份现有规则
backup_rules() {
    log "备份现有防火墙规则..."
    
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/backup-$(date +%Y%m%d-%H%M%S).rules
    log_success "防火墙规则备份完成"
}

# 清除现有规则
flush_rules() {
    log "清除现有防火墙规则..."
    
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    
    log_success "现有规则清除完成"
}

# 设置默认策略
set_default_policies() {
    log "设置默认策略..."
    
    # 默认拒绝所有连接
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    log_success "默认策略设置完成"
}

# 允许回环接口
allow_loopback() {
    log "允许回环接口..."
    
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    log_success "回环接口规则添加完成"
}

# 允许已建立的连接
allow_established() {
    log "允许已建立的连接..."
    
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    log_success "已建立连接规则添加完成"
}

# 允许SSH连接
allow_ssh() {
    log "允许SSH连接..."
    
    # 限制SSH连接频率
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    log_success "SSH规则添加完成"
}

# 允许HTTP和HTTPS
allow_web() {
    log "允许HTTP和HTTPS连接..."
    
    # HTTP
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    
    log_success "Web服务规则添加完成"
}

# 允许LLMOps服务端口
allow_llmops_services() {
    log "允许LLMOps服务端口..."
    
    # 微服务端口
    iptables -A INPUT -p tcp --dport 8081 -j ACCEPT  # 用户服务
    iptables -A INPUT -p tcp --dport 8082 -j ACCEPT  # 项目管理服务
    iptables -A INPUT -p tcp --dport 8083 -j ACCEPT  # 模型服务
    iptables -A INPUT -p tcp --dport 8084 -j ACCEPT  # 推理服务
    iptables -A INPUT -p tcp --dport 8085 -j ACCEPT  # 成本服务
    iptables -A INPUT -p tcp --dport 8086 -j ACCEPT  # 监控服务
    iptables -A INPUT -p tcp --dport 8087 -j ACCEPT  # API网关
    
    # 基础设施端口
    iptables -A INPUT -p tcp --dport 5432 -j ACCEPT  # PostgreSQL
    iptables -A INPUT -p tcp --dport 6379 -j ACCEPT  # Redis
    iptables -A INPUT -p tcp --dport 8500 -j ACCEPT  # Consul
    iptables -A INPUT -p tcp --dport 9000 -j ACCEPT  # MinIO
    iptables -A INPUT -p tcp --dport 9001 -j ACCEPT  # MinIO Console
    iptables -A INPUT -p tcp --dport 9090 -j ACCEPT  # Prometheus
    iptables -A INPUT -p tcp --dport 3000 -j ACCEPT  # Grafana
    
    log_success "LLMOps服务端口规则添加完成"
}

# 防止DDoS攻击
prevent_ddos() {
    log "配置DDoS防护..."
    
    # 限制连接频率
    iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
    
    # 防止SYN洪水攻击
    iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
    iptables -A INPUT -p tcp --syn -j DROP
    
    # 防止ICMP洪水攻击
    iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
    iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
    
    log_success "DDoS防护配置完成"
}

# 防止端口扫描
prevent_port_scan() {
    log "配置端口扫描防护..."
    
    # 记录端口扫描尝试
    iptables -A INPUT -p tcp --tcp-flags ALL NONE -j LOG --log-prefix "NULL_SCAN: "
    iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
    
    iptables -A INPUT -p tcp --tcp-flags ALL ALL -j LOG --log-prefix "XMAS_SCAN: "
    iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
    
    iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j LOG --log-prefix "XMAS_SCAN: "
    iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
    
    iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j LOG --log-prefix "XMAS_SCAN: "
    iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
    
    log_success "端口扫描防护配置完成"
}

# 防止IP欺骗
prevent_ip_spoofing() {
    log "配置IP欺骗防护..."
    
    # 拒绝来自私有网络的源地址
    iptables -A INPUT -s 10.0.0.0/8 -j DROP
    iptables -A INPUT -s 172.16.0.0/12 -j DROP
    iptables -A INPUT -s 192.168.0.0/16 -j DROP
    iptables -A INPUT -s 127.0.0.0/8 -j DROP
    
    # 拒绝广播地址
    iptables -A INPUT -s 255.255.255.255 -j DROP
    iptables -A INPUT -s 0.0.0.0 -j DROP
    
    log_success "IP欺骗防护配置完成"
}

# 允许ICMP
allow_icmp() {
    log "允许ICMP..."
    
    iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
    iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
    iptables -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
    iptables -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
    
    log_success "ICMP规则添加完成"
}

# 记录被拒绝的连接
log_rejected() {
    log "配置拒绝连接日志..."
    
    iptables -A INPUT -j LOG --log-prefix "REJECTED: " --log-level 4
    iptables -A INPUT -j DROP
    
    log_success "拒绝连接日志配置完成"
}

# 保存规则
save_rules() {
    log "保存防火墙规则..."
    
    # 保存iptables规则
    iptables-save > /etc/iptables/rules.v4
    
    # 安装iptables-persistent
    apt-get install -y iptables-persistent
    
    # 启用iptables服务
    systemctl enable iptables
    systemctl start iptables
    
    log_success "防火墙规则保存完成"
}

# 显示规则
show_rules() {
    log "显示当前防火墙规则..."
    
    echo ""
    echo "=== 当前防火墙规则 ==="
    iptables -L -n -v
    echo ""
    echo "=== 规则统计 ==="
    iptables -L -n | grep -c "ACCEPT\|DROP\|REJECT"
    echo ""
}

# 主函数
main() {
    case "${1:-setup}" in
        "setup")
            log "开始配置防火墙安全规则..."
            check_root
            install_iptables
            backup_rules
            flush_rules
            set_default_policies
            allow_loopback
            allow_established
            allow_ssh
            allow_web
            allow_llmops_services
            prevent_ddos
            prevent_port_scan
            prevent_ip_spoofing
            allow_icmp
            log_rejected
            save_rules
            show_rules
            log_success "防火墙安全规则配置完成!"
            ;;
        "status")
            show_rules
            ;;
        "backup")
            backup_rules
            ;;
        "restore")
            if [ -z "$2" ]; then
                log_error "请指定备份文件"
                exit 1
            fi
            log "恢复防火墙规则..."
            iptables-restore < "$2"
            save_rules
            log_success "防火墙规则恢复完成"
            ;;
        "flush")
            log "清除所有防火墙规则..."
            flush_rules
            save_rules
            log_success "防火墙规则清除完成"
            ;;
        *)
            echo "用法: $0 {setup|status|backup|restore|flush} [backup-file]"
            echo ""
            echo "命令:"
            echo "  setup     配置防火墙安全规则 (默认)"
            echo "  status    显示当前防火墙规则"
            echo "  backup    备份当前防火墙规则"
            echo "  restore   恢复防火墙规则"
            echo "  flush     清除所有防火墙规则"
            echo ""
            echo "示例:"
            echo "  $0 setup"
            echo "  $0 status"
            echo "  $0 backup"
            echo "  $0 restore /etc/iptables/backup-20240101-120000.rules"
            echo "  $0 flush"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"







