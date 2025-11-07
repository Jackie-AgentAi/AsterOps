# 模型管理API设计

> **模块名称**: model_management  
> **API版本**: v1.0  
> **更新日期**: 2025-10-17

## 一、模块概述

### 1.1 功能描述

模型管理API提供模型注册、版本管理、文件管理、部署管理、实例管理等核心功能，支持开源和闭源LLM的统一管理，包括模型生命周期管理、版本控制、部署监控等。

### 1.2 核心功能

- **模型管理**: 模型注册、更新、删除、状态管理
- **版本管理**: 模型版本创建、切换、回滚
- **文件管理**: 模型文件上传、下载、管理
- **部署管理**: 模型部署、配置、监控
- **实例管理**: 部署实例管理、扩缩容
- **指标管理**: 模型性能指标、使用统计
- **标签管理**: 模型标签、分类管理
- **血缘管理**: 模型血缘关系、依赖管理

## 二、认证授权

### 2.1 认证方式

```http
Authorization: Bearer <jwt_token>
```

### 2.2 权限要求

- **模型管理**: 需要 `model:manage` 权限
- **版本管理**: 需要 `model:version:manage` 权限
- **部署管理**: 需要 `model:deploy:manage` 权限
- **文件管理**: 需要 `model:file:manage` 权限

## 三、模型管理API

### 3.1 注册模型

#### 注册新模型
```http
POST /api/v1/models
```

**请求体**:
```json
{
  "name": "GPT-4 Chatbot",
  "code": "gpt-4-chatbot",
  "description": "GPT-4 based chatbot model for customer service",
  "type": "llm",
  "category": "chat",
  "framework": "transformers",
  "base_model": "gpt-4",
  "model_size": "175B",
  "precision": "fp16",
  "tags": ["chatbot", "customer-service", "gpt-4"],
  "metadata": {
    "author": "OpenAI",
    "license": "commercial",
    "language": "en",
    "domain": "general",
    "capabilities": ["text-generation", "conversation", "qa"]
  },
  "settings": {
    "max_tokens": 4096,
    "temperature": 0.7,
    "top_p": 0.9,
    "frequency_penalty": 0.0,
    "presence_penalty": 0.0
  }
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Model registered successfully",
  "data": {
    "model": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "name": "GPT-4 Chatbot",
      "code": "gpt-4-chatbot",
      "description": "GPT-4 based chatbot model for customer service",
      "type": "llm",
      "category": "chat",
      "framework": "transformers",
      "base_model": "gpt-4",
      "model_size": "175B",
      "precision": "fp16",
      "status": "active",
      "tags": ["chatbot", "customer-service", "gpt-4"],
      "metadata": {
        "author": "OpenAI",
        "license": "commercial",
        "language": "en",
        "domain": "general",
        "capabilities": ["text-generation", "conversation", "qa"]
      },
      "settings": {
        "max_tokens": 4096,
        "temperature": 0.7,
        "top_p": 0.9,
        "frequency_penalty": 0.0,
        "presence_penalty": 0.0
      },
      "owner_id": 1,
      "project_id": 1,
      "created_at": "2025-10-17T16:00:00Z",
      "updated_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 3.2 获取模型列表

#### 获取模型列表
```http
GET /api/v1/models
```

**查询参数**:
- `page`: 页码 (默认: 1)
- `per_page`: 每页数量 (默认: 20, 最大: 100)
- `search`: 搜索关键词
- `type`: 模型类型过滤
- `category`: 模型分类过滤
- `framework`: 框架过滤
- `status`: 状态过滤
- `tags`: 标签过滤
- `project_id`: 项目过滤
- `sort`: 排序字段 (默认: created_at:desc)

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "models": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "GPT-4 Chatbot",
        "code": "gpt-4-chatbot",
        "description": "GPT-4 based chatbot model for customer service",
        "type": "llm",
        "category": "chat",
        "framework": "transformers",
        "base_model": "gpt-4",
        "model_size": "175B",
        "status": "active",
        "tags": ["chatbot", "customer-service", "gpt-4"],
        "owner": {
          "id": 1,
          "username": "john_doe",
          "first_name": "John",
          "last_name": "Doe"
        },
        "project": {
          "id": 1,
          "name": "AI Chatbot Project",
          "code": "ai-chatbot"
        },
        "version_count": 3,
        "deployment_count": 2,
        "created_at": "2025-10-17T16:00:00Z",
        "updated_at": "2025-10-17T16:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 50,
      "total_pages": 3,
      "has_next": true,
      "has_prev": false
    }
  }
}
```

