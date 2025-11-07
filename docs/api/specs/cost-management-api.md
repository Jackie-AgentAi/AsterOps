# 成本管理API设计

> **模块名称**: cost_management  
> **API版本**: v1.0  
> **更新日期**: 2025-10-17

## 一、模块概述

### 1.1 功能描述

成本管理API提供成本记录、预算管理、计费规则、使用统计、优化建议等核心功能，支持多维度成本分析和智能成本优化。

### 1.2 核心功能

- **成本记录**: 成本记录、统计、分析
- **预算管理**: 预算设置、监控、告警
- **计费规则**: 计费规则、定价策略
- **使用统计**: 使用统计、趋势分析
- **优化建议**: 成本优化建议、智能推荐

## 二、认证授权

### 2.1 认证方式

```http
Authorization: Bearer <jwt_token>
```

### 2.2 权限要求

- **成本查看**: 需要 `cost:read` 权限
- **成本管理**: 需要 `cost:manage` 权限
- **预算管理**: 需要 `cost:budget:manage` 权限
- **计费规则**: 需要 `cost:rule:manage` 权限

## 三、成本记录API

### 3.1 获取成本记录

#### 获取成本记录列表
```http
GET /api/v1/costs/records
```

**查询参数**:
- `page`: 页码 (默认: 1)
- `per_page`: 每页数量 (默认: 20, 最大: 100)
- `start_date`: 开始日期
- `end_date`: 结束日期
- `project_id`: 项目过滤
- `user_id`: 用户过滤
- `model_id`: 模型过滤
- `cost_type`: 成本类型过滤
- `sort`: 排序字段 (默认: created_at:desc)

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "records": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "cost_type": "inference",
        "resource_type": "model",
        "resource_id": 123,
        "resource_name": "gpt-4-chatbot",
        "project_id": 1,
        "project_name": "AI Chatbot Project",
        "user_id": 1,
        "user_name": "john_doe",
        "usage": {
          "input_tokens": 1000,
          "output_tokens": 500,
          "total_tokens": 1500,
          "requests": 10
        },
        "cost": {
          "input_cost": 0.002,
          "output_cost": 0.001,
          "total_cost": 0.003,
          "currency": "USD"
        },
        "pricing": {
          "input_price_per_1k": 0.002,
          "output_price_per_1k": 0.002,
          "model": "gpt-4"
        },
        "metadata": {
          "session_id": "session_123",
          "request_id": "req_456",
          "deployment_id": "deploy_789"
        },
        "created_at": "2025-10-17T16:00:00Z"
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
      "total_cost": 1250.50,
      "total_usage": {
        "input_tokens": 500000,
        "output_tokens": 250000,
        "total_tokens": 750000,
        "requests": 5000
      },
      "cost_by_type": {
        "inference": 1000.00,
        "storage": 150.50,
        "compute": 100.00
      }
    }
  }
}
```

### 3.2 创建成本记录

#### 创建成本记录
```http
POST /api/v1/costs/records
```

**请求体**:
```json
{
  "cost_type": "inference",
  "resource_type": "model",
  "resource_id": 123,
  "project_id": 1,
  "user_id": 1,
  "usage": {
    "input_tokens": 1000,
    "output_tokens": 500,
    "total_tokens": 1500,
    "requests": 10
  },
  "pricing": {
    "input_price_per_1k": 0.002,
    "output_price_per_1k": 0.002,
    "model": "gpt-4"
  },
  "metadata": {
    "session_id": "session_123",
    "request_id": "req_456",
    "deployment_id": "deploy_789"
  }
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Cost record created successfully",
  "data": {
    "record": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "cost_type": "inference",
      "resource_type": "model",
      "resource_id": 123,
      "project_id": 1,
      "user_id": 1,
      "usage": {
        "input_tokens": 1000,
        "output_tokens": 500,
        "total_tokens": 1500,
        "requests": 10
      },
      "cost": {
        "input_cost": 0.002,
        "output_cost": 0.001,
        "total_cost": 0.003,
        "currency": "USD"
      },
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 3.3 获取成本统计

#### 获取成本统计
```http
GET /api/v1/costs/statistics
```

**查询参数**:
- `start_date`: 开始日期
- `end_date`: 结束日期
- `granularity`: 时间粒度 (hour, day, week, month)
- `project_id`: 项目过滤
- `user_id`: 用户过滤
- `model_id`: 模型过滤
- `cost_type`: 成本类型过滤

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "statistics": {
      "total_cost": 1250.50,
      "total_usage": {
        "input_tokens": 500000,
        "output_tokens": 250000,
        "total_tokens": 750000,
        "requests": 5000
      },
      "cost_by_type": {
        "inference": 1000.00,
        "storage": 150.50,
        "compute": 100.00
      },
      "cost_by_project": [
        {
          "project_id": 1,
          "project_name": "AI Chatbot Project",
          "cost": 800.00,
          "percentage": 64.0
        }
      ],
      "cost_by_user": [
        {
          "user_id": 1,
          "user_name": "john_doe",
          "cost": 500.00,
          "percentage": 40.0
        }
      ],
      "cost_by_model": [
        {
          "model_id": 123,
          "model_name": "gpt-4-chatbot",
          "cost": 600.00,
          "percentage": 48.0
        }
      ],
      "trends": [
        {
          "date": "2025-10-17",
          "cost": 50.00,
          "usage": {
            "input_tokens": 20000,
            "output_tokens": 10000,
            "total_tokens": 30000,
            "requests": 200
          }
        }
      ]
    }
  }
}
```

## 四、预算管理API

### 4.1 获取预算列表

#### 获取预算列表
```http
GET /api/v1/costs/budgets
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `project_id`: 项目过滤
- `user_id`: 用户过滤
- `status`: 状态过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "budgets": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "AI Chatbot Project Budget",
        "description": "Monthly budget for AI Chatbot Project",
        "type": "project",
        "scope_id": 1,
        "scope_name": "AI Chatbot Project",
        "amount": 1000.00,
        "currency": "USD",
        "period": "monthly",
        "status": "active",
        "usage": {
          "current": 750.00,
          "percentage": 75.0,
          "remaining": 250.00
        },
        "alerts": {
          "enabled": true,
          "thresholds": [50, 80, 90, 100],
          "notifications": ["email", "slack"]
        },
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

