# LLMOps平台Go后端API规范

> **文档版本**: v1.0  
> **更新日期**: 2025-01-17  
> **技术栈**: Go Gin + GORM

## 一、API设计原则

### 1.1 RESTful设计
- 使用标准HTTP方法 (GET, POST, PUT, DELETE)
- 资源导向的URL设计
- 统一的响应格式
- 合理的HTTP状态码

### 1.2 认证授权
- JWT Token认证
- RBAC权限控制
- API Key认证 (可选)
- 请求限流

### 1.3 响应格式
```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "timestamp": "2025-01-17T10:30:00Z",
  "request_id": "req_123456789"
}
```

### 1.4 错误处理
```json
{
  "code": 400,
  "message": "validation failed",
  "error": "invalid email format",
  "details": {
    "field": "email",
    "value": "invalid-email"
  },
  "timestamp": "2025-01-17T10:30:00Z",
  "request_id": "req_123456789"
}
```

## 二、用户权限服务API

### 2.1 认证相关

#### 2.1.1 用户注册
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "username": "testuser",
  "email": "test@example.com",
  "password": "TestPass123!",
  "confirm_password": "TestPass123!"
}
```

**响应**:
```json
{
  "code": 201,
  "message": "user created successfully",
  "data": {
    "user": {
      "id": 1,
      "username": "testuser",
      "email": "test@example.com",
      "status": "active",
      "created_at": "2025-01-17T10:30:00Z"
    }
  }
}
```

#### 2.1.2 用户登录
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "testuser",
  "password": "TestPass123!"
}
```

**响应**:
```json
{
  "code": 200,
  "message": "login successful",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600,
    "token_type": "Bearer",
    "user": {
      "id": 1,
      "username": "testuser",
      "email": "test@example.com",
      "roles": ["user"]
    }
  }
}
```

#### 2.1.3 刷新Token
```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### 2.1.4 用户登出
```http
POST /api/v1/auth/logout
Authorization: Bearer <access_token>
```

### 2.2 用户管理

#### 2.2.1 获取用户信息
```http
GET /api/v1/users/profile
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "user": {
      "id": 1,
      "username": "testuser",
      "email": "test@example.com",
      "status": "active",
      "last_login_at": "2025-01-17T10:30:00Z",
      "created_at": "2025-01-17T09:00:00Z",
      "roles": [
        {
          "id": 1,
          "name": "user",
          "description": "普通用户"
        }
      ]
    }
  }
}
```

#### 2.2.2 更新用户信息
```http
PUT /api/v1/users/profile
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "email": "newemail@example.com",
  "display_name": "Test User"
}
```

#### 2.2.3 修改密码
```http
PUT /api/v1/users/password
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "old_password": "OldPass123!",
  "new_password": "NewPass123!",
  "confirm_password": "NewPass123!"
}
```

### 2.3 权限管理

#### 2.3.1 获取用户权限
```http
GET /api/v1/users/permissions
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "permissions": [
      {
        "id": 1,
        "name": "project:read",
        "resource": "project",
        "action": "read",
        "description": "查看项目"
      },
      {
        "id": 2,
        "name": "project:create",
        "resource": "project",
        "action": "create",
        "description": "创建项目"
      }
    ]
  }
}
```

## 三、项目管理服务API

### 3.1 项目管理

#### 3.1.1 获取项目列表
```http
GET /api/v1/projects?page=1&limit=10&status=active
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "projects": [
      {
        "id": 1,
        "name": "LLM Chatbot",
        "description": "智能聊天机器人项目",
        "status": "active",
        "owner": {
          "id": 1,
          "username": "testuser"
        },
        "member_count": 5,
        "created_at": "2025-01-17T09:00:00Z",
        "updated_at": "2025-01-17T10:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 25,
      "pages": 3
    }
  }
}
```

#### 3.1.2 创建项目
```http
POST /api/v1/projects
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "New Project",
  "description": "项目描述",
  "template_id": 1
}
```

#### 3.1.3 获取项目详情
```http
GET /api/v1/projects/{id}
Authorization: Bearer <access_token>
```

#### 3.1.4 更新项目
```http
PUT /api/v1/projects/{id}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "Updated Project Name",
  "description": "更新的项目描述"
}
```

#### 3.1.5 删除项目
```http
DELETE /api/v1/projects/{id}
Authorization: Bearer <access_token>
```

### 3.2 项目成员管理

#### 3.2.1 获取项目成员
```http
GET /api/v1/projects/{id}/members
Authorization: Bearer <access_token>
```

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
          "username": "testuser",
          "email": "test@example.com"
        },
        "role": "owner",
        "status": "active",
        "joined_at": "2025-01-17T09:00:00Z"
      }
    ]
  }
}
```

