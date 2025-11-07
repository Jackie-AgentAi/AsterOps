#!/bin/bash

# LLMOps平台健康检查脚本
# 用于检查所有服务的健康状态

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

# 服务配置
declare -A SERVICES=(
    ["user-service"]="http://localhost:8081/health"
    ["model-service"]="http://localhost:8083/health"
    ["inference-service"]="http://localhost:8084/health"
    ["cost-service"]="http://localhost:8085/health"
    ["monitoring-service"]="http://localhost:8086/health"
    ["project-service"]="http://localhost:8082/health"
    ["api-gateway"]="http://localhost:8080/health"
)

# 基础设施服务
declare -A INFRASTRUCTURE=(
    ["consul"]="http://localhost:8500/v1/status/leader"
    ["postgres"]="localhost:5432"
    ["redis"]="localhost:6379"
)

# 检查单个服务
check_service() {
    local service_name=$1
    local health_url=$2
    local timeout=${3:-5}
    
    log_info "检查 $service_name 健康状态..."
    
    if curl -f -s --max-time $timeout "$health_url" > /dev/null 2>&1; then
        log_success "$service_name 健康状态正常"
        return 0
    else
        log_error "$service_name 健康检查失败"
        return 1
    fi
}

# 检查基础设施服务
check_infrastructure() {
    local service_name=$1
    local check_target=$2
    
    log_info "检查 $service_name 连接状态..."
    
    case $service_name in
        "consul")
            if curl -f -s --max-time 5 "$check_target" > /dev/null 2>&1; then
                log_success "$service_name 连接正常"
                return 0
            else
                log_error "$service_name 连接失败"
                return 1
            fi
            ;;
        "postgres")
            if nc -z localhost 5432 2>/dev/null; then
                log_success "$service_name 连接正常"
                return 0
            else
                log_error "$service_name 连接失败"
                return 1
            fi
            ;;
        "redis")
            if nc -z localhost 6379 2>/dev/null; then
                log_success "$service_name 连接正常"
                return 0
            else
                log_error "$service_name 连接失败"
                return 1
            fi
            ;;
        *)
            log_warning "未知的基础设施服务: $service_name"
            return 1
            ;;
    esac
}

# 检查所有微服务
check_all_services() {
    log_info "开始检查所有微服务..."
    
    local failed_services=()
    local total_services=0
    local healthy_services=0
    
    for service in "${!SERVICES[@]}"; do
        total_services=$((total_services + 1))
        if check_service "$service" "${SERVICES[$service]}"; then
            healthy_services=$((healthy_services + 1))
        else
            failed_services+=("$service")
        fi
    done
    
    log_info "微服务健康检查完成: $healthy_services/$total_services 服务健康"
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        log_warning "以下服务健康检查失败:"
        for service in "${failed_services[@]}"; do
            log_warning "  - $service"
        done
        return 1
    fi
    
    return 0
}

# 检查所有基础设施
check_all_infrastructure() {
    log_info "开始检查所有基础设施服务..."
    
    local failed_infrastructure=()
    local total_infrastructure=0
    local healthy_infrastructure=0
    
    for infra in "${!INFRASTRUCTURE[@]}"; do
        total_infrastructure=$((total_infrastructure + 1))
        if check_infrastructure "$infra" "${INFRASTRUCTURE[$infra]}"; then
            healthy_infrastructure=$((healthy_infrastructure + 1))
        else
            failed_infrastructure+=("$infra")
        fi
    done
    
    log_info "基础设施健康检查完成: $healthy_infrastructure/$total_infrastructure 服务健康"
    
    if [ ${#failed_infrastructure[@]} -gt 0 ]; then
        log_warning "以下基础设施服务健康检查失败:"
        for infra in "${failed_infrastructure[@]}"; do
            log_warning "  - $infra"
        done
        return 1
    fi
    
    return 0
}

# 检查特定服务
check_specific_service() {
    local service_name=$1
    
    if [ -z "$service_name" ]; then
        log_error "请指定服务名称"
        return 1
    fi
    
    if [ -n "${SERVICES[$service_name]}" ]; then
        check_service "$service_name" "${SERVICES[$service_name]}"
    elif [ -n "${INFRASTRUCTURE[$service_name]}" ]; then
        check_infrastructure "$service_name" "${INFRASTRUCTURE[$service_name]}"
    else
        log_error "未知服务: $service_name"
        return 1
    fi
}

# 生成健康报告
generate_health_report() {
    log_info "生成健康检查报告..."
    
    local report_file="/tmp/llmops-health-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "LLMOps平台健康检查报告"
        echo "生成时间: $(date)"
        echo "=================================="
        echo ""
        
        echo "微服务健康状态:"
        for service in "${!SERVICES[@]}"; do
            if curl -f -s --max-time 5 "${SERVICES[$service]}" > /dev/null 2>&1; then
                echo "  ✓ $service: 健康"
            else
                echo "  ✗ $service: 不健康"
            fi
        done
        
        echo ""
        echo "基础设施健康状态:"
        for infra in "${!INFRASTRUCTURE[@]}"; do
            case $infra in
                "consul")
                    if curl -f -s --max-time 5 "${INFRASTRUCTURE[$infra]}" > /dev/null 2>&1; then
                        echo "  ✓ $infra: 健康"
                    else
                        echo "  ✗ $infra: 不健康"
                    fi
                    ;;
                "postgres")
                    if nc -z localhost 5432 2>/dev/null; then
                        echo "  ✓ $infra: 健康"
                    else
                        echo "  ✗ $infra: 不健康"
                    fi
                    ;;
                "redis")
                    if nc -z localhost 6379 2>/dev/null; then
                        echo "  ✓ $infra: 健康"
                    else
                        echo "  ✗ $infra: 不健康"
                    fi
                    ;;
            esac
        done
        
        echo ""
        echo "Docker容器状态:"
        docker-compose ps
        
    } > "$report_file"
    
    log_success "健康检查报告已生成: $report_file"
}

# 显示帮助
show_help() {
    echo "LLMOps平台健康检查脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  all         检查所有服务"
    echo "  services    检查所有微服务"
    echo "  infra       检查所有基础设施"
    echo "  <service>   检查特定服务"
    echo "  report      生成健康检查报告"
    echo "  help        显示帮助信息"
    echo ""
    echo "可用服务:"
    echo "  微服务: user-service, model-service, inference-service, cost-service, monitoring-service, project-service, api-gateway"
    echo "  基础设施: consul, postgres, redis"
    echo ""
    echo "示例:"
    echo "  $0 all                    # 检查所有服务"
    echo "  $0 services              # 检查所有微服务"
    echo "  $0 user-service          # 检查用户服务"
    echo "  $0 report                # 生成健康报告"
}

# 主函数
main() {
    case "${1:-help}" in
        all)
            check_all_infrastructure
            check_all_services
            ;;
        services)
            check_all_services
            ;;
        infra)
            check_all_infrastructure
            ;;
        report)
            generate_health_report
            ;;
        help)
            show_help
            ;;
        *)
            check_specific_service "$1"
            ;;
    esac
}

# 执行主函数
main "$@"
