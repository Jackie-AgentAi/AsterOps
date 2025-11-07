# 评测管理API设计

> **模块名称**: evaluation_management  
> **API版本**: v1.0  
> **更新日期**: 2025-10-17

## 一、模块概述

### 1.1 功能描述

评测管理API提供评测任务、测试数据集、评测结果、评测指标、评测报告等核心功能，支持自动化评测和人工评测的协同管理。

### 1.2 核心功能

- **评测任务**: 评测任务创建、执行、管理
- **测试数据集**: 测试数据集管理、版本控制
- **评测结果**: 评测结果、报告生成、分析
- **评测指标**: 评测指标、评分标准、权重配置
- **人工反馈**: 人工评测、反馈收集、质量评估

## 二、认证授权

### 2.1 认证方式

```http
Authorization: Bearer <jwt_token>
```

### 2.2 权限要求

- **评测查看**: 需要 `evaluation:read` 权限
- **评测管理**: 需要 `evaluation:manage` 权限
- **数据集管理**: 需要 `evaluation:dataset:manage` 权限
- **报告生成**: 需要 `evaluation:report:generate` 权限

## 三、评测任务API

### 3.1 获取评测任务

#### 获取评测任务列表
```http
GET /api/v1/evaluation/tasks
```

**查询参数**:
- `page`: 页码 (默认: 1)
- `per_page`: 每页数量 (默认: 20, 最大: 100)
- `status`: 状态过滤 (pending, running, completed, failed, cancelled)
- `model_id`: 模型过滤
- `dataset_id`: 数据集过滤
- `evaluation_type`: 评测类型过滤
- `created_by`: 创建者过滤
- `sort`: 排序字段 (默认: created_at:desc)

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "tasks": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "GPT-4 Chatbot Evaluation",
        "description": "Comprehensive evaluation of GPT-4 chatbot model",
        "status": "completed",
        "evaluation_type": "automated",
        "model_id": 123,
        "model_name": "gpt-4-chatbot",
        "dataset_id": 1,
        "dataset_name": "Customer Service Dataset",
        "metrics": [
          "accuracy",
          "response_time",
          "user_satisfaction",
          "safety_score"
        ],
        "progress": {
          "total_samples": 1000,
          "processed_samples": 1000,
          "percentage": 100.0
        },
        "results": {
          "overall_score": 85.5,
          "accuracy": 92.0,
          "response_time": 1.2,
          "user_satisfaction": 4.2,
          "safety_score": 95.0
        },
        "created_by": 1,
        "created_at": "2025-10-17T16:00:00Z",
        "started_at": "2025-10-17T16:05:00Z",
        "completed_at": "2025-10-17T16:30:00Z"
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

### 3.2 创建评测任务

#### 创建评测任务
```http
POST /api/v1/evaluation/tasks
```

