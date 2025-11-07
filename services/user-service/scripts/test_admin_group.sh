#!/bin/bash

# 测试admin用户组功能脚本
# 创建时间: 2025-01-17
# 描述: 测试admin用户是否在admin用户组中

echo "=== 测试Admin用户组功能 ==="

# 设置API基础URL
API_BASE="http://localhost:8080/api/v1"

# 测试admin用户登录
echo "1. 测试admin用户登录..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }')

echo "登录响应: $LOGIN_RESPONSE"

# 提取token
TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.token // .token // empty')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ 登录失败，无法获取token"
  exit 1
fi

echo "✅ 登录成功，token: ${TOKEN:0:20}..."

# 测试获取admin用户组信息
echo "2. 测试获取admin用户组信息..."
GROUP_INFO_RESPONSE=$(curl -s -X GET "$API_BASE/admin/group-info" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "用户组信息响应: $GROUP_INFO_RESPONSE"

# 测试确保admin在admin组中
echo "3. 测试确保admin在admin组中..."
ENSURE_RESPONSE=$(curl -s -X POST "$API_BASE/admin/ensure" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "确保响应: $ENSURE_RESPONSE"

# 测试获取用户组列表
echo "4. 测试获取用户组列表..."
GROUPS_RESPONSE=$(curl -s -X GET "$API_BASE/user-groups/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "用户组列表响应: $GROUPS_RESPONSE"

# 测试获取admin用户组详情
echo "5. 测试获取admin用户组详情..."
ADMIN_GROUP_ID="00000000-0000-0000-0000-000000000002"
GROUP_DETAIL_RESPONSE=$(curl -s -X GET "$API_BASE/user-groups/$ADMIN_GROUP_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "Admin用户组详情响应: $GROUP_DETAIL_RESPONSE"

# 测试获取admin用户组成员
echo "6. 测试获取admin用户组成员..."
MEMBERS_RESPONSE=$(curl -s -X GET "$API_BASE/user-groups/$ADMIN_GROUP_ID/members" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "Admin用户组成员响应: $MEMBERS_RESPONSE"

echo "=== 测试完成 ==="
