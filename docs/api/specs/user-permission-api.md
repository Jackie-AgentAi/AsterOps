# 用户权限管理API设计

> **模块名称**: user_permission  
> **API版本**: v1.0  
> **更新日期**: 2025-10-17

## 一、模块概述

### 1.1 功能描述

用户权限管理API提供用户管理、角色管理、权限管理、组织管理和租户管理等核心功能，支持多租户架构下的用户认证、授权和权限控制。

### 1.2 核心功能

- **用户管理**: 用户注册、登录、信息管理
- **角色管理**: 角色创建、分配、权限绑定
- **权限管理**: 权限定义、分配、验证
- **组织管理**: 组织架构、成员管理
- **租户管理**: 租户创建、配置、隔离

## 二、认证授权

### 2.1 认证方式

#### JWT Token认证
```http
Authorization: Bearer <jwt_token>
```

#### API Key认证
```http
X-API-Key: <api_key>
```

### 2.2 权限要求

- **用户管理**: 需要 `user:manage` 权限
- **角色管理**: 需要 `role:manage` 权限
- **权限管理**: 需要 `permission:manage` 权限
- **组织管理**: 需要 `organization:manage` 权限
- **租户管理**: 需要 `tenant:manage` 权限

## 三、用户管理API

### 3.1 用户注册

#### 注册新用户
```http
POST /api/v1/users/register
```

**请求体**:
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePass123!",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890",
  "organization_id": 1,
  "invitation_code": "INV123456"
}
```

**响应**:
```json
{
  "code": 201,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "username": "john_doe",
      "email": "john@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "+1234567890",
      "status": "pending_verification",
      "created_at": "2025-10-17T16:00:00Z"
    },
    "verification_token": "verify_123456789"
  }
}
```

### 3.2 用户登录

#### 用户登录
```http
POST /api/v1/users/login
```

**请求体**:
```json
{
  "email": "john@example.com",
  "password": "SecurePass123!",
  "remember_me": true,
  "device_info": {
    "device_type": "web",
    "user_agent": "Mozilla/5.0...",
    "ip_address": "192.168.1.1"
  }
}
```

**响应**:
```json
{
  "code": 200,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "username": "john_doe",
      "email": "john@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "status": "active",
      "last_login_at": "2025-10-17T16:00:00Z"
    },
    "tokens": {
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expires_in": 3600,
      "token_type": "Bearer"
    },
    "permissions": [
      "user:read",
      "project:read",
      "model:read"
    ],
    "roles": [
      "developer",
      "project_member"
    ]
  }
}
```

### 3.3 获取用户信息

#### 获取当前用户信息
```http
GET /api/v1/users/me
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "user": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "username": "john_doe",
      "email": "john@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "+1234567890",
      "avatar_url": "https://cdn.example.com/avatars/1.jpg",
      "status": "active",
      "email_verified": true,
      "phone_verified": true,
      "two_factor_enabled": false,
      "last_login_at": "2025-10-17T16:00:00Z",
      "created_at": "2025-10-17T15:00:00Z",
      "updated_at": "2025-10-17T16:00:00Z"
    },
    "organization": {
      "id": 1,
      "name": "Example Corp",
      "role": "member"
    },
    "permissions": [
      "user:read",
      "project:read",
      "model:read"
    ],
    "roles": [
      "developer",
      "project_member"
    ]
  }
}
```

#### 获取用户列表
```http
GET /api/v1/users
```

**查询参数**:
- `page`: 页码 (默认: 1)
- `per_page`: 每页数量 (默认: 20, 最大: 100)
- `search`: 搜索关键词
- `status`: 用户状态过滤
- `role`: 角色过滤
- `organization_id`: 组织过滤
- `sort`: 排序字段 (默认: created_at:desc)

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "users": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "username": "john_doe",
        "email": "john@example.com",
        "first_name": "John",
        "last_name": "Doe",
        "status": "active",
        "last_login_at": "2025-10-17T16:00:00Z",
        "created_at": "2025-10-17T15:00:00Z"
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

### 3.4 更新用户信息

#### 更新用户信息
```http
PUT /api/v1/users/{id}
```

**请求体**:
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890",
  "avatar_url": "https://cdn.example.com/avatars/1.jpg",
  "preferences": {
    "language": "en",
    "timezone": "UTC",
    "notifications": {
      "email": true,
      "sms": false,
      "push": true
    }
  }
}
```

