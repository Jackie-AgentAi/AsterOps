# 成本管理服务 (Cost Service)

## 服务概述

成本管理服务是LLMOps平台的核心服务，负责成本记录、预算管理、成本分析、优化建议等功能。支持多种计费模式和成本优化策略。

## 技术栈

- **语言**: Go 1.21+
- **框架**: Gin
- **ORM**: GORM
- **数据库**: PostgreSQL
- **缓存**: Redis
- **端口**: 8085

## 功能特性

### 核心功能
- ✅ **成本记录**: 自动记录和手动记录成本
- ✅ **预算管理**: 预算设置、监控和告警
- ✅ **成本分析**: 多维度成本分析和报表
- ✅ **优化建议**: 智能成本优化建议
- ✅ **计费管理**: 多种计费模式支持
- ✅ **成本预测**: 基于历史数据的成本预测

### 技术特性
- ✅ **微服务架构**: 独立部署和扩展
- ✅ **服务发现**: Consul注册和发现
- ✅ **健康检查**: 服务健康状态监控
- ✅ **API文档**: 自动生成Swagger文档
- ✅ **数据验证**: 结构体标签验证
- ✅ **并发安全**: 高并发场景下的数据一致性

## 服务架构

### 分层架构
```
┌─────────────────┐
│   API层         │  Gin路由和请求处理
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
- **CostRecord**: 成本记录实体
- **Budget**: 预算实体
- **CostAnalysis**: 成本分析实体
- **BillingRule**: 计费规则实体
- **CostOptimization**: 成本优化实体

#### 2. 仓储层 (Repository)
- **CostRepository**: 成本数据访问
- **BudgetRepository**: 预算数据访问
- **AnalysisRepository**: 分析数据访问

#### 3. 服务层 (Service)
- **CostService**: 成本业务逻辑
- **BudgetService**: 预算业务逻辑
- **AnalysisService**: 分析业务逻辑
- **OptimizationService**: 优化业务逻辑

#### 4. API层 (Handler)
- **CostHandler**: 成本HTTP请求处理
- **BudgetHandler**: 预算HTTP请求处理
- **AnalysisHandler**: 分析HTTP请求处理
- **OptimizationHandler**: 优化HTTP请求处理

## API接口

### 成本记录接口
- `POST /api/v1/costs` - 创建成本记录
- `GET /api/v1/costs/{id}` - 获取成本记录详情
- `PUT /api/v1/costs/{id}` - 更新成本记录
- `DELETE /api/v1/costs/{id}` - 删除成本记录
- `GET /api/v1/costs` - 获取成本记录列表
- `GET /api/v1/costs/export` - 导出成本数据

### 预算管理接口
- `POST /api/v1/budgets` - 创建预算
- `GET /api/v1/budgets/{id}` - 获取预算详情
- `PUT /api/v1/budgets/{id}` - 更新预算
- `DELETE /api/v1/budgets/{id}` - 删除预算
- `GET /api/v1/budgets` - 获取预算列表
- `POST /api/v1/budgets/{id}/alert` - 设置预算告警

### 成本分析接口
- `GET /api/v1/analysis/summary` - 获取成本汇总
- `GET /api/v1/analysis/trend` - 获取成本趋势
- `GET /api/v1/analysis/breakdown` - 获取成本分解
- `GET /api/v1/analysis/comparison` - 获取成本对比
- `GET /api/v1/analysis/forecast` - 获取成本预测

### 优化建议接口
- `GET /api/v1/optimization/suggestions` - 获取优化建议
- `POST /api/v1/optimization/apply` - 应用优化建议
- `GET /api/v1/optimization/impact` - 获取优化影响

## 数据库设计

### 核心表结构

#### cost_records表
```sql
CREATE TABLE cost_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    model_id UUID,
    user_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    cost_type VARCHAR(50) NOT NULL,
    amount DECIMAL(15,4) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### budgets表
```sql
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    amount DECIMAL(15,4) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    period VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    alert_threshold DECIMAL(5,2) DEFAULT 80.00,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## 部署配置

### Docker配置
```dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o cost-service cmd/server/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/cost-service .
COPY --from=builder /app/configs ./configs

CMD ["./cost-service"]
```

### Docker Compose配置
```yaml
cost-service:
  build: ./services/cost-service
  ports:
    - "8085:8085"
  environment:
    - DB_HOST=postgres
    - DB_PORT=5432
    - DB_NAME=cost_db
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
  networks:
    - llmops-network
  restart: unless-stopped
```

## 开发指南

### 本地开发
```bash
# 克隆项目
git clone <repository-url>
cd services/cost-service

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
go build -o cost-service cmd/server/main.go

# 构建Docker镜像
docker build -t llmops/cost-service:latest .

# 推送到镜像仓库
docker push llmops/cost-service:latest
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
- 成本记录数量和金额
- 预算使用率
- 优化建议数量
- 错误率和成功率

## 安全考虑

### 数据安全
- 成本数据加密存储
- 敏感数据脱敏
- 数据库连接加密
- 传输层安全

### 访问控制
- JWT token认证
- 基于角色的权限控制
- API限流和防护
- 跨域资源共享

### 审计日志
- 成本操作记录
- 预算变更追踪
- 优化建议记录
- 安全事件记录

## 扩展性

### 水平扩展
- 无状态设计
- 负载均衡支持
- 数据库读写分离
- 缓存集群支持

### 功能扩展
- 支持更多计费模式
- 支持更多优化策略
- 支持更多分析维度
- 支持更多预测模型

---

**文档版本**: 1.0.0  
**创建时间**: 2024-01-01  
**更新时间**: 2024-01-01  
**维护者**: LLMOps开发团队



