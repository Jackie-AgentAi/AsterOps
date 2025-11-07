# 推理服务API设计

> **模块名称**: inference_service  
> **API版本**: v1.0  
> **更新日期**: 2025-10-17

## 一、模块概述

### 1.1 功能描述

推理服务API提供模型推理、批量推理、流式推理、服务配置、缓存管理等核心功能，支持多种推理模式和高性能推理服务。

### 1.2 核心功能

- **推理请求**: 单次推理、批量推理、流式推理
- **服务配置**: 推理参数配置、模型选择
- **缓存管理**: 推理结果缓存、缓存策略
- **负载均衡**: 智能路由、负载分发
- **监控告警**: 推理性能监控、异常告警
- **配额管理**: 推理配额限制、使用统计

## 二、认证授权

### 2.1 认证方式

```http
Authorization: Bearer <jwt_token>
```

### 2.2 权限要求

- **推理服务**: 需要 `inference:use` 权限
- **服务配置**: 需要 `inference:config:manage` 权限
- **缓存管理**: 需要 `inference:cache:manage` 权限

## 三、推理请求API

### 3.1 单次推理

#### 发送推理请求
```http
POST /api/v1/inference/chat
```

**请求体**:
```json
{
  "model": "gpt-4-chatbot",
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful AI assistant for customer service."
    },
    {
      "role": "user",
      "content": "How can I help you today?"
    }
  ],
  "parameters": {
    "max_tokens": 1000,
    "temperature": 0.7,
    "top_p": 0.9,
    "frequency_penalty": 0.0,
    "presence_penalty": 0.0,
    "stop": ["\n\n"]
  },
  "stream": false,
  "user": "user_123",
  "session_id": "session_456",
  "request_id": "req_789"
}
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "chatcmpl-123",
    "object": "chat.completion",
    "created": 1677652288,
    "model": "gpt-4-chatbot",
    "choices": [
      {
        "index": 0,
        "message": {
          "role": "assistant",
          "content": "Hello! I'm here to help you with any questions or issues you might have. What can I assist you with today?"
        },
        "finish_reason": "stop"
      }
    ],
    "usage": {
      "prompt_tokens": 25,
      "completion_tokens": 35,
      "total_tokens": 60
    },
    "cost": {
      "input_cost": 0.0005,
      "output_cost": 0.0015,
      "total_cost": 0.002
    },
    "metadata": {
      "request_id": "req_789",
      "session_id": "session_456",
      "user": "user_123",
      "response_time": 1.2,
      "model_version": "v1.2.0",
      "deployment_id": "deploy_123"
    }
  }
}
```

### 3.2 批量推理

#### 发送批量推理请求
```http
POST /api/v1/inference/batch
```

**请求体**:
```json
{
  "model": "gpt-4-chatbot",
  "requests": [
    {
      "id": "batch_1",
      "messages": [
        {
          "role": "user",
          "content": "What is the weather like today?"
        }
      ],
      "parameters": {
        "max_tokens": 100,
        "temperature": 0.7
      }
    },
    {
      "id": "batch_2",
      "messages": [
        {
          "role": "user",
          "content": "Tell me a joke."
        }
      ],
      "parameters": {
        "max_tokens": 200,
        "temperature": 0.9
      }
    }
  ],
  "user": "user_123",
  "request_id": "batch_req_456"
}
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "batch_123",
    "object": "batch.completion",
    "created": 1677652288,
    "model": "gpt-4-chatbot",
    "results": [
      {
        "id": "batch_1",
        "choices": [
          {
            "index": 0,
            "message": {
              "role": "assistant",
              "content": "I don't have access to real-time weather data. Please check a weather service or app for current conditions."
            },
            "finish_reason": "stop"
          }
        ],
        "usage": {
          "prompt_tokens": 10,
          "completion_tokens": 25,
          "total_tokens": 35
        },
        "cost": {
          "input_cost": 0.0002,
          "output_cost": 0.001,
          "total_cost": 0.0012
        }
      },
      {
        "id": "batch_2",
        "choices": [
          {
            "index": 0,
            "message": {
              "role": "assistant",
              "content": "Why don't scientists trust atoms? Because they make up everything!"
            },
            "finish_reason": "stop"
          }
        ],
        "usage": {
          "prompt_tokens": 8,
          "completion_tokens": 20,
          "total_tokens": 28
        },
        "cost": {
          "input_cost": 0.00016,
          "output_cost": 0.0008,
          "total_cost": 0.00096
        }
      }
    ],
    "total_usage": {
      "prompt_tokens": 18,
      "completion_tokens": 45,
      "total_tokens": 63
    },
    "total_cost": {
      "input_cost": 0.00036,
      "output_cost": 0.0018,
      "total_cost": 0.00216
    },
    "metadata": {
      "request_id": "batch_req_456",
      "user": "user_123",
      "response_time": 2.5,
      "model_version": "v1.2.0",
      "deployment_id": "deploy_123"
    }
  }
}
```

