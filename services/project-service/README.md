# 项目管理服务 (Project Service)

## 服务概述

项目管理服务是LLMOps平台的核心业务服务，负责项目的生命周期管理、成员管理、资源配额控制、项目模板等功能。

## 技术栈

- **语言**: Go 1.21+
- **框架**: Gin
- **ORM**: GORM
- **数据库**: PostgreSQL
- **缓存**: Redis
- **端口**: 8082

## 功能特性

### 核心功能
- ✅ **项目生命周期管理**: 创建、更新、删除、查询项目
- ✅ **成员管理**: 添加、移除、角色管理项目成员
- ✅ **权限控制**: 基于角色的访问控制(RBAC)
- ✅ **资源配额管理**: CPU、内存、GPU、存储、带宽配额控制
- ✅ **活动日志**: 完整的项目操作审计日志
- ✅ **项目模板**: 支持项目模板创建和快速创建项目

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
- **Project**: 项目实体
- **ProjectMember**: 项目成员实体
- **ProjectResourceQuota**: 资源配额实体
- **ProjectTemplate**: 项目模板实体
- **ProjectActivity**: 活动日志实体

#### 2. 仓储层 (Repository)
- **ProjectRepository**: 项目数据访问
- **ProjectTemplateRepository**: 项目模板数据访问

#### 3. 服务层 (Service)
- **ProjectService**: 项目业务逻辑
- **ProjectTemplateService**: 项目模板业务逻辑

#### 4. 处理器层 (Handler)
- **ProjectHandler**: 项目HTTP请求处理
- **ProjectTemplateHandler**: 项目模板HTTP请求处理

## API接口

### 项目管理接口
- `POST /api/v1/projects` - 创建项目
- `GET /api/v1/projects/{id}` - 获取项目详情
- `PUT /api/v1/projects/{id}` - 更新项目
- `DELETE /api/v1/projects/{id}` - 删除项目
- `GET /api/v1/projects` - 获取项目列表
- `GET /api/v1/projects/search` - 搜索项目

### 项目成员管理接口
- `POST /api/v1/projects/{id}/members` - 添加成员
- `DELETE /api/v1/projects/{id}/members/{member_id}` - 移除成员
- `GET /api/v1/projects/{id}/members` - 获取成员列表

### 项目模板接口
- `POST /api/v1/templates` - 创建模板
- `GET /api/v1/templates/{id}` - 获取模板详情
- `PUT /api/v1/templates/{id}` - 更新模板
- `DELETE /api/v1/templates/{id}` - 删除模板
- `GET /api/v1/templates` - 获取模板列表
- `GET /api/v1/templates/search` - 搜索模板

## 数据库设计

### 核心表结构

#### projects表
```sql
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    owner_id UUID NOT NULL REFERENCES users(id),
    tenant_id UUID NOT NULL,
    quota_cpu_limit BIGINT DEFAULT 0,
    quota_memory_limit BIGINT DEFAULT 0,
    quota_gpu_limit BIGINT DEFAULT 0,
    quota_storage_limit BIGINT DEFAULT 0,
    quota_bandwidth_limit BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);
```

#### project_members表
```sql
CREATE TABLE project_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    permissions TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(project_id, user_id)
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
project-service:
  build: ./services/project-service
  ports:
    - "8082:8082"
  environment:
    - DB_HOST=postgres
    - DB_PORT=5432
    - DB_NAME=project_db
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
cd services/project-service

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
go build -o project-service cmd/server/main.go

# 构建Docker镜像
docker build -t llmops/project-service:latest .

# 推送到镜像仓库
docker push llmops/project-service:latest
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
- 所有敏感数据加密存储
- 数据库连接使用SSL
- Redis连接认证支持

### 访问控制
- JWT token认证
- 基于角色的权限控制
- API限流和防护

### 审计日志
- 完整的操作审计日志
- 用户行为追踪
- 安全事件记录

## 扩展性

### 水平扩展
- 无状态设计
- 负载均衡支持
- 数据库读写分离
- 缓存集群支持

### 功能扩展
- 支持更多资源类型
- 支持更细粒度的权限控制
- 支持项目工作流管理
- 支持项目模板市场

---

**文档版本**: 1.0.0  
**创建时间**: 2024-01-01  
**更新时间**: 2024-01-01  
**维护者**: LLMOps开发团队