### 4.2 创建预算

#### 创建预算
```http
POST /api/v1/costs/budgets
```

**请求体**:
```json
{
  "name": "AI Chatbot Project Budget",
  "description": "Monthly budget for AI Chatbot Project",
  "type": "project",
  "scope_id": 1,
  "amount": 1000.00,
  "currency": "USD",
  "period": "monthly",
  "alerts": {
    "enabled": true,
    "thresholds": [50, 80, 90, 100],
    "notifications": ["email", "slack"]
  }
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Budget created successfully",
  "data": {
    "budget": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "name": "AI Chatbot Project Budget",
      "description": "Monthly budget for AI Chatbot Project",
      "type": "project",
      "scope_id": 1,
      "amount": 1000.00,
      "currency": "USD",
      "period": "monthly",
      "status": "active",
      "usage": {
        "current": 0.00,
        "percentage": 0.0,
        "remaining": 1000.00
      },
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 4.3 更新预算

#### 更新预算
```http
PUT /api/v1/costs/budgets/{id}
```

**请求体**:
```json
{
  "name": "Updated AI Chatbot Project Budget",
  "description": "Updated monthly budget for AI Chatbot Project",
  "amount": 1500.00,
  "alerts": {
    "enabled": true,
    "thresholds": [60, 80, 90, 100],
    "notifications": ["email", "slack", "webhook"]
  }
}
```

### 4.4 获取预算使用情况

#### 获取预算使用情况
```http
GET /api/v1/costs/budgets/{id}/usage
```

**查询参数**:
- `start_date`: 开始日期
- `end_date`: 结束日期
- `granularity`: 时间粒度

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "usage": {
      "budget_id": 1,
      "budget_name": "AI Chatbot Project Budget",
      "amount": 1000.00,
      "current": 750.00,
      "percentage": 75.0,
      "remaining": 250.00,
      "daily_usage": [
        {
          "date": "2025-10-17",
          "cost": 50.00,
          "percentage": 5.0
        }
      ],
      "cost_by_type": {
        "inference": 600.00,
        "storage": 100.00,
        "compute": 50.00
      },
      "cost_by_user": [
        {
          "user_id": 1,
          "user_name": "john_doe",
          "cost": 400.00,
          "percentage": 53.3
        }
      ],
      "alerts": [
        {
          "type": "threshold_reached",
          "threshold": 80,
          "message": "Budget usage reached 80%",
          "created_at": "2025-10-17T15:00:00Z"
        }
      ]
    }
  }
}
```

## 五、计费规则API

### 5.1 获取计费规则

