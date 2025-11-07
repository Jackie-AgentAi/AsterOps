#!/bin/bash

# API调试脚本
# 使用方法: ./debug_api.sh

echo "=== API调试脚本 ==="

# 检查服务是否运行
echo "1. 检查服务状态"
curl -s http://localhost:8081/health | jq . || echo "服务未运行"

echo -e "\n"

# 检查API根路径
echo "2. 检查API根路径"
curl -s http://localhost:8081/api/v1/ | jq . || echo "API根路径不可访问"

echo -e "\n"

# 检查用户统计API
echo "3. 检查用户统计API"
curl -s http://localhost:8081/api/v1/users/stats | jq . || echo "用户统计API不可访问"

echo -e "\n"

# 检查用户列表API
echo "4. 检查用户列表API"
curl -s http://localhost:8081/api/v1/users | jq . || echo "用户列表API不可访问"

echo -e "\n"

# 检查用户组API
echo "5. 检查用户组API"
curl -s http://localhost:8081/api/v1/user-groups | jq . || echo "用户组API不可访问"

echo -e "\n"

echo "=== 调试完成 ==="