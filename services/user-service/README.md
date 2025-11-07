# 用户权限服务 (User Service)

## 服务概述

用户权限服务是LLMOps平台的认证授权中心，负责用户管理、身份认证、角色权限控制等核心功能。

## 技术栈

- **语言**: Go 1.21+
- **框架**: Gin
- **ORM**: GORM
- **数据库**: PostgreSQL
- **缓存**: Redis
- **认证**: JWT
- **端口**: 8081

## 功能特性

### 核心功能
- ✅ **用户管理**: 用户注册、登录、信息管理
- ✅ **认证授权**: JWT token认证、多因素认证
- ✅ **角色权限**: 基于角色的访问控制(RBAC)
- ✅ **租户管理**: 多租户支持和隔离
- ✅ **会话管理**: 用户会话和token管理

### 技术特性
- ✅ **微服务架构**: 独立部署和扩展
- ✅ **服务发现**: Consul注册和发现
- ✅ **健康检查**: 服务健康状态监控
- ✅ **API文档**: Swagger API文档
- ✅ **数据验证**: 完整的数据验证和错误处理

## 服务架构

### 分层架构
```
┌─────────────────┐
│   Handler层      │  HTTP请求处理，参数验证
├─────────────────┤
│   Service层      │  业务逻辑处理
├─────────────────┤
│   Repository层   │  数据访问层
├─────────────────┤
│   Entity层       │  数据模型定义
└─────────────────┘
```

### 核心组件

#### 1. 数据模型 (Entity)
- **User**: 用户实体
- **Role**: 角色实体
- **Permission**: 权限实体
- **UserRole**: 用户角色关联
- **Tenant**: 租户实体

#### 2. 仓储层 (Repository)
- **UserRepository**: 用户数据访问
- **RoleRepository**: 角色数据访问
- **PermissionRepository**: 权限数据访问

#### 3. 服务层 (Service)
- **UserService**: 用户业务逻辑
- **AuthService**: 认证业务逻辑
- **RoleService**: 角色业务逻辑

#### 4. 处理器层 (Handler)
- **UserHandler**: 用户HTTP请求处理
- **AuthHandler**: 认证HTTP请求处理
- **RoleHandler**: 角色HTTP请求处理

## API接口

### 认证接口
- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/register` - 用户注册
- `POST /api/v1/auth/refresh` - 刷新token
- `POST /api/v1/auth/logout` - 用户登出
- `POST /api/v1/auth/forgot-password` - 忘记密码
- `POST /api/v1/auth/reset-password` - 重置密码

### 用户管理接口
- `GET /api/v1/users` - 获取用户列表
- `POST /api/v1/users` - 创建用户
- `GET /api/v1/users/{id}` - 获取用户详情
- `PUT /api/v1/users/{id}` - 更新用户信息
- `DELETE /api/v1/users/{id}` - 删除用户
- `PUT /api/v1/users/{id}/password` - 修改密码

### 角色管理接口
- `GET /api/v1/roles` - 获取角色列表
- `POST /api/v1/roles` - 创建角色
- `GET /api/v1/roles/{id}` - 获取角色详情
- `PUT /api/v1/roles/{id}` - 更新角色
- `DELETE /api/v1/roles/{id}` - 删除角色

### 权限管理接口
- `GET /api/v1/permissions` - 获取权限列表
- `POST /api/v1/permissions` - 创建权限
- `GET /api/v1/permissions/{id}` - 获取权限详情
- `PUT /api/v1/permissions/{id}` - 更新权限
- `DELETE /api/v1/permissions/{id}` - 删除权限

## 数据库设计

### 核心表结构

#### users表
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    status VARCHAR(50) DEFAULT 'active',
    tenant_id UUID NOT NULL,
    last_login_at TIMESTAMP WITH TIME ZONE,
    mfa_enabled BOOLEAN DEFAULT false,
    mfa_secret VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);
```

#### roles表
```sql
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    tenant_id UUID NOT NULL,
    is_system BOOLEAN DEFAULT false,
    permissions TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);
```

#### user_roles表
```sql
CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, role_id)
);
```

## 部署配置

### Docker配置
```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod download
RUN go build -o main cmd/server/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
CMD ["./main"]
```

### Docker Compose配置
```yaml
version: '3.8'
services:
  user-service:
    build: ./services/user-service
    ports:
      - "8081:8081"
    environment:
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=user_db
      - DB_USER=user
      - DB_PASSWORD=password
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - CONSUL_HOST=consul
      - CONSUL_PORT=8500
    depends_on:
      - postgres
      - redis
      - consul
```

## 开发指南

### 本地开发
```bash
# 克隆项目
git clone <repository-url>
cd services/user-service

# 安装依赖
go mod download

# 启动依赖服务
docker-compose up -d postgres redis consul

# 运行服务
go run cmd/server/main.go
```

### 测试
```bash
# 运行单元测试
go test ./...

# 运行集成测试
go test -tags=integration ./...

# 测试覆盖率
go test -cover ./...
```

### 构建部署
```bash
# 构建二进制文件
go build -o user-service cmd/server/main.go

# 构建Docker镜像
docker build -t llmops/user-service:latest .

# 推送到镜像仓库
docker push llmops/user-service:latest
```

## 监控和运维

### 健康检查
- `GET /health` - 服务健康状态
- `GET /ready` - 服务就绪状态
- `GET /metrics` - Prometheus指标

### 日志记录
- 结构化日志输出
- 请求追踪ID
- 错误堆栈信息
- 性能指标记录

### 监控指标
- 请求数量和响应时间
- 错误率和成功率
- 数据库连接池状态
- 缓存命中率

## 安全考虑

### 数据安全
- 密码加密存储
- 敏感数据脱敏
- 数据库连接加密
- 传输层安全

### 访问控制
- JWT token认证
- 基于角色的权限控制
- API限流和防护
- 跨域资源共享

### 审计日志
- 用户操作记录
- 登录登出日志
- 权限变更追踪
- 安全事件记录

## 扩展性

### 水平扩展
- 无状态设计
- 负载均衡支持
- 数据库读写分离
- 缓存集群支持

### 功能扩展
- 多因素认证
- 单点登录
- 第三方认证
- 权限细粒度控制

---

**文档版本**: 1.0.0  
**创建时间**: 2024-01-01  
**更新时间**: 2024-01-01  
**维护者**: LLMOps开发团队



