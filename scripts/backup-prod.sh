#!/bin/bash

# LLMOps生产环境备份脚本
# 支持数据库、配置文件、数据卷的完整备份

set -e

# 配置参数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.prod.yml"
ENV_FILE="$PROJECT_ROOT/.env.production"
BACKUP_BASE_DIR="$PROJECT_ROOT/backup"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_BASE_DIR/backup-$TIMESTAMP"
RETENTION_DAYS=30

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

# 检查环境
check_environment() {
    log "检查备份环境..."
    
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
    
    # 检查备份目录
    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        mkdir -p "$BACKUP_BASE_DIR"
        log "创建备份目录: $BACKUP_BASE_DIR"
    fi
    
    # 检查磁盘空间
    AVAILABLE_SPACE=$(df -BG "$BACKUP_BASE_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$AVAILABLE_SPACE" -lt 5 ]; then
        log_warning "可用磁盘空间不足5GB，当前: ${AVAILABLE_SPACE}GB"
    fi
    
    log_success "环境检查通过"
}

# 创建备份目录
create_backup_directory() {
    log "创建备份目录: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"/{database,configs,volumes,logs}
    log_success "备份目录创建完成"
}

# 备份数据库
backup_database() {
    log "备份PostgreSQL数据库..."
    
    if docker-compose -f "$COMPOSE_FILE" ps postgres | grep -q "Up"; then
        # 备份所有数据库
        docker-compose -f "$COMPOSE_FILE" exec -T postgres pg_dumpall -U llmops_prod > "$BACKUP_DIR/database/postgres-all.sql"
        
        # 备份各服务数据库
        databases=("user_db_prod" "project_db_prod" "model_db_prod" "inference_db_prod" "cost_db_prod" "monitoring_db_prod")
        
        for db in "${databases[@]}"; do
            log "备份数据库: $db"
            docker-compose -f "$COMPOSE_FILE" exec -T postgres pg_dump -U llmops_prod -d "$db" > "$BACKUP_DIR/database/$db.sql"
        done
        
        log_success "数据库备份完成"
    else
        log_warning "PostgreSQL服务未运行，跳过数据库备份"
    fi
}

# 备份配置文件
backup_configs() {
    log "备份配置文件..."
    
    # 备份环境配置
    if [ -f "$ENV_FILE" ]; then
        cp "$ENV_FILE" "$BACKUP_DIR/configs/"
        log "备份环境配置文件"
    fi
    
    # 备份Docker Compose配置
    if [ -f "$COMPOSE_FILE" ]; then
        cp "$COMPOSE_FILE" "$BACKUP_DIR/configs/"
        log "备份Docker Compose配置"
    fi
    
    # 备份应用配置
    if [ -d "$PROJECT_ROOT/configs" ]; then
        cp -r "$PROJECT_ROOT/configs" "$BACKUP_DIR/configs/"
        log "备份应用配置"
    fi
    
    # 备份脚本
    if [ -d "$PROJECT_ROOT/scripts" ]; then
        cp -r "$PROJECT_ROOT/scripts" "$BACKUP_DIR/configs/"
        log "备份脚本文件"
    fi
    
    # 备份基础设施配置
    if [ -d "$PROJECT_ROOT/infrastructure" ]; then
        cp -r "$PROJECT_ROOT/infrastructure" "$BACKUP_DIR/configs/"
        log "备份基础设施配置"
    fi
    
    log_success "配置文件备份完成"
}

