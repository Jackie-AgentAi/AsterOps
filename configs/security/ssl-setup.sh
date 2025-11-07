#!/bin/bash

# SSL/TLS证书配置脚本
# 生产环境HTTPS安全配置

set -e

# 配置参数
DOMAIN="${1:-yourdomain.com}"
EMAIL="${2:-admin@yourdomain.com}"
SSL_DIR="/etc/ssl/llmops"
CERT_DIR="$SSL_DIR/certs"
KEY_DIR="$SSL_DIR/private"
BACKUP_DIR="$SSL_DIR/backup"

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

# 检查参数
check_arguments() {
    if [ -z "$1" ]; then
        log_error "请指定域名"
        echo "用法: $0 <domain> [email]"
        echo "示例: $0 yourdomain.com admin@yourdomain.com"
        exit 1
    fi
    
    log "配置域名: $DOMAIN"
    log "配置邮箱: $EMAIL"
}

# 检查环境
check_environment() {
    log "检查SSL配置环境..."
    
    # 检查是否为root用户
    if [ "$EUID" -ne 0 ]; then
        log_error "请以root用户运行此脚本"
        exit 1
    fi
    
    # 检查openssl
    if ! command -v openssl &> /dev/null; then
        log_error "OpenSSL未安装"
        exit 1
    fi
    
    # 检查certbot
    if ! command -v certbot &> /dev/null; then
        log "安装Certbot..."
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
        log_success "Certbot安装完成"
    fi
    
    log_success "环境检查通过"
}

# 创建SSL目录
create_ssl_directories() {
    log "创建SSL目录..."
    
    mkdir -p "$SSL_DIR"
    mkdir -p "$CERT_DIR"
    mkdir -p "$KEY_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # 设置权限
    chmod 700 "$SSL_DIR"
    chmod 700 "$KEY_DIR"
    chmod 755 "$CERT_DIR"
    
    log_success "SSL目录创建完成"
}

# 生成自签名证书
generate_self_signed_cert() {
    log "生成自签名证书..."
    
    # 生成私钥
    openssl genrsa -out "$KEY_DIR/llmops.key" 4096
    chmod 600 "$KEY_DIR/llmops.key"
    
    # 生成证书签名请求
    openssl req -new -key "$KEY_DIR/llmops.key" -out "$SSL_DIR/llmops.csr" -subj "/C=CN/ST=Beijing/L=Beijing/O=LLMOps/OU=IT/CN=$DOMAIN"
    
    # 生成自签名证书
    openssl x509 -req -days 365 -in "$SSL_DIR/llmops.csr" -signkey "$KEY_DIR/llmops.key" -out "$CERT_DIR/llmops.crt"
    
    # 生成证书链
    cat "$CERT_DIR/llmops.crt" > "$CERT_DIR/llmops-chain.crt"
    
    log_success "自签名证书生成完成"
}

# 申请Let's Encrypt证书
request_letsencrypt_cert() {
    log "申请Let's Encrypt证书..."
    
    # 停止Nginx
    systemctl stop nginx 2>/dev/null || true
    
    # 申请证书
    certbot certonly --standalone -d "$DOMAIN" -d "www.$DOMAIN" -d "api.$DOMAIN" -d "admin.$DOMAIN" -d "monitor.$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive
    
    # 创建符号链接
    ln -sf "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$CERT_DIR/llmops.crt"
    ln -sf "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$KEY_DIR/llmops.key"
    ln -sf "/etc/letsencrypt/live/$DOMAIN/chain.pem" "$CERT_DIR/llmops-chain.crt"
    
    log_success "Let's Encrypt证书申请完成"
}

# 生成DH参数
generate_dh_params() {
    log "生成DH参数..."
    
    openssl dhparam -out "$SSL_DIR/dhparam.pem" 2048
    chmod 600 "$SSL_DIR/dhparam.pem"
    
    log_success "DH参数生成完成"
}

# 配置证书自动续期
setup_auto_renewal() {
    log "配置证书自动续期..."
    
    # 创建续期脚本
    cat > /etc/cron.d/certbot-renew << EOF
# Let's Encrypt证书自动续期
0 12 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
EOF
    
    # 创建续期钩子脚本
    cat > /etc/letsencrypt/renewal-hooks/post/reload-nginx.sh << 'EOF'
#!/bin/bash
# 证书续期后重新加载Nginx
systemctl reload nginx
EOF
    
    chmod +x /etc/letsencrypt/renewal-hooks/post/reload-nginx.sh
    
    log_success "证书自动续期配置完成"
}

# 配置Nginx SSL
configure_nginx_ssl() {
    log "配置Nginx SSL..."
    
    # 创建SSL配置文件
    cat > /etc/nginx/snippets/ssl-params.conf << EOF
# SSL配置参数
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS;
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
ssl_dhparam $SSL_DIR/dhparam.pem;
ssl_ecdh_curve secp384r1;
ssl_buffer_size 8k;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate $CERT_DIR/llmops-chain.crt;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
EOF
    
    # 创建SSL站点配置
    cat > /etc/nginx/sites-available/llmops-ssl << EOF
# LLMOps SSL站点配置
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN api.$DOMAIN admin.$DOMAIN monitor.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    ssl_certificate $CERT_DIR/llmops.crt;
    ssl_certificate_key $KEY_DIR/llmops.key;
    include /etc/nginx/snippets/ssl-params.conf;
    
    root /usr/share/nginx/html;
    index index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}

