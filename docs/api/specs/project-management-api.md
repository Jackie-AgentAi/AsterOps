# 项目管理API设计

> **模块名称**: project_management  
> **API版本**: v1.0  
> **更新日期**: 2025-10-17

## 一、模块概述

### 1.1 功能描述

项目管理API提供项目创建、配置、成员管理、资源分配、配额管理等核心功能，支持多租户架构下的项目生命周期管理。

### 1.2 核心功能

- **项目管理**: 项目创建、更新、删除、状态管理
- **成员管理**: 项目成员添加、移除、角色分配
- **配置管理**: 项目配置、环境变量、参数设置
- **资源管理**: 项目资源分配、使用监控
- **配额管理**: 项目配额设置、使用统计
- **活动管理**: 项目活动记录、操作日志

## 二、认证授权

### 2.1 认证方式

```http
Authorization: Bearer <jwt_token>
```

### 2.2 权限要求

- **项目管理**: 需要 `project:manage` 权限
- **成员管理**: 需要 `project:member:manage` 权限
- **配置管理**: 需要 `project:config:manage` 权限
- **资源管理**: 需要 `project:resource:manage` 权限
- **配额管理**: 需要 `project:quota:manage` 权限

## 三、项目管理API

### 3.1 创建项目

#### 创建新项目
```http
POST /api/v1/projects
```

**请求体**:
```json
{
  "name": "AI Chatbot Project",
  "code": "ai-chatbot",
  "description": "AI-powered chatbot for customer service",
  "type": "production",
  "visibility": "private",
  "avatar_url": "https://cdn.example.com/projects/ai-chatbot.png",
  "website_url": "https://chatbot.example.com",
  "repository_url": "https://github.com/example/ai-chatbot",
  "tags": ["ai", "chatbot", "nlp", "customer-service"],
  "settings": {
    "default_model": "gpt-4",
    "max_concurrent_requests": 100,
    "rate_limit": 1000,
    "timeout": 30,
    "retry_count": 3
  },
  "metadata": {
    "department": "engineering",
    "priority": "high",
    "budget": 50000,
    "timeline": "3 months"
  }
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Project created successfully",
  "data": {
    "project": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "name": "AI Chatbot Project",
      "code": "ai-chatbot",
      "description": "AI-powered chatbot for customer service",
      "type": "production",
      "status": "active",
      "visibility": "private",
      "avatar_url": "https://cdn.example.com/projects/ai-chatbot.png",
      "website_url": "https://chatbot.example.com",
      "repository_url": "https://github.com/example/ai-chatbot",
      "tags": ["ai", "chatbot", "nlp", "customer-service"],
      "settings": {
        "default_model": "gpt-4",
        "max_concurrent_requests": 100,
        "rate_limit": 1000,
        "timeout": 30,
        "retry_count": 3
      },
      "metadata": {
        "department": "engineering",
        "priority": "high",
        "budget": 50000,
        "timeline": "3 months"
      },
      "owner_id": 1,
      "tenant_id": 1,
      "organization_id": 1,
      "created_at": "2025-10-17T16:00:00Z",
      "updated_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 3.2 获取项目列表

#### 获取项目列表
```http
GET /api/v1/projects
```

**查询参数**:
- `page`: 页码 (默认: 1)
- `per_page`: 每页数量 (默认: 20, 最大: 100)
- `search`: 搜索关键词
- `type`: 项目类型过滤
- `status`: 项目状态过滤
- `visibility`: 可见性过滤
- `owner_id`: 所有者过滤
- `organization_id`: 组织过滤
- `tags`: 标签过滤
- `sort`: 排序字段 (默认: created_at:desc)

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "projects": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "AI Chatbot Project",
        "code": "ai-chatbot",
        "description": "AI-powered chatbot for customer service",
        "type": "production",
        "status": "active",
        "visibility": "private",
        "avatar_url": "https://cdn.example.com/projects/ai-chatbot.png",
        "tags": ["ai", "chatbot", "nlp"],
        "owner": {
          "id": 1,
          "username": "john_doe",
          "first_name": "John",
          "last_name": "Doe"
        },
        "organization": {
          "id": 1,
          "name": "Example Corp"
        },
        "member_count": 5,
        "model_count": 3,
        "created_at": "2025-10-17T16:00:00Z",
        "updated_at": "2025-10-17T16:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 25,
      "total_pages": 2,
      "has_next": true,
      "has_prev": false
    }
  }
}
```

### 3.3 获取项目详情

