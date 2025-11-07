# API网关 (API Gateway)

## 服务概述

API网关是LLMOps平台的统一入口，负责请求路由、负载均衡、认证授权、限流熔断、监控日志等功能。提供统一的API管理和服务治理能力。

## 技术栈

- **语言**: Go 1.21+
- **框架**: Gin + gRPC
- **代理**: HTTP反向代理
- **服务发现**: Consul
- **缓存**: Redis
- **端口**: 8080

## 功能特性

### 核心功能
- ✅ **统一入口**: 所有微服务的统一访问入口
- ✅ **请求路由**: 智能路由和负载均衡
- ✅ **认证授权**: JWT认证和权限控制
- ✅ **限流熔断**: 请求限流和熔断保护
- ✅ **监控日志**: 请求监控和日志记录
- ✅ **服务治理**: 服务发现和健康检查

### 技术特性
- ✅ **高性能**: 基于Go的高性能代理
- ✅ **高可用**: 多实例部署和故障转移
- ✅ **可扩展**: 水平扩展和动态配置
- ✅ **安全**: 多层安全防护
- ✅ **监控**: 完整的监控和告警
- ✅ **日志**: 结构化日志和追踪

## 服务架构

### 分层架构
```
┌─────────────────┐
│   Gateway层      │  API网关和路由
├─────────────────┤
│   Middleware层   │  中间件处理
├─────────────────┤
│   Router层       │  路由管理
├─────────────────┤
│   Config层       │  配置管理
└─────────────────┘
```

### 核心组件

#### 1. 网关层 (Gateway)
- **HTTPGateway**: HTTP请求处理
- **gRPCGateway**: gRPC请求处理
- **WebSocketGateway**: WebSocket连接处理

#### 2. 中间件层 (Middleware)
- **AuthMiddleware**: 认证中间件
- **RateLimitMiddleware**: 限流中间件
- **LoggingMiddleware**: 日志中间件
- **MetricsMiddleware**: 监控中间件

#### 3. 路由层 (Router)
- **ServiceRouter**: 服务路由
- **LoadBalancer**: 负载均衡器
- **HealthChecker**: 健康检查器

#### 4. 配置层 (Config)
- **ServiceConfig**: 服务配置
- **RouteConfig**: 路由配置
- **MiddlewareConfig**: 中间件配置

## API接口

### 网关接口
- `GET /health` - 网关健康检查
- `GET /ready` - 网关就绪检查
- `GET /metrics` - 网关指标
- `GET /services` - 服务列表
- `GET /routes` - 路由列表

### 代理接口
- `GET /api/v1/*` - 代理到用户服务
- `GET /api/v2/*` - 代理到模型服务
- `GET /api/v3/*` - 代理到推理服务
- `GET /api/v4/*` - 代理到成本服务
- `GET /api/v5/*` - 代理到监控服务
- `GET /api/v6/*` - 代理到项目服务

## 配置管理

### 路由配置
```yaml
routes:
  - name: "user-service"
    path: "/api/v1/*"
    target: "user-service"
    methods: ["GET", "POST", "PUT", "DELETE"]
    middleware: ["auth", "rate-limit"]
  
  - name: "model-service"
    path: "/api/v2/*"
    target: "model-service"
    methods: ["GET", "POST", "PUT", "DELETE"]
    middleware: ["auth", "rate-limit"]
```

### 中间件配置
```yaml
middleware:
  auth:
    type: "jwt"
    secret: "your-secret-key"
    expire: 3600
  
  rate-limit:
    type: "redis"
    limit: 100
    window: "1m"
```

## 部署配置

### Docker配置
```dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o api-gateway cmd/server/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/api-gateway .
COPY --from=builder /app/configs ./configs

CMD ["./api-gateway"]
```

### Docker Compose配置
```yaml
api-gateway:
  build: ./infrastructure/api-gateway
  ports:
    - "8080:8080"
  environment:
    - CONSUL_HOST=consul
    - CONSUL_PORT=8500
    - REDIS_HOST=redis
    - REDIS_PORT=6379
  depends_on:
    - consul
    - redis
  networks:
    - llmops-network
  restart: unless-stopped
```

## 开发指南

### 本地开发
```bash
# 克隆项目
git clone <repository-url>
cd infrastructure/api-gateway

# 安装依赖
go mod download

# 启动服务
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
go build -o api-gateway cmd/server/main.go

# 构建Docker镜像
docker build -t llmops/api-gateway:latest .

# 推送到镜像仓库
docker push llmops/api-gateway:latest
```

## 监控和运维

### 健康检查
- `GET /health` - 网关健康状态
- `GET /ready` - 网关就绪状态
- `GET /metrics` - Prometheus指标

### 日志记录
- 结构化日志输出
- 请求追踪ID
- 错误堆栈信息
- 性能指标记录

### 监控指标
- 请求数量和延迟
- 错误率和成功率
- 服务健康状态
- 中间件执行时间

## 安全考虑

### 数据安全
- 请求数据加密传输
- 敏感数据脱敏
- 数据库连接加密
- 传输层安全

### 访问控制
- JWT token认证
- 基于角色的权限控制
- API限流和防护
- 跨域资源共享

### 审计日志
- 请求操作记录
- 认证失败记录
- 限流触发记录
- 安全事件记录

## 扩展性

### 水平扩展
- 无状态设计
- 负载均衡支持
- 数据库读写分离
- 缓存集群支持

### 功能扩展
- 支持更多协议
- 支持更多中间件
- 支持更多负载均衡算法
- 支持更多监控指标

---

**文档版本**: 1.0.0  
**创建时间**: 2024-01-01  
**更新时间**: 2024-01-01  
**维护者**: LLMOps开发团队