server {
    listen 443 ssl http2;
    server_name api.$DOMAIN;
    
    ssl_certificate $CERT_DIR/llmops.crt;
    ssl_certificate_key $KEY_DIR/llmops.key;
    include /etc/nginx/snippets/ssl-params.conf;
    
    location / {
        proxy_pass http://localhost:8087;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

server {
    listen 443 ssl http2;
    server_name admin.$DOMAIN;
    
    ssl_certificate $CERT_DIR/llmops.crt;
    ssl_certificate_key $KEY_DIR/llmops.key;
    include /etc/nginx/snippets/ssl-params.conf;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

server {
    listen 443 ssl http2;
    server_name monitor.$DOMAIN;
    
    ssl_certificate $CERT_DIR/llmops.crt;
    ssl_certificate_key $KEY_DIR/llmops.key;
    include /etc/nginx/snippets/ssl-params.conf;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # 启用站点
    ln -sf /etc/nginx/sites-available/llmops-ssl /etc/nginx/sites-enabled/
    
    # 测试Nginx配置
    nginx -t
    
    log_success "Nginx SSL配置完成"
}

# 配置HSTS
configure_hsts() {
    log "配置HSTS..."
    
    # 创建HSTS配置文件
    cat > /etc/nginx/snippets/hsts.conf << EOF
# HSTS配置
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
EOF
    
    log_success "HSTS配置完成"
}

# 配置OCSP装订
configure_ocsp() {
    log "配置OCSP装订..."
    
    # 创建OCSP配置文件
    cat > /etc/nginx/snippets/ocsp.conf << EOF
# OCSP装订配置
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate $CERT_DIR/llmops-chain.crt;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
EOF
    
    log_success "OCSP装订配置完成"
}

# 测试SSL配置
test_ssl_config() {
    log "测试SSL配置..."
    
    # 测试证书
    if [ -f "$CERT_DIR/llmops.crt" ]; then
        openssl x509 -in "$CERT_DIR/llmops.crt" -text -noout
        log_success "证书测试通过"
    else
        log_error "证书文件不存在"
        return 1
    fi
    
    # 测试私钥
    if [ -f "$KEY_DIR/llmops.key" ]; then
        openssl rsa -in "$KEY_DIR/llmops.key" -check -noout
        log_success "私钥测试通过"
    else
        log_error "私钥文件不存在"
        return 1
    fi
    
    # 测试Nginx配置
    nginx -t
    log_success "Nginx配置测试通过"
}

# 显示SSL信息
show_ssl_info() {
    log "SSL配置信息:"
    echo ""
    echo "📁 SSL目录: $SSL_DIR"
    echo "🔐 证书文件: $CERT_DIR/llmops.crt"
    echo "🔑 私钥文件: $KEY_DIR/llmops.key"
    echo "🔗 证书链: $CERT_DIR/llmops-chain.crt"
    echo "🔒 DH参数: $SSL_DIR/dhparam.pem"
    echo ""
    echo "🌐 访问地址:"
    echo "  - 主站: https://$DOMAIN"
    echo "  - API: https://api.$DOMAIN"
    echo "  - 管理: https://admin.$DOMAIN"
    echo "  - 监控: https://monitor.$DOMAIN"
    echo ""
    echo "📋 管理命令:"
    echo "  - 测试配置: nginx -t"
    echo "  - 重新加载: systemctl reload nginx"
    echo "  - 查看证书: openssl x509 -in $CERT_DIR/llmops.crt -text -noout"
    echo "  - 续期证书: certbot renew"
    echo ""
    echo "🔄 自动续期: 已配置，每天12:00检查"
}

# 主函数
main() {
    case "${3:-setup}" in
        "setup")
            log "开始SSL配置..."
            check_arguments "$1" "$2"
            check_environment
            create_ssl_directories
            generate_self_signed_cert
            generate_dh_params
            configure_nginx_ssl
            configure_hsts
            configure_ocsp
            test_ssl_config
            show_ssl_info
            log_success "SSL配置完成!"
            ;;
        "letsencrypt")
            log "申请Let's Encrypt证书..."
            check_arguments "$1" "$2"
            check_environment
            create_ssl_directories
            request_letsencrypt_cert
            generate_dh_params
            configure_nginx_ssl
            configure_hsts
            configure_ocsp
            setup_auto_renewal
            test_ssl_config
            show_ssl_info
            log_success "Let's Encrypt证书配置完成!"
            ;;
        "test")
            test_ssl_config
            ;;
        "renew")
            log "续期证书..."
            certbot renew --quiet
            systemctl reload nginx
            log_success "证书续期完成"
            ;;
        "info")
            show_ssl_info
            ;;
        *)
            echo "用法: $0 <domain> [email] {setup|letsencrypt|test|renew|info}"
            echo ""
            echo "命令:"
            echo "  setup       配置自签名证书 (默认)"
            echo "  letsencrypt 申请Let's Encrypt证书"
            echo "  test        测试SSL配置"
            echo "  renew       续期证书"
            echo "  info        显示SSL信息"
            echo ""
            echo "示例:"
            echo "  $0 yourdomain.com admin@yourdomain.com setup"
            echo "  $0 yourdomain.com admin@yourdomain.com letsencrypt"
            echo "  $0 yourdomain.com admin@yourdomain.com test"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"