### 3.3 流式推理

#### 发送流式推理请求
```http
POST /api/v1/inference/stream
```

**请求体**:
```json
{
  "model": "gpt-4-chatbot",
  "messages": [
    {
      "role": "user",
      "content": "Write a short story about a robot learning to paint."
    }
  ],
  "parameters": {
    "max_tokens": 500,
    "temperature": 0.8,
    "stream": true
  },
  "user": "user_123",
  "session_id": "session_456",
  "request_id": "stream_req_789"
}
```

**响应** (Server-Sent Events):
```
data: {"id": "chatcmpl-123", "object": "chat.completion.chunk", "created": 1677652288, "model": "gpt-4-chatbot", "choices": [{"index": 0, "delta": {"role": "assistant", "content": "Once"}, "finish_reason": null}]}

data: {"id": "chatcmpl-123", "object": "chat.completion.chunk", "created": 1677652288, "model": "gpt-4-chatbot", "choices": [{"index": 0, "delta": {"content": " upon"}, "finish_reason": null}]}

data: {"id": "chatcmpl-123", "object": "chat.completion.chunk", "created": 1677652288, "model": "gpt-4-chatbot", "choices": [{"index": 0, "delta": {"content": " a time"}, "finish_reason": null}]}

data: {"id": "chatcmpl-123", "object": "chat.completion.chunk", "created": 1677652288, "model": "gpt-4-chatbot", "choices": [{"index": 0, "delta": {"content": null}, "finish_reason": "stop"}]}

data: [DONE]
```

## 四、服务配置API

### 4.1 获取推理配置

#### 获取推理服务配置
```http
GET /api/v1/inference/configs
```

