# 监控日志API设计

> **模块名称**: monitoring_logging  
> **API版本**: v1.0  
> **更新日期**: 2025-10-17

## 一、模块概述

### 1.1 功能描述

监控日志API提供监控指标、告警规则、告警事件、系统日志、审计日志等核心功能，支持全维度系统监控和智能告警。

### 1.2 核心功能

- **监控指标**: 系统指标、性能监控、业务指标
- **告警规则**: 告警规则、通知配置、告警策略
- **告警事件**: 告警事件、处理记录、状态管理
- **系统日志**: 系统日志、应用日志、错误日志
- **审计日志**: 审计日志、操作记录、安全审计

## 二、认证授权

### 2.1 认证方式

```http
Authorization: Bearer <jwt_token>
```

### 2.2 权限要求

- **监控查看**: 需要 `monitoring:read` 权限
- **告警管理**: 需要 `monitoring:alert:manage` 权限
- **日志查看**: 需要 `monitoring:log:read` 权限
- **配置管理**: 需要 `monitoring:config:manage` 权限

## 三、监控指标API

### 3.1 获取监控指标

#### 获取监控指标
```http
GET /api/v1/monitoring/metrics
```

**查询参数**:
- `start_time`: 开始时间
- `end_time`: 结束时间
- `granularity`: 时间粒度 (1m, 5m, 1h, 1d)
- `metric_type`: 指标类型 (system, application, business)
- `resource_type`: 资源类型 (server, service, model, user)
- `resource_id`: 资源ID
- `aggregation`: 聚合方式 (avg, sum, max, min, count)

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "metrics": [
      {
        "id": 1,
        "name": "cpu_usage",
        "type": "system",
        "resource_type": "server",
        "resource_id": "server-1",
        "resource_name": "Web Server 1",
        "value": 65.5,
        "unit": "percent",
        "timestamp": "2025-10-17T16:00:00Z",
        "tags": {
          "environment": "production",
          "region": "us-east-1",
          "instance_type": "t3.large"
        }
      },
      {
        "id": 2,
        "name": "response_time",
        "type": "application",
        "resource_type": "service",
        "resource_id": "inference-service",
        "resource_name": "Inference Service",
        "value": 1.2,
        "unit": "seconds",
        "timestamp": "2025-10-17T16:00:00Z",
        "tags": {
          "endpoint": "/api/v1/inference/chat",
          "method": "POST",
          "status_code": "200"
        }
      }
    ],
    "aggregated": {
      "cpu_usage": {
        "avg": 65.5,
        "max": 85.2,
        "min": 45.1,
        "sum": 1310.0,
        "count": 20
      },
      "response_time": {
        "avg": 1.2,
        "max": 3.5,
        "min": 0.8,
        "sum": 24.0,
        "count": 20
      }
    },
    "time_range": {
      "start_time": "2025-10-17T15:00:00Z",
      "end_time": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 3.2 记录监控指标

#### 记录监控指标
```http
POST /api/v1/monitoring/metrics
```

**请求体**:
```json
{
  "metrics": [
    {
      "name": "cpu_usage",
      "type": "system",
      "resource_type": "server",
      "resource_id": "server-1",
      "value": 65.5,
      "unit": "percent",
      "timestamp": "2025-10-17T16:00:00Z",
      "tags": {
        "environment": "production",
        "region": "us-east-1"
      }
    },
    {
      "name": "memory_usage",
      "type": "system",
      "resource_type": "server",
      "resource_id": "server-1",
      "value": 78.2,
      "unit": "percent",
      "timestamp": "2025-10-17T16:00:00Z",
      "tags": {
        "environment": "production",
        "region": "us-east-1"
      }
    }
  ]
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Metrics recorded successfully",
  "data": {
    "recorded_count": 2,
    "timestamp": "2025-10-17T16:00:00Z"
  }
}
```

### 3.3 获取指标定义

#### 获取指标定义
```http
GET /api/v1/monitoring/metrics/definitions
```

**查询参数**:
- `metric_type`: 指标类型过滤
- `resource_type`: 资源类型过滤
- `status`: 状态过滤

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "definitions": [
      {
        "id": 1,
        "name": "cpu_usage",
        "display_name": "CPU Usage",
        "description": "CPU utilization percentage",
        "type": "system",
        "unit": "percent",
        "data_type": "float",
        "min_value": 0,
        "max_value": 100,
        "aggregation_methods": ["avg", "max", "min", "sum"],
        "retention_days": 30,
        "status": "active",
        "created_at": "2025-10-17T16:00:00Z"
      }
    ]
  }
}
```

## 四、告警规则API

### 4.1 获取告警规则

#### 获取告警规则列表
```http
GET /api/v1/monitoring/alerts/rules
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `status`: 状态过滤
- `severity`: 严重程度过滤
- `resource_type`: 资源类型过滤
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
        "name": "High CPU Usage",
        "description": "Alert when CPU usage exceeds 80%",
        "metric_name": "cpu_usage",
        "condition": "cpu_usage > 80",
        "threshold": 80.0,
        "operator": ">",
        "duration": "5m",
        "severity": "warning",
        "resource_type": "server",
        "resource_filter": {
          "environment": "production"
        },
        "status": "active",
        "notifications": [
          {
            "type": "email",
            "recipients": ["admin@example.com"],
            "template": "high_cpu_usage"
          },
          {
            "type": "slack",
            "channel": "#alerts",
            "template": "high_cpu_usage"
          }
        ],
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

