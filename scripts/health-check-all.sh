#!/bin/bash

# 全面健康检查脚本
set -e

echo "=== LLMOps平台健康检查 ==="
echo "时间: $(date)"
echo ""

# 检查基础设施服务
echo "1. 检查基础设施服务..."
echo "PostgreSQL: $(curl -s http://localhost:5433/health 2>/dev/null || echo "未响应")"
echo "Redis: $(redis-cli -h localhost -p 6380 ping 2>/dev/null || echo "未响应")"
echo "Consul: $(curl -s http://localhost:8500/v1/status/leader 2>/dev/null || echo "未响应")"
echo ""

# 检查微服务
echo "2. 检查微服务..."
services=(
    "user-service:8081"
    "project-service:8082"
    "model-service:8083"
    "inference-service:8084"
    "cost-service:8085"
    "monitoring-service:8086"
)

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    echo -n "$name ($port): "
    response=$(curl -s http://localhost:$port/health 2>/dev/null || echo "未响应")
    echo "$response"
done

echo ""

# 检查监控服务
echo "3. 检查监控服务..."
echo "Prometheus: $(curl -s http://localhost:9090/-/healthy 2>/dev/null || echo "未响应")"
echo "Grafana: $(curl -s http://localhost:3000/api/health 2>/dev/null || echo "未响应")"
echo ""

# 检查API接口
echo "4. 检查API接口..."
echo "项目管理API: $(curl -s "http://localhost:8082/api/v1/projects?tenant_id=550e8400-e29b-41d4-a716-446655440000" | jq -r '.message' 2>/dev/null || echo "未响应")"
echo ""

echo "=== 健康检查完成 ==="