**查询参数**:
- `model`: 模型过滤
- `environment`: 环境过滤

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "configs": [
      {
        "id": 1,
        "model": "gpt-4-chatbot",
        "environment": "production",
        "default_parameters": {
          "max_tokens": 1000,
          "temperature": 0.7,
          "top_p": 0.9,
          "frequency_penalty": 0.0,
          "presence_penalty": 0.0
        },
        "limits": {
          "max_tokens": 4096,
          "max_requests_per_minute": 60,
          "max_requests_per_hour": 1000,
          "max_concurrent_requests": 10
        },
        "timeout": 30,
        "retry_count": 3,
        "fallback_model": "gpt-3.5-turbo",
        "cache_enabled": true,
        "cache_ttl": 3600,
        "created_at": "2025-10-17T16:00:00Z",
        "updated_at": "2025-10-17T16:00:00Z"
      }
    ]
  }
}
```

### 4.2 创建推理配置

#### 创建推理服务配置
```http
POST /api/v1/inference/configs
```

**请求体**:
```json
{
  "model": "gpt-4-chatbot",
  "environment": "staging",
  "default_parameters": {
    "max_tokens": 2000,
    "temperature": 0.5,
    "top_p": 0.95,
    "frequency_penalty": 0.1,
    "presence_penalty": 0.1
  },
  "limits": {
    "max_tokens": 8192,
    "max_requests_per_minute": 30,
    "max_requests_per_hour": 500,
    "max_concurrent_requests": 5
  },
  "timeout": 60,
  "retry_count": 5,
  "fallback_model": "gpt-3.5-turbo",
  "cache_enabled": true,
  "cache_ttl": 1800
}
```

### 4.3 更新推理配置

#### 更新推理服务配置
```http
PUT /api/v1/inference/configs/{id}
```

**请求体**:
```json
{
  "default_parameters": {
    "max_tokens": 1500,
    "temperature": 0.6,
    "top_p": 0.9,
    "frequency_penalty": 0.05,
    "presence_penalty": 0.05
  },
  "limits": {
    "max_tokens": 4096,
    "max_requests_per_minute": 45,
    "max_requests_per_hour": 750,
    "max_concurrent_requests": 8
  },
  "timeout": 45,
  "retry_count": 4
}
```

### 4.4 删除推理配置

#### 删除推理服务配置
```http
DELETE /api/v1/inference/configs/{id}
```

## 五、缓存管理API

### 5.1 获取缓存状态

#### 获取缓存状态
```http
GET /api/v1/inference/cache/status
```

**查询参数**:
- `model`: 模型过滤
- `user`: 用户过滤

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "cache_status": {
      "enabled": true,
      "total_entries": 15000,
      "hit_rate": 0.75,
      "miss_rate": 0.25,
      "memory_usage": "2.5GB",
      "disk_usage": "15.2GB",
      "ttl": 3600,
      "models": [
        {
          "model": "gpt-4-chatbot",
          "entries": 5000,
          "hit_rate": 0.80,
          "memory_usage": "800MB"
        }
      ]
    }
  }
}
```

### 5.2 清除缓存

#### 清除指定缓存
```http
DELETE /api/v1/inference/cache
```

**请求体**:
```json
{
  "model": "gpt-4-chatbot",
  "user": "user_123",
  "pattern": "session_456*",
  "clear_all": false
}
```

**响应**:
```json
{
  "code": 200,
  "message": "Cache cleared successfully",
  "data": {
    "cleared_entries": 150,
    "cleared_size": "25MB"
  }
}
```

### 5.3 预热缓存

#### 预热缓存
```http
POST /api/v1/inference/cache/warmup
```

**请求体**:
```json
{
  "model": "gpt-4-chatbot",
  "requests": [
    {
      "messages": [
        {
          "role": "user",
          "content": "Hello, how are you?"
        }
      ],
      "parameters": {
        "max_tokens": 100,
        "temperature": 0.7
      }
    }
  ]
}
```

## 六、负载均衡API

### 6.1 获取负载状态

#### 获取负载均衡状态
```http
GET /api/v1/inference/load-balancer/status
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "load_balancer": {
      "algorithm": "round_robin",
      "health_check_enabled": true,
      "health_check_interval": 30,
      "instances": [
        {
          "id": "instance_1",
          "endpoint": "https://api1.example.com",
          "status": "healthy",
          "weight": 1,
          "current_connections": 25,
          "max_connections": 100,
          "response_time": 1.2,
          "last_health_check": "2025-10-17T16:00:00Z"
        },
        {
          "id": "instance_2",
          "endpoint": "https://api2.example.com",
          "status": "healthy",
          "weight": 1,
          "current_connections": 30,
          "max_connections": 100,
          "response_time": 1.1,
          "last_health_check": "2025-10-17T16:00:00Z"
        }
      ],
      "total_instances": 2,
      "healthy_instances": 2,
      "total_connections": 55,
      "max_connections": 200
    }
  }
}
```