# 备份数据卷
backup_volumes() {
    log "备份数据卷..."
    
    # 备份PostgreSQL数据卷
    if docker volume ls | grep -q "llmops_postgres_data"; then
        log "备份PostgreSQL数据卷..."
        docker run --rm -v llmops_postgres_data:/data -v "$BACKUP_DIR/volumes":/backup alpine tar czf /backup/postgres-data.tar.gz -C /data .
    fi
    
    # 备份Redis数据卷
    if docker volume ls | grep -q "llmops_redis_data"; then
        log "备份Redis数据卷..."
        docker run --rm -v llmops_redis_data:/data -v "$BACKUP_DIR/volumes":/backup alpine tar czf /backup/redis-data.tar.gz -C /data .
    fi
    
    # 备份Consul数据卷
    if docker volume ls | grep -q "llmops_consul_data"; then
        log "备份Consul数据卷..."
        docker run --rm -v llmops_consul_data:/data -v "$BACKUP_DIR/volumes":/backup alpine tar czf /backup/consul-data.tar.gz -C /data .
    fi
    
    # 备份MinIO数据卷
    if docker volume ls | grep -q "llmops_minio_data"; then
        log "备份MinIO数据卷..."
        docker run --rm -v llmops_minio_data:/data -v "$BACKUP_DIR/volumes":/backup alpine tar czf /backup/minio-data.tar.gz -C /data .
    fi
    
    # 备份Grafana数据卷
    if docker volume ls | grep -q "llmops_grafana_data"; then
        log "备份Grafana数据卷..."
        docker run --rm -v llmops_grafana_data:/data -v "$BACKUP_DIR/volumes":/backup alpine tar czf /backup/grafana-data.tar.gz -C /data .
    fi
    
    # 备份模型存储卷
    if docker volume ls | grep -q "llmops_model_storage"; then
        log "备份模型存储卷..."
        docker run --rm -v llmops_model_storage:/data -v "$BACKUP_DIR/volumes":/backup alpine tar czf /backup/model-storage.tar.gz -C /data .
    fi
    
    # 备份推理缓存卷
    if docker volume ls | grep -q "llmops_inference_cache"; then
        log "备份推理缓存卷..."
        docker run --rm -v llmops_inference_cache:/data -v "$BACKUP_DIR/volumes":/backup alpine tar czf /backup/inference-cache.tar.gz -C /data .
    fi
    
    log_success "数据卷备份完成"
}

# 备份日志文件
backup_logs() {
    log "备份日志文件..."
    
    # 备份应用日志
    if [ -d "$PROJECT_ROOT/logs" ]; then
        cp -r "$PROJECT_ROOT/logs" "$BACKUP_DIR/logs/"
        log "备份应用日志"
    fi
    
    # 备份Docker日志
    if [ -d "/var/lib/docker/containers" ]; then
        docker logs $(docker-compose -f "$COMPOSE_FILE" ps -q) > "$BACKUP_DIR/logs/docker-logs.txt" 2>&1 || true
        log "备份Docker日志"
    fi
    
    log_success "日志文件备份完成"
}

# 创建备份清单
create_backup_manifest() {
    log "创建备份清单..."
    
    cat > "$BACKUP_DIR/backup-manifest.txt" << EOF
# LLMOps生产环境备份清单
备份时间: $(date)
备份版本: $(git rev-parse HEAD 2>/dev/null || echo "unknown")
备份类型: 完整备份

## 数据库备份
- postgres-all.sql: 完整数据库备份
- user_db_prod.sql: 用户服务数据库
- project_db_prod.sql: 项目管理服务数据库
- model_db_prod.sql: 模型管理服务数据库
- inference_db_prod.sql: 推理服务数据库
- cost_db_prod.sql: 成本管理服务数据库
- monitoring_db_prod.sql: 监控服务数据库

## 配置文件
- .env.production: 环境配置
- docker-compose.prod.yml: Docker编排配置
- configs/: 应用配置目录
- scripts/: 脚本文件
- infrastructure/: 基础设施配置

## 数据卷备份
- postgres-data.tar.gz: PostgreSQL数据
- redis-data.tar.gz: Redis数据
- consul-data.tar.gz: Consul数据
- minio-data.tar.gz: MinIO数据
- grafana-data.tar.gz: Grafana数据
- model-storage.tar.gz: 模型存储
- inference-cache.tar.gz: 推理缓存

## 日志文件
- logs/: 应用日志
- docker-logs.txt: Docker容器日志

## 恢复说明
1. 停止所有服务: docker-compose -f docker-compose.prod.yml down
2. 恢复配置文件到项目根目录
3. 启动基础设施服务: docker-compose -f docker-compose.prod.yml up -d postgres redis consul minio
4. 恢复数据库: 使用restore-prod.sh脚本
5. 恢复数据卷: 使用restore-prod.sh脚本
6. 启动所有服务: docker-compose -f docker-compose.prod.yml up -d
EOF
    
    log_success "备份清单创建完成"
}

