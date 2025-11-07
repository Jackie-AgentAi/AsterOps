#!/bin/bash

# 服务注册脚本
# 用于向Consul注册所有微服务

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

# Consul地址
CONSUL_ADDR="http://localhost:8500"

# 检查Consul是否可用
check_consul() {
    log_info "检查Consul连接..."
    if curl -f $CONSUL_ADDR/v1/status/leader > /dev/null 2>&1; then
        log_success "Consul连接正常"
    else
        log_error "Consul连接失败"
        exit 1
    fi
}

# 注册用户服务
register_user_service() {
    log_info "注册用户服务..."
    curl -X PUT $CONSUL_ADDR/v1/agent/service/register \
        -H "Content-Type: application/json" \
        -d '{
            "ID": "user-service-1",
            "Name": "user-service",
            "Tags": ["api", "user", "auth"],
            "Address": "user-service",
            "Port": 8081,
            "Check": {
                "HTTP": "http://user-service:8081/health",
                "Interval": "10s",
                "Timeout": "3s",
                "DeregisterCriticalServiceAfter": "30s"
            }
        }'
    log_success "用户服务注册完成"
}

# 注册模型服务
register_model_service() {
    log_info "注册模型服务..."
    curl -X PUT $CONSUL_ADDR/v1/agent/service/register \
        -H "Content-Type: application/json" \
        -d '{
            "ID": "model-service-1",
            "Name": "model-service",
            "Tags": ["api", "model", "ml"],
            "Address": "model-service",
            "Port": 8083,
            "Check": {
                "HTTP": "http://model-service:8083/health",
                "Interval": "10s",
                "Timeout": "3s",
                "DeregisterCriticalServiceAfter": "30s"
            }
        }'
    log_success "模型服务注册完成"
}

# 注册推理服务
register_inference_service() {
    log_info "注册推理服务..."
    curl -X PUT $CONSUL_ADDR/v1/agent/service/register \
        -H "Content-Type: application/json" \
        -d '{
            "ID": "inference-service-1",
            "Name": "inference-service",
            "Tags": ["api", "inference", "ai"],
            "Address": "inference-service",
            "Port": 8084,
            "Check": {
                "HTTP": "http://inference-service:8084/health",
                "Interval": "10s",
                "Timeout": "3s",
                "DeregisterCriticalServiceAfter": "30s"
            }
        }'
    log_success "推理服务注册完成"
}

# 注册成本服务
register_cost_service() {
    log_info "注册成本服务..."
    curl -X PUT $CONSUL_ADDR/v1/agent/service/register \
        -H "Content-Type: application/json" \
        -d '{
            "ID": "cost-service-1",
            "Name": "cost-service",
            "Tags": ["api", "cost", "billing"],
            "Address": "cost-service",
            "Port": 8085,
            "Check": {
                "HTTP": "http://cost-service:8085/health",
                "Interval": "10s",
                "Timeout": "3s",
                "DeregisterCriticalServiceAfter": "30s"
            }
        }'
    log_success "成本服务注册完成"
}

# 注册监控服务
register_monitoring_service() {
    log_info "注册监控服务..."
    curl -X PUT $CONSUL_ADDR/v1/agent/service/register \
        -H "Content-Type: application/json" \
        -d '{
            "ID": "monitoring-service-1",
            "Name": "monitoring-service",
            "Tags": ["api", "monitoring", "alerting"],
            "Address": "monitoring-service",
            "Port": 8086,
            "Check": {
                "HTTP": "http://monitoring-service:8086/health",
                "Interval": "10s",
                "Timeout": "3s",
                "DeregisterCriticalServiceAfter": "30s"
            }
        }'
    log_success "监控服务注册完成"
}

# 注册项目服务
register_project_service() {
    log_info "注册项目服务..."
    curl -X PUT $CONSUL_ADDR/v1/agent/service/register \
        -H "Content-Type: application/json" \
        -d '{
            "ID": "project-service-1",
            "Name": "project-service",
            "Tags": ["api", "project", "management"],
            "Address": "project-service",
            "Port": 8082,
            "Check": {
                "HTTP": "http://project-service:8082/health",
                "Interval": "10s",
                "Timeout": "3s",
                "DeregisterCriticalServiceAfter": "30s"
            }
        }'
    log_success "项目服务注册完成"
}

# 注册API网关
register_api_gateway() {
    log_info "注册API网关..."
    curl -X PUT $CONSUL_ADDR/v1/agent/service/register \
        -H "Content-Type: application/json" \
        -d '{
            "ID": "api-gateway-1",
            "Name": "api-gateway",
            "Tags": ["api", "gateway", "proxy"],
            "Address": "api-gateway",
            "Port": 8080,
            "Check": {
                "HTTP": "http://api-gateway:8080/health",
                "Interval": "10s",
                "Timeout": "3s",
                "DeregisterCriticalServiceAfter": "30s"
            }
        }'
    log_success "API网关注册完成"
}

# 注册所有服务
register_all_services() {
    log_info "开始注册所有服务..."
    
    check_consul
    register_user_service
    register_model_service
    register_inference_service
    register_cost_service
    register_monitoring_service
    register_project_service
    register_api_gateway
    
    log_success "所有服务注册完成"
}

# 查看服务列表
list_services() {
    log_info "查看服务列表..."
    curl -s $CONSUL_ADDR/v1/catalog/services | jq .
}

# 查看服务健康状态
check_services_health() {
    log_info "检查服务健康状态..."
    services=("user-service" "model-service" "inference-service" "cost-service" "monitoring-service" "project-service" "api-gateway")
    
    for service in "${services[@]}"; do
        log_info "检查 $service 健康状态..."
        health=$(curl -s $CONSUL_ADDR/v1/health/service/$service | jq -r '.[0].Checks[0].Status')
        if [ "$health" = "passing" ]; then
            log_success "$service 健康状态正常"
        else
            log_warning "$service 健康状态异常: $health"
        fi
    done
}

# 注销服务
deregister_service() {
    local service_name=$1
    if [ -z "$service_name" ]; then
        log_error "请指定服务名称"
        exit 1
    fi
    
    log_info "注销服务: $service_name"
    curl -X PUT $CONSUL_ADDR/v1/agent/service/deregister/$service_name
    log_success "服务 $service_name 注销完成"
}

# 显示帮助
show_help() {
    echo "服务注册脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  register    注册所有服务"
    echo "  list        查看服务列表"
    echo "  health      检查服务健康状态"
    echo "  deregister  注销指定服务"
    echo "  help        显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 register                    # 注册所有服务"
    echo "  $0 list                        # 查看服务列表"
    echo "  $0 health                      # 检查健康状态"
    echo "  $0 deregister user-service-1   # 注销指定服务"
}

# 主函数
main() {
    case "${1:-help}" in
        register)
            register_all_services
            ;;
        list)
            list_services
            ;;
        health)
            check_services_health
            ;;
        deregister)
            deregister_service "$2"
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



