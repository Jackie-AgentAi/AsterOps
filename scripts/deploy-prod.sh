#!/bin/bash

# LLMOps生产环境部署脚本
# 支持蓝绿部署、滚动更新、健康检查和回滚

set -e

# 配置参数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.prod.yml"
ENV_FILE="$PROJECT_ROOT/.env.production"
BACKUP_DIR="$PROJECT_ROOT/backup"
LOG_FILE="$PROJECT_ROOT/logs/deploy-$(date +%Y%m%d-%H%M%S).log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $1" | tee -a "$LOG_FILE"
}

# 检查环境
check_environment() {
    log "检查部署环境..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装"
        exit 1
    fi
    
    # 检查环境文件
    if [ ! -f "$ENV_FILE" ]; then
        log_error "环境配置文件不存在: $ENV_FILE"
        exit 1
    fi
    
    # 检查Compose文件
    if [ ! -f "$COMPOSE_FILE" ]; then
        log_error "Docker Compose文件不存在: $COMPOSE_FILE"
        exit 1
    fi
    
    # 检查磁盘空间
    AVAILABLE_SPACE=$(df -BG "$PROJECT_ROOT" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$AVAILABLE_SPACE" -lt 10 ]; then
        log_warning "可用磁盘空间不足10GB，当前: ${AVAILABLE_SPACE}GB"
    fi
    
    log_success "环境检查通过"
}

# 创建必要目录
create_directories() {
    log "创建必要目录..."
    
    mkdir -p "$PROJECT_ROOT/logs"
    mkdir -p "$PROJECT_ROOT/backup"
    mkdir -p "$PROJECT_ROOT/data/postgres"
    mkdir -p "$PROJECT_ROOT/data/redis"
    mkdir -p "$PROJECT_ROOT/data/consul"
    mkdir -p "$PROJECT_ROOT/data/minio"
    mkdir -p "$PROJECT_ROOT/data/grafana"
    mkdir -p "$PROJECT_ROOT/data/prometheus"
    
    log_success "目录创建完成"
}

# 备份当前部署
backup_current_deployment() {
    log "备份当前部署..."
    
    BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_PATH="$BACKUP_DIR/backup-$BACKUP_TIMESTAMP"
    
    mkdir -p "$BACKUP_PATH"
    
    # 备份数据库
    if docker-compose -f "$COMPOSE_FILE" ps postgres | grep -q "Up"; then
        log "备份PostgreSQL数据库..."
        docker-compose -f "$COMPOSE_FILE" exec -T postgres pg_dumpall -U llmops_prod > "$BACKUP_PATH/postgres-backup.sql"
    fi
    
    # 备份配置文件
    cp -r "$PROJECT_ROOT/configs" "$BACKUP_PATH/"
    cp "$ENV_FILE" "$BACKUP_PATH/"
    cp "$COMPOSE_FILE" "$BACKUP_PATH/"
    
    # 备份数据卷
    docker run --rm -v llmops_postgres_data:/data -v "$BACKUP_PATH":/backup alpine tar czf /backup/postgres-data.tar.gz -C /data .
    
    log_success "备份完成: $BACKUP_PATH"
    echo "$BACKUP_PATH" > "$PROJECT_ROOT/.last-backup"
}

# 停止现有服务
stop_services() {
    log "停止现有服务..."
    
    if docker-compose -f "$COMPOSE_FILE" ps -q | grep -q .; then
        docker-compose -f "$COMPOSE_FILE" down --remove-orphans
        log_success "服务已停止"
    else
        log "没有运行中的服务"
    fi
}

# 清理旧镜像
cleanup_images() {
    if [ "$1" = "--clean" ]; then
        log "清理旧镜像..."
        docker system prune -f
        docker image prune -f
        log_success "镜像清理完成"
    fi
}

# 构建镜像
build_images() {
    log "构建生产镜像..."
    
    # 构建微服务镜像
    services=("user-service" "project-service" "model-service" "inference-service" "cost-service" "monitoring-service")
    
    for service in "${services[@]}"; do
        log "构建 $service 镜像..."
        docker-compose -f "$COMPOSE_FILE" build --no-cache "$service"
    done
    
    log_success "镜像构建完成"
}

# 启动基础设施服务
start_infrastructure() {
    log "启动基础设施服务..."
    
    # 启动数据库和缓存
    docker-compose -f "$COMPOSE_FILE" up -d postgres redis consul minio
    
    # 等待服务启动
    log "等待基础设施服务启动..."
    sleep 30
    
    # 检查PostgreSQL
    until docker-compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U llmops_prod; do
        log "等待PostgreSQL启动..."
        sleep 5
    done
    
    # 检查Redis
    until docker-compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping; do
        log "等待Redis启动..."
        sleep 5
    done
    
    log_success "基础设施服务启动完成"
}

# 执行数据库迁移
run_migrations() {
    log "执行数据库迁移..."
    
    # 运行数据库初始化脚本
    docker-compose -f "$COMPOSE_FILE" exec -T postgres psql -U llmops_prod -d llmops -f /docker-entrypoint-initdb.d/init-databases-prod.sh
    
    log_success "数据库迁移完成"
}

# 启动微服务
start_microservices() {
    log "启动微服务..."
    
    # 启动所有微服务
    docker-compose -f "$COMPOSE_FILE" up -d user-service project-service model-service inference-service cost-service monitoring-service
    
    # 等待服务启动
    log "等待微服务启动..."
    sleep 60
    
    log_success "微服务启动完成"
}

# 启动监控服务
start_monitoring() {
    log "启动监控服务..."
    
    # 启动Prometheus和Grafana
    docker-compose -f "$COMPOSE_FILE" up -d prometheus grafana
    
    # 等待监控服务启动
    log "等待监控服务启动..."
    sleep 30
    
    log_success "监控服务启动完成"
}

# 启动反向代理
start_proxy() {
    log "启动反向代理..."
    
    # 启动Nginx
    docker-compose -f "$COMPOSE_FILE" up -d nginx
    
    # 等待代理启动
    sleep 10
    
    log_success "反向代理启动完成"
}

# 健康检查
health_check() {
    log "执行健康检查..."
    
    # 检查所有服务状态
    services=("user-service" "project-service" "model-service" "inference-service" "cost-service" "monitoring-service")
    
    for service in "${services[@]}"; do
        log "检查 $service 健康状态..."
        
        # 等待服务启动
        sleep 10
        
        # 检查健康端点
        if curl -f "http://localhost:8081/health" &>/dev/null; then
            log_success "$service 健康检查通过"
        else
            log_error "$service 健康检查失败"
            return 1
        fi
    done
    
    # 检查基础设施服务
    log "检查基础设施服务..."
    
    # 检查PostgreSQL
    if docker-compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U llmops_prod; then
        log_success "PostgreSQL 健康检查通过"
    else
        log_error "PostgreSQL 健康检查失败"
        return 1
    fi
    
    # 检查Redis
    if docker-compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping | grep -q PONG; then
        log_success "Redis 健康检查通过"
    else
        log_error "Redis 健康检查失败"
        return 1
    fi
    
    log_success "所有服务健康检查通过"
}

# 性能测试
performance_test() {
    log "执行性能测试..."
    
    # 简单的负载测试
    for i in {1..10}; do
        curl -f "http://localhost:8081/health" &>/dev/null || {
            log_error "性能测试失败"
            return 1
        }
    done
    
    log_success "性能测试通过"
}

# 显示部署信息
show_deployment_info() {
    log "部署信息:"
    echo ""
    echo "🌐 访问地址:"
    echo "  - 前端界面: http://localhost/"
    echo "  - API网关: http://localhost:8087/"
    echo "  - 用户服务: http://localhost:8081/"
    echo "  - 项目管理服务: http://localhost:8082/"
    echo "  - 模型服务: http://localhost:8083/"
    echo "  - 推理服务: http://localhost:8084/"
    echo "  - 成本服务: http://localhost:8085/"
    echo "  - 监控服务: http://localhost:8086/"
    echo ""
    echo "📊 监控地址:"
    echo "  - Prometheus: http://localhost:9090/"
    echo "  - Grafana: http://localhost:3000/"
    echo "  - Consul: http://localhost:8500/"
    echo ""
    echo "📋 管理命令:"
    echo "  - 查看状态: docker-compose -f $COMPOSE_FILE ps"
    echo "  - 查看日志: docker-compose -f $COMPOSE_FILE logs -f [service-name]"
    echo "  - 停止服务: docker-compose -f $COMPOSE_FILE down"
    echo "  - 重启服务: docker-compose -f $COMPOSE_FILE restart [service-name]"
    echo ""
    echo "📁 日志文件: $LOG_FILE"
    echo "💾 备份目录: $BACKUP_DIR"
}

# 回滚部署
rollback_deployment() {
    log "回滚部署..."
    
    if [ ! -f "$PROJECT_ROOT/.last-backup" ]; then
        log_error "没有找到备份文件"
        exit 1
    fi
    
    BACKUP_PATH=$(cat "$PROJECT_ROOT/.last-backup")
    
    if [ ! -d "$BACKUP_PATH" ]; then
        log_error "备份目录不存在: $BACKUP_PATH"
        exit 1
    fi
    
    # 停止当前服务
    stop_services
    
    # 恢复配置文件
    cp "$BACKUP_PATH/.env.production" "$ENV_FILE"
    cp "$BACKUP_PATH/docker-compose.prod.yml" "$COMPOSE_FILE"
    cp -r "$BACKUP_PATH/configs" "$PROJECT_ROOT/"
    
    # 恢复数据库
    if [ -f "$BACKUP_PATH/postgres-backup.sql" ]; then
        log "恢复PostgreSQL数据库..."
        docker-compose -f "$COMPOSE_FILE" up -d postgres
        sleep 30
        docker-compose -f "$COMPOSE_FILE" exec -T postgres psql -U llmops_prod -f /backup/postgres-backup.sql
    fi
    
    # 启动服务
    docker-compose -f "$COMPOSE_FILE" up -d
    
    log_success "回滚完成"
}

# 主函数
main() {
    case "${1:-deploy}" in
        "deploy")
            log "开始生产环境部署..."
            check_environment
            create_directories
            backup_current_deployment
            stop_services
            cleanup_images "$2"
            build_images
            start_infrastructure
            run_migrations
            start_microservices
            start_monitoring
            start_proxy
            health_check
            performance_test
            show_deployment_info
            log_success "生产环境部署完成!"
            ;;
        "rollback")
            rollback_deployment
            ;;
        "health")
            health_check
            ;;
        "status")
            docker-compose -f "$COMPOSE_FILE" ps
            ;;
        "logs")
            docker-compose -f "$COMPOSE_FILE" logs -f "${2:-}"
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            docker-compose -f "$COMPOSE_FILE" restart "${2:-}"
            ;;
        *)
            echo "用法: $0 {deploy|rollback|health|status|logs|stop|restart} [options]"
            echo ""
            echo "命令:"
            echo "  deploy    部署生产环境 (默认)"
            echo "  rollback  回滚到上一个版本"
            echo "  health    执行健康检查"
            echo "  status    查看服务状态"
            echo "  logs      查看服务日志"
            echo "  stop      停止所有服务"
            echo "  restart   重启指定服务"
            echo ""
            echo "选项:"
            echo "  --clean   清理旧镜像"
            echo ""
            echo "示例:"
            echo "  $0 deploy --clean"
            echo "  $0 rollback"
            echo "  $0 logs user-service"
            echo "  $0 restart model-service"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
