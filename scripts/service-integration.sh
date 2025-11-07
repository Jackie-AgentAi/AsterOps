#!/bin/bash

# 服务集成测试脚本
set -e

echo "=== LLMOps平台服务集成测试 ==="
echo "时间: $(date)"
echo ""

# 检查Consul服务发现
echo "1. 检查Consul服务发现..."
consul_services=$(curl -s http://localhost:8500/v1/catalog/services 2>/dev/null || echo "{}")
echo "Consul注册的服务:"
echo "$consul_services" | jq . 2>/dev/null || echo "$consul_services"

echo ""

# 检查服务健康状态
echo "2. 检查服务健康状态..."
consul_health=$(curl -s http://localhost:8500/v1/health/service/user-service 2>/dev/null || echo "[]")
echo "用户服务健康状态:"
echo "$consul_health" | jq . 2>/dev/null || echo "$consul_health"

echo ""

# 测试服务间通信
echo "3. 测试服务间通信..."

# 通过项目管理服务创建项目
echo "通过项目管理服务创建项目..."
project_id=$(curl -s -X POST http://localhost:8082/api/v1/projects \
  -H "Content-Type: application/json" \
  -d '{
    "name": "集成测试项目",
    "description": "用于测试服务间集成的项目",
    "owner_id": "550e8400-e29b-41d4-a716-446655440000",
    "tenant_id": "550e8400-e29b-41d4-a716-446655440000"
  }' | jq -r '.data.id' 2>/dev/null || echo "创建失败")

echo "创建的项目ID: $project_id"

# 添加项目成员
if [ "$project_id" != "创建失败" ] && [ "$project_id" != "null" ]; then
    echo "添加项目成员..."
    member_response=$(curl -s -X POST "http://localhost:8082/api/v1/projects/$project_id/members" \
      -H "Content-Type: application/json" \
      -d '{
        "user_id": "550e8400-e29b-41d4-a716-446655440001",
        "role": "member",
        "permissions": ["read", "write"]
      }' 2>/dev/null || echo "添加成员失败")
    
    echo "添加成员响应: $member_response"
    
    # 设置资源配额
    echo "设置资源配额..."
    quota_response=$(curl -s -X POST "http://localhost:8082/api/v1/projects/$project_id/quota" \
      -H "Content-Type: application/json" \
      -d '{
        "cpu_limit": 1000,
        "memory_limit": 2048,
        "gpu_limit": 1,
        "storage_limit": 100,
        "bandwidth_limit": 1000
      }' 2>/dev/null || echo "设置配额失败")
    
    echo "设置配额响应: $quota_response"
    
    # 获取项目详情
    echo "获取项目详情..."
    project_detail=$(curl -s "http://localhost:8082/api/v1/projects/$project_id" 2>/dev/null || echo "获取失败")
    echo "项目详情: $project_detail"
fi

echo ""

# 检查监控指标
echo "4. 检查监控指标..."
prometheus_metrics=$(curl -s http://localhost:9090/api/v1/query?query=up 2>/dev/null || echo "{}")
echo "Prometheus指标:"
echo "$prometheus_metrics" | jq . 2>/dev/null || echo "$prometheus_metrics"

echo ""
echo "=== 服务集成测试完成 ==="
