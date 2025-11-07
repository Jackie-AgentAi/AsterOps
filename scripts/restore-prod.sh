#!/bin/bash

# LLMOps生产环境恢复脚本
# 支持从备份文件恢复数据库、配置文件和数据卷

set -e

# 配置参数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.prod.yml"
ENV_FILE="$PROJECT_ROOT/.env.production"
BACKUP_BASE_DIR="$PROJECT_ROOT/backup"
RESTORE_DIR="$PROJECT_ROOT/restore-temp"

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
        log_error "请指定备份文件名"
        echo "用法: $0 <backup-file> [options]"
        echo "示例: $0 backup-20240101-120000.tar.gz"
        exit 1
    fi
    
    BACKUP_FILE="$1"
    
    # 检查备份文件是否存在
    if [ ! -f "$BACKUP_FILE" ]; then
        # 尝试在备份目录中查找
        if [ -f "$BACKUP_BASE_DIR/$BACKUP_FILE" ]; then
            BACKUP_FILE="$BACKUP_BASE_DIR/$BACKUP_FILE"
        else
            log_error "备份文件不存在: $BACKUP_FILE"
            exit 1
        fi
    fi
    
    log "使用备份文件: $BACKUP_FILE"
}

# 检查环境
check_environment() {
    log "检查恢复环境..."
    
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
    
    # 检查备份文件完整性
    if ! tar -tzf "$BACKUP_FILE" >/dev/null 2>&1; then
        log_error "备份文件损坏或格式不正确"
        exit 1
    fi
    
    log_success "环境检查通过"
}

# 确认恢复操作
confirm_restore() {
    log_warning "恢复操作将覆盖当前数据，请确认是否继续？"
    echo "备份文件: $BACKUP_FILE"
    echo "恢复目录: $RESTORE_DIR"
    echo ""
    read -p "是否继续？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "恢复操作已取消"
        exit 0
    fi
}

# 创建恢复目录
create_restore_directory() {
    log "创建恢复目录: $RESTORE_DIR"
    
    # 清理旧的恢复目录
    if [ -d "$RESTORE_DIR" ]; then
        rm -rf "$RESTORE_DIR"
    fi
    
    mkdir -p "$RESTORE_DIR"
    log_success "恢复目录创建完成"
}