#### 3.2.2 邀请成员
```http
POST /api/v1/projects/{id}/members
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "email": "newuser@example.com",
  "role": "developer"
}
```

#### 3.2.3 更新成员角色
```http
PUT /api/v1/projects/{id}/members/{user_id}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "role": "admin"
}
```

#### 3.2.4 移除成员
```http
DELETE /api/v1/projects/{id}/members/{user_id}
Authorization: Bearer <access_token>
```

### 3.3 项目资源配置

#### 3.3.1 获取项目资源
```http
GET /api/v1/projects/{id}/resources
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "resources": {
      "compute": {
        "cpu_quota": 8,
        "memory_quota": 16384,
        "gpu_quota": 2,
        "used_cpu": 4,
        "used_memory": 8192,
        "used_gpu": 1
      },
      "storage": {
        "quota": 1000,
        "used": 250,
        "unit": "GB"
      },
      "network": {
        "bandwidth_quota": 1000,
        "used_bandwidth": 200,
        "unit": "Mbps"
      }
    }
  }
}
```

#### 3.3.2 更新资源配置
```http
PUT /api/v1/projects/{id}/resources
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "compute": {
    "cpu_quota": 16,
    "memory_quota": 32768,
    "gpu_quota": 4
  },
  "storage": {
    "quota": 2000
  }
}
```

## 四、成本管理服务API

### 4.1 成本统计

#### 4.1.1 获取成本概览
```http
GET /api/v1/costs/summary?start_date=2025-01-01&end_date=2025-01-31&project_id=1
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "summary": {
      "total_cost": 1250.50,
      "currency": "USD",
      "period": {
        "start_date": "2025-01-01",
        "end_date": "2025-01-31"
      },
      "breakdown": {
        "compute_cost": 800.30,
        "storage_cost": 200.20,
        "network_cost": 150.00,
        "api_cost": 100.00
      },
      "trend": {
        "daily_avg": 40.34,
        "growth_rate": 5.2
      }
    }
  }
}
```

#### 4.1.2 获取成本明细
```http
GET /api/v1/costs/details?page=1&limit=20&start_date=2025-01-01&end_date=2025-01-31
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "costs": [
      {
        "id": 1,
        "date": "2025-01-17",
        "project_id": 1,
        "project_name": "LLM Chatbot",
        "service": "inference",
        "resource_type": "gpu",
        "usage": 2.5,
        "unit": "hours",
        "unit_price": 1.2,
        "total_cost": 3.0,
        "currency": "USD"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 150,
      "pages": 8
    }
  }
}
```

### 4.2 预算管理

#### 4.2.1 获取预算列表
```http
GET /api/v1/costs/budgets?project_id=1
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "budgets": [
      {
        "id": 1,
        "name": "月度预算",
        "project_id": 1,
        "amount": 1000.0,
        "currency": "USD",
        "period": "monthly",
        "start_date": "2025-01-01",
        "end_date": "2025-01-31",
        "used_amount": 750.5,
        "remaining_amount": 249.5,
        "alert_threshold": 80,
        "status": "active",
        "created_at": "2025-01-01T00:00:00Z"
      }
    ]
  }
}
```

#### 4.2.2 创建预算
```http
POST /api/v1/costs/budgets
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "季度预算",
  "project_id": 1,
  "amount": 5000.0,
  "currency": "USD",
  "period": "quarterly",
  "start_date": "2025-01-01",
  "end_date": "2025-03-31",
  "alert_threshold": 85
}
```

#### 4.2.3 更新预算
```http
PUT /api/v1/costs/budgets/{id}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "amount": 6000.0,
  "alert_threshold": 90
}
```

### 4.3 成本优化

#### 4.3.1 获取优化建议
```http
GET /api/v1/costs/optimization?project_id=1
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "recommendations": [
      {
        "id": 1,
        "type": "resource_optimization",
        "title": "GPU资源优化",
        "description": "建议使用更小的GPU实例，可节省30%成本",
        "potential_savings": 240.0,
        "currency": "USD",
        "impact": "medium",
        "effort": "low"
      },
      {
        "id": 2,
        "type": "cache_optimization",
        "title": "启用语义缓存",
        "description": "启用语义缓存可减少重复推理，节省40%成本",
        "potential_savings": 320.0,
        "currency": "USD",
        "impact": "high",
        "effort": "medium"
      }
    ]
  }
}
```