### 6.2 更新负载均衡配置

#### 更新负载均衡配置
```http
PUT /api/v1/inference/load-balancer/config
```

**请求体**:
```json
{
  "algorithm": "least_connections",
  "health_check_enabled": true,
  "health_check_interval": 15,
  "health_check_timeout": 10,
  "health_check_retries": 3,
  "instance_weights": [
    {
      "instance_id": "instance_1",
      "weight": 2
    },
    {
      "instance_id": "instance_2",
      "weight": 1
    }
  ]
}
```

## 七、监控告警API

### 7.1 获取推理指标

#### 获取推理服务指标
```http
GET /api/v1/inference/metrics
```

**查询参数**:
- `start_time`: 开始时间
- `end_time`: 结束时间
- `granularity`: 时间粒度 (1m, 5m, 1h, 1d)
- `model`: 模型过滤
- `user`: 用户过滤

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "metrics": {
      "performance": {
        "response_time": {
          "avg": 1.2,
          "p50": 1.0,
          "p95": 2.5,
          "p99": 4.0,
          "max": 8.0
        },
        "throughput": {
          "requests_per_second": 150.5,
          "tokens_per_second": 1200.0
        },
        "success_rate": 99.5,
        "error_rate": 0.5
      },
      "usage": {
        "total_requests": 15000,
        "total_tokens": 1200000,
        "unique_users": 250,
        "active_sessions": 45
      },
      "cost": {
        "total_cost": 1250.50,
        "cost_per_request": 0.083,
        "cost_per_token": 0.001
      },
      "cache": {
        "hit_rate": 0.75,
        "miss_rate": 0.25,
        "total_hits": 11250,
        "total_misses": 3750
      }
    },
    "time_range": {
      "start_time": "2025-10-17T00:00:00Z",
      "end_time": "2025-10-17T23:59:59Z"
    }
  }
}
```

### 7.2 获取告警规则

#### 获取告警规则
```http
GET /api/v1/inference/alerts/rules
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "rules": [
      {
        "id": 1,
        "name": "High Response Time",
        "description": "Alert when response time exceeds threshold",
        "condition": "response_time > 5.0",
        "threshold": 5.0,
        "duration": "5m",
        "severity": "warning",
        "enabled": true,
        "notifications": [
          {
            "type": "email",
            "recipients": ["admin@example.com"]
          },
          {
            "type": "webhook",
            "url": "https://hooks.example.com/alerts"
          }
        ],
        "created_at": "2025-10-17T16:00:00Z"
      }
    ]
  }
}
```

### 7.3 创建告警规则

#### 创建告警规则
```http
POST /api/v1/inference/alerts/rules
```

**请求体**:
```json
{
  "name": "High Error Rate",
  "description": "Alert when error rate exceeds threshold",
  "condition": "error_rate > 0.05",
  "threshold": 0.05,
  "duration": "10m",
  "severity": "critical",
  "enabled": true,
  "notifications": [
    {
      "type": "email",
      "recipients": ["admin@example.com", "ops@example.com"]
    },
    {
      "type": "slack",
      "channel": "#alerts"
    }
  ]
}
```

## 八、配额管理API

### 8.1 获取推理配额

#### 获取推理配额
```http
GET /api/v1/inference/quotas
```

**查询参数**:
- `user`: 用户过滤
- `model`: 模型过滤

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "quotas": {
      "user": "user_123",
      "model": "gpt-4-chatbot",
      "limits": {
        "requests_per_minute": 60,
        "requests_per_hour": 1000,
        "requests_per_day": 10000,
        "tokens_per_minute": 60000,
        "tokens_per_hour": 1000000,
        "tokens_per_day": 10000000,
        "cost_per_day": 100.00
      },
      "usage": {
        "requests_per_minute": 25,
        "requests_per_hour": 450,
        "requests_per_day": 2500,
        "tokens_per_minute": 15000,
        "tokens_per_hour": 250000,
        "tokens_per_day": 1500000,
        "cost_per_day": 25.50
      },
      "remaining": {
        "requests_per_minute": 35,
        "requests_per_hour": 550,
        "requests_per_day": 7500,
        "tokens_per_minute": 45000,
        "tokens_per_hour": 750000,
        "tokens_per_day": 8500000,
        "cost_per_day": 74.50
      },
      "reset_times": {
        "minute": "2025-10-17T16:01:00Z",
        "hour": "2025-10-17T17:00:00Z",
        "day": "2025-10-18T00:00:00Z"
      }
    }
  }
}
```