### 4.2 创建告警规则

#### 创建告警规则
```http
POST /api/v1/monitoring/alerts/rules
```

**请求体**:
```json
{
  "name": "High Response Time",
  "description": "Alert when response time exceeds 5 seconds",
  "metric_name": "response_time",
  "condition": "response_time > 5",
  "threshold": 5.0,
  "operator": ">",
  "duration": "10m",
  "severity": "critical",
  "resource_type": "service",
  "resource_filter": {
    "service_name": "inference-service"
  },
  "notifications": [
    {
      "type": "email",
      "recipients": ["admin@example.com", "ops@example.com"],
      "template": "high_response_time"
    },
    {
      "type": "webhook",
      "url": "https://hooks.example.com/alerts",
      "template": "high_response_time"
    }
  ]
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Alert rule created successfully",
  "data": {
    "rule": {
      "id": 2,
      "uuid": "550e8400-e29b-41d4-a716-446655440001",
      "name": "High Response Time",
      "description": "Alert when response time exceeds 5 seconds",
      "metric_name": "response_time",
      "condition": "response_time > 5",
      "threshold": 5.0,
      "operator": ">",
      "duration": "10m",
      "severity": "critical",
      "resource_type": "service",
      "resource_filter": {
        "service_name": "inference-service"
      },
      "status": "active",
      "notifications": [
        {
          "type": "email",
          "recipients": ["admin@example.com", "ops@example.com"],
          "template": "high_response_time"
        }
      ],
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 4.3 更新告警规则

#### 更新告警规则
```http
PUT /api/v1/monitoring/alerts/rules/{id}
```

**请求体**:
```json
{
  "name": "Updated High Response Time",
  "description": "Alert when response time exceeds 3 seconds",
  "threshold": 3.0,
  "duration": "5m",
  "notifications": [
    {
      "type": "email",
      "recipients": ["admin@example.com", "ops@example.com", "dev@example.com"],
      "template": "high_response_time"
    }
  ]
}
```

### 4.4 删除告警规则

#### 删除告警规则
```http
DELETE /api/v1/monitoring/alerts/rules/{id}
```

## 五、告警事件API

### 5.1 获取告警事件

#### 获取告警事件列表
```http
GET /api/v1/monitoring/alerts/events
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `status`: 状态过滤 (active, resolved, acknowledged)
- `severity`: 严重程度过滤
- `rule_id`: 规则过滤
- `resource_type`: 资源类型过滤
- `start_time`: 开始时间
- `end_time`: 结束时间
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "events": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "rule_id": 1,
        "rule_name": "High CPU Usage",
        "status": "active",
        "severity": "warning",
        "resource_type": "server",
        "resource_id": "server-1",
        "resource_name": "Web Server 1",
        "metric_value": 85.2,
        "threshold": 80.0,
        "message": "CPU usage is 85.2%, exceeding threshold of 80%",
        "started_at": "2025-10-17T15:30:00Z",
        "last_updated": "2025-10-17T16:00:00Z",
        "resolved_at": null,
        "acknowledged_by": null,
        "acknowledged_at": null,
        "notifications_sent": [
          {
            "type": "email",
            "recipient": "admin@example.com",
            "sent_at": "2025-10-17T15:30:00Z",
            "status": "delivered"
          }
        ]
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 5,
      "total_pages": 1,
      "has_next": false,
      "has_prev": false
    },
    "summary": {
      "active_count": 3,
      "resolved_count": 2,
      "acknowledged_count": 1,
      "critical_count": 1,
      "warning_count": 2
    }
  }
}
```

### 5.2 确认告警事件

#### 确认告警事件
```http
POST /api/v1/monitoring/alerts/events/{id}/acknowledge
```

**请求体**:
```json
{
  "message": "Investigating the issue",
  "assigned_to": "john_doe"
}
```

**响应**:
```json
{
  "code": 200,
  "message": "Alert event acknowledged successfully",
  "data": {
    "event": {
      "id": 1,
      "status": "acknowledged",
      "acknowledged_by": "john_doe",
      "acknowledged_at": "2025-10-17T16:00:00Z",
      "message": "Investigating the issue"
    }
  }
}
```

### 5.3 解决告警事件

#### 解决告警事件
```http
POST /api/v1/monitoring/alerts/events/{id}/resolve
```

**请求体**:
```json
{
  "message": "Issue resolved by scaling up the server",
  "resolution_notes": "Increased server capacity from t3.large to t3.xlarge"
}
```

**响应**:
```json
{
  "code": 200,
  "message": "Alert event resolved successfully",
  "data": {
    "event": {
      "id": 1,
      "status": "resolved",
      "resolved_at": "2025-10-17T16:00:00Z",
      "message": "Issue resolved by scaling up the server",
      "resolution_notes": "Increased server capacity from t3.large to t3.xlarge"
    }
  }
}
```

## 六、系统日志API

### 6.1 获取系统日志

#### 获取系统日志
```http
GET /api/v1/monitoring/logs
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `start_time`: 开始时间
- `end_time`: 结束时间
- `level`: 日志级别 (debug, info, warn, error, fatal)
- `service`: 服务过滤
- `component`: 组件过滤
- `user_id`: 用户过滤
- `request_id`: 请求ID过滤
- `search`: 搜索关键词
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "logs": [
      {
        "id": 1,
        "timestamp": "2025-10-17T16:00:00Z",
        "level": "info",
        "service": "inference-service",
        "component": "api",
        "message": "Request processed successfully",
        "request_id": "req_123456",
        "user_id": 1,
        "session_id": "session_789",
        "duration": 1.2,
        "status_code": 200,
        "tags": {
          "endpoint": "/api/v1/inference/chat",
          "method": "POST",
          "ip_address": "192.168.1.100"
        },
        "context": {
          "model": "gpt-4-chatbot",
          "tokens": 150,
          "cost": 0.003
        }
      },
      {
        "id": 2,
        "timestamp": "2025-10-17T15:59:30Z",
        "level": "error",
        "service": "inference-service",
        "component": "model",
        "message": "Model inference failed",
        "request_id": "req_123455",
        "user_id": 1,
        "session_id": "session_789",
        "duration": 0.0,
        "status_code": 500,
        "error": {
          "type": "ModelInferenceError",
          "message": "CUDA out of memory",
          "stack_trace": "Traceback (most recent call last)..."
        },
        "tags": {
          "endpoint": "/api/v1/inference/chat",
          "method": "POST",
          "ip_address": "192.168.1.100"
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
    },
    "summary": {
      "total_logs": 1000,
      "error_count": 50,
      "warning_count": 100,
      "info_count": 800,
      "debug_count": 50
    }
  }
}
```

### 6.2 记录系统日志

#### 记录系统日志
```http
POST /api/v1/monitoring/logs
```

**请求体**:
```json
{
  "level": "info",
  "service": "inference-service",
  "component": "api",
  "message": "User authentication successful",
  "request_id": "req_123456",
  "user_id": 1,
  "tags": {
    "endpoint": "/api/v1/users/login",
    "method": "POST",
    "ip_address": "192.168.1.100"
  },
  "context": {
    "user_agent": "Mozilla/5.0...",
    "login_method": "password"
  }
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Log recorded successfully",
  "data": {
    "log_id": 1001,
    "timestamp": "2025-10-17T16:00:00Z"
  }
}
```

## 七、审计日志API

### 7.1 获取审计日志

#### 获取审计日志
```http
GET /api/v1/monitoring/audit
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `start_time`: 开始时间
- `end_time`: 结束时间
- `action`: 操作类型过滤
- `resource_type`: 资源类型过滤
- `user_id`: 用户过滤
- `ip_address`: IP地址过滤
- `status`: 状态过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "audit_logs": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "timestamp": "2025-10-17T16:00:00Z",
        "action": "user_login",
        "resource_type": "user",
        "resource_id": 1,
        "resource_name": "john_doe",
        "user_id": 1,
        "user_name": "john_doe",
        "ip_address": "192.168.1.100",
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "status": "success",
        "details": {
          "login_method": "password",
          "session_id": "session_123",
          "mfa_used": false
        },
        "changes": null,
        "metadata": {
          "request_id": "req_123456",
          "duration": 0.5
        }
      },
      {
        "id": 2,
        "uuid": "550e8400-e29b-41d4-a716-446655440001",
        "timestamp": "2025-10-17T15:59:30Z",
        "action": "model_update",
        "resource_type": "model",
        "resource_id": 123,
        "resource_name": "gpt-4-chatbot",
        "user_id": 1,
        "user_name": "john_doe",
        "ip_address": "192.168.1.100",
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "status": "success",
        "details": {
          "field": "description",
          "old_value": "GPT-4 based chatbot",
          "new_value": "Updated GPT-4 based chatbot with enhanced capabilities"
        },
        "changes": {
          "description": {
            "old": "GPT-4 based chatbot",
            "new": "Updated GPT-4 based chatbot with enhanced capabilities"
          }
        },
        "metadata": {
          "request_id": "req_123455",
          "duration": 0.8
        }
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 500,
      "total_pages": 25,
      "has_next": true,
      "has_prev": false
    },
    "summary": {
      "total_actions": 500,
      "success_count": 450,
      "failure_count": 50,
      "action_types": {
        "user_login": 100,
        "model_update": 50,
        "project_create": 25,
        "inference_request": 325
      }
    }
  }
}
```

### 7.2 记录审计日志

#### 记录审计日志
```http
POST /api/v1/monitoring/audit
```

**请求体**:
```json
{
  "action": "user_logout",
  "resource_type": "user",
  "resource_id": 1,
  "user_id": 1,
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
  "status": "success",
  "details": {
    "session_id": "session_123",
    "logout_method": "manual"
  },
  "metadata": {
    "request_id": "req_123457",
    "duration": 0.2
  }
}
```

## 八、监控配置API

### 8.1 获取监控配置

#### 获取监控配置
```http
GET /api/v1/monitoring/configs
```

**查询参数**:
- `config_type`: 配置类型过滤
- `status`: 状态过滤

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "configs": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "System Monitoring Config",
        "type": "system",
        "status": "active",
        "settings": {
          "metrics_retention_days": 30,
          "log_retention_days": 90,
          "audit_retention_days": 365,
          "alert_cooldown_minutes": 15,
          "max_alert_frequency": 10
        },
        "created_at": "2025-10-17T16:00:00Z",
        "updated_at": "2025-10-17T16:00:00Z"
      }
    ]
  }
}
```

