#!/bin/bash

# LLMOps技术架构设置脚本
# 用于设置和配置技术架构组件

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
    log_info "检查技术架构依赖..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装"
        exit 1
    fi
    
    # 检查Go
    if ! command -v go &> /dev/null; then
        log_error "Go 未安装"
        exit 1
    fi
    
    # 检查Python
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 未安装"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 设置消息队列
setup_message_queue() {
    log_info "设置消息队列..."
    
    # 创建RabbitMQ配置
    cat > docker-compose.rabbitmq.yml << EOF
version: '3.8'

services:
  rabbitmq:
    image: rabbitmq:3-management
    hostname: rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=admin
      - RABBITMQ_DEFAULT_PASS=admin
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - llmops-network
    restart: unless-stopped

volumes:
  rabbitmq_data:

networks:
  llmops-network:
    external: true
EOF

    # 启动RabbitMQ
    docker-compose -f docker-compose.rabbitmq.yml up -d
    
    log_success "消息队列设置完成"
}

# 设置服务发现
setup_service_discovery() {
    log_info "设置服务发现..."
    
    # 启动Consul集群
    docker-compose up -d consul
    
    # 等待Consul启动
    log_info "等待Consul启动..."
    sleep 30
    
    # 检查Consul健康状态
    if curl -f http://localhost:8500/v1/status/leader > /dev/null 2>&1; then
        log_success "Consul启动成功"
    else
        log_error "Consul启动失败"
        exit 1
    fi
}

# 设置监控系统
setup_monitoring() {
    log_info "设置监控系统..."
    
    # 创建Prometheus配置
    mkdir -p configs/prometheus
    cat > configs/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

scrape_configs:
  - job_name: 'consul'
    consul_sd_configs:
      - server: 'consul:8500'
    relabel_configs:
      - source_labels: [__meta_consul_service]
        target_label: job
      - source_labels: [__meta_consul_service_id]
        target_label: instance

  - job_name: 'user-service'
    static_configs:
      - targets: ['user-service:8081']
    metrics_path: '/metrics'

  - job_name: 'model-service'
    static_configs:
      - targets: ['model-service:8083']
    metrics_path: '/metrics'

  - job_name: 'inference-service'
    static_configs:
      - targets: ['inference-service:8084']
    metrics_path: '/metrics'

  - job_name: 'cost-service'
    static_configs:
      - targets: ['cost-service:8085']
    metrics_path: '/metrics'

  - job_name: 'monitoring-service'
    static_configs:
      - targets: ['monitoring-service:8086']
    metrics_path: '/metrics'

  - job_name: 'api-gateway'
    static_configs:
      - targets: ['api-gateway:8080']
    metrics_path: '/metrics'
EOF

    # 创建Grafana配置
    mkdir -p configs/grafana/datasources
    cat > configs/grafana/datasources/prometheus.yml << EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

    # 启动监控服务
    docker-compose up -d prometheus grafana
    
    log_success "监控系统设置完成"
}

# 设置数据库
setup_database() {
    log_info "设置数据库..."
    
    # 启动PostgreSQL
    docker-compose up -d postgres
    
    # 等待数据库启动
    log_info "等待数据库启动..."
    sleep 30
    
    # 检查数据库连接
    if docker exec postgres pg_isready -U user > /dev/null 2>&1; then
        log_success "数据库启动成功"
    else
        log_error "数据库启动失败"
        exit 1
    fi
}

# 设置缓存
setup_cache() {
    log_info "设置缓存..."
    
    # 启动Redis
    docker-compose up -d redis
    
    # 等待Redis启动
    log_info "等待Redis启动..."
    sleep 10
    
    # 检查Redis连接
    if docker exec redis redis-cli ping > /dev/null 2>&1; then
        log_success "缓存启动成功"
    else
        log_error "缓存启动失败"
        exit 1
    fi
}

# 生成gRPC代码
generate_grpc_code() {
    log_info "生成gRPC代码..."
    
    # 检查protoc是否安装
    if ! command -v protoc &> /dev/null; then
        log_warning "protoc 未安装，跳过gRPC代码生成"
        return
    fi
    
    # 生成Go代码
    if command -v protoc-gen-go &> /dev/null; then
        log_info "生成Go gRPC代码..."
        find shared/proto -name "*.proto" -exec protoc --go_out=. --go-grpc_out=. {} \;
    fi
    
    # 生成Python代码
    if command -v protoc-gen-python &> /dev/null; then
        log_info "生成Python gRPC代码..."
        find shared/proto -name "*.proto" -exec protoc --python_out=. --grpc_python_out=. {} \;
    fi
    
    log_success "gRPC代码生成完成"
}

# 设置服务注册
setup_service_registration() {
    log_info "设置服务注册..."
    
    # 等待所有服务启动
    log_info "等待服务启动..."
    sleep 60
    
    # 注册所有服务
    ./infrastructure/service-discovery/scripts/register-services.sh register
    
    log_success "服务注册完成"
}

# 验证架构
verify_architecture() {
    log_info "验证技术架构..."
    
    # 检查所有服务健康状态
    ./scripts/health-check.sh all
    
    # 检查服务发现
    log_info "检查服务发现..."
    if curl -f http://localhost:8500/v1/catalog/services > /dev/null 2>&1; then
        log_success "服务发现正常"
    else
        log_error "服务发现异常"
    fi
    
    # 检查监控系统
    log_info "检查监控系统..."
    if curl -f http://localhost:9090/api/v1/status/config > /dev/null 2>&1; then
        log_success "Prometheus正常"
    else
        log_error "Prometheus异常"
    fi
    
    if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
        log_success "Grafana正常"
    else
        log_error "Grafana异常"
    fi
    
    log_success "技术架构验证完成"
}

# 显示帮助
show_help() {
    echo "LLMOps技术架构设置脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  all         设置所有技术架构组件"
    echo "  message     设置消息队列"
    echo "  discovery   设置服务发现"
    echo "  monitoring  设置监控系统"
    echo "  database    设置数据库"
    echo "  cache       设置缓存"
    echo "  grpc        生成gRPC代码"
    echo "  register    设置服务注册"
    echo "  verify      验证架构"
    echo "  help        显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 all      # 设置所有组件"
    echo "  $0 message  # 只设置消息队列"
}

# 主函数
main() {
    case "${1:-help}" in
        all)
            check_dependencies
            setup_database
            setup_cache
            setup_message_queue
            setup_service_discovery
            setup_monitoring
            generate_grpc_code
            setup_service_registration
            verify_architecture
            ;;
        message)
            setup_message_queue
            ;;
        discovery)
            setup_service_discovery
            ;;
        monitoring)
            setup_monitoring
            ;;
        database)
            setup_database
            ;;
        cache)
            setup_cache
            ;;
        grpc)
            generate_grpc_code
            ;;
        register)
            setup_service_registration
            ;;
        verify)
            verify_architecture
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



