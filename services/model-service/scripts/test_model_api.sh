#!/bin/bash

# 模型管理服务API测试脚本
# 使用方法: ./scripts/test_model_api.sh

BASE_URL="http://localhost:8083/api/v1"
TENANT_ID="00000000-0000-0000-0000-000000000001"

echo "=== 模型管理服务API测试 ==="
echo "基础URL: $BASE_URL"
echo "租户ID: $TENANT_ID"
echo ""

# 测试健康检查
echo "1. 测试健康检查..."
curl -s -X GET "$BASE_URL/../health" | jq .
echo ""

# 测试API基础信息
echo "2. 测试API基础信息..."
curl -s -X GET "$BASE_URL/../" | jq .
echo ""

# 测试创建模型
echo "3. 测试创建模型..."
CREATE_MODEL_RESPONSE=$(curl -s -X POST "$BASE_URL/models" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d '{
    "name": "Test Model",
    "description": "Test model for API testing",
    "framework": "pytorch",
    "task_type": "text-classification",
    "is_public": false,
    "tags": ["test", "api"],
    "metadata": {"test": true}
  }')

echo "$CREATE_MODEL_RESPONSE" | jq .

# 提取模型ID
MODEL_ID=$(echo "$CREATE_MODEL_RESPONSE" | jq -r '.id // empty')
if [ -z "$MODEL_ID" ] || [ "$MODEL_ID" = "null" ]; then
    echo "创建模型失败，无法获取模型ID"
    exit 1
fi

echo "模型ID: $MODEL_ID"
echo ""

# 测试获取模型列表
echo "4. 测试获取模型列表..."
curl -s -X GET "$BASE_URL/models?offset=0&limit=10" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试搜索模型
echo "5. 测试搜索模型..."
curl -s -X GET "$BASE_URL/models/search?keyword=test&offset=0&limit=10" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取模型详情
echo "6. 测试获取模型详情..."
curl -s -X GET "$BASE_URL/models/$MODEL_ID" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试更新模型
echo "7. 测试更新模型..."
curl -s -X PUT "$BASE_URL/models/$MODEL_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d '{
    "description": "Updated test model description",
    "tags": ["test", "api", "updated"]
  }' | jq .
echo ""

# 测试创建模型版本
echo "8. 测试创建模型版本..."
CREATE_VERSION_RESPONSE=$(curl -s -X POST "$BASE_URL/models/$MODEL_ID/versions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d '{
    "version": "1.0.0",
    "description": "Initial version",
    "file_path": "/models/test-model-v1.0.0.pt",
    "file_size": 1024000,
    "checksum": "abc123def456",
    "metadata": {"accuracy": 0.95}
  }')

echo "$CREATE_VERSION_RESPONSE" | jq .

# 提取版本ID
VERSION_ID=$(echo "$CREATE_VERSION_RESPONSE" | jq -r '.id // empty')
if [ -n "$VERSION_ID" ] && [ "$VERSION_ID" != "null" ]; then
    echo "版本ID: $VERSION_ID"
    echo ""
fi

# 测试获取模型版本列表
echo "9. 测试获取模型版本列表..."
curl -s -X GET "$BASE_URL/models/$MODEL_ID/versions?offset=0&limit=10" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试创建模型部署
echo "10. 测试创建模型部署..."
CREATE_DEPLOYMENT_RESPONSE=$(curl -s -X POST "$BASE_URL/models/$MODEL_ID/deployments" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d '{
    "model_version_id": "'$VERSION_ID'",
    "name": "Test Deployment",
    "description": "Test deployment for API testing",
    "deployment_type": "kubernetes",
    "replicas": 2,
    "cpu_limit": "1000m",
    "memory_limit": "2Gi",
    "config": {"env": "test"}
  }')

echo "$CREATE_DEPLOYMENT_RESPONSE" | jq .

# 提取部署ID
DEPLOYMENT_ID=$(echo "$CREATE_DEPLOYMENT_RESPONSE" | jq -r '.id // empty')
if [ -n "$DEPLOYMENT_ID" ] && [ "$DEPLOYMENT_ID" != "null" ]; then
    echo "部署ID: $DEPLOYMENT_ID"
    echo ""
fi

# 测试获取模型部署列表
echo "11. 测试获取模型部署列表..."
curl -s -X GET "$BASE_URL/models/$MODEL_ID/deployments?offset=0&limit=10" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试创建模型评测
echo "12. 测试创建模型评测..."
CREATE_EVALUATION_RESPONSE=$(curl -s -X POST "$BASE_URL/models/$MODEL_ID/evaluations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d '{
    "model_version_id": "'$VERSION_ID'",
    "name": "Test Evaluation",
    "description": "Test evaluation for API testing",
    "dataset_id": "test-dataset",
    "evaluation_type": "accuracy",
    "config": {"test_size": 0.2}
  }')

echo "$CREATE_EVALUATION_RESPONSE" | jq .

# 提取评测ID
EVALUATION_ID=$(echo "$CREATE_EVALUATION_RESPONSE" | jq -r '.id // empty')
if [ -n "$EVALUATION_ID" ] && [ "$EVALUATION_ID" != "null" ]; then
    echo "评测ID: $EVALUATION_ID"
    echo ""
fi

# 测试获取模型评测列表
echo "13. 测试获取模型评测列表..."
curl -s -X GET "$BASE_URL/models/$MODEL_ID/evaluations?offset=0&limit=10" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取模型指标
echo "14. 测试获取模型指标..."
curl -s -X GET "$BASE_URL/models/$MODEL_ID/metrics?offset=0&limit=10" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试发布模型
echo "15. 测试发布模型..."
curl -s -X POST "$BASE_URL/models/$MODEL_ID/publish" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试取消发布模型
echo "16. 测试取消发布模型..."
curl -s -X POST "$BASE_URL/models/$MODEL_ID/unpublish" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试删除模型
echo "17. 测试删除模型..."
curl -s -X DELETE "$BASE_URL/models/$MODEL_ID" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

echo "=== 测试完成 ==="



