#!/bin/bash

# LLMOps平台测试脚本
# 用于测试所有微服务的API接口

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

# 测试用户服务
test_user_service() {
    log_info "测试用户服务..."
    
    # 健康检查
    if curl -f http://localhost:8081/health > /dev/null 2>&1; then
        log_success "用户服务健康检查通过"
    else
        log_error "用户服务健康检查失败"
        return 1
    fi
    
    # 测试用户注册
    log_info "测试用户注册..."
    response=$(curl -s -X POST http://localhost:8081/api/v1/auth/register \
        -H "Content-Type: application/json" \
        -d '{
            "username": "testuser",
            "email": "test@example.com",
            "password": "password123"
        }')
    
    if echo "$response" | grep -q "success"; then
        log_success "用户注册测试通过"
    else
        log_warning "用户注册测试失败: $response"
    fi
    
    # 测试用户登录
    log_info "测试用户登录..."
    response=$(curl -s -X POST http://localhost:8081/api/v1/auth/login \
        -H "Content-Type: application/json" \
        -d '{
            "username": "testuser",
            "password": "password123"
        }')
    
    if echo "$response" | grep -q "token"; then
        log_success "用户登录测试通过"
    else
        log_warning "用户登录测试失败: $response"
    fi
}

# 测试模型服务
test_model_service() {
    log_info "测试模型服务..."
    
    # 健康检查
    if curl -f http://localhost:8083/health > /dev/null 2>&1; then
        log_success "模型服务健康检查通过"
    else
        log_error "模型服务健康检查失败"
        return 1
    fi
    
    # 测试模型列表
    log_info "测试模型列表..."
    response=$(curl -s http://localhost:8083/api/v1/models)
    
    if echo "$response" | grep -q "models"; then
        log_success "模型列表测试通过"
    else
        log_warning "模型列表测试失败: $response"
    fi
}

# 测试推理服务
test_inference_service() {
    log_info "测试推理服务..."
    
    # 健康检查
    if curl -f http://localhost:8084/health > /dev/null 2>&1; then
        log_success "推理服务健康检查通过"
    else
        log_error "推理服务健康检查失败"
        return 1
    fi
    
    # 测试推理接口
    log_info "测试推理接口..."
    response=$(curl -s -X POST http://localhost:8084/api/v1/inference/chat \
        -H "Content-Type: application/json" \
        -d '{
            "model": "gpt-3.5-turbo",
            "messages": [{"role": "user", "content": "Hello"}]
        }')
    
    if echo "$response" | grep -q "response"; then
        log_success "推理接口测试通过"
    else
        log_warning "推理接口测试失败: $response"
    fi
}

# 测试成本服务
test_cost_service() {
    log_info "测试成本服务..."
    
    # 健康检查
    if curl -f http://localhost:8085/health > /dev/null 2>&1; then
        log_success "成本服务健康检查通过"
    else
        log_error "成本服务健康检查失败"
        return 1
    fi
    
    # 测试成本记录
    log_info "测试成本记录..."
    response=$(curl -s -X POST http://localhost:8085/api/v1/costs \
        -H "Content-Type: application/json" \
        -d '{
            "project_id": "00000000-0000-0000-0000-000000000001",
            "cost_type": "compute",
            "amount": 100.0,
            "currency": "USD",
            "description": "Test cost"
        }')
    
    if echo "$response" | grep -q "success"; then
        log_success "成本记录测试通过"
    else
        log_warning "成本记录测试失败: $response"
    fi
}

# 测试监控服务
test_monitoring_service() {
    log_info "测试监控服务..."
    
    # 健康检查
    if curl -f http://localhost:8086/health > /dev/null 2>&1; then
        log_success "监控服务健康检查通过"
    else
        log_error "监控服务健康检查失败"
        return 1
    fi
    
    # 测试监控指标
    log_info "测试监控指标..."
    response=$(curl -s http://localhost:8086/api/v1/monitoring/metrics)
    
    if echo "$response" | grep -q "metrics"; then
        log_success "监控指标测试通过"
    else
        log_warning "监控指标测试失败: $response"
    fi
}

# 测试API网关
test_api_gateway() {
    log_info "测试API网关..."
    
    # 健康检查
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        log_success "API网关健康检查通过"
    else
        log_error "API网关健康检查失败"
        return 1
    fi
    
    # 测试路由
    log_info "测试API网关路由..."
    response=$(curl -s http://localhost:8080/api/v1/health)
    
    if echo "$response" | grep -q "healthy"; then
        log_success "API网关路由测试通过"
    else
        log_warning "API网关路由测试失败: $response"
    fi
}

# 执行所有测试
run_all_tests() {
    log_info "开始执行所有测试..."
    
    test_user_service
    test_model_service
    test_inference_service
    test_cost_service
    test_monitoring_service
    test_api_gateway
    
    log_success "所有测试完成"
}

# 显示帮助
show_help() {
    echo "LLMOps平台测试脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  user       测试用户服务"
    echo "  model      测试模型服务"
    echo "  inference  测试推理服务"
    echo "  cost       测试成本服务"
    echo "  monitoring 测试监控服务"
    echo "  gateway    测试API网关"
    echo "  all        测试所有服务"
    echo "  help       显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 all      # 测试所有服务"
    echo "  $0 user     # 测试用户服务"
}

# 主函数
main() {
    case "${1:-help}" in
        user)
            test_user_service
            ;;
        model)
            test_model_service
            ;;
        inference)
            test_inference_service
            ;;
        cost)
            test_cost_service
            ;;
        monitoring)
            test_monitoring_service
            ;;
        gateway)
            test_api_gateway
            ;;
        all)
            run_all_tests
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
