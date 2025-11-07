#!/bin/bash

# 用户权限服务API测试脚本
# 使用方法: ./scripts/test_user_api.sh

BASE_URL="http://localhost:8081/api/v1"
TENANT_ID="00000000-0000-0000-0000-000000000001"

echo "=== 用户权限服务API测试 ==="
echo "基础URL: $BASE_URL"
echo "租户ID: $TENANT_ID"
echo ""

# 测试健康检查
echo "1. 测试健康检查..."
curl -s -X GET "$BASE_URL/../health" | jq .
echo ""

# 测试API基础信息
echo "2. 测试API基础信息..."
curl -s -X GET "$BASE_URL/" | jq .
echo ""

# 测试用户注册
echo "3. 测试用户注册..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User",
    "tenant_id": "'$TENANT_ID'"
  }')

echo "$REGISTER_RESPONSE" | jq .

# 测试用户登录
echo "4. 测试用户登录..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123",
    "tenant_id": "'$TENANT_ID'"
  }')

echo "$LOGIN_RESPONSE" | jq .

# 提取token
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.token // empty')
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "登录失败，无法获取token"
    exit 1
fi

echo "Token: $TOKEN"
echo ""

# 测试获取用户列表
echo "5. 测试获取用户列表..."
curl -s -X GET "$BASE_URL/users?tenant_id=$TENANT_ID&offset=0&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# 测试搜索用户
echo "6. 测试搜索用户..."
curl -s -X GET "$BASE_URL/users/search?tenant_id=$TENANT_ID&keyword=test&offset=0&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# 测试获取用户详情
echo "7. 测试获取用户详情..."
USER_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.data.user.id // empty')
if [ -n "$USER_ID" ] && [ "$USER_ID" != "null" ]; then
    curl -s -X GET "$BASE_URL/users/$USER_ID" \
      -H "Authorization: Bearer $TOKEN" | jq .
    echo ""
fi

# 测试更新用户
echo "8. 测试更新用户..."
if [ -n "$USER_ID" ] && [ "$USER_ID" != "null" ]; then
    curl -s -X PUT "$BASE_URL/users/$USER_ID" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN" \
      -d '{
        "name": "Updated Test User",
        "email": "updated@example.com"
      }' | jq .
    echo ""
fi

# 测试修改密码
echo "9. 测试修改密码..."
curl -s -X POST "$BASE_URL/auth/change-password" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "user_id": "'$USER_ID'",
    "old_password": "password123",
    "new_password": "newpassword123"
  }' | jq .
echo ""

# 测试刷新token
echo "10. 测试刷新token..."
REFRESH_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.refresh_token // empty')
if [ -n "$REFRESH_TOKEN" ] && [ "$REFRESH_TOKEN" != "null" ]; then
    curl -s -X POST "$BASE_URL/auth/refresh" \
      -H "Content-Type: application/json" \
      -d '{
        "refresh_token": "'$REFRESH_TOKEN'"
      }' | jq .
    echo ""
fi

# 测试获取用户角色
echo "11. 测试获取用户角色..."
if [ -n "$USER_ID" ] && [ "$USER_ID" != "null" ]; then
    curl -s -X GET "$BASE_URL/users/$USER_ID/roles" \
      -H "Authorization: Bearer $TOKEN" | jq .
    echo ""
fi

# 测试分配角色
echo "12. 测试分配角色..."
curl -s -X POST "$BASE_URL/users/roles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "user_id": "'$USER_ID'",
    "role_id": "00000000-0000-0000-0000-000000000003",
    "tenant_id": "'$TENANT_ID'"
  }' | jq .
echo ""

# 测试忘记密码
echo "13. 测试忘记密码..."
curl -s -X POST "$BASE_URL/auth/forgot-password" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "tenant_id": "'$TENANT_ID'"
  }' | jq .
echo ""

# 测试用户登出
echo "14. 测试用户登出..."
curl -s -X POST "$BASE_URL/auth/logout" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# 测试删除用户
echo "15. 测试删除用户..."
if [ -n "$USER_ID" ] && [ "$USER_ID" != "null" ]; then
    curl -s -X DELETE "$BASE_URL/users/$USER_ID" \
      -H "Authorization: Bearer $TOKEN" | jq .
    echo ""
fi

echo "=== 测试完成 ==="



