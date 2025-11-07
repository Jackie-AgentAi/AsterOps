#!/bin/bash

# API测试脚本
set -e

echo "=== LLMOps平台API测试 ==="
echo "时间: $(date)"
echo ""

# 测试项目管理API
echo "1. 测试项目管理API..."

# 创建项目
echo "创建测试项目..."
project_response=$(curl -s -X POST http://localhost:8082/api/v1/projects \
  -H "Content-Type: application/json" \
  -d '{
    "name": "测试项目",
    "description": "这是一个测试项目",
    "owner_id": "550e8400-e29b-41d4-a716-446655440000",
    "tenant_id": "550e8400-e29b-41d4-a716-446655440000"
  }' 2>/dev/null || echo "创建失败")

echo "创建项目响应: $project_response"

# 获取项目列表
echo "获取项目列表..."
projects_response=$(curl -s "http://localhost:8082/api/v1/projects?tenant_id=550e8400-e29b-41d4-a716-446655440000" 2>/dev/null || echo "获取失败")
echo "项目列表响应: $projects_response"

echo ""

# 测试用户服务API
echo "2. 测试用户服务API..."
user_response=$(curl -s http://localhost:8081/health 2>/dev/null || echo "未响应")
echo "用户服务健康检查: $user_response"

echo ""

# 测试其他服务API
echo "3. 测试其他服务API..."
services=(
    "model-service:8083"
    "inference-service:8084"
    "cost-service:8085"
    "monitoring-service:8086"
)

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    echo -n "$name API: "
    response=$(curl -s http://localhost:$port/ 2>/dev/null || echo "未响应")
    echo "$response"
done

echo ""
echo "=== API测试完成 ==="