### 8.2 更新推理配额

#### 更新推理配额
```http
PUT /api/v1/inference/quotas
```

**请求体**:
```json
{
  "user": "user_123",
  "model": "gpt-4-chatbot",
  "limits": {
    "requests_per_minute": 120,
    "requests_per_hour": 2000,
    "requests_per_day": 20000,
    "tokens_per_minute": 120000,
    "tokens_per_hour": 2000000,
    "tokens_per_day": 20000000,
    "cost_per_day": 200.00
  }
}
```

## 九、错误处理

### 9.1 常见错误码

| 错误码 | 错误类型 | 描述 |
|--------|----------|------|
| 400 | Bad Request | 请求参数错误 |
| 401 | Unauthorized | 未授权访问 |
| 403 | Forbidden | 权限不足 |
| 404 | Not Found | 模型不存在 |
| 408 | Timeout | 请求超时 |
| 422 | Validation Error | 参数验证失败 |
| 429 | Rate Limited | 请求频率超限 |
| 500 | Internal Error | 服务器内部错误 |
| 503 | Service Unavailable | 服务不可用 |

### 9.2 错误响应示例

#### 请求超时错误
```json
{
  "code": 408,
  "message": "Request timeout",
  "error": {
    "type": "timeout_error",
    "details": "The request exceeded the maximum timeout of 30 seconds",
    "timeout": 30,
    "request_id": "req_789"
  }
}
```

#### 配额超限错误
```json
{
  "code": 429,
  "message": "Quota exceeded",
  "error": {
    "type": "quota_error",
    "details": "Request rate limit exceeded",
    "limit": 60,
    "current": 61,
    "reset_time": "2025-10-17T16:01:00Z",
    "request_id": "req_789"
  }
}
```

#### 服务不可用错误
```json
{
  "code": 503,
  "message": "Service unavailable",
  "error": {
    "type": "service_error",
    "details": "All model instances are currently unavailable",
    "model": "gpt-4-chatbot",
    "retry_after": 30,
    "request_id": "req_789"
  }
}
```

## 十、限流策略

### 10.1 限流规则

- **推理请求**: 1000 requests/hour
- **批量推理**: 100 requests/hour
- **流式推理**: 500 requests/hour
- **配置管理**: 100 requests/hour
- **缓存管理**: 50 requests/hour

### 10.2 限流响应

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1640995200
Retry-After: 3600
```

## 十一、安全考虑

### 11.1 请求安全

- **输入验证**: 严格的输入参数验证
- **内容过滤**: 有害内容检测和过滤
- **速率限制**: 防止滥用和攻击
- **请求签名**: 重要请求签名验证

### 11.2 响应安全

- **输出过滤**: 敏感信息过滤
- **内容审核**: 输出内容安全审核
- **访问控制**: 基于用户的访问控制
- **审计日志**: 完整的请求响应日志

### 11.3 服务安全

- **负载保护**: 防止服务过载
- **故障隔离**: 故障实例自动隔离
- **健康检查**: 定期健康状态检查
- **自动恢复**: 异常情况自动恢复

---

**文档维护**: 本文档应随API设计变化持续更新，保持与系统架构的一致性。

**版本历史**:
- v1.0 (2025-10-17): 初始版本，推理服务API设计

