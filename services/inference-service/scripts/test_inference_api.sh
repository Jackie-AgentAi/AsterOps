#!/bin/bash

# 推理服务API测试脚本
# 使用方法: ./scripts/test_inference_api.sh

BASE_URL="http://localhost:8084/api/v1"
TENANT_ID="00000000-0000-0000-0000-000000000001"
MODEL_ID="00000000-0000-0000-0000-000000000001"

echo "=== 推理服务API测试 ==="
echo "基础URL: $BASE_URL"
echo "租户ID: $TENANT_ID"
echo "模型ID: $MODEL_ID"
echo ""

# 测试健康检查
echo "1. 测试健康检查..."
curl -s -X GET "$BASE_URL/../health" | jq .
echo ""

# 测试API基础信息
echo "2. 测试API基础信息..."
curl -s -X GET "$BASE_URL/../" | jq .
echo ""

# 测试获取模型列表
echo "3. 测试获取模型列表..."
curl -s -X GET "$BASE_URL/models?offset=0&limit=10" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取模型信息
echo "4. 测试获取模型信息..."
curl -s -X GET "$BASE_URL/models/$MODEL_ID/info" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试加载模型
echo "5. 测试加载模型..."
LOAD_RESPONSE=$(curl -s -X POST "$BASE_URL/models/$MODEL_ID/load" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d '{
    "model_id": "'$MODEL_ID'",
    "model_path": "/models/gpt-3.5-turbo",
    "engine_type": "vllm",
    "config": {
      "max_tokens": 4096,
      "temperature": 0.7,
      "top_p": 0.9
    }
  }')

echo "$LOAD_RESPONSE" | jq .

# 提取实例ID
INSTANCE_ID=$(echo "$LOAD_RESPONSE" | jq -r '.instance_id // empty')
if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "null" ]; then
    echo "实例ID: $INSTANCE_ID"
    echo ""
fi

# 测试获取模型实例列表
echo "6. 测试获取模型实例列表..."
curl -s -X GET "$BASE_URL/models/$MODEL_ID/instances" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取模型实例详情
echo "7. 测试获取模型实例详情..."
curl -s -X GET "$BASE_URL/models/$MODEL_ID/instances/$INSTANCE_ID" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试推理请求
echo "8. 测试推理请求..."
INFERENCE_RESPONSE=$(curl -s -X POST "$BASE_URL/inference/$MODEL_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d '{
    "model_id": "'$MODEL_ID'",
    "request_data": {
      "prompt": "Hello, how are you?",
      "max_tokens": 100,
      "temperature": 0.7
    },
    "config": {
      "stream": false
    }
  }')

echo "$INFERENCE_RESPONSE" | jq .

# 提取请求ID
REQUEST_ID=$(echo "$INFERENCE_RESPONSE" | jq -r '.request_id // empty')
if [ -n "$REQUEST_ID" ] && [ "$REQUEST_ID" != "null" ]; then
    echo "请求ID: $REQUEST_ID"
    echo ""
fi

# 测试批量推理
echo "9. 测试批量推理..."
curl -s -X POST "$BASE_URL/inference/$MODEL_ID/batch" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d '{
    "requests": [
      {
        "model_id": "'$MODEL_ID'",
        "request_data": {
          "prompt": "What is AI?",
          "max_tokens": 50
        }
      },
      {
        "model_id": "'$MODEL_ID'",
        "request_data": {
          "prompt": "Explain machine learning",
          "max_tokens": 50
        }
      }
    ],
    "batch_config": {
      "max_batch_size": 2
    }
  }' | jq .
echo ""

# 测试获取推理状态
echo "10. 测试获取推理状态..."
curl -s -X GET "$BASE_URL/inference/$MODEL_ID/status" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取推理请求列表
echo "11. 测试获取推理请求列表..."
curl -s -X GET "$BASE_URL/inference/$MODEL_ID/requests?offset=0&limit=10" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取推理请求详情
echo "12. 测试获取推理请求详情..."
curl -s -X GET "$BASE_URL/inference/$MODEL_ID/requests/$REQUEST_ID" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试创建推理会话
echo "13. 测试创建推理会话..."
SESSION_RESPONSE=$(curl -s -X POST "$BASE_URL/inference/$MODEL_ID/sessions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d '{
    "session_name": "Test Session",
    "session_type": "chat",
    "config": {
      "max_tokens": 1000,
      "temperature": 0.7
    },
    "context": {
      "system_message": "You are a helpful assistant."
    }
  }')

echo "$SESSION_RESPONSE" | jq .

# 提取会话ID
SESSION_ID=$(echo "$SESSION_RESPONSE" | jq -r '.id // empty')
if [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "null" ]; then
    echo "会话ID: $SESSION_ID"
    echo ""
fi

# 测试获取推理会话列表
echo "14. 测试获取推理会话列表..."
curl -s -X GET "$BASE_URL/inference/$MODEL_ID/sessions?offset=0&limit=10" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取指标
echo "15. 测试获取指标..."
curl -s -X GET "$BASE_URL/metrics" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取模型指标
echo "16. 测试获取模型指标..."
curl -s -X GET "$BASE_URL/metrics/$MODEL_ID?offset=0&limit=10" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取健康指标
echo "17. 测试获取健康指标..."
curl -s -X GET "$BASE_URL/metrics/health" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取性能指标
echo "18. 测试获取性能指标..."
curl -s -X GET "$BASE_URL/metrics/performance?model_id=$MODEL_ID" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取GPU指标
echo "19. 测试获取GPU指标..."
curl -s -X GET "$BASE_URL/metrics/gpu" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取内存指标
echo "20. 测试获取内存指标..."
curl -s -X GET "$BASE_URL/metrics/memory" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取请求指标
echo "21. 测试获取请求指标..."
curl -s -X GET "$BASE_URL/metrics/requests?model_id=$MODEL_ID" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取错误指标
echo "22. 测试获取错误指标..."
curl -s -X GET "$BASE_URL/metrics/errors?model_id=$MODEL_ID" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取模型实例日志
echo "23. 测试获取模型实例日志..."
curl -s -X GET "$BASE_URL/models/$MODEL_ID/instances/$INSTANCE_ID/logs?lines=50" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试获取模型实例指标
echo "24. 测试获取模型实例指标..."
curl -s -X GET "$BASE_URL/models/$MODEL_ID/instances/$INSTANCE_ID/metrics" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试重启模型实例
echo "25. 测试重启模型实例..."
curl -s -X POST "$BASE_URL/models/$MODEL_ID/instances/$INSTANCE_ID/restart" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试扩缩容模型实例
echo "26. 测试扩缩容模型实例..."
curl -s -X POST "$BASE_URL/models/$MODEL_ID/instances/$INSTANCE_ID/scale?replicas=2" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试取消推理请求
echo "27. 测试取消推理请求..."
curl -s -X DELETE "$BASE_URL/inference/$MODEL_ID/requests/$REQUEST_ID" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试删除推理会话
echo "28. 测试删除推理会话..."
curl -s -X DELETE "$BASE_URL/inference/$MODEL_ID/sessions/$SESSION_ID" \
  -H "Authorization: Bearer test-token" | jq .
echo ""

# 测试卸载模型
echo "29. 测试卸载模型..."
curl -s -X POST "$BASE_URL/models/$MODEL_ID/unload" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d '{
    "model_id": "'$MODEL_ID'",
    "instance_id": "'$INSTANCE_ID'",
    "force": false
  }' | jq .
echo ""

echo "=== 测试完成 ==="



