#!/bin/bash

# 认证系统测试脚本
set -e

echo "🔐 LLMOps认证系统测试"
echo "====================="
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
    if echo "$response" | grep -q '"success":true'; then
        status_code="true"
    elif echo "$response" | grep -q '"error":'; then
        status_code="false"
    else
        status_code="false"
    fi
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}通过${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}失败${NC}"
        echo "  响应: $response"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# 1. 用户登录测试
echo "1. 用户登录测试"
echo "==============="

run_test "管理员登录" "curl -s -X POST http://localhost:8081/api/v1/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"admin123\"}'" "true"

run_test "错误密码登录" "curl -s -X POST http://localhost:8081/api/v1/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"wrong\"}'" "false"

run_test "空用户名登录" "curl -s -X POST http://localhost:8081/api/v1/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"\",\"password\":\"admin123\"}'" "false"

echo ""

# 2. 用户注册测试
echo "2. 用户注册测试"
echo "==============="

run_test "新用户注册" "curl -s -X POST http://localhost:8081/api/v1/auth/register -H 'Content-Type: application/json' -d '{\"username\":\"newuser\",\"email\":\"newuser@example.com\",\"password\":\"password123\",\"first_name\":\"New\",\"last_name\":\"User\",\"tenant_id\":\"550e8400-e29b-41d4-a716-446655440000\"}'" "true"

run_test "无效邮箱注册" "curl -s -X POST http://localhost:8081/api/v1/auth/register -H 'Content-Type: application/json' -d '{\"username\":\"testuser2\",\"email\":\"invalid-email\",\"password\":\"password123\",\"first_name\":\"Test\",\"last_name\":\"User\",\"tenant_id\":\"550e8400-e29b-41d4-a716-446655440000\"}'" "false"

run_test "短密码注册" "curl -s -X POST http://localhost:8081/api/v1/auth/register -H 'Content-Type: application/json' -d '{\"username\":\"testuser3\",\"email\":\"test3@example.com\",\"password\":\"123\",\"first_name\":\"Test\",\"last_name\":\"User\",\"tenant_id\":\"550e8400-e29b-41d4-a716-446655440000\"}'" "false"

echo ""

# 3. 令牌刷新测试
echo "3. 令牌刷新测试"
echo "==============="

run_test "有效刷新令牌" "curl -s -X POST http://localhost:8081/api/v1/auth/refresh -H 'Content-Type: application/json' -d '{\"refresh_token\":\"refresh_token_admin\"}'" "true"

run_test "无效刷新令牌" "curl -s -X POST http://localhost:8081/api/v1/auth/refresh -H 'Content-Type: application/json' -d '{\"refresh_token\":\"invalid_refresh_token\"}'" "true"

echo ""

# 4. 认证保护测试
echo "4. 认证保护测试"
echo "==============="

# 获取有效令牌
ACCESS_TOKEN=$(curl -s -X POST http://localhost:8081/api/v1/auth/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123"}' | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

run_test "有效令牌访问用户信息" "curl -s -H 'Authorization: Bearer $ACCESS_TOKEN' http://localhost:8081/api/v1/auth/profile" "true"

run_test "有效令牌访问用户列表" "curl -s -H 'Authorization: Bearer $ACCESS_TOKEN' http://localhost:8081/api/v1/users" "true"

run_test "有效令牌访问角色列表" "curl -s -H 'Authorization: Bearer $ACCESS_TOKEN' http://localhost:8081/api/v1/roles" "true"

run_test "有效令牌访问权限列表" "curl -s -H 'Authorization: Bearer $ACCESS_TOKEN' http://localhost:8081/api/v1/permissions" "true"

echo ""

# 5. 未认证访问测试
echo "5. 未认证访问测试"
echo "================="

run_test "无令牌访问用户信息" "curl -s http://localhost:8081/api/v1/auth/profile" "false"

run_test "无令牌访问用户列表" "curl -s http://localhost:8081/api/v1/users" "false"

run_test "无令牌访问角色列表" "curl -s http://localhost:8081/api/v1/roles" "false"

echo ""

# 6. 无效令牌测试
echo "6. 无效令牌测试"
echo "==============="

run_test "无效令牌访问用户信息" "curl -s -H 'Authorization: Bearer invalid_token' http://localhost:8081/api/v1/auth/profile" "false"

run_test "无效令牌访问用户列表" "curl -s -H 'Authorization: Bearer invalid_token' http://localhost:8081/api/v1/users" "false"

run_test "错误格式令牌" "curl -s -H 'Authorization: InvalidFormat token123' http://localhost:8081/api/v1/users" "false"

echo ""

# 7. 登出测试
echo "7. 登出测试"
echo "==========="

run_test "有效令牌登出" "curl -s -X POST -H 'Authorization: Bearer $ACCESS_TOKEN' http://localhost:8081/api/v1/auth/logout" "true"

echo ""

# 8. API响应格式测试
echo "8. API响应格式测试"
echo "=================="

run_test "登录响应格式" "curl -s -X POST http://localhost:8081/api/v1/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"admin123\"}' | grep -q 'access_token' && echo 'true' || echo 'false'" "true"

run_test "错误响应格式" "curl -s -X POST http://localhost:8081/api/v1/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"wrong\"}' | grep -q 'error' && echo 'true' || echo 'false'" "true"

echo ""

# 测试结果汇总
echo "测试结果汇总"
echo "============"
echo "总测试数: $TOTAL_TESTS"
echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 所有认证测试通过！认证系统运行正常。${NC}"
    exit 0
else
    echo -e "${RED}❌ 有 $FAILED_TESTS 个测试失败，请检查认证系统。${NC}"
    exit 1
fi