**响应**:
```json
{
  "code": 200,
  "message": "User updated successfully",
  "data": {
    "user": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "username": "john_doe",
      "email": "john@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "+1234567890",
      "avatar_url": "https://cdn.example.com/avatars/1.jpg",
      "preferences": {
        "language": "en",
        "timezone": "UTC",
        "notifications": {
          "email": true,
          "sms": false,
          "push": true
        }
      },
      "updated_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 3.5 用户状态管理

#### 激活用户
```http
POST /api/v1/users/{id}/activate
```

#### 停用用户
```http
POST /api/v1/users/{id}/deactivate
```

#### 删除用户
```http
DELETE /api/v1/users/{id}
```

## 四、角色管理API

### 4.1 获取角色列表

#### 获取角色列表
```http
GET /api/v1/roles
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `search`: 搜索关键词
- `type`: 角色类型过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "roles": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Super Admin",
        "code": "super_admin",
        "description": "Super administrator with full access",
        "type": "system",
        "is_system": true,
        "permissions": [
          "user:manage",
          "role:manage",
          "permission:manage",
          "organization:manage",
          "tenant:manage"
        ],
        "user_count": 5,
        "created_at": "2025-10-17T15:00:00Z"
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

### 4.2 创建角色

#### 创建新角色
```http
POST /api/v1/roles
```

