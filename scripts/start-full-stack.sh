#!/bin/bash

# LLMOps全栈启动脚本 - 同时启动前后端服务
# 使用Docker Compose管理所有服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 显示横幅
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    LLMOps 全栈启动脚本                        ║"
    echo "║              前端 + 后端 + 基础设施 + 监控                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# 检查环境依赖
check_environment() {
    log_step "1. 检查环境依赖..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    # 检查Docker服务状态
    if ! docker info &> /dev/null; then
        log_error "Docker服务未运行，请启动Docker服务"
        exit 1
    fi
    
    log_success "环境检查通过"
}

# 检查端口占用
check_ports() {
    log_step "2. 检查端口占用..."
    
    local ports=(80 3000 3001 5432 6379 8080 8081 8082 8083 8084 8085 8086 8500 9000 9001 9090)
    local occupied_ports=()
    
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            occupied_ports+=($port)
        fi
    done
    
    if [ ${#occupied_ports[@]} -gt 0 ]; then
        log_warning "以下端口已被占用: ${occupied_ports[*]}"
        log_info "正在尝试停止现有服务..."
        docker-compose down 2>/dev/null || true
        sleep 5
        
        # 再次检查
        occupied_ports=()
        for port in "${ports[@]}"; do
            if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
                occupied_ports+=($port)
            fi
        done
        
        if [ ${#occupied_ports[@]} -gt 0 ]; then
            log_error "端口 ${occupied_ports[*]} 仍被占用，请手动释放后重试"
            exit 1
        fi
    fi
    
    log_success "端口检查通过"
}

# 创建必要目录
create_directories() {
    log_step "3. 创建必要目录..."
    
    local dirs=(
        "logs"
        "data/postgres"
        "data/redis"
        "data/minio"
        "data/consul"
        "data/grafana"
        "data/prometheus"
        "frontend/admin-dashboard/dist"
        "frontend/user-portal/dist"
        "frontend/mobile-app/dist"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        chmod 755 "$dir"
    done
    
    log_success "目录创建完成"
}

# 构建前端应用
build_frontend() {
    log_step "4. 构建前端应用..."
    
    # 检查Node.js环境
    if ! command -v node &> /dev/null; then
        log_warning "Node.js未安装，跳过前端构建"
        return
    fi
    
    if ! command -v npm &> /dev/null; then
        log_warning "npm未安装，跳过前端构建"
        return
    fi
    
    # 构建管理后台
    if [ -d "frontend/admin-dashboard" ]; then
        log_info "构建管理后台..."
        cd frontend/admin-dashboard
        if [ -f "package.json" ]; then
            npm install --silent
            npm run build --silent
        fi
        cd ../..
    fi
    
    # 构建用户门户
    if [ -d "frontend/user-portal" ]; then
        log_info "构建用户门户..."
        cd frontend/user-portal
        if [ -f "package.json" ]; then
            npm install --silent
            npm run build --silent
        fi
        cd ../..
    fi
    
    # 构建移动端
    if [ -d "frontend/mobile-app" ]; then
        log_info "构建移动端应用..."
        cd frontend/mobile-app
        if [ -f "package.json" ]; then
            npm install --silent
            npm run build --silent
        fi
        cd ../..
    fi
    
    log_success "前端构建完成"
}

# 启动基础设施服务
start_infrastructure() {
    log_step "5. 启动基础设施服务..."
    
    log_info "启动数据库和缓存服务..."
    docker-compose up -d postgres redis consul minio
    
    # 等待数据库启动
    log_info "等待PostgreSQL启动..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker exec $(docker-compose ps -q postgres) pg_isready -U llmops -d llmops >/dev/null 2>&1; then
            log_success "PostgreSQL已就绪"
            break
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        log_error "PostgreSQL启动超时"
        exit 1
    fi
    
    # 等待Redis启动
    log_info "等待Redis启动..."
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if docker exec $(docker-compose ps -q redis) redis-cli ping >/dev/null 2>&1; then
            log_success "Redis已就绪"
            break
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        log_error "Redis启动超时"
        exit 1
    fi
    
    log_success "基础设施服务启动完成"
}

# 启动微服务
start_microservices() {
    log_step "6. 启动微服务..."
    
    log_info "启动后端微服务..."
    docker-compose up -d user-service project-service model-service inference-service cost-service monitoring-service
    
    # 等待微服务启动
    log_info "等待微服务启动..."
    sleep 20
    
    # 检查服务健康状态
    local services=("user-service" "project-service" "model-service" "inference-service" "cost-service" "monitoring-service")
    local healthy_services=()
    local unhealthy_services=()
    
    for service in "${services[@]}"; do
        if docker-compose ps "$service" | grep -q "Up"; then
            healthy_services+=("$service")
        else
            unhealthy_services+=("$service")
        fi
    done
    
    if [ ${#healthy_services[@]} -gt 0 ]; then
        log_success "健康服务: ${healthy_services[*]}"
    fi
    
    if [ ${#unhealthy_services[@]} -gt 0 ]; then
        log_warning "异常服务: ${unhealthy_services[*]}"
    fi
}

# 启动监控服务
start_monitoring() {
    log_step "7. 启动监控服务..."
    
    log_info "启动Prometheus和Grafana..."
    docker-compose up -d prometheus grafana
    
    # 等待监控服务启动
    log_info "等待监控服务启动..."
    sleep 15
    
    log_success "监控服务启动完成"
}

# 启动前端服务
start_frontend() {
    log_step "8. 启动前端服务..."
    
    log_info "启动前端应用和Nginx..."
    docker-compose up -d frontend nginx
    
    # 等待前端服务启动
    log_info "等待前端服务启动..."
    sleep 10
    
    log_success "前端服务启动完成"
}

# 运行健康检查
run_health_checks() {
    log_step "9. 运行健康检查..."
    
    # 检查API服务
    local api_services=(
        "http://localhost:8081/health:用户服务"
        "http://localhost:8082/health:项目服务"
        "http://localhost:8083/health:模型服务"
        "http://localhost:8084/health:推理服务"
        "http://localhost:8085/health:成本服务"
        "http://localhost:8086/health:监控服务"
    )
    
    local healthy_count=0
    local total_count=${#api_services[@]}
    
    for service in "${api_services[@]}"; do
        local url=$(echo "$service" | cut -d: -f1-2)
        local name=$(echo "$service" | cut -d: -f3)
        
        if curl -f -s "$url" >/dev/null 2>&1; then
            log_success "$name 健康检查通过"
            healthy_count=$((healthy_count + 1))
        else
            log_warning "$name 健康检查失败"
        fi
    done
    
    # 检查前端服务
    if curl -f -s "http://localhost:3000" >/dev/null 2>&1; then
        log_success "前端应用健康检查通过"
        healthy_count=$((healthy_count + 1))
        total_count=$((total_count + 1))
    else
        log_warning "前端应用健康检查失败"
        total_count=$((total_count + 1))
    fi
    
    # 检查监控服务
    if curl -f -s "http://localhost:9090/-/healthy" >/dev/null 2>&1; then
        log_success "Prometheus健康检查通过"
        healthy_count=$((healthy_count + 1))
        total_count=$((total_count + 1))
    else
        log_warning "Prometheus健康检查失败"
        total_count=$((total_count + 1))
    fi
    
    if curl -f -s "http://localhost:3001/api/health" >/dev/null 2>&1; then
        log_success "Grafana健康检查通过"
        healthy_count=$((healthy_count + 1))
        total_count=$((total_count + 1))
    else
        log_warning "Grafana健康检查失败"
        total_count=$((total_count + 1))
    fi
    
    log_info "健康检查完成: $healthy_count/$total_count 服务正常"
}

# 显示服务状态
show_status() {
    log_step "10. 显示服务状态..."
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        服务状态总览                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    docker-compose ps
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                        访问地址                            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}🌐 前端应用:${NC}     http://localhost:3000"
    echo -e "${BLUE}🔗 Nginx代理:${NC}    http://localhost:80"
    echo ""
    echo -e "${YELLOW}📡 后端API服务:${NC}"
    echo -e "   👤 用户服务:     http://localhost:8081"
    echo -e "   📁 项目服务:     http://localhost:8082"
    echo -e "   🤖 模型服务:     http://localhost:8083"
    echo -e "   ⚡ 推理服务:     http://localhost:8084"
    echo -e "   💰 成本服务:     http://localhost:8085"
    echo -e "   📊 监控服务:     http://localhost:8086"
    echo ""
    echo -e "${PURPLE}🔧 基础设施服务:${NC}"
    echo -e "   🗄️  PostgreSQL:  localhost:5432"
    echo -e "   🔄 Redis:        localhost:6379"
    echo -e "   🔍 Consul:       http://localhost:8500"
    echo -e "   📦 MinIO:        http://localhost:9001"
    echo ""
    echo -e "${CYAN}📈 监控系统:${NC}"
    echo -e "   📊 Prometheus:   http://localhost:9090"
    echo -e "   📈 Grafana:      http://localhost:3001"
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                        管理命令                            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}查看日志:${NC}       docker-compose logs -f [服务名]"
    echo -e "${BLUE}停止服务:${NC}       docker-compose down"
    echo -e "${BLUE}重启服务:${NC}       docker-compose restart [服务名]"
    echo -e "${BLUE}查看状态:${NC}       docker-compose ps"
    echo -e "${BLUE}健康检查:${NC}       ./scripts/health-check-all.sh"
    echo -e "${BLUE}API测试:${NC}        ./scripts/api-test.sh"
    echo ""
}

# 启动日志监控
start_log_monitoring() {
    if [ "$1" = "--logs" ]; then
        log_step "11. 启动日志监控..."
        echo ""
        log_info "按 Ctrl+C 退出日志监控"
        echo ""
        docker-compose logs -f --tail=50
    fi
}

# 主函数
main() {
    show_banner
    
    # 解析命令行参数
    local show_logs=false
    local clean_build=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --logs)
                show_logs=true
                shift
                ;;
            --clean)
                clean_build=true
                shift
                ;;
            --help)
                echo "用法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  --logs     启动后显示日志"
                echo "  --clean    清理构建缓存"
                echo "  --help     显示帮助信息"
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                echo "使用 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
    
    # 清理构建缓存
    if [ "$clean_build" = true ]; then
        log_info "清理构建缓存..."
        docker system prune -f
        docker-compose down -v
    fi
    
    # 执行启动流程
    check_environment
    check_ports
    create_directories
    build_frontend
    start_infrastructure
    start_microservices
    start_monitoring
    start_frontend
    run_health_checks
    show_status
    
    # 启动日志监控
    if [ "$show_logs" = true ]; then
        start_log_monitoring --logs
    fi
    
    echo ""
    log_success "🎉 LLMOps全栈环境启动完成！"
    echo ""
}

# 捕获中断信号
trap 'echo ""; log_warning "收到中断信号，正在停止服务..."; docker-compose down; exit 0' INT

# 执行主函数
main "$@"