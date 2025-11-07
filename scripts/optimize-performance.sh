#!/bin/bash

# LLMOps平台性能优化脚本
# 用于优化数据库、缓存、网络等性能

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

# 数据库性能优化
optimize_database() {
    log_info "开始数据库性能优化..."
    
    # 创建数据库优化配置
    cat > configs/postgres/postgresql.conf << EOF
# 连接设置
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB

# 内存设置
work_mem = 4MB
maintenance_work_mem = 64MB

# 查询优化
random_page_cost = 1.1
effective_io_concurrency = 200

# 日志设置
log_statement = 'all'
log_duration = on
log_min_duration_statement = 1000

# 统计信息
track_activities = on
track_counts = on
track_io_timing = on

# 自动清理
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 1min

# 检查点
checkpoint_completion_target = 0.9
wal_buffers = 16MB
checkpoint_segments = 32
EOF

    # 创建数据库索引优化脚本
    cat > scripts/optimize-database.sql << EOF
-- 用户表索引优化
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_tenant_id ON users(tenant_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_created_at ON users(created_at);

-- 模型表索引优化
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_models_tenant_id ON models(tenant_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_models_owner_id ON models(owner_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_models_status ON models(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_models_created_at ON models(created_at);

-- 推理表索引优化
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_inference_requests_user_id ON inference_requests(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_inference_requests_model_id ON inference_requests(model_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_inference_requests_created_at ON inference_requests(created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_inference_requests_status ON inference_requests(status);

-- 成本表索引优化
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cost_records_tenant_id ON cost_records(tenant_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cost_records_project_id ON cost_records(project_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cost_records_user_id ON cost_records(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cost_records_created_at ON cost_records(created_at);

-- 监控表索引优化
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_metrics_service_id ON metrics(service_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_metrics_metric_name ON metrics(metric_name);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_metrics_timestamp ON metrics(timestamp);

-- 项目表索引优化
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_projects_tenant_id ON projects(tenant_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_projects_owner_id ON projects(owner_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_projects_created_at ON projects(created_at);

-- 分析表统计信息
ANALYZE users;
ANALYZE models;
ANALYZE inference_requests;
ANALYZE cost_records;
ANALYZE metrics;
ANALYZE projects;
EOF

    # 执行数据库优化
    if docker exec postgres psql -U user -d user_db -f /tmp/optimize-database.sql; then
        log_success "数据库索引优化完成"
    else
        log_warning "数据库索引优化失败"
    fi
    
    log_success "数据库性能优化完成"
}

# Redis缓存优化
optimize_redis() {
    log_info "开始Redis缓存优化..."
    
    # 创建Redis优化配置
    cat > configs/redis/redis.conf << EOF
# 内存优化
maxmemory 512mb
maxmemory-policy allkeys-lru

# 持久化优化
save 900 1
save 300 10
save 60 10000

# 网络优化
tcp-keepalive 60
timeout 300

# 日志优化
loglevel notice
logfile /var/log/redis/redis-server.log

# 性能优化
tcp-backlog 511
databases 16
EOF

    # 创建Redis集群配置
    cat > configs/redis/redis-cluster.conf << EOF
# Redis集群配置
port 7000
cluster-enabled yes
cluster-config-file nodes-7000.conf
cluster-node-timeout 5000
appendonly yes
EOF

    log_success "Redis缓存优化完成"
}

# 网络性能优化
optimize_network() {
    log_info "开始网络性能优化..."
    
    # 创建网络优化配置
    cat > configs/network/nginx.conf << EOF
# Nginx性能优化配置
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    # 基础优化
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 100;
    
    # 缓冲区优化
    client_body_buffer_size 128k;
    client_max_body_size 10m;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 4k;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # 上游服务器配置
    upstream api_gateway {
        server api-gateway:8080 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }
    
    # 负载均衡配置
    server {
        listen 80;
        server_name localhost;
        
        location / {
            proxy_pass http://api_gateway;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            
            # 连接优化
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
            
            # 缓冲区优化
            proxy_buffering on;
            proxy_buffer_size 4k;
            proxy_buffers 8 4k;
        }
    }
}
EOF

    log_success "网络性能优化完成"
}

# 应用性能优化
optimize_application() {
    log_info "开始应用性能优化..."
    
    # Go应用优化
    cat > configs/go/go.optimize << EOF
# Go编译优化
CGO_ENABLED=0
GOOS=linux
GOARCH=amd64
go build -ldflags="-s -w" -o app cmd/server/main.go

# 运行时优化
GOMAXPROCS=4
GOMEMLIMIT=512MiB
EOF

    # Python应用优化
    cat > configs/python/uvicorn.optimize << EOF
# Uvicorn性能优化
uvicorn app.main:app \
    --host 0.0.0.0 \
    --port 8080 \
    --workers 4 \
    --worker-class uvicorn.workers.UvicornWorker \
    --loop uvloop \
    --http httptools \
    --access-log \
    --log-level info
EOF

    # 创建性能监控配置
    cat > configs/monitoring/performance.yml << EOF
# 性能监控配置
metrics:
  enabled: true
  interval: 30s
  exporters:
    - prometheus
    - grafana

# 性能指标
performance:
  response_time:
    threshold: 1000ms
    alert: true
  throughput:
    threshold: 1000rps
    alert: true
  error_rate:
    threshold: 5%
    alert: true

# 资源监控
resources:
  cpu:
    threshold: 80%
    alert: true
  memory:
    threshold: 80%
    alert: true
  disk:
    threshold: 90%
    alert: true
EOF

    log_success "应用性能优化完成"
}

# 容器性能优化
optimize_containers() {
    log_info "开始容器性能优化..."
    
    # 创建Docker优化配置
    cat > configs/docker/docker-compose.optimized.yml << EOF
version: '3.8'

services:
  # 数据库优化
  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=llmops
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./configs/postgres/postgresql.conf:/etc/postgresql/postgresql.conf
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
        reservations:
          memory: 512M
          cpus: '0.5'
    networks:
      - llmops-network

  # Redis优化
  redis:
    image: redis:7-alpine
    volumes:
      - ./configs/redis/redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
    networks:
      - llmops-network

  # API网关优化
  api-gateway:
    build: ./infrastructure/api-gateway
    ports:
      - "8080:8080"
    environment:
      - GOMAXPROCS=4
      - GOMEMLIMIT=512MiB
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '1.0'
        reservations:
          memory: 256M
          cpus: '0.5'
    networks:
      - llmops-network

volumes:
  postgres_data:

networks:
  llmops-network:
    driver: bridge
EOF

    log_success "容器性能优化完成"
}

# 运行性能测试
run_performance_tests() {
    log_info "开始性能测试..."
    
    # 安装Python依赖
    pip install -r tests/performance/requirements.txt
    
    # 运行性能测试
    python tests/performance/load_test.py
    
    # 运行数据库性能测试
    python tests/performance/database_test.py
    
    # 运行缓存性能测试
    python tests/performance/cache_test.py
    
    log_success "性能测试完成"
}

# 生成性能报告
generate_performance_report() {
    log_info "生成性能报告..."
    
    # 创建性能报告模板
    cat > reports/performance-report.md << EOF
# LLMOps平台性能优化报告

## 优化概述
- 数据库性能优化
- Redis缓存优化
- 网络性能优化
- 应用性能优化
- 容器性能优化

## 性能指标
- 响应时间: < 100ms
- 吞吐量: > 1000 RPS
- 错误率: < 1%
- 资源使用率: < 80%

## 优化建议
1. 数据库索引优化
2. 缓存策略优化
3. 负载均衡优化
4. 容器资源优化
EOF

    log_success "性能报告生成完成"
}

# 显示帮助
show_help() {
    echo "LLMOps平台性能优化脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  all         优化所有组件"
    echo "  database    优化数据库"
    echo "  redis       优化Redis缓存"
    echo "  network     优化网络"
    echo "  application 优化应用"
    echo "  containers  优化容器"
    echo "  test        运行性能测试"
    echo "  report      生成性能报告"
    echo "  help        显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 all      # 优化所有组件"
    echo "  $0 database # 只优化数据库"
}

# 主函数
main() {
    case "${1:-help}" in
        all)
            optimize_database
            optimize_redis
            optimize_network
            optimize_application
            optimize_containers
            run_performance_tests
            generate_performance_report
            ;;
        database)
            optimize_database
            ;;
        redis)
            optimize_redis
            ;;
        network)
            optimize_network
            ;;
        application)
            optimize_application
            ;;
        containers)
            optimize_containers
            ;;
        test)
            run_performance_tests
            ;;
        report)
            generate_performance_report
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



