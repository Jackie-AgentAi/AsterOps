#!/bin/bash

# 用户统计API测试脚本
# 使用方法: ./test_user_stats.sh

BASE_URL="http://localhost:8081/api/v1"

echo "=== 用户统计API测试 ==="

# 测试获取用户统计
echo "1. 获取用户统计"
curl -X GET "${BASE_URL}/users/stats" \
  -H "Content-Type: application/json" \
  -v

echo -e "\n"

# 测试获取用户列表
echo "2. 获取用户列表"
curl -X GET "${BASE_URL}/users" \
  -H "Content-Type: application/json" \
  -v

echo -e "\n"

# 测试获取用户组列表
echo "3. 获取用户组列表"
curl -X GET "${BASE_URL}/user-groups" \
  -H "Content-Type: application/json" \
  -v

echo -e "\n"

echo "=== 测试完成 ==="