#### 获取计费规则列表
```http
GET /api/v1/costs/rules
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `resource_type`: 资源类型过滤
- `model_id`: 模型过滤
- `status`: 状态过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "rules": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "GPT-4 Inference Pricing",
        "description": "Pricing rules for GPT-4 inference",
        "resource_type": "model",
        "resource_id": 123,
        "resource_name": "gpt-4-chatbot",
        "pricing_type": "per_token",
        "pricing": {
          "input_price_per_1k": 0.002,
          "output_price_per_1k": 0.002,
          "currency": "USD"
        },
        "conditions": {
          "min_tokens": 1,
          "max_tokens": 1000000,
          "time_window": "1h"
        },
        "status": "active",
        "effective_from": "2025-10-17T00:00:00Z",
        "effective_to": "2025-12-31T23:59:59Z",
        "created_at": "2025-10-17T16:00:00Z",
        "updated_at": "2025-10-17T16:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 5,
      "total_pages": 1,
      "has_next": false,
      "has_prev": false
    }
  }
}
```

### 5.2 创建计费规则

#### 创建计费规则
```http
POST /api/v1/costs/rules
```

**请求体**:
```json
{
  "name": "GPT-4 Turbo Inference Pricing",
  "description": "Pricing rules for GPT-4 Turbo inference",
  "resource_type": "model",
  "resource_id": 124,
  "pricing_type": "per_token",
  "pricing": {
    "input_price_per_1k": 0.001,
    "output_price_per_1k": 0.001,
    "currency": "USD"
  },
  "conditions": {
    "min_tokens": 1,
    "max_tokens": 2000000,
    "time_window": "1h"
  },
  "effective_from": "2025-10-17T00:00:00Z",
  "effective_to": "2025-12-31T23:59:59Z"
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Pricing rule created successfully",
  "data": {
    "rule": {
      "id": 2,
      "uuid": "550e8400-e29b-41d4-a716-446655440001",
      "name": "GPT-4 Turbo Inference Pricing",
      "description": "Pricing rules for GPT-4 Turbo inference",
      "resource_type": "model",
      "resource_id": 124,
      "pricing_type": "per_token",
      "pricing": {
        "input_price_per_1k": 0.001,
        "output_price_per_1k": 0.001,
        "currency": "USD"
      },
      "conditions": {
        "min_tokens": 1,
        "max_tokens": 2000000,
        "time_window": "1h"
      },
      "status": "active",
      "effective_from": "2025-10-17T00:00:00Z",
      "effective_to": "2025-12-31T23:59:59Z",
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 5.3 更新计费规则

#### 更新计费规则
```http
PUT /api/v1/costs/rules/{id}
```

**请求体**:
```json
{
  "name": "Updated GPT-4 Inference Pricing",
  "pricing": {
    "input_price_per_1k": 0.0015,
    "output_price_per_1k": 0.0015,
    "currency": "USD"
  },
  "effective_to": "2026-12-31T23:59:59Z"
}
```

### 5.4 删除计费规则

#### 删除计费规则
```http
DELETE /api/v1/costs/rules/{id}
```

## 六、成本优化API

### 6.1 获取优化建议

#### 获取成本优化建议
```http
GET /api/v1/costs/optimizations
```

**查询参数**:
- `project_id`: 项目过滤
- `user_id`: 用户过滤
- `cost_type`: 成本类型过滤
- `priority`: 优先级过滤 (high, medium, low)
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "optimizations": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "title": "Switch to GPT-3.5 Turbo for Non-Critical Tasks",
        "description": "Consider using GPT-3.5 Turbo for non-critical tasks to reduce costs by 50%",
        "type": "model_optimization",
        "priority": "high",
        "potential_savings": {
          "amount": 200.00,
          "percentage": 50.0,
          "currency": "USD"
        },
        "impact": {
          "performance_impact": "low",
          "quality_impact": "minimal",
          "implementation_effort": "low"
        },
        "recommendations": [
          "Identify non-critical use cases",
          "Implement model routing logic",
          "Monitor quality metrics"
        ],
        "status": "pending",
        "created_at": "2025-10-17T16:00:00Z"
      }
    ],
    "summary": {
      "total_savings": 500.00,
      "high_priority_count": 3,
      "medium_priority_count": 5,
      "low_priority_count": 2
    }
  }
}
```

### 6.2 应用优化建议

#### 应用优化建议
```http
POST /api/v1/costs/optimizations/{id}/apply
```

**请求体**:
```json
{
  "action": "implement",
  "notes": "Implementing model routing for non-critical tasks",
  "expected_savings": 200.00
}
```

