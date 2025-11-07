#!/bin/bash

# 综合测试脚本
set -e

echo "=== LLMOps平台综合测试 ==="
echo "时间: $(date)"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "测试: $test_name ... "
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}通过${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}失败${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# 1. 基础设施测试
echo "1. 基础设施测试"
echo "=================="

run_test "PostgreSQL连接" "docker exec asterops-postgres-1 pg_isready -U user"
run_test "Redis连接" "docker exec asterops-redis-1 redis-cli ping"
run_test "Consul服务发现" "curl -s http://localhost:8500/v1/status/leader"

echo ""

# 2. 微服务健康检查
echo "2. 微服务健康检查"
echo "=================="

run_test "API网关健康检查" "curl -s http://localhost:8087/health"
run_test "用户服务健康检查" "curl -s http://localhost:8081/health"
run_test "项目管理服务健康检查" "curl -s http://localhost:8082/health"
run_test "模型服务健康检查" "curl -s http://localhost:8083/health"
run_test "推理服务健康检查" "curl -s http://localhost:8084/health"
run_test "成本服务健康检查" "curl -s http://localhost:8085/health"
run_test "监控服务健康检查" "curl -s http://localhost:8086/health"

echo ""

# 3. API功能测试
echo "3. API功能测试"
echo "=============="

# 项目管理API测试
run_test "创建项目" "curl -s -X POST http://localhost:8082/api/v1/projects -H 'Content-Type: application/json' -d '{\"name\":\"测试项目\",\"description\":\"API测试项目\",\"owner_id\":\"550e8400-e29b-41d4-a716-446655440000\",\"tenant_id\":\"550e8400-e29b-41d4-a716-446655440000\"}' | grep -q '201'"

run_test "获取项目列表" "curl -s 'http://localhost:8082/api/v1/projects?tenant_id=550e8400-e29b-41d4-a716-446655440000' | grep -q '200'"

# API网关测试
run_test "API网关服务列表" "curl -s http://localhost:8087/services | grep -q 'user-service'"
run_test "API网关代理用户服务" "curl -s http://localhost:8087/api/v1/users/health | grep -q 'user-service'"

echo ""

# 4. 监控服务测试
echo "4. 监控服务测试"
echo "=============="

run_test "Prometheus健康检查" "curl -s http://localhost:9090/-/healthy | grep -q 'Prometheus Server is Healthy'"
run_test "Grafana健康检查" "curl -s http://localhost:3001/api/health | grep -q 'ok'"
run_test "Prometheus指标查询" "curl -s 'http://localhost:9090/api/v1/query?query=up' | grep -q 'success'"

echo ""

# 5. 前端界面测试
echo "5. 前端界面测试"
echo "=============="

run_test "Nginx服务" "curl -s http://localhost/admin/ | grep -q 'LLMOps管理后台'"
run_test "前端静态文件" "curl -s http://localhost/admin/ | grep -q 'app'"

echo ""

# 6. 服务间通信测试
echo "6. 服务间通信测试"
echo "================"

# 通过API网关访问各个服务
run_test "通过网关访问用户服务" "curl -s http://localhost:8087/api/v1/users/health | grep -q 'user-service'"
run_test "通过网关访问项目管理服务" "curl -s http://localhost:8087/api/v1/projects/health | grep -q 'project-service'"

echo ""

# 7. 性能测试
echo "7. 性能测试"
echo "=========="

run_test "响应时间测试" "time curl -s http://localhost:8082/health | grep -q 'ok'"

echo ""

# 8. 安全测试
echo "8. 安全测试"
echo "=========="

run_test "CORS头检查" "curl -s -H 'Origin: http://localhost' http://localhost:8087/health -I | grep -q 'Access-Control-Allow-Origin'"
run_test "OPTIONS请求处理" "curl -s -X OPTIONS http://localhost:8087/health -I | grep -q '200'"

echo ""

# 测试结果汇总
echo "测试结果汇总"
echo "============"
echo "总测试数: $TOTAL_TESTS"
echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}所有测试通过！平台运行正常。${NC}"
    exit 0
else
    echo -e "${RED}有 $FAILED_TESTS 个测试失败，请检查相关服务。${NC}"
    exit 1
fi