### 8.2 更新监控配置

#### 更新监控配置
```http
PUT /api/v1/monitoring/configs/{id}
```

**请求体**:
```json
{
  "name": "Updated System Monitoring Config",
  "settings": {
    "metrics_retention_days": 60,
    "log_retention_days": 180,
    "audit_retention_days": 730,
    "alert_cooldown_minutes": 30,
    "max_alert_frequency": 5
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
| 404 | Not Found | 资源不存在 |
| 409 | Conflict | 资源冲突 |
| 422 | Validation Error | 参数验证失败 |
| 429 | Rate Limited | 请求频率超限 |
| 500 | Internal Error | 服务器内部错误 |

### 9.2 错误响应示例

#### 告警规则冲突错误
```json
{
  "code": 409,
  "message": "Alert rule conflict",
  "error": {
    "type": "rule_conflict",
    "details": "Conflicting alert rules found",
    "conflicting_rules": [1, 2],
    "metric_name": "cpu_usage"
  }
}
```

#### 日志查询超限错误
```json
{
  "code": 429,
  "message": "Query limit exceeded",
  "error": {
    "type": "query_limit_exceeded",
    "details": "Log query exceeds maximum time range",
    "max_range": "7d",
    "requested_range": "30d"
  }
}
```

## 十、限流策略

### 10.1 限流规则

- **指标查询**: 1000 requests/hour
- **指标记录**: 10000 requests/hour
- **告警管理**: 100 requests/hour
- **日志查询**: 500 requests/hour
- **日志记录**: 5000 requests/hour
- **审计日志**: 200 requests/hour

### 10.2 限流响应

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1640995200
```

## 十一、安全考虑

### 11.1 数据保护

- **敏感数据加密**: 日志数据加密存储
- **访问控制**: 基于角色的监控数据访问控制
- **数据脱敏**: 敏感信息脱敏处理
- **审计追踪**: 完整的监控操作审计

### 11.2 监控安全

- **异常检测**: 异常监控行为检测
- **告警验证**: 告警规则验证和测试
- **日志完整性**: 日志数据完整性保护
- **访问审计**: 监控数据访问审计

---

**文档维护**: 本文档应随API设计变化持续更新，保持与系统架构的一致性。

**版本历史**:
- v1.0 (2025-10-17): 初始版本，监控日志API设计