**响应**:
```json
{
  "code": 200,
  "message": "Optimization applied successfully",
  "data": {
    "optimization": {
      "id": 1,
      "status": "implemented",
      "applied_at": "2025-10-17T16:00:00Z",
      "expected_savings": 200.00,
      "notes": "Implementing model routing for non-critical tasks"
    }
  }
}
```

### 6.3 获取成本预测

#### 获取成本预测
```http
GET /api/v1/costs/predictions
```

**查询参数**:
- `project_id`: 项目过滤
- `user_id`: 用户过滤
- `period`: 预测周期 (7d, 30d, 90d)
- `model_id`: 模型过滤

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "predictions": {
      "period": "30d",
      "current_cost": 1250.50,
      "predicted_cost": 1500.00,
      "confidence": 0.85,
      "factors": [
        {
          "factor": "usage_growth",
          "impact": 0.15,
          "description": "Expected 15% growth in usage"
        },
        {
          "factor": "model_optimization",
          "impact": -0.10,
          "description": "10% savings from model optimization"
        }
      ],
      "daily_predictions": [
        {
          "date": "2025-10-18",
          "predicted_cost": 50.00,
          "confidence_interval": [45.00, 55.00]
        }
      ]
    }
  }
}
```

## 七、成本分配API

### 7.1 获取成本分配

#### 获取成本分配
```http
GET /api/v1/costs/allocations
```

**查询参数**:
- `start_date`: 开始日期
- `end_date`: 结束日期
- `project_id`: 项目过滤
- `user_id`: 用户过滤
- `allocation_method`: 分配方法 (usage, equal, custom)

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "allocations": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "cost_record_id": 1,
        "allocation_method": "usage",
        "allocations": [
          {
            "project_id": 1,
            "project_name": "AI Chatbot Project",
            "user_id": 1,
            "user_name": "john_doe",
            "allocation_percentage": 60.0,
            "allocation_amount": 0.0018,
            "currency": "USD"
          },
          {
            "project_id": 1,
            "project_name": "AI Chatbot Project",
            "user_id": 2,
            "user_name": "jane_smith",
            "allocation_percentage": 40.0,
            "allocation_amount": 0.0012,
            "currency": "USD"
          }
        ],
        "total_cost": 0.003,
        "created_at": "2025-10-17T16:00:00Z"
      }
    ]
  }
}
```

### 7.2 创建成本分配

#### 创建成本分配
```http
POST /api/v1/costs/allocations
```

**请求体**:
```json
{
  "cost_record_id": 1,
  "allocation_method": "usage",
  "allocations": [
    {
      "project_id": 1,
      "user_id": 1,
      "allocation_percentage": 60.0
    },
    {
      "project_id": 1,
      "user_id": 2,
      "allocation_percentage": 40.0
    }
  ]
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

#### 预算超限错误
```json
{
  "code": 422,
  "message": "Budget exceeded",
  "error": {
    "type": "budget_exceeded",
    "details": "Cost exceeds budget limit",
    "budget_id": 1,
    "budget_limit": 1000.00,
    "current_cost": 1200.00,
    "excess": 200.00
  }
}
```

#### 计费规则冲突错误
```json
{
  "code": 409,
  "message": "Pricing rule conflict",
  "error": {
    "type": "rule_conflict",
    "details": "Conflicting pricing rules found",
    "conflicting_rules": [1, 2],
    "resource_id": 123
  }
}
```

## 九、限流策略

### 9.1 限流规则

- **成本记录查询**: 1000 requests/hour
- **成本记录创建**: 100 requests/hour
- **预算管理**: 100 requests/hour
- **计费规则**: 50 requests/hour
- **优化建议**: 200 requests/hour

### 9.2 限流响应

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1640995200
```

## 十、安全考虑

### 10.1 数据保护

- **敏感数据加密**: 成本数据加密存储
- **访问控制**: 基于角色的成本数据访问控制
- **审计日志**: 完整的成本操作审计记录
- **数据脱敏**: 敏感成本信息脱敏

### 10.2 计算安全

- **计算验证**: 成本计算过程验证
- **数据完整性**: 成本数据完整性检查
- **异常检测**: 异常成本模式检测
- **自动告警**: 异常成本自动告警

---

**文档维护**: 本文档应随API设计变化持续更新，保持与系统架构的一致性。

**版本历史**:
- v1.0 (2025-10-17): 初始版本，成本管理API设计