**请求体**:
```json
{
  "name": "GPT-4 Turbo Evaluation",
  "description": "Evaluation of GPT-4 Turbo model performance",
  "evaluation_type": "automated",
  "model_id": 124,
  "dataset_id": 2,
  "metrics": [
    "accuracy",
    "response_time",
    "user_satisfaction",
    "safety_score",
    "factual_accuracy"
  ],
  "config": {
    "max_samples": 500,
    "timeout_per_request": 30,
    "parallel_requests": 10,
    "retry_count": 3,
    "temperature": 0.7,
    "max_tokens": 1000
  },
  "schedule": {
    "type": "immediate",
    "start_time": "2025-10-17T16:00:00Z"
  }
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Evaluation task created successfully",
  "data": {
    "task": {
      "id": 2,
      "uuid": "550e8400-e29b-41d4-a716-446655440001",
      "name": "GPT-4 Turbo Evaluation",
      "description": "Evaluation of GPT-4 Turbo model performance",
      "status": "pending",
      "evaluation_type": "automated",
      "model_id": 124,
      "dataset_id": 2,
      "metrics": [
        "accuracy",
        "response_time",
        "user_satisfaction",
        "safety_score",
        "factual_accuracy"
      ],
      "config": {
        "max_samples": 500,
        "timeout_per_request": 30,
        "parallel_requests": 10,
        "retry_count": 3,
        "temperature": 0.7,
        "max_tokens": 1000
      },
      "created_by": 1,
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 3.3 启动评测任务

#### 启动评测任务
```http
POST /api/v1/evaluation/tasks/{id}/start
```

**响应**:
```json
{
  "code": 200,
  "message": "Evaluation task started successfully",
  "data": {
    "task": {
      "id": 2,
      "status": "running",
      "started_at": "2025-10-17T16:00:00Z",
      "estimated_completion": "2025-10-17T16:15:00Z"
    }
  }
}
```

### 3.4 取消评测任务

#### 取消评测任务
```http
POST /api/v1/evaluation/tasks/{id}/cancel
```

**请求体**:
```json
{
  "reason": "Model configuration changed, need to restart evaluation"
}
```

**响应**:
```json
{
  "code": 200,
  "message": "Evaluation task cancelled successfully",
  "data": {
    "task": {
      "id": 2,
      "status": "cancelled",
      "cancelled_at": "2025-10-17T16:10:00Z",
      "reason": "Model configuration changed, need to restart evaluation"
    }
  }
}
```

### 3.5 获取评测任务详情

#### 获取评测任务详情
```http
GET /api/v1/evaluation/tasks/{id}
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "task": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "name": "GPT-4 Chatbot Evaluation",
      "description": "Comprehensive evaluation of GPT-4 chatbot model",
      "status": "completed",
      "evaluation_type": "automated",
      "model": {
        "id": 123,
        "name": "gpt-4-chatbot",
        "version": "v1.2.0"
      },
      "dataset": {
        "id": 1,
        "name": "Customer Service Dataset",
        "version": "v2.1.0",
        "sample_count": 1000
      },
      "metrics": [
        "accuracy",
        "response_time",
        "user_satisfaction",
        "safety_score"
      ],
      "config": {
        "max_samples": 1000,
        "timeout_per_request": 30,
        "parallel_requests": 5,
        "retry_count": 3,
        "temperature": 0.7,
        "max_tokens": 1000
      },
      "progress": {
        "total_samples": 1000,
        "processed_samples": 1000,
        "percentage": 100.0,
        "current_batch": 0,
        "total_batches": 20
      },
      "results": {
        "overall_score": 85.5,
        "accuracy": 92.0,
        "response_time": 1.2,
        "user_satisfaction": 4.2,
        "safety_score": 95.0,
        "factual_accuracy": 88.0
      },
      "created_by": 1,
      "created_at": "2025-10-17T16:00:00Z",
      "started_at": "2025-10-17T16:05:00Z",
      "completed_at": "2025-10-17T16:30:00Z"
    }
  }
}
```

## 四、测试数据集API

### 4.1 获取测试数据集

#### 获取测试数据集列表
```http
GET /api/v1/evaluation/datasets
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `category`: 分类过滤
- `language`: 语言过滤
- `status`: 状态过滤
- `created_by`: 创建者过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "datasets": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Customer Service Dataset",
        "description": "Customer service conversation dataset for chatbot evaluation",
        "category": "conversation",
        "language": "en",
        "version": "v2.1.0",
        "status": "active",
        "sample_count": 1000,
        "file_size": "25.6MB",
        "tags": ["customer-service", "conversation", "evaluation"],
        "metadata": {
          "domain": "customer_service",
          "difficulty": "medium",
          "source": "internal",
          "created_date": "2025-01-15"
        },
        "created_by": 1,
        "created_at": "2025-10-17T16:00:00Z",
        "updated_at": "2025-10-17T16:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 10,
      "total_pages": 1,
      "has_next": false,
      "has_prev": false
    }
  }
}
```

### 4.2 创建测试数据集

#### 创建测试数据集
```http
POST /api/v1/evaluation/datasets
```

**请求体**:
```json
{
  "name": "Technical Support Dataset",
  "description": "Technical support conversation dataset for model evaluation",
  "category": "conversation",
  "language": "en",
  "tags": ["technical-support", "conversation", "evaluation"],
  "metadata": {
    "domain": "technical_support",
    "difficulty": "high",
    "source": "internal",
    "created_date": "2025-10-17"
  },
  "file": "base64_encoded_file_content"
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Dataset created successfully",
  "data": {
    "dataset": {
      "id": 2,
      "uuid": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Technical Support Dataset",
      "description": "Technical support conversation dataset for model evaluation",
      "category": "conversation",
      "language": "en",
      "version": "v1.0.0",
      "status": "processing",
      "sample_count": 0,
      "file_size": "0MB",
      "tags": ["technical-support", "conversation", "evaluation"],
      "metadata": {
        "domain": "technical_support",
        "difficulty": "high",
        "source": "internal",
        "created_date": "2025-10-17"
      },
      "created_by": 1,
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 4.3 获取数据集样本

#### 获取数据集样本
```http
GET /api/v1/evaluation/datasets/{id}/samples
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `sample_type`: 样本类型过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "samples": [
      {
        "id": 1,
        "input": "How can I reset my password?",
        "expected_output": "To reset your password, please visit the login page and click on 'Forgot Password'. You will receive an email with instructions to reset your password.",
        "context": {
          "category": "password_reset",
          "difficulty": "easy",
          "user_type": "customer"
        },
        "metadata": {
          "source": "customer_service_logs",
          "created_date": "2025-01-15"
        }
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 1000,
      "total_pages": 50,
      "has_next": true,
      "has_prev": false
    }
  }
}
```

## 五、评测结果API

### 5.1 获取评测结果

#### 获取评测结果
```http
GET /api/v1/evaluation/results
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `task_id`: 任务过滤
- `model_id`: 模型过滤
- `dataset_id`: 数据集过滤
- `metric`: 指标过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "results": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "task_id": 1,
        "task_name": "GPT-4 Chatbot Evaluation",
        "model_id": 123,
        "model_name": "gpt-4-chatbot",
        "dataset_id": 1,
        "dataset_name": "Customer Service Dataset",
        "sample_id": 1,
        "input": "How can I reset my password?",
        "expected_output": "To reset your password, please visit the login page and click on 'Forgot Password'.",
        "actual_output": "To reset your password, please visit the login page and click on 'Forgot Password'. You will receive an email with instructions to reset your password.",
        "metrics": {
          "accuracy": 1.0,
          "response_time": 1.2,
          "user_satisfaction": 4.5,
          "safety_score": 95.0,
          "factual_accuracy": 90.0
        },
        "scores": {
          "overall": 92.0,
          "relevance": 95.0,
          "helpfulness": 90.0,
          "safety": 95.0
        },
        "created_at": "2025-10-17T16:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 1000,
      "total_pages": 50,
      "has_next": true,
      "has_prev": false
    },
    "summary": {
      "total_samples": 1000,
      "average_scores": {
        "overall": 85.5,
        "accuracy": 92.0,
        "response_time": 1.2,
        "user_satisfaction": 4.2,
        "safety_score": 95.0
      }
    }
  }
}
```

### 5.2 获取评测报告

#### 获取评测报告
```http
GET /api/v1/evaluation/reports/{task_id}
```

**查询参数**:
- `format`: 报告格式 (json, pdf, html)
- `include_details`: 是否包含详细信息
- `include_samples`: 是否包含样本数据

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "report": {
      "task_id": 1,
      "task_name": "GPT-4 Chatbot Evaluation",
      "model": {
        "id": 123,
        "name": "gpt-4-chatbot",
        "version": "v1.2.0"
      },
      "dataset": {
        "id": 1,
        "name": "Customer Service Dataset",
        "version": "v2.1.0",
        "sample_count": 1000
      },
      "evaluation_summary": {
        "total_samples": 1000,
        "processed_samples": 1000,
        "success_rate": 98.5,
        "average_response_time": 1.2,
        "overall_score": 85.5
      },
      "metrics": {
        "accuracy": {
          "score": 92.0,
          "rank": "excellent",
          "description": "Model shows high accuracy in understanding and responding to queries"
        },
        "response_time": {
          "score": 1.2,
          "rank": "good",
          "description": "Response time is within acceptable limits"
        },
        "user_satisfaction": {
          "score": 4.2,
          "rank": "good",
          "description": "Users are generally satisfied with the responses"
        },
        "safety_score": {
          "score": 95.0,
          "rank": "excellent",
          "description": "Model demonstrates high safety standards"
        }
      },
      "detailed_analysis": {
        "strengths": [
          "High accuracy in understanding user queries",
          "Consistent response quality",
          "Good safety compliance"
        ],
        "weaknesses": [
          "Occasional slow response times",
          "Limited handling of complex technical queries"
        ],
        "recommendations": [
          "Optimize model inference for faster response times",
          "Expand training data for technical support scenarios"
        ]
      },
      "generated_at": "2025-10-17T16:30:00Z"
    }
  }
}
```

## 六、评测指标API

### 6.1 获取评测指标

#### 获取评测指标列表
```http
GET /api/v1/evaluation/metrics
```

**查询参数**:
- `category`: 分类过滤
- `type`: 类型过滤 (automated, manual, hybrid)
- `status`: 状态过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "metrics": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "accuracy",
        "display_name": "Accuracy",
        "description": "Measures the correctness of model responses",
        "category": "quality",
        "type": "automated",
        "unit": "percentage",
        "min_value": 0,
        "max_value": 100,
        "weight": 0.3,
        "calculation_method": "exact_match",
        "status": "active",
        "created_at": "2025-10-17T16:00:00Z"
      },
      {
        "id": 2,
        "uuid": "550e8400-e29b-41d4-a716-446655440001",
        "name": "response_time",
        "display_name": "Response Time",
        "description": "Measures the time taken to generate responses",
        "category": "performance",
        "type": "automated",
        "unit": "seconds",
        "min_value": 0,
        "max_value": 60,
        "weight": 0.2,
        "calculation_method": "average",
        "status": "active",
        "created_at": "2025-10-17T16:00:00Z"
      }
    ]
  }
}
```

### 6.2 创建评测指标

#### 创建评测指标
```http
POST /api/v1/evaluation/metrics
```

**请求体**:
```json
{
  "name": "factual_accuracy",
  "display_name": "Factual Accuracy",
  "description": "Measures the factual correctness of model responses",
  "category": "quality",
  "type": "hybrid",
  "unit": "percentage",
  "min_value": 0,
  "max_value": 100,
  "weight": 0.25,
  "calculation_method": "fact_checking",
  "config": {
    "fact_checking_api": "openai",
    "confidence_threshold": 0.8,
    "max_claims_per_response": 5
  }
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Evaluation metric created successfully",
  "data": {
    "metric": {
      "id": 3,
      "uuid": "550e8400-e29b-41d4-a716-446655440002",
      "name": "factual_accuracy",
      "display_name": "Factual Accuracy",
      "description": "Measures the factual correctness of model responses",
      "category": "quality",
      "type": "hybrid",
      "unit": "percentage",
      "min_value": 0,
      "max_value": 100,
      "weight": 0.25,
      "calculation_method": "fact_checking",
      "config": {
        "fact_checking_api": "openai",
        "confidence_threshold": 0.8,
        "max_claims_per_response": 5
      },
      "status": "active",
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

## 七、人工反馈API

### 7.1 获取人工反馈

#### 获取人工反馈列表
```http
GET /api/v1/evaluation/human-feedback
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `task_id`: 任务过滤
- `evaluator_id`: 评估者过滤
- `status`: 状态过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "feedback": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "task_id": 1,
        "sample_id": 1,
        "evaluator_id": 2,
        "evaluator_name": "jane_smith",
        "scores": {
          "relevance": 4,
          "helpfulness": 5,
          "safety": 5,
          "overall": 4.5
        },
        "comments": "Response is very helpful and addresses the user's question completely. The tone is professional and appropriate.",
        "status": "completed",
        "created_at": "2025-10-17T16:30:00Z",
        "updated_at": "2025-10-17T16:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 100,
      "total_pages": 5,
      "has_next": true,
      "has_prev": false
    }
  }
}
```

### 7.2 提交人工反馈

#### 提交人工反馈
```http
POST /api/v1/evaluation/human-feedback
```

**请求体**:
```json
{
  "task_id": 1,
  "sample_id": 1,
  "evaluator_id": 2,
  "scores": {
    "relevance": 4,
    "helpfulness": 5,
    "safety": 5,
    "overall": 4.5
  },
  "comments": "Response is very helpful and addresses the user's question completely. The tone is professional and appropriate.",
  "metadata": {
    "evaluation_time": 120,
    "confidence": 0.9
  }
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Human feedback submitted successfully",
  "data": {
    "feedback": {
      "id": 2,
      "uuid": "550e8400-e29b-41d4-a716-446655440001",
      "task_id": 1,
      "sample_id": 1,
      "evaluator_id": 2,
      "scores": {
        "relevance": 4,
        "helpfulness": 5,
        "safety": 5,
        "overall": 4.5
      },
      "comments": "Response is very helpful and addresses the user's question completely. The tone is professional and appropriate.",
      "status": "completed",
      "created_at": "2025-10-17T16:30:00Z"
    }
  }
}
```

## 八、错误处理

### 8.1 常见错误码

| 错误码 | 错误类型 | 描述 |
|--------|----------|------|
| 400 | Bad Request | 请求参数错误 |
| 401 | Unauthorized | 未授权访问 |
| 403 | Forbidden | 权限不足 |
| 404 | Not Found | 资源不存在 |
| 409 | Conflict | 资源冲突 |
| 422 | Validation Error | 参数验证失败 |
| 429 | Rate Limited | 请求频率超限 |
| 500 | Internal Error | 服务器内部错误 |

### 8.2 错误响应示例

#### 评测任务冲突错误
```json
{
  "code": 409,
  "message": "Evaluation task conflict",
  "error": {
    "type": "task_conflict",
    "details": "Another evaluation task is already running for this model",
    "conflicting_task_id": 1,
    "model_id": 123
  }
}
```

#### 数据集格式错误
```json
{
  "code": 422,
  "message": "Dataset format error",
  "error": {
    "type": "format_error",
    "details": "Invalid dataset format",
    "field": "file",
    "expected_format": "jsonl",
    "actual_format": "csv"
  }
}
```

## 九、限流策略

### 9.1 限流规则

- **评测任务查询**: 1000 requests/hour
- **评测任务创建**: 10 requests/hour
- **数据集管理**: 100 requests/hour
- **结果查询**: 500 requests/hour
- **报告生成**: 50 requests/hour

### 9.2 限流响应

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1640995200
```

## 十、安全考虑

### 10.1 数据保护

- **敏感数据加密**: 评测数据加密存储
- **访问控制**: 基于角色的评测数据访问控制
- **数据脱敏**: 敏感评测数据脱敏处理
- **审计追踪**: 完整的评测操作审计

### 10.2 评测安全

- **数据完整性**: 评测数据完整性验证
- **结果验证**: 评测结果验证和校验
- **权限控制**: 评测任务权限控制
- **质量保证**: 评测质量保证机制

---

**文档维护**: 本文档应随API设计变化持续更新，保持与系统架构的一致性。

**版本历史**:
- v1.0 (2025-10-17): 初始版本，评测管理API设计