# 压缩备份
compress_backup() {
    log "压缩备份文件..."
    
    cd "$BACKUP_BASE_DIR"
    tar czf "backup-$TIMESTAMP.tar.gz" "backup-$TIMESTAMP"
    rm -rf "backup-$TIMESTAMP"
    
    BACKUP_SIZE=$(du -h "backup-$TIMESTAMP.tar.gz" | cut -f1)
    log_success "备份压缩完成，大小: $BACKUP_SIZE"
}

# 清理旧备份
cleanup_old_backups() {
    log "清理旧备份文件..."
    
    # 删除超过保留期的备份
    find "$BACKUP_BASE_DIR" -name "backup-*.tar.gz" -mtime +$RETENTION_DAYS -delete
    
    # 统计备份文件
    BACKUP_COUNT=$(find "$BACKUP_BASE_DIR" -name "backup-*.tar.gz" | wc -l)
    log_success "清理完成，当前备份数量: $BACKUP_COUNT"
}

# 验证备份
verify_backup() {
    log "验证备份完整性..."
    
    BACKUP_FILE="$BACKUP_BASE_DIR/backup-$TIMESTAMP.tar.gz"
    
    if [ ! -f "$BACKUP_FILE" ]; then
        log_error "备份文件不存在: $BACKUP_FILE"
        return 1
    fi
    
    # 检查压缩文件完整性
    if ! tar -tzf "$BACKUP_FILE" >/dev/null 2>&1; then
        log_error "备份文件损坏"
        return 1
    fi
    
    # 检查关键文件
    if ! tar -tzf "$BACKUP_FILE" | grep -q "backup-manifest.txt"; then
        log_error "备份清单文件缺失"
        return 1
    fi
    
    if ! tar -tzf "$BACKUP_FILE" | grep -q "postgres-all.sql"; then
        log_warning "数据库备份文件缺失"
    fi
    
    log_success "备份验证通过"
}

# 显示备份信息
show_backup_info() {
    log "备份信息:"
    echo ""
    echo "📁 备份目录: $BACKUP_BASE_DIR"
    echo "📦 备份文件: backup-$TIMESTAMP.tar.gz"
    echo "📊 备份大小: $(du -h "$BACKUP_BASE_DIR/backup-$TIMESTAMP.tar.gz" | cut -f1)"
    echo "📅 备份时间: $(date)"
    echo "🕒 保留期限: $RETENTION_DAYS 天"
    echo ""
    echo "📋 恢复命令:"
    echo "  ./scripts/restore-prod.sh backup-$TIMESTAMP.tar.gz"
    echo ""
    echo "📋 管理命令:"
    echo "  - 列出备份: ls -la $BACKUP_BASE_DIR/"
    echo "  - 查看备份内容: tar -tzf $BACKUP_BASE_DIR/backup-$TIMESTAMP.tar.gz"
    echo "  - 删除备份: rm $BACKUP_BASE_DIR/backup-$TIMESTAMP.tar.gz"
}

# 主函数
main() {
    case "${1:-backup}" in
        "backup")
            log "开始生产环境备份..."
            check_environment
            create_backup_directory
            backup_database
            backup_configs
            backup_volumes
            backup_logs
            create_backup_manifest
            compress_backup
            cleanup_old_backups
            verify_backup
            show_backup_info
            log_success "生产环境备份完成!"
            ;;
        "list")
            log "列出备份文件..."
            ls -la "$BACKUP_BASE_DIR"/backup-*.tar.gz 2>/dev/null || log "没有找到备份文件"
            ;;
        "cleanup")
            cleanup_old_backups
            ;;
        "verify")
            if [ -z "$2" ]; then
                log_error "请指定备份文件名"
                exit 1
            fi
            verify_backup "$2"
            ;;
        *)
            echo "用法: $0 {backup|list|cleanup|verify} [backup-file]"
            echo ""
            echo "命令:"
            echo "  backup     执行完整备份 (默认)"
            echo "  list       列出所有备份文件"
            echo "  cleanup    清理旧备份文件"
            echo "  verify     验证备份文件完整性"
            echo ""
            echo "示例:"
            echo "  $0 backup"
            echo "  $0 list"
            echo "  $0 cleanup"
            echo "  $0 verify backup-20240101-120000.tar.gz"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
