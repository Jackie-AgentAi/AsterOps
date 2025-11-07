#!/bin/bash

# LLMOps前端后端集成测试脚本

set -e

echo "🧪 开始LLMOps前端后端集成测试..."

# 测试配置
API_GATEWAY_URL="http://localhost:8080"
FRONTEND_URL="http://localhost:3000"
TIMEOUT=30

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试函数
test_endpoint() {
    local url=$1
    local name=$2
    local expected_status=${3:-200}
    
    echo -n "测试 $name ($url)... "
    
    if response=$(curl -s -w "%{http_code}" -o /dev/null --max-time $TIMEOUT "$url" 2>/dev/null); then
        if [ "$response" = "$expected_status" ]; then
            echo -e "${GREEN}✅ 通过${NC}"
            return 0
        else
            echo -e "${RED}❌ 失败 (HTTP $response)${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ 失败 (连接超时)${NC}"
        return 1
    fi
}

# 测试API响应
test_api_response() {
    local url=$1
    local name=$2
    
    echo -n "测试 $name API响应... "
    
    if response=$(curl -s --max-time $TIMEOUT "$url" 2>/dev/null); then
        if echo "$response" | grep -q "healthy\|status\|data"; then
            echo -e "${GREEN}✅ 通过${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  响应格式异常${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ 失败${NC}"
        return 1
    fi
}

# 测试WebSocket连接
test_websocket() {
    local url=$1
    local name=$2
    
    echo -n "测试 $name WebSocket连接... "
    
    # 使用websocat或类似工具测试WebSocket
    if command -v websocat &> /dev/null; then
        if echo "ping" | timeout 5 websocat "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ 通过${NC}"
            return 0
        else
            echo -e "${RED}❌ 失败${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  跳过 (websocat未安装)${NC}"
        return 0
    fi
}

# 测试数据库连接
test_database() {
    echo -n "测试数据库连接... "
    
    if docker-compose -f docker-compose.frontend.yml exec -T postgres pg_isready -U llmops -d llmops > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 通过${NC}"
        return 0
    else
        echo -e "${RED}❌ 失败${NC}"
        return 1
    fi
}

# 测试Redis连接
test_redis() {
    echo -n "测试Redis连接... "
    
    if docker-compose -f docker-compose.frontend.yml exec -T redis redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 通过${NC}"
        return 0
    else
        echo -e "${RED}❌ 失败${NC}"
        return 1
    fi
}

# 测试服务发现
test_consul() {
    echo -n "测试Consul服务发现... "
    
    if curl -s --max-time $TIMEOUT "http://localhost:8500/v1/agent/services" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 通过${NC}"
        return 0
    else
        echo -e "${RED}❌ 失败${NC}"
        return 1
    fi
}

# 测试对象存储
test_minio() {
    echo -n "测试MinIO对象存储... "
    
    if curl -s --max-time $TIMEOUT "http://localhost:9001" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 通过${NC}"
        return 0
    else
        echo -e "${RED}❌ 失败${NC}"
        return 1
    fi
}

# 执行测试
echo "🔍 开始基础连接测试..."

# 基础设施测试
echo ""
echo "📦 基础设施服务测试:"
test_endpoint "http://localhost:5432" "PostgreSQL" 0
test_endpoint "http://localhost:6379" "Redis" 0
test_endpoint "http://localhost:8500" "Consul" 200
test_endpoint "http://localhost:9001" "MinIO" 200

# 微服务测试
echo ""
echo "🔧 微服务测试:"
test_endpoint "$API_GATEWAY_URL/health" "API网关健康检查"
test_endpoint "$API_GATEWAY_URL/api/v1/health" "用户服务"
test_endpoint "$API_GATEWAY_URL/api/v6/health" "项目服务"
test_endpoint "$API_GATEWAY_URL/api/v2/health" "模型服务"
test_endpoint "$API_GATEWAY_URL/api/v3/health" "推理服务"
test_endpoint "$API_GATEWAY_URL/api/v4/health" "成本服务"
test_endpoint "$API_GATEWAY_URL/api/v5/health" "监控服务"

# 前端测试
echo ""
echo "🎨 前端应用测试:"
test_endpoint "$FRONTEND_URL" "前端应用"
test_endpoint "$FRONTEND_URL/health" "前端健康检查"

# API响应测试
echo ""
echo "📡 API响应测试:"
test_api_response "$API_GATEWAY_URL/health" "API网关"
test_api_response "$API_GATEWAY_URL/api/v1/health" "用户服务API"
test_api_response "$API_GATEWAY_URL/api/v6/health" "项目服务API"

# 数据库连接测试
echo ""
echo "🗄️  数据库连接测试:"
test_database
test_redis
test_consul
test_minio

# WebSocket测试
echo ""
echo "🔌 WebSocket连接测试:"
test_websocket "ws://localhost:8080/ws" "API网关WebSocket"

# 性能测试
echo ""
echo "⚡ 性能测试:"
echo -n "测试API响应时间... "
start_time=$(date +%s%N)
if curl -s --max-time $TIMEOUT "$API_GATEWAY_URL/health" > /dev/null 2>&1; then
    end_time=$(date +%s%N)
    response_time=$(( (end_time - start_time) / 1000000 ))
    if [ $response_time -lt 1000 ]; then
        echo -e "${GREEN}✅ 通过 (${response_time}ms)${NC}"
    else
        echo -e "${YELLOW}⚠️  响应较慢 (${response_time}ms)${NC}"
    fi
else
    echo -e "${RED}❌ 失败${NC}"
fi

# 服务状态检查
echo ""
echo "📊 服务状态检查:"
echo "Docker容器状态:"
docker-compose -f docker-compose.frontend.yml ps

echo ""
echo "🔍 服务健康状态:"
for service in frontend api-gateway user-service project-service model-service inference-service cost-service monitoring-service postgres redis consul minio; do
    if docker-compose -f docker-compose.frontend.yml ps | grep -q "$service.*Up"; then
        echo -e "  $service: ${GREEN}✅ 运行中${NC}"
    else
        echo -e "  $service: ${RED}❌ 未运行${NC}"
    fi
done

# 资源使用情况
echo ""
echo "💾 资源使用情况:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | head -10

# 日志检查
echo ""
echo "📋 错误日志检查:"
error_count=0
for service in frontend api-gateway user-service project-service model-service inference-service cost-service monitoring-service; do
    if docker-compose -f docker-compose.frontend.yml logs --tail=10 "$service" 2>&1 | grep -i "error\|exception\|fatal" > /dev/null; then
        echo -e "  $service: ${RED}❌ 发现错误${NC}"
        error_count=$((error_count + 1))
    else
        echo -e "  $service: ${GREEN}✅ 无错误${NC}"
    fi
done

# 测试总结
echo ""
echo "📈 测试总结:"
echo "=================================="

if [ $error_count -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过！前端后端集成正常${NC}"
    exit 0
else
    echo -e "${RED}❌ 发现 $error_count 个服务有错误，请检查日志${NC}"
    exit 1
fi
