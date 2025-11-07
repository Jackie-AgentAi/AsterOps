#!/bin/bash

# 项目管理服务测试脚本

set -e

echo "🚀 启动项目管理服务测试..."

# 检查服务是否运行
check_service() {
    local port=$1
    local service_name=$2
    
    echo "检查 $service_name 服务状态..."
    if curl -s http://localhost:$port/health > /dev/null; then
        echo "✅ $service_name 服务运行正常"
        return 0
    else
        echo "❌ $service_name 服务未运行"
        return 1
    fi
}

# 测试健康检查
test_health() {
    echo "测试健康检查端点..."
    response=$(curl -s http://localhost:8082/health)
    echo "健康检查响应: $response"
    
    if echo "$response" | grep -q "ok"; then
        echo "✅ 健康检查通过"
    else
        echo "❌ 健康检查失败"
        exit 1
    fi
}

# 测试就绪检查
test_ready() {
    echo "测试就绪检查端点..."
    response=$(curl -s http://localhost:8082/ready)
    echo "就绪检查响应: $response"
    
    if echo "$response" | grep -q "ready"; then
        echo "✅ 就绪检查通过"
    else
        echo "❌ 就绪检查失败"
        exit 1
    fi
}

# 测试API端点
test_api() {
    echo "测试API端点..."
    
    # 测试项目列表API
    echo "测试项目列表API..."
    response=$(curl -s "http://localhost:8082/api/v1/projects?tenant_id=00000000-0000-0000-0000-000000000000" || echo "API调用失败")
    echo "项目列表API响应: $response"
    
    # 测试模板列表API
    echo "测试模板列表API..."
    response=$(curl -s "http://localhost:8082/api/v1/templates?tenant_id=00000000-0000-0000-0000-000000000000" || echo "API调用失败")
    echo "模板列表API响应: $response"
}

# 主测试流程
main() {
    echo "开始项目管理服务测试..."
    
    # 检查服务状态
    if ! check_service 8082 "项目管理服务"; then
        echo "请先启动项目管理服务"
        exit 1
    fi
    
    # 运行测试
    test_health
    test_ready
    test_api
    
    echo "🎉 所有测试完成！"
}

# 运行主函数
main "$@"