#### 获取项目详情
```http
GET /api/v1/projects/{id}
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "project": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "name": "AI Chatbot Project",
      "code": "ai-chatbot",
      "description": "AI-powered chatbot for customer service",
      "type": "production",
      "status": "active",
      "visibility": "private",
      "avatar_url": "https://cdn.example.com/projects/ai-chatbot.png",
      "website_url": "https://chatbot.example.com",
      "repository_url": "https://github.com/example/ai-chatbot",
      "tags": ["ai", "chatbot", "nlp", "customer-service"],
      "settings": {
        "default_model": "gpt-4",
        "max_concurrent_requests": 100,
        "rate_limit": 1000,
        "timeout": 30,
        "retry_count": 3
      },
      "metadata": {
        "department": "engineering",
        "priority": "high",
        "budget": 50000,
        "timeline": "3 months"
      },
      "owner": {
        "id": 1,
        "username": "john_doe",
        "first_name": "John",
        "last_name": "Doe",
        "email": "john@example.com"
      },
      "organization": {
        "id": 1,
        "name": "Example Corp",
        "code": "example_corp"
      },
      "statistics": {
        "member_count": 5,
        "model_count": 3,
        "api_call_count": 15000,
        "storage_used": "2.5GB",
        "cost_this_month": 1250.50
      },
      "created_at": "2025-10-17T16:00:00Z",
      "updated_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 3.4 更新项目

#### 更新项目信息
```http
PUT /api/v1/projects/{id}
```

**请求体**:
```json
{
  "name": "Advanced AI Chatbot Project",
  "description": "Advanced AI-powered chatbot with multi-language support",
  "visibility": "internal",
  "tags": ["ai", "chatbot", "nlp", "multilingual", "customer-service"],
  "settings": {
    "default_model": "gpt-4-turbo",
    "max_concurrent_requests": 200,
    "rate_limit": 2000,
    "timeout": 60,
    "retry_count": 5,
    "fallback_model": "gpt-3.5-turbo"
  },
  "metadata": {
    "department": "engineering",
    "priority": "high",
    "budget": 75000,
    "timeline": "4 months",
    "languages": ["en", "es", "fr", "de"]
  }
}
```

### 3.5 项目状态管理

#### 激活项目
```http
POST /api/v1/projects/{id}/activate
```

#### 停用项目
```http
POST /api/v1/projects/{id}/deactivate
```

#### 归档项目
```http
POST /api/v1/projects/{id}/archive
```

#### 删除项目
```http
DELETE /api/v1/projects/{id}
```

## 四、项目成员管理API

### 4.1 获取项目成员

#### 获取项目成员列表
```http
GET /api/v1/projects/{id}/members
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `search`: 搜索关键词
- `role`: 角色过滤
- `status`: 状态过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "members": [
      {
        "id": 1,
        "user": {
          "id": 1,
          "username": "john_doe",
          "first_name": "John",
          "last_name": "Doe",
          "email": "john@example.com",
          "avatar_url": "https://cdn.example.com/avatars/1.jpg"
        },
        "role": "owner",
        "permissions": [
          "project:manage",
          "project:member:manage",
          "project:config:manage",
          "project:resource:manage"
        ],
        "status": "active",
        "joined_at": "2025-10-17T16:00:00Z",
        "last_active_at": "2025-10-17T15:30:00Z"
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

### 4.2 添加项目成员

#### 添加项目成员
```http
POST /api/v1/projects/{id}/members
```

**请求体**:
```json
{
  "user_id": 2,
  "role": "developer",
  "permissions": [
    "project:read",
    "model:read",
    "model:deploy"
  ],
  "expires_at": "2025-12-31T23:59:59Z"
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Member added successfully",
  "data": {
    "member": {
      "id": 2,
      "user": {
        "id": 2,
        "username": "jane_smith",
        "first_name": "Jane",
        "last_name": "Smith",
        "email": "jane@example.com"
      },
      "role": "developer",
      "permissions": [
        "project:read",
        "model:read",
        "model:deploy"
      ],
      "status": "active",
      "expires_at": "2025-12-31T23:59:59Z",
      "joined_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 4.3 更新成员权限

#### 更新成员权限
```http
PUT /api/v1/projects/{id}/members/{user_id}
```

**请求体**:
```json
{
  "role": "senior_developer",
  "permissions": [
    "project:read",
    "model:read",
    "model:deploy",
    "model:manage"
  ]
}
```

### 4.4 移除项目成员

#### 移除项目成员
```http
DELETE /api/v1/projects/{id}/members/{user_id}
```

## 五、项目配置管理API

### 5.1 获取项目配置

#### 获取项目配置
```http
GET /api/v1/projects/{id}/configs
```

**查询参数**:
- `environment`: 环境过滤 (dev, staging, prod)
- `category`: 配置分类过滤

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "configs": [
      {
        "id": 1,
        "key": "api_rate_limit",
        "value": "1000",
        "type": "integer",
        "environment": "production",
        "category": "performance",
        "description": "API rate limit per hour",
        "is_encrypted": false,
        "is_required": true,
        "created_at": "2025-10-17T16:00:00Z",
        "updated_at": "2025-10-17T16:00:00Z"
      }
    ]
  }
}
```

### 5.2 创建项目配置

#### 创建项目配置
```http
POST /api/v1/projects/{id}/configs
```

**请求体**:
```json
{
  "key": "database_url",
  "value": "postgresql://user:pass@localhost:5432/db",
  "type": "string",
  "environment": "production",
  "category": "database",
  "description": "Database connection URL",
  "is_encrypted": true,
  "is_required": true
}
```

### 5.3 更新项目配置

#### 更新项目配置
```http
PUT /api/v1/projects/{id}/configs/{config_id}
```

**请求体**:
```json
{
  "value": "postgresql://user:newpass@localhost:5432/db",
  "description": "Updated database connection URL"
}
```

### 5.4 删除项目配置

#### 删除项目配置
```http
DELETE /api/v1/projects/{id}/configs/{config_id}
```

## 六、项目资源管理API

### 6.1 获取项目资源

#### 获取项目资源列表
```http
GET /api/v1/projects/{id}/resources
```

**查询参数**:
- `type`: 资源类型过滤
- `status`: 资源状态过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "resources": [
      {
        "id": 1,
        "type": "compute",
        "name": "GPU Cluster",
        "status": "active",
        "specifications": {
          "cpu_cores": 8,
          "memory_gb": 32,
          "gpu_count": 2,
          "gpu_type": "V100"
        },
        "usage": {
          "cpu_usage": 65.5,
          "memory_usage": 24.8,
          "gpu_usage": 45.2,
          "storage_usage": 125.6
        },
        "cost": {
          "hourly_rate": 2.50,
          "monthly_cost": 1800.00,
          "total_cost": 5400.00
        },
        "created_at": "2025-10-17T16:00:00Z",
        "updated_at": "2025-10-17T16:00:00Z"
      }
    ]
  }
}
```

### 6.2 分配项目资源

#### 分配项目资源
```http
POST /api/v1/projects/{id}/resources
```

**请求体**:
```json
{
  "type": "storage",
  "name": "Model Storage",
  "specifications": {
    "storage_gb": 500,
    "storage_type": "ssd",
    "replication": 3
  },
  "cost_limit": 100.00
}
```

### 6.3 更新资源使用

#### 更新资源使用情况
```http
PUT /api/v1/projects/{id}/resources/{resource_id}/usage
```

**请求体**:
```json
{
  "usage": {
    "cpu_usage": 70.2,
    "memory_usage": 28.5,
    "gpu_usage": 52.1,
    "storage_usage": 130.8
  }
}
```

## 七、项目配额管理API

### 7.1 获取项目配额

#### 获取项目配额
```http
GET /api/v1/projects/{id}/quotas
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "quotas": {
      "compute": {
        "cpu_cores": 16,
        "memory_gb": 64,
        "gpu_count": 4,
        "used": {
          "cpu_cores": 8,
          "memory_gb": 32,
          "gpu_count": 2
        },
        "remaining": {
          "cpu_cores": 8,
          "memory_gb": 32,
          "gpu_count": 2
        }
      },
      "storage": {
        "total_gb": 1000,
        "used_gb": 250,
        "remaining_gb": 750
      },
      "api": {
        "requests_per_hour": 10000,
        "requests_per_day": 100000,
        "used": {
          "requests_per_hour": 2500,
          "requests_per_day": 15000
        }
      },
      "cost": {
        "monthly_limit": 5000.00,
        "used": 1250.50,
        "remaining": 3749.50
      }
    }
  }
}
```

### 7.2 更新项目配额

#### 更新项目配额
```http
PUT /api/v1/projects/{id}/quotas
```

**请求体**:
```json
{
  "compute": {
    "cpu_cores": 32,
    "memory_gb": 128,
    "gpu_count": 8
  },
  "storage": {
    "total_gb": 2000
  },
  "api": {
    "requests_per_hour": 20000,
    "requests_per_day": 200000
  },
  "cost": {
    "monthly_limit": 10000.00
  }
}
```

## 八、项目活动管理API

### 8.1 获取项目活动

#### 获取项目活动记录
```http
GET /api/v1/projects/{id}/activities
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `type`: 活动类型过滤
- `user_id`: 用户过滤
- `date_from`: 开始日期
- `date_to`: 结束日期
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "activities": [
      {
        "id": 1,
        "type": "project_created",
        "description": "Project created",
        "details": {
          "project_name": "AI Chatbot Project",
          "project_code": "ai-chatbot"
        },
        "user": {
          "id": 1,
          "username": "john_doe",
          "first_name": "John",
          "last_name": "Doe"
        },
        "metadata": {
          "ip_address": "192.168.1.1",
          "user_agent": "Mozilla/5.0..."
        },
        "created_at": "2025-10-17T16:00:00Z"
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

### 8.2 记录项目活动

#### 记录项目活动
```http
POST /api/v1/projects/{id}/activities
```

**请求体**:
```json
{
  "type": "model_deployed",
  "description": "Model deployed to production",
  "details": {
    "model_name": "gpt-4-chatbot",
    "model_version": "v1.2.0",
    "environment": "production"
  },
  "metadata": {
    "deployment_id": "deploy_123",
    "deployment_time": "2025-10-17T16:00:00Z"
  }
}
```

## 九、项目邀请管理API

### 9.1 发送项目邀请

#### 发送项目邀请
```http
POST /api/v1/projects/{id}/invitations
```

**请求体**:
```json
{
  "email": "newuser@example.com",
  "role": "developer",
  "permissions": [
    "project:read",
    "model:read"
  ],
  "message": "Welcome to our AI Chatbot project!",
  "expires_at": "2025-10-24T23:59:59Z"
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Invitation sent successfully",
  "data": {
    "invitation": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "email": "newuser@example.com",
      "role": "developer",
      "permissions": [
        "project:read",
        "model:read"
      ],
      "status": "pending",
      "expires_at": "2025-10-24T23:59:59Z",
      "invited_by": 1,
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 9.2 获取项目邀请

#### 获取项目邀请列表
```http
GET /api/v1/projects/{id}/invitations
```

### 9.3 接受项目邀请

#### 接受项目邀请
```http
POST /api/v1/projects/invitations/{token}/accept
```

### 9.4 拒绝项目邀请

#### 拒绝项目邀请
```http
POST /api/v1/projects/invitations/{token}/reject
```

## 十、错误处理

### 10.1 常见错误码

| 错误码 | 错误类型 | 描述 |
|--------|----------|------|
| 400 | Bad Request | 请求参数错误 |
| 401 | Unauthorized | 未授权访问 |
| 403 | Forbidden | 权限不足 |
| 404 | Not Found | 项目不存在 |
| 409 | Conflict | 项目代码已存在 |
| 422 | Validation Error | 参数验证失败 |
| 429 | Rate Limited | 请求频率超限 |
| 500 | Internal Error | 服务器内部错误 |

### 10.2 错误响应示例

#### 项目不存在错误
```json
{
  "code": 404,
  "message": "Project not found",
  "error": {
    "type": "not_found_error",
    "details": "The requested project does not exist",
    "project_id": 999
  }
}
```

#### 权限不足错误
```json
{
  "code": 403,
  "message": "Insufficient permissions",
  "error": {
    "type": "authorization_error",
    "details": "You don't have permission to manage this project",
    "required_permission": "project:manage",
    "user_permissions": ["project:read"]
  }
}
```

## 十一、限流策略

### 11.1 限流规则

- **项目创建**: 10 requests/hour
- **成员管理**: 50 requests/hour
- **配置管理**: 100 requests/hour
- **一般API**: 1000 requests/hour

### 11.2 限流响应

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1640995200
```

## 十二、安全考虑

### 12.1 数据保护

- **敏感配置加密**: 数据库密码、API密钥等敏感配置加密存储
- **访问控制**: 基于角色的细粒度权限控制
- **审计日志**: 完整的项目操作审计记录
- **数据隔离**: 多租户数据隔离

### 12.2 操作安全

- **操作确认**: 危险操作需要二次确认
- **权限验证**: 每次操作都验证用户权限
- **资源限制**: 防止资源滥用和超限
- **异常监控**: 异常操作行为监控和告警

---

**文档维护**: 本文档应随API设计变化持续更新，保持与系统架构的一致性。

**版本历史**:
- v1.0 (2025-10-17): 初始版本，项目管理API设计