**请求体**:
```json
{
  "name": "Project Manager",
  "code": "project_manager",
  "description": "Project manager with project management permissions",
  "type": "custom",
  "permissions": [
    "project:manage",
    "user:read",
    "model:read"
  ],
  "metadata": {
    "department": "engineering",
    "level": "senior"
  }
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Role created successfully",
  "data": {
    "role": {
      "id": 2,
      "uuid": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Project Manager",
      "code": "project_manager",
      "description": "Project manager with project management permissions",
      "type": "custom",
      "is_system": false,
      "permissions": [
        "project:manage",
        "user:read",
        "model:read"
      ],
      "metadata": {
        "department": "engineering",
        "level": "senior"
      },
      "user_count": 0,
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 4.3 更新角色

#### 更新角色信息
```http
PUT /api/v1/roles/{id}
```

**请求体**:
```json
{
  "name": "Senior Project Manager",
  "description": "Senior project manager with enhanced permissions",
  "permissions": [
    "project:manage",
    "user:read",
    "user:manage",
    "model:read",
    "model:manage"
  ]
}
```

### 4.4 分配角色

#### 为用户分配角色
```http
POST /api/v1/users/{user_id}/roles
```

**请求体**:
```json
{
  "role_id": 2,
  "scope_type": "project",
  "scope_id": 1,
  "expires_at": "2025-12-31T23:59:59Z"
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Role assigned successfully",
  "data": {
    "user_role": {
      "id": 1,
      "user_id": 1,
      "role_id": 2,
      "scope_type": "project",
      "scope_id": 1,
      "status": "active",
      "expires_at": "2025-12-31T23:59:59Z",
      "assigned_by": 1,
      "assigned_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

## 五、权限管理API

### 5.1 获取权限列表

#### 获取权限列表
```http
GET /api/v1/permissions
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `search`: 搜索关键词
- `category`: 权限分类过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "permissions": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "User Management",
        "code": "user:manage",
        "description": "Manage users including create, update, delete",
        "category": "user",
        "resource": "user",
        "action": "manage",
        "is_system": true,
        "created_at": "2025-10-17T15:00:00Z"
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

### 5.2 创建权限

#### 创建新权限
```http
POST /api/v1/permissions
```

**请求体**:
```json
{
  "name": "Model Deployment",
  "code": "model:deploy",
  "description": "Deploy models to production environment",
  "category": "model",
  "resource": "model",
  "action": "deploy",
  "metadata": {
    "risk_level": "high",
    "requires_approval": true
  }
}
```

### 5.3 权限验证

#### 验证用户权限
```http
POST /api/v1/permissions/check
```

**请求体**:
```json
{
  "user_id": 1,
  "permission": "model:deploy",
  "resource_id": 123,
  "context": {
    "project_id": 1,
    "organization_id": 1
  }
}
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "has_permission": true,
    "permission": "model:deploy",
    "user_id": 1,
    "resource_id": 123,
    "granted_by": "role:project_manager",
    "expires_at": "2025-12-31T23:59:59Z"
  }
}
```

## 六、组织管理API

### 6.1 获取组织列表

#### 获取组织列表
```http
GET /api/v1/organizations
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `search`: 搜索关键词
- `type`: 组织类型过滤
- `status`: 状态过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "organizations": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Example Corp",
        "code": "example_corp",
        "type": "company",
        "status": "active",
        "description": "Example Corporation",
        "website": "https://example.com",
        "logo_url": "https://cdn.example.com/logos/1.png",
        "contact_email": "contact@example.com",
        "contact_phone": "+1234567890",
        "address": {
          "street": "123 Main St",
          "city": "New York",
          "state": "NY",
          "country": "US",
          "postal_code": "10001"
        },
        "settings": {
          "timezone": "America/New_York",
          "language": "en",
          "currency": "USD"
        },
        "member_count": 25,
        "created_at": "2025-10-17T15:00:00Z"
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

### 6.2 创建组织

#### 创建新组织
```http
POST /api/v1/organizations
```

**请求体**:
```json
{
  "name": "New Company",
  "code": "new_company",
  "type": "company",
  "description": "A new company",
  "website": "https://newcompany.com",
  "contact_email": "contact@newcompany.com",
  "contact_phone": "+1234567890",
  "address": {
    "street": "456 Oak Ave",
    "city": "San Francisco",
    "state": "CA",
    "country": "US",
    "postal_code": "94102"
  },
  "settings": {
    "timezone": "America/Los_Angeles",
    "language": "en",
    "currency": "USD"
  }
}
```

### 6.3 组织成员管理

#### 获取组织成员
```http
GET /api/v1/organizations/{id}/members
```

#### 添加组织成员
```http
POST /api/v1/organizations/{id}/members
```

**请求体**:
```json
{
  "user_id": 1,
  "role": "admin",
  "department": "engineering",
  "position": "Senior Developer"
}
```

#### 更新成员信息
```http
PUT /api/v1/organizations/{id}/members/{user_id}
```

#### 移除组织成员
```http
DELETE /api/v1/organizations/{id}/members/{user_id}
```

## 七、租户管理API

### 7.1 获取租户列表

#### 获取租户列表
```http
GET /api/v1/tenants
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `search`: 搜索关键词
- `status`: 状态过滤
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "tenants": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Example Tenant",
        "code": "example_tenant",
        "status": "active",
        "description": "Example tenant for demonstration",
        "settings": {
          "max_users": 1000,
          "max_projects": 100,
          "max_models": 500,
          "storage_limit": "1TB",
          "api_rate_limit": 10000
        },
        "billing": {
          "plan": "enterprise",
          "billing_cycle": "monthly",
          "next_billing_date": "2025-11-17T00:00:00Z"
        },
        "user_count": 25,
        "project_count": 5,
        "created_at": "2025-10-17T15:00:00Z"
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

### 7.2 创建租户

#### 创建新租户
```http
POST /api/v1/tenants
```

**请求体**:
```json
{
  "name": "New Tenant",
  "code": "new_tenant",
  "description": "A new tenant",
  "settings": {
    "max_users": 500,
    "max_projects": 50,
    "max_models": 200,
    "storage_limit": "500GB",
    "api_rate_limit": 5000
  },
  "billing": {
    "plan": "professional",
    "billing_cycle": "monthly"
  }
}
```

### 7.3 租户配置管理

#### 更新租户配置
```http
PUT /api/v1/tenants/{id}/settings
```

**请求体**:
```json
{
  "max_users": 2000,
  "max_projects": 200,
  "max_models": 1000,
  "storage_limit": "2TB",
  "api_rate_limit": 20000
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

#### 参数验证错误
```json
{
  "code": 422,
  "message": "Validation failed",
  "error": {
    "type": "validation_error",
    "details": "The given data was invalid",
    "errors": {
      "email": ["The email field is required"],
      "password": ["The password must be at least 8 characters"]
    }
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
    "details": "You don't have permission to perform this action",
    "required_permission": "user:manage",
    "user_permissions": ["user:read"]
  }
}
```

## 九、限流策略

### 9.1 限流规则

- **用户注册**: 5 requests/hour
- **用户登录**: 10 requests/hour
- **密码重置**: 3 requests/hour
- **一般API**: 1000 requests/hour
- **管理API**: 100 requests/hour

### 9.2 限流响应

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1640995200
```

## 十、安全考虑

### 10.1 密码安全

- **密码强度**: 最少8位，包含大小写字母、数字和特殊字符
- **密码加密**: 使用bcrypt加密存储
- **密码历史**: 不能使用最近5次使用过的密码
- **密码过期**: 90天强制更换密码

### 10.2 会话安全

- **JWT过期**: 访问令牌1小时过期
- **刷新令牌**: 30天过期
- **会话管理**: 支持多设备登录管理
- **异常检测**: 异常登录行为检测

### 10.3 数据保护

- **敏感数据加密**: 手机号、邮箱等敏感信息加密存储
- **数据脱敏**: API响应中敏感数据脱敏
- **审计日志**: 完整的用户操作审计
- **数据备份**: 定期数据备份和恢复

---

**文档维护**: 本文档应随API设计变化持续更新，保持与系统架构的一致性。

**版本历史**:
- v1.0 (2025-10-17): 初始版本，用户权限管理API设计