### 3.3 获取模型详情

#### 获取模型详情
```http
GET /api/v1/models/{id}
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "model": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "name": "GPT-4 Chatbot",
      "code": "gpt-4-chatbot",
      "description": "GPT-4 based chatbot model for customer service",
      "type": "llm",
      "category": "chat",
      "framework": "transformers",
      "base_model": "gpt-4",
      "model_size": "175B",
      "precision": "fp16",
      "status": "active",
      "tags": ["chatbot", "customer-service", "gpt-4"],
      "metadata": {
        "author": "OpenAI",
        "license": "commercial",
        "language": "en",
        "domain": "general",
        "capabilities": ["text-generation", "conversation", "qa"]
      },
      "settings": {
        "max_tokens": 4096,
        "temperature": 0.7,
        "top_p": 0.9,
        "frequency_penalty": 0.0,
        "presence_penalty": 0.0
      },
      "owner": {
        "id": 1,
        "username": "john_doe",
        "first_name": "John",
        "last_name": "Doe"
      },
      "project": {
        "id": 1,
        "name": "AI Chatbot Project",
        "code": "ai-chatbot"
      },
      "statistics": {
        "version_count": 3,
        "deployment_count": 2,
        "total_requests": 15000,
        "success_rate": 99.5,
        "avg_response_time": 1.2
      },
      "created_at": "2025-10-17T16:00:00Z",
      "updated_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 3.4 更新模型

#### 更新模型信息
```http
PUT /api/v1/models/{id}
```

**请求体**:
```json
{
  "name": "Advanced GPT-4 Chatbot",
  "description": "Advanced GPT-4 based chatbot with enhanced capabilities",
  "tags": ["chatbot", "customer-service", "gpt-4", "advanced"],
  "metadata": {
    "author": "OpenAI",
    "license": "commercial",
    "language": "en",
    "domain": "general",
    "capabilities": ["text-generation", "conversation", "qa", "reasoning"]
  },
  "settings": {
    "max_tokens": 8192,
    "temperature": 0.5,
    "top_p": 0.95,
    "frequency_penalty": 0.1,
    "presence_penalty": 0.1
  }
}
```

### 3.5 模型状态管理

#### 激活模型
```http
POST /api/v1/models/{id}/activate
```

#### 停用模型
```http
POST /api/v1/models/{id}/deactivate
```

#### 删除模型
```http
DELETE /api/v1/models/{id}
```

## 四、模型版本管理API

### 4.1 创建模型版本

#### 创建新版本
```http
POST /api/v1/models/{id}/versions
```

**请求体**:
```json
{
  "version": "v1.2.0",
  "description": "Improved response quality and reduced latency",
  "changelog": [
    "Improved response quality",
    "Reduced average latency by 20%",
    "Added support for longer conversations",
    "Fixed memory leak issues"
  ],
  "model_files": [
    {
      "name": "model.bin",
      "size": 8589934592,
      "checksum": "sha256:abc123...",
      "type": "weights"
    },
    {
      "name": "config.json",
      "size": 1024,
      "checksum": "sha256:def456...",
      "type": "config"
    }
  ],
  "dependencies": [
    {
      "name": "transformers",
      "version": "4.21.0"
    },
    {
      "name": "torch",
      "version": "1.12.0"
    }
  ],
  "metadata": {
    "training_data": "customer_service_v2",
    "training_epochs": 3,
    "validation_score": 0.95,
    "test_score": 0.92
  }
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Model version created successfully",
  "data": {
    "version": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440001",
      "version": "v1.2.0",
      "description": "Improved response quality and reduced latency",
      "changelog": [
        "Improved response quality",
        "Reduced average latency by 20%",
        "Added support for longer conversations",
        "Fixed memory leak issues"
      ],
      "status": "active",
      "is_default": false,
      "model_files": [
        {
          "id": 1,
          "name": "model.bin",
          "size": 8589934592,
          "checksum": "sha256:abc123...",
          "type": "weights",
          "url": "https://storage.example.com/models/1/versions/v1.2.0/model.bin"
        }
      ],
      "dependencies": [
        {
          "name": "transformers",
          "version": "4.21.0"
        }
      ],
      "metadata": {
        "training_data": "customer_service_v2",
        "training_epochs": 3,
        "validation_score": 0.95,
        "test_score": 0.92
      },
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 4.2 获取模型版本列表

#### 获取模型版本列表
```http
GET /api/v1/models/{id}/versions
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `status`: 状态过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "versions": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440001",
        "version": "v1.2.0",
        "description": "Improved response quality and reduced latency",
        "status": "active",
        "is_default": true,
        "file_count": 2,
        "size": 8589934592,
        "created_at": "2025-10-17T16:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 3,
      "total_pages": 1,
      "has_next": false,
      "has_prev": false
    }
  }
}
```

### 4.3 设置默认版本

#### 设置默认版本
```http
POST /api/v1/models/{id}/versions/{version_id}/set-default
```

### 4.4 版本回滚

#### 回滚到指定版本
```http
POST /api/v1/models/{id}/versions/{version_id}/rollback
```

## 五、模型文件管理API

### 5.1 上传模型文件

#### 上传模型文件
```http
POST /api/v1/models/{id}/versions/{version_id}/files
```

**请求体** (multipart/form-data):
```
file: [binary file data]
name: model.bin
type: weights
description: Model weights file
```

**响应**:
```json
{
  "code": 201,
  "message": "File uploaded successfully",
  "data": {
    "file": {
      "id": 1,
      "name": "model.bin",
      "size": 8589934592,
      "checksum": "sha256:abc123...",
      "type": "weights",
      "description": "Model weights file",
      "url": "https://storage.example.com/models/1/versions/v1.2.0/model.bin",
      "uploaded_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 5.2 获取模型文件列表

#### 获取模型文件列表
```http
GET /api/v1/models/{id}/versions/{version_id}/files
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "files": [
      {
        "id": 1,
        "name": "model.bin",
        "size": 8589934592,
        "checksum": "sha256:abc123...",
        "type": "weights",
        "description": "Model weights file",
        "url": "https://storage.example.com/models/1/versions/v1.2.0/model.bin",
        "uploaded_at": "2025-10-17T16:00:00Z"
      }
    ]
  }
}
```

### 5.3 下载模型文件

#### 下载模型文件
```http
GET /api/v1/models/{id}/versions/{version_id}/files/{file_id}/download
```

**响应**: 文件流

### 5.4 删除模型文件

#### 删除模型文件
```http
DELETE /api/v1/models/{id}/versions/{version_id}/files/{file_id}
```

## 六、模型部署管理API

### 6.1 创建模型部署

#### 创建模型部署
```http
POST /api/v1/models/{id}/deployments
```

**请求体**:
```json
{
  "name": "GPT-4 Chatbot Production",
  "version_id": 1,
  "environment": "production",
  "replicas": 3,
  "resources": {
    "cpu_cores": 8,
    "memory_gb": 32,
    "gpu_count": 2,
    "gpu_type": "V100"
  },
  "config": {
    "max_tokens": 4096,
    "temperature": 0.7,
    "top_p": 0.9,
    "timeout": 30,
    "retry_count": 3
  },
  "scaling": {
    "min_replicas": 1,
    "max_replicas": 10,
    "target_cpu": 70,
    "target_memory": 80
  },
  "health_check": {
    "enabled": true,
    "path": "/health",
    "interval": 30,
    "timeout": 10,
    "retries": 3
  }
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Model deployment created successfully",
  "data": {
    "deployment": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440002",
      "name": "GPT-4 Chatbot Production",
      "version_id": 1,
      "environment": "production",
      "status": "deploying",
      "replicas": 3,
      "resources": {
        "cpu_cores": 8,
        "memory_gb": 32,
        "gpu_count": 2,
        "gpu_type": "V100"
      },
      "config": {
        "max_tokens": 4096,
        "temperature": 0.7,
        "top_p": 0.9,
        "timeout": 30,
        "retry_count": 3
      },
      "scaling": {
        "min_replicas": 1,
        "max_replicas": 10,
        "target_cpu": 70,
        "target_memory": 80
      },
      "endpoints": {
        "api": "https://api.example.com/models/gpt-4-chatbot/v1",
        "health": "https://api.example.com/models/gpt-4-chatbot/health"
      },
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 6.2 获取模型部署列表

#### 获取模型部署列表
```http
GET /api/v1/models/{id}/deployments
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `environment`: 环境过滤
- `status`: 状态过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "deployments": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440002",
        "name": "GPT-4 Chatbot Production",
        "version_id": 1,
        "environment": "production",
        "status": "active",
        "replicas": 3,
        "endpoints": {
          "api": "https://api.example.com/models/gpt-4-chatbot/v1",
          "health": "https://api.example.com/models/gpt-4-chatbot/health"
        },
        "created_at": "2025-10-17T16:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 2,
      "total_pages": 1,
      "has_next": false,
      "has_prev": false
    }
  }
}
```

### 6.3 更新模型部署

#### 更新模型部署
```http
PUT /api/v1/models/{id}/deployments/{deployment_id}
```

**请求体**:
```json
{
  "replicas": 5,
  "config": {
    "max_tokens": 8192,
    "temperature": 0.5,
    "top_p": 0.95,
    "timeout": 60,
    "retry_count": 5
  },
  "scaling": {
    "min_replicas": 2,
    "max_replicas": 20,
    "target_cpu": 60,
    "target_memory": 70
  }
}
```

### 6.4 模型部署状态管理

#### 启动部署
```http
POST /api/v1/models/{id}/deployments/{deployment_id}/start
```

#### 停止部署
```http
POST /api/v1/models/{id}/deployments/{deployment_id}/stop
```

#### 重启部署
```http
POST /api/v1/models/{id}/deployments/{deployment_id}/restart
```

#### 删除部署
```http
DELETE /api/v1/models/{id}/deployments/{deployment_id}
```

## 七、模型实例管理API

### 7.1 获取部署实例

#### 获取部署实例列表
```http
GET /api/v1/models/{id}/deployments/{deployment_id}/instances
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "instances": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440003",
        "name": "gpt-4-chatbot-prod-1",
        "status": "running",
        "node": "worker-node-1",
        "ip_address": "10.0.1.100",
        "port": 8080,
        "resources": {
          "cpu_usage": 65.5,
          "memory_usage": 24.8,
          "gpu_usage": 45.2
        },
        "health": {
          "status": "healthy",
          "last_check": "2025-10-17T16:00:00Z",
          "response_time": 1.2
        },
        "created_at": "2025-10-17T16:00:00Z",
        "started_at": "2025-10-17T16:00:00Z"
      }
    ]
  }
}
```

### 7.2 扩缩容部署

#### 扩缩容部署
```http
POST /api/v1/models/{id}/deployments/{deployment_id}/scale
```

**请求体**:
```json
{
  "replicas": 5
}
```

### 7.3 实例操作

#### 重启实例
```http
POST /api/v1/models/{id}/deployments/{deployment_id}/instances/{instance_id}/restart
```

#### 删除实例
```http
DELETE /api/v1/models/{id}/deployments/{deployment_id}/instances/{instance_id}
```

## 八、模型指标管理API

### 8.1 获取模型指标

#### 获取模型指标
```http
GET /api/v1/models/{id}/metrics
```

**查询参数**:
- `start_time`: 开始时间
- `end_time`: 结束时间
- `granularity`: 时间粒度 (1m, 5m, 1h, 1d)
- `metrics`: 指标类型 (performance, usage, cost)

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
      }
    },
    "time_range": {
      "start_time": "2025-10-17T00:00:00Z",
      "end_time": "2025-10-17T23:59:59Z"
    }
  }
}
```

### 8.2 记录模型指标

#### 记录模型指标
```http
POST /api/v1/models/{id}/metrics
```

**请求体**:
```json
{
  "timestamp": "2025-10-17T16:00:00Z",
  "metrics": {
    "response_time": 1.2,
    "tokens_generated": 150,
    "success": true,
    "cost": 0.05
  }
}
```

## 九、模型标签管理API

### 9.1 获取模型标签

#### 获取模型标签
```http
GET /api/v1/models/{id}/tags
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "tags": [
      {
        "id": 1,
        "name": "chatbot",
        "category": "application",
        "color": "#3B82F6",
        "created_at": "2025-10-17T16:00:00Z"
      }
    ]
  }
}
```

### 9.2 添加模型标签

#### 添加模型标签
```http
POST /api/v1/models/{id}/tags
```

**请求体**:
```json
{
  "name": "customer-service",
  "category": "domain",
  "color": "#10B981"
}
```

### 9.3 删除模型标签

#### 删除模型标签
```http
DELETE /api/v1/models/{id}/tags/{tag_id}
```

## 十、模型血缘管理API

### 10.1 获取模型血缘

#### 获取模型血缘关系
```http
GET /api/v1/models/{id}/lineage
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "lineage": {
      "parents": [
        {
          "id": 2,
          "name": "GPT-4 Base",
          "type": "base_model",
          "relationship": "base"
        }
      ],
      "children": [
        {
          "id": 3,
          "name": "GPT-4 Chatbot Fine-tuned",
          "type": "fine_tuned",
          "relationship": "fine_tuned"
        }
      ],
      "datasets": [
        {
          "id": 1,
          "name": "Customer Service Dataset",
          "type": "training_data",
          "relationship": "trained_on"
        }
      ]
    }
  }
}
```

### 10.2 添加血缘关系

#### 添加血缘关系
```http
POST /api/v1/models/{id}/lineage
```

**请求体**:
```json
{
  "related_model_id": 2,
  "relationship": "base",
  "description": "Based on GPT-4 base model"
}
```

## 十一、错误处理

### 11.1 常见错误码

| 错误码 | 错误类型 | 描述 |
|--------|----------|------|
| 400 | Bad Request | 请求参数错误 |
| 401 | Unauthorized | 未授权访问 |
| 403 | Forbidden | 权限不足 |
| 404 | Not Found | 模型不存在 |
| 409 | Conflict | 模型代码已存在 |
| 422 | Validation Error | 参数验证失败 |
| 429 | Rate Limited | 请求频率超限 |
| 500 | Internal Error | 服务器内部错误 |

### 11.2 错误响应示例

#### 模型不存在错误
```json
{
  "code": 404,
  "message": "Model not found",
  "error": {
    "type": "not_found_error",
    "details": "The requested model does not exist",
    "model_id": 999
  }
}
```

#### 部署失败错误
```json
{
  "code": 500,
  "message": "Deployment failed",
  "error": {
    "type": "deployment_error",
    "details": "Failed to deploy model due to insufficient resources",
    "deployment_id": 1,
    "reason": "insufficient_gpu_resources"
  }
}
```

## 十二、限流策略

### 12.1 限流规则

- **模型注册**: 10 requests/hour
- **文件上传**: 5 requests/hour
- **部署操作**: 20 requests/hour
- **一般API**: 1000 requests/hour

### 12.2 限流响应

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1640995200
```

## 十三、安全考虑

### 13.1 数据保护

- **模型文件加密**: 模型文件加密存储
- **访问控制**: 基于角色的模型访问控制
- **审计日志**: 完整的模型操作审计记录
- **版本控制**: 模型版本完整性验证

### 13.2 部署安全

- **资源限制**: 部署资源使用限制
- **网络隔离**: 部署网络隔离
- **健康检查**: 部署健康状态监控
- **自动恢复**: 异常情况自动恢复

---

**文档维护**: 本文档应随API设计变化持续更新，保持与系统架构的一致性。

**版本历史**:
- v1.0 (2025-10-17): 初始版本，模型管理API设计

