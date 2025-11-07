#!/bin/bash

# API网关认证集成测试脚本
set -e

echo "🔌 API网关认证集成测试"
echo "======================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_status="$3"
    
    echo -n "测试: $test_name ... "
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    response=$(eval "$test_command" 2>/dev/null || echo "")
    status_code=$(echo "$response" | grep -o '"success":[^,]*' | cut -d: -f2 | tr -d ' ' || echo "false")
    http_status=$(curl -s -w "%{http_code}" -o /dev/null $(echo "$test_command" | sed 's/curl -s/curl -s -w "%{http_code}" -o \/dev\/null/') 2>/dev/null || echo "000")
    
    if [ "$status_code" = "$expected_status" ] || [ "$http_status" = "$expected_status" ]; then
        echo -e "${GREEN}通过${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}失败${NC}"
        echo "  响应: $response"
        echo "  HTTP状态: $http_status"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# 1. 公开API测试
echo "1. 公开API测试"
echo "=============="

run_test "健康检查" "curl -s http://localhost:8087/health" "true"
run_test "服务列表" "curl -s http://localhost:8087/services" "true"
run_test "根路径" "curl -s http://localhost:8087/" "true"

echo ""

# 2. 认证API测试
echo "2. 认证API测试"
echo "=============="

run_test "用户登录" "curl -s -X POST http://localhost:8087/api/v1/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"admin123\"}'" "true"

run_test "用户注册" "curl -s -X POST http://localhost:8087/api/v1/auth/register -H 'Content-Type: application/json' -d '{\"username\":\"testuser\",\"email\":\"test@example.com\",\"password\":\"password123\",\"first_name\":\"Test\",\"last_name\":\"User\",\"tenant_id\":\"550e8400-e29b-41d4-a716-446655440000\"}'" "true"

run_test "令牌刷新" "curl -s -X POST http://localhost:8087/api/v1/auth/refresh -H 'Content-Type: application/json' -d '{\"refresh_token\":\"refresh_token_admin\"}'" "true"

echo ""

# 3. 受保护API测试（无认证）
echo "3. 受保护API测试（无认证）"
echo "========================="

run_test "无认证访问用户列表" "curl -s -w '%{http_code}' -o /dev/null http://localhost:8087/api/v1/users/" "401"
run_test "无认证访问项目管理" "curl -s -w '%{http_code}' -o /dev/null http://localhost:8087/api/v1/projects/" "401"
run_test "无认证访问模型服务" "curl -s -w '%{http_code}' -o /dev/null http://localhost:8087/api/v1/models/" "401"
run_test "无认证访问推理服务" "curl -s -w '%{http_code}' -o /dev/null http://localhost:8087/api/v1/inference/" "401"
run_test "无认证访问成本服务" "curl -s -w '%{http_code}' -o /dev/null http://localhost:8087/api/v1/costs/" "401"
run_test "无认证访问监控服务" "curl -s -w '%{http_code}' -o /dev/null http://localhost:8087/api/v1/monitoring/" "401"

echo ""

# 4. 受保护API测试（有效认证）
echo "4. 受保护API测试（有效认证）"
echo "==========================="

# 获取有效令牌
ACCESS_TOKEN=$(curl -s -X POST http://localhost:8087/api/v1/auth/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123"}' | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

run_test "有效令牌访问用户列表" "curl -s -H 'Authorization: Bearer $ACCESS_TOKEN' http://localhost:8087/api/v1/users/" "true"

run_test "有效令牌访问用户信息" "curl -s -H 'Authorization: Bearer $ACCESS_TOKEN' http://localhost:8087/api/v1/auth/profile" "true"

run_test "有效令牌访问角色列表" "curl -s -H 'Authorization: Bearer $ACCESS_TOKEN' http://localhost:8087/api/v1/roles" "true"

run_test "有效令牌访问权限列表" "curl -s -H 'Authorization: Bearer $ACCESS_TOKEN' http://localhost:8087/api/v1/permissions" "true"

echo ""

# 5. 无效令牌测试
echo "5. 无效令牌测试"
echo "==============="

run_test "无效令牌访问用户列表" "curl -s -w '%{http_code}' -o /dev/null -H 'Authorization: Bearer invalid_token' http://localhost:8087/api/v1/users/" "401"

run_test "错误格式令牌" "curl -s -w '%{http_code}' -o /dev/null -H 'Authorization: InvalidFormat token123' http://localhost:8087/api/v1/users/" "401"

run_test "空令牌" "curl -s -w '%{http_code}' -o /dev/null -H 'Authorization: Bearer ' http://localhost:8087/api/v1/users/" "401"

echo ""

# 6. 用户信息传递测试
echo "6. 用户信息传递测试"
echo "==================="

# 测试用户信息是否正确传递给后端服务
echo "检查用户信息传递..."
USER_RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" http://localhost:8087/api/v1/users/)
if echo "$USER_RESPONSE" | grep -q "testuser"; then
    echo -e "${GREEN}✅ 用户信息传递正常${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}❌ 用户信息传递异常${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""

# 7. CORS测试
echo "7. CORS测试"
echo "==========="

run_test "OPTIONS预检请求" "curl -s -X OPTIONS -H 'Origin: http://localhost:3000' -H 'Access-Control-Request-Method: GET' -H 'Access-Control-Request-Headers: Authorization' -w '%{http_code}' -o /dev/null http://localhost:8087/api/v1/users/" "200"

echo ""

# 8. 性能测试
echo "8. 性能测试"
echo "==========="

echo "测试API网关响应时间..."
start_time=$(date +%s%N)
curl -s -H "Authorization: Bearer $ACCESS_TOKEN" http://localhost:8087/api/v1/users/ > /dev/null
end_time=$(date +%s%N)
response_time=$(( (end_time - start_time) / 1000000 ))
echo -e "${GREEN}✅ API网关响应时间: ${response_time}ms${NC}"

echo ""

# 9. 错误处理测试
echo "9. 错误处理测试"
echo "==============="

run_test "不存在的服务" "curl -s -w '%{http_code}' -o /dev/null http://localhost:8087/api/v1/nonexistent/" "404"

run_test "无效的API路径" "curl -s -w '%{http_code}' -o /dev/null http://localhost:8087/invalid/path" "404"

echo ""

# 测试结果汇总
echo "测试结果汇总"
echo "============"
echo "总测试数: $TOTAL_TESTS"
echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 所有API网关认证测试通过！认证集成运行正常。${NC}"
    exit 0
else
    echo -e "${RED}❌ 有 $FAILED_TESTS 个测试失败，请检查API网关认证集成。${NC}"
    exit 1
fi