## 五、API网关配置

### 5.1 路由配置

```yaml
# 路由配置示例
routes:
  - name: "user-service"
    path: "/api/v1/users/*"
    target: "http://user-service:8081"
    methods: ["GET", "POST", "PUT", "DELETE"]
    
  - name: "project-service"
    path: "/api/v1/projects/*"
    target: "http://project-service:8082"
    methods: ["GET", "POST", "PUT", "DELETE"]
    
  - name: "cost-service"
    path: "/api/v1/costs/*"
    target: "http://cost-service:8083"
    methods: ["GET", "POST", "PUT", "DELETE"]
```

### 5.2 中间件配置

```yaml
# 中间件配置
middlewares:
  - name: "auth"
    type: "jwt"
    config:
      secret: "${JWT_SECRET}"
      header: "Authorization"
      prefix: "Bearer "
      
  - name: "rate_limit"
    type: "rate_limit"
    config:
      requests_per_minute: 100
      burst: 20
      
  - name: "cors"
    type: "cors"
    config:
      allowed_origins: ["*"]
      allowed_methods: ["GET", "POST", "PUT", "DELETE"]
      allowed_headers: ["*"]
```

## 六、错误码定义

### 6.1 HTTP状态码
- `200` - 成功
- `201` - 创建成功
- `400` - 请求参数错误
- `401` - 未授权
- `403` - 禁止访问
- `404` - 资源不存在
- `409` - 资源冲突
- `422` - 验证失败
- `429` - 请求过于频繁
- `500` - 服务器内部错误

### 6.2 业务错误码
```yaml
# 用户相关错误
USER_NOT_FOUND: 10001
USER_ALREADY_EXISTS: 10002
INVALID_CREDENTIALS: 10003
USER_DISABLED: 10004
PASSWORD_TOO_WEAK: 10005

# 项目相关错误
PROJECT_NOT_FOUND: 20001
PROJECT_ACCESS_DENIED: 20002
PROJECT_QUOTA_EXCEEDED: 20003
PROJECT_MEMBER_EXISTS: 20004

# 成本相关错误
BUDGET_NOT_FOUND: 30001
BUDGET_EXCEEDED: 30002
INVALID_COST_DATA: 30003

# 系统错误
INTERNAL_ERROR: 90001
SERVICE_UNAVAILABLE: 90002
DATABASE_ERROR: 90003
```

## 七、请求限流

### 7.1 限流策略
```yaml
rate_limits:
  # 用户级别限流
  user:
    requests_per_minute: 100
    requests_per_hour: 1000
    burst: 20
    
  # IP级别限流
  ip:
    requests_per_minute: 200
    requests_per_hour: 5000
    burst: 50
    
  # API级别限流
  api:
    requests_per_minute: 1000
    requests_per_hour: 10000
    burst: 100
```

### 7.2 限流响应
```json
{
  "code": 429,
  "message": "rate limit exceeded",
  "error": "too many requests",
  "details": {
    "limit": 100,
    "remaining": 0,
    "reset_time": "2025-01-17T11:00:00Z"
  }
}
```

## 八、API版本管理

### 8.1 版本策略
- URL路径版本控制: `/api/v1/`, `/api/v2/`
- 向后兼容性保证
- 废弃API提前通知
- 版本迁移指南

### 8.2 版本头
```http
GET /api/v1/users
Accept: application/vnd.llmops.v1+json
API-Version: v1
```

## 九、监控和日志

### 9.1 请求日志
```json
{
  "timestamp": "2025-01-17T10:30:00Z",
  "request_id": "req_123456789",
  "method": "POST",
  "path": "/api/v1/users",
  "status_code": 201,
  "response_time": 150,
  "user_id": 1,
  "ip": "192.168.1.100",
  "user_agent": "Mozilla/5.0..."
}
```

### 9.2 性能指标
- 响应时间 (P50, P90, P99)
- 请求量 (QPS)
- 错误率
- 可用性

## 十、安全考虑

### 10.1 输入验证
- 参数类型验证
- 长度限制
- 格式验证
- SQL注入防护
- XSS防护

### 10.2 输出过滤
- 敏感信息脱敏
- 数据权限控制
- 响应大小限制

### 10.3 安全头
```http
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000
```

---

**文档维护**: 本文档应随着API演进持续更新，保持与实际实现的一致性。

**版本历史**:
- v1.0 (2025-01-17): 初始版本，Go后端API规范
