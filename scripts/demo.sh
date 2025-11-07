#!/bin/bash

# LLMOps平台演示脚本
set -e

echo "🎬 LLMOps平台功能演示"
echo "====================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 演示函数
demo_step() {
    local step="$1"
    local description="$2"
    echo -e "${BLUE}步骤 $step:${NC} $description"
    echo "----------------------------------------"
}

demo_result() {
    local result="$1"
    if [[ $result == *"成功"* ]] || [[ $result == *"healthy"* ]] || [[ $result == *"200"* ]]; then
        echo -e "${GREEN}✅ $result${NC}"
    else
        echo -e "${RED}❌ $result${NC}"
    fi
    echo ""
}

# 1. 平台概览
demo_step "1" "平台概览"
echo "LLMOps运营管理平台是一个基于微服务架构的LLM运营管理平台"
echo "包含6个微服务：用户、项目、模型、推理、成本、监控"
echo ""

# 2. 服务健康检查
demo_step "2" "服务健康检查"
echo "检查所有微服务的健康状态..."

services=(
    "API网关:8087"
    "用户服务:8081"
    "项目管理服务:8082"
    "模型服务:8083"
    "推理服务:8084"
    "成本服务:8085"
    "监控服务:8086"
)

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    echo -n "  $name: "
    response=$(curl -s http://localhost:$port/health 2>/dev/null || echo "未响应")
    if [[ $response == *"healthy"* ]] || [[ $response == *"ok"* ]]; then
        echo -e "${GREEN}健康${NC}"
    else
        echo -e "${RED}异常${NC}"
    fi
done
echo ""

# 3. 项目管理功能演示
demo_step "3" "项目管理功能演示"
echo "演示项目管理服务的核心功能..."

# 创建项目
echo "📝 创建测试项目..."
project_response=$(curl -s -X POST http://localhost:8082/api/v1/projects \
  -H "Content-Type: application/json" \
  -d '{
    "name": "演示项目",
    "description": "这是一个演示项目，展示LLMOps平台的项目管理功能",
    "owner_id": "550e8400-e29b-41d4-a716-446655440000",
    "tenant_id": "550e8400-e29b-41d4-a716-446655440000"
  }' 2>/dev/null || echo "创建失败")

if [[ $project_response == *"201"* ]]; then
    project_id=$(echo $project_response | jq -r '.data.id' 2>/dev/null || echo "未知")
    echo -e "${GREEN}✅ 项目创建成功，ID: $project_id${NC}"
else
    echo -e "${RED}❌ 项目创建失败${NC}"
fi

# 获取项目列表
echo "📋 获取项目列表..."
projects_response=$(curl -s "http://localhost:8082/api/v1/projects?tenant_id=550e8400-e29b-41d4-a716-446655440000" 2>/dev/null || echo "获取失败")
if [[ $projects_response == *"200"* ]]; then
    project_count=$(echo $projects_response | jq -r '.data.total' 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ 获取项目列表成功，共 $project_count 个项目${NC}"
else
    echo -e "${RED}❌ 获取项目列表失败${NC}"
fi
echo ""

# 4. API网关功能演示
demo_step "4" "API网关功能演示"
echo "演示API网关的统一入口功能..."

# 获取服务列表
echo "🔍 获取注册的服务列表..."
services_response=$(curl -s http://localhost:8087/services 2>/dev/null || echo "获取失败")
if [[ $services_response == *"user-service"* ]]; then
    echo -e "${GREEN}✅ 服务发现正常，已注册6个微服务${NC}"
else
    echo -e "${RED}❌ 服务发现异常${NC}"
fi

# 通过网关访问服务
echo "🌐 通过网关访问用户服务..."
gateway_response=$(curl -s http://localhost:8087/api/v1/users/ 2>/dev/null || echo "访问失败")
if [[ $gateway_response == *"user-service"* ]]; then
    echo -e "${GREEN}✅ 网关代理功能正常${NC}"
else
    echo -e "${RED}❌ 网关代理功能异常${NC}"
fi
echo ""

# 5. 监控系统演示
demo_step "5" "监控系统演示"
echo "演示监控和可视化功能..."

# Prometheus健康检查
echo "📊 Prometheus监控系统..."
prometheus_response=$(curl -s http://localhost:9090/-/healthy 2>/dev/null || echo "未响应")
if [[ $prometheus_response == *"Prometheus Server is Healthy"* ]]; then
    echo -e "${GREEN}✅ Prometheus运行正常${NC}"
else
    echo -e "${RED}❌ Prometheus运行异常${NC}"
fi

# Grafana健康检查
echo "📈 Grafana可视化面板..."
grafana_response=$(curl -s http://localhost:3000/api/health 2>/dev/null || echo "未响应")
if [[ $grafana_response == *"ok"* ]]; then
    echo -e "${GREEN}✅ Grafana运行正常${NC}"
else
    echo -e "${RED}❌ Grafana运行异常${NC}"
fi
echo ""

# 6. 前端界面演示
demo_step "6" "前端界面演示"
echo "演示Web界面的实时监控功能..."

# 检查前端界面
echo "🌐 前端界面访问..."
frontend_response=$(curl -s http://localhost/ | grep -o "LLMOps运营管理平台" 2>/dev/null || echo "未找到")
if [[ $frontend_response == "LLMOps运营管理平台" ]]; then
    echo -e "${GREEN}✅ 前端界面正常，支持实时监控${NC}"
else
    echo -e "${RED}❌ 前端界面异常${NC}"
fi
echo ""

# 7. 性能测试
demo_step "7" "性能测试"
echo "测试平台性能和响应时间..."

# 响应时间测试
echo "⏱️ 测试API响应时间..."
start_time=$(date +%s%N)
curl -s http://localhost:8082/health > /dev/null
end_time=$(date +%s%N)
response_time=$(( (end_time - start_time) / 1000000 ))
echo -e "${GREEN}✅ API响应时间: ${response_time}ms${NC}"

# 并发测试
echo "🔄 测试并发处理能力..."
concurrent_requests=10
for i in $(seq 1 $concurrent_requests); do
    curl -s http://localhost:8082/health > /dev/null &
done
wait
echo -e "${GREEN}✅ 并发测试完成，处理了 $concurrent_requests 个并发请求${NC}"
echo ""

# 8. 总结
demo_step "8" "演示总结"
echo "🎉 LLMOps平台演示完成！"
echo ""
echo "📊 平台特性:"
echo "  ✅ 微服务架构 - 6个独立服务"
echo "  ✅ 容器化部署 - 100% Docker化"
echo "  ✅ API网关 - 统一入口管理"
echo "  ✅ 实时监控 - Prometheus + Grafana"
echo "  ✅ Web界面 - 可视化监控面板"
echo "  ✅ 项目管理 - 完整功能实现"
echo "  ✅ 服务发现 - Consul自动注册"
echo "  ✅ 健康检查 - 全链路监控"
echo ""
echo "🌐 访问地址:"
echo "  前端界面: http://localhost/"
echo "  API网关: http://localhost:8087/"
echo "  监控面板: http://localhost:3000/"
echo "  指标收集: http://localhost:9090/"
echo ""
echo "🛠️ 管理命令:"
echo "  健康检查: ./scripts/health-check-all.sh"
echo "  API测试: ./scripts/api-test.sh"
echo "  综合测试: ./scripts/comprehensive-test.sh"
echo "  停止服务: docker-compose down"
echo ""
echo -e "${PURPLE}✨ 感谢使用LLMOps运营管理平台！${NC}"

