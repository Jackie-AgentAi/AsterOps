#!/bin/bash

# 用户组API测试脚本
# 使用方法: ./test_user_groups.sh

BASE_URL="http://localhost:8081/api/v1"
TOKEN="your-jwt-token-here"

echo "=== 用户组API测试 ==="

# 测试获取用户组列表
echo "1. 获取用户组列表"
curl -X GET "${BASE_URL}/user-groups" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq .

echo -e "\n"

# 测试创建用户组
echo "2. 创建用户组"
curl -X POST "${BASE_URL}/user-groups" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "测试用户组",
    "description": "这是一个测试用户组",
    "organization_id": "",
    "parent_id": "",
    "settings": "{}"
  }' | jq .

echo -e "\n"

# 测试获取用户组详情
echo "3. 获取用户组详情"
GROUP_ID="00000000-0000-0000-0000-000000000001"
curl -X GET "${BASE_URL}/user-groups/${GROUP_ID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq .

echo -e "\n"

# 测试获取用户组成员
echo "4. 获取用户组成员"
curl -X GET "${BASE_URL}/user-groups/${GROUP_ID}/members" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq .

echo -e "\n"

# 测试添加用户组成员
echo "5. 添加用户组成员"
USER_ID="00000000-0000-0000-0000-000000000001"
curl -X POST "${BASE_URL}/user-groups/${GROUP_ID}/members" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "'${USER_ID}'",
    "role": "member"
  }' | jq .

echo -e "\n"

# 测试搜索用户组
echo "6. 搜索用户组"
curl -X GET "${BASE_URL}/user-groups/search?keyword=测试" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq .

echo -e "\n"

echo "=== 测试完成 ==="