# 解压备份文件
extract_backup() {
    log "解压备份文件..."
    
    cd "$RESTORE_DIR"
    tar -xzf "$BACKUP_FILE"
    
    # 查找解压后的目录
    BACKUP_EXTRACT_DIR=$(find . -maxdepth 1 -type d -name "backup-*" | head -1)
    
    if [ -z "$BACKUP_EXTRACT_DIR" ]; then
        log_error "无法找到备份目录"
        exit 1
    fi
    
    log_success "备份文件解压完成: $BACKUP_EXTRACT_DIR"
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

# 恢复配置文件
restore_configs() {
    log "恢复配置文件..."
    
    BACKUP_CONFIG_DIR="$RESTORE_DIR/$BACKUP_EXTRACT_DIR/configs"
    
    # 恢复环境配置
    if [ -f "$BACKUP_CONFIG_DIR/.env.production" ]; then
        cp "$BACKUP_CONFIG_DIR/.env.production" "$ENV_FILE"
        log "恢复环境配置文件"
    fi
    
    # 恢复Docker Compose配置
    if [ -f "$BACKUP_CONFIG_DIR/docker-compose.prod.yml" ]; then
        cp "$BACKUP_CONFIG_DIR/docker-compose.prod.yml" "$COMPOSE_FILE"
        log "恢复Docker Compose配置"
    fi
    
    # 恢复应用配置
    if [ -d "$BACKUP_CONFIG_DIR/configs" ]; then
        rm -rf "$PROJECT_ROOT/configs"
        cp -r "$BACKUP_CONFIG_DIR/configs" "$PROJECT_ROOT/"
        log "恢复应用配置"
    fi
    
    # 恢复脚本
    if [ -d "$BACKUP_CONFIG_DIR/scripts" ]; then
        cp -r "$BACKUP_CONFIG_DIR/scripts" "$PROJECT_ROOT/"
        log "恢复脚本文件"
    fi
    
    # 恢复基础设施配置
    if [ -d "$BACKUP_CONFIG_DIR/infrastructure" ]; then
        rm -rf "$PROJECT_ROOT/infrastructure"
        cp -r "$BACKUP_CONFIG_DIR/infrastructure" "$PROJECT_ROOT/"
        log "恢复基础设施配置"
    fi
    
    log_success "配置文件恢复完成"
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
    
    log_success "基础设施服务启动完成"
}

# 恢复数据库
restore_database() {
    log "恢复PostgreSQL数据库..."
    
    BACKUP_DB_DIR="$RESTORE_DIR/$BACKUP_EXTRACT_DIR/database"
    
    if [ -f "$BACKUP_DB_DIR/postgres-all.sql" ]; then
        # 恢复完整数据库
        docker-compose -f "$COMPOSE_FILE" exec -T postgres psql -U llmops_prod -f /backup/postgres-all.sql || {
            log_warning "完整数据库恢复失败，尝试单独恢复各数据库"
            restore_individual_databases
        }
    else
        # 恢复各服务数据库
        restore_individual_databases
    fi
    
    log_success "数据库恢复完成"
}

# 恢复各服务数据库
restore_individual_databases() {
    log "恢复各服务数据库..."
    
    BACKUP_DB_DIR="$RESTORE_DIR/$BACKUP_EXTRACT_DIR/database"
    
    # 创建各服务数据库
    databases=("user_db_prod" "project_db_prod" "model_db_prod" "inference_db_prod" "cost_db_prod" "monitoring_db_prod")
    
    for db in "${databases[@]}"; do
        if [ -f "$BACKUP_DB_DIR/$db.sql" ]; then
            log "恢复数据库: $db"
            docker-compose -f "$COMPOSE_FILE" exec -T postgres psql -U llmops_prod -d "$db" -f "/backup/$db.sql" || {
                log_warning "数据库 $db 恢复失败"
            }
        else
            log_warning "数据库 $db 的备份文件不存在"
        fi
    done
}

# 恢复数据卷
restore_volumes() {
    log "恢复数据卷..."
    
    BACKUP_VOL_DIR="$RESTORE_DIR/$BACKUP_EXTRACT_DIR/volumes"
    
    # 恢复PostgreSQL数据卷
    if [ -f "$BACKUP_VOL_DIR/postgres-data.tar.gz" ]; then
        log "恢复PostgreSQL数据卷..."
        docker run --rm -v llmops_postgres_data:/data -v "$BACKUP_VOL_DIR":/backup alpine sh -c "cd /data && tar -xzf /backup/postgres-data.tar.gz"
    fi
    
    # 恢复Redis数据卷
    if [ -f "$BACKUP_VOL_DIR/redis-data.tar.gz" ]; then
        log "恢复Redis数据卷..."
        docker run --rm -v llmops_redis_data:/data -v "$BACKUP_VOL_DIR":/backup alpine sh -c "cd /data && tar -xzf /backup/redis-data.tar.gz"
    fi
    
    # 恢复Consul数据卷
    if [ -f "$BACKUP_VOL_DIR/consul-data.tar.gz" ]; then
        log "恢复Consul数据卷..."
        docker run --rm -v llmops_consul_data:/data -v "$BACKUP_VOL_DIR":/backup alpine sh -c "cd /data && tar -xzf /backup/consul-data.tar.gz"
    fi
    
    # 恢复MinIO数据卷
    if [ -f "$BACKUP_VOL_DIR/minio-data.tar.gz" ]; then
        log "恢复MinIO数据卷..."
        docker run --rm -v llmops_minio_data:/data -v "$BACKUP_VOL_DIR":/backup alpine sh -c "cd /data && tar -xzf /backup/minio-data.tar.gz"
    fi
    
    # 恢复Grafana数据卷
    if [ -f "$BACKUP_VOL_DIR/grafana-data.tar.gz" ]; then
        log "恢复Grafana数据卷..."
        docker run --rm -v llmops_grafana_data:/data -v "$BACKUP_VOL_DIR":/backup alpine sh -c "cd /data && tar -xzf /backup/grafana-data.tar.gz"
    fi
    
    # 恢复模型存储卷
    if [ -f "$BACKUP_VOL_DIR/model-storage.tar.gz" ]; then
        log "恢复模型存储卷..."
        docker run --rm -v llmops_model_storage:/data -v "$BACKUP_VOL_DIR":/backup alpine sh -c "cd /data && tar -xzf /backup/model-storage.tar.gz"
    fi
    
    # 恢复推理缓存卷
    if [ -f "$BACKUP_VOL_DIR/inference-cache.tar.gz" ]; then
        log "恢复推理缓存卷..."
        docker run --rm -v llmops_inference_cache:/data -v "$BACKUP_VOL_DIR":/backup alpine sh -c "cd /data && tar -xzf /backup/inference-cache.tar.gz"
    fi
    
    log_success "数据卷恢复完成"
}

# 启动所有服务
start_all_services() {
    log "启动所有服务..."
    
    # 启动所有服务
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # 等待服务启动
    log "等待所有服务启动..."
    sleep 60
    
    log_success "所有服务启动完成"
}

# 验证恢复
verify_restore() {
    log "验证恢复结果..."
    
    # 检查服务状态
    if ! docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        log_error "部分服务启动失败"
        return 1
    fi
    
    # 检查数据库连接
    if ! docker-compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U llmops_prod; then
        log_error "数据库连接失败"
        return 1
    fi
    
    # 检查Redis连接
    if ! docker-compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping | grep -q PONG; then
        log_error "Redis连接失败"
        return 1
    fi
    
    log_success "恢复验证通过"
}

# 清理临时文件
cleanup_temp_files() {
    log "清理临时文件..."
    
    if [ -d "$RESTORE_DIR" ]; then
        rm -rf "$RESTORE_DIR"
        log_success "临时文件清理完成"
    fi
}

# 显示恢复信息
show_restore_info() {
    log "恢复信息:"
    echo ""
    echo "📦 备份文件: $BACKUP_FILE"
    echo "📅 恢复时间: $(date)"
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
}

# 主函数
main() {
    case "${2:-restore}" in
        "restore")
            log "开始生产环境恢复..."
            check_arguments "$1"
            check_environment
            confirm_restore
            create_restore_directory
            extract_backup
            stop_services
            restore_configs
            start_infrastructure
            restore_database
            restore_volumes
            start_all_services
            verify_restore
            cleanup_temp_files
            show_restore_info
            log_success "生产环境恢复完成!"
            ;;
        "verify")
            check_arguments "$1"
            check_environment
            log_success "备份文件验证通过"
            ;;
        "list")
            log "列出备份文件..."
            ls -la "$BACKUP_BASE_DIR"/backup-*.tar.gz 2>/dev/null || log "没有找到备份文件"
            ;;
        *)
            echo "用法: $0 <backup-file> {restore|verify|list}"
            echo ""
            echo "命令:"
            echo "  restore     恢复生产环境 (默认)"
            echo "  verify      验证备份文件"
            echo "  list        列出所有备份文件"
            echo ""
            echo "示例:"
            echo "  $0 backup-20240101-120000.tar.gz restore"
            echo "  $0 backup-20240101-120000.tar.gz verify"
            echo "  $0 list"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
