# 微服务架构详细设计

> **文档类型**: 系统架构详细设计  
> **更新时间**: 2025-10-17  
> **版本**: v1.0

## 一、微服务架构概述

### 1.1 设计目标

LLMOps平台采用微服务架构，实现高可用、高并发、可扩展的分布式系统，支持大规模LLM运营需求。

### 1.2 架构原则

- **单一职责**: 每个服务专注于特定业务领域
- **松耦合**: 服务间通过API和消息队列通信
- **高内聚**: 相关功能聚合在同一服务内
- **可扩展**: 支持水平扩展和独立部署
- **容错性**: 服务故障不影响整体系统

### 1.3 技术栈

- **服务框架**: Go Gin (主要), Python FastAPI (AI/ML服务)
- **服务注册**: Consul
- **配置管理**: Consul KV, Viper
- **API网关**: Kong + Go Gin中间件
- **消息队列**: Apache Kafka, RabbitMQ
- **数据库**: PostgreSQL, MongoDB, Redis
- **容器化**: Docker, Kubernetes
- **ORM框架**: GORM (Go)
- **缓存**: Redis, Go-Redis
- **日志**: Logrus, Zap
- **监控**: Prometheus, Grafana
- **链路追踪**: Jaeger, OpenTelemetry

## 二、服务划分

### 2.1 核心业务服务

#### 2.1.1 用户权限服务 (user-service)
**职责**: 用户管理、认证授权、权限控制
**技术栈**: Go Gin + GORM + JWT
**数据库**: PostgreSQL
**端口**: 8081

**核心功能**:
- 用户注册、登录、信息管理
- JWT Token生成和验证
- 角色权限管理
- 组织租户管理
- 多因素认证

**API接口**:
```
POST /api/v1/users/register
POST /api/v1/users/login
GET  /api/v1/users/me
GET  /api/v1/users
PUT  /api/v1/users/{id}
DELETE /api/v1/users/{id}
```

#### 2.1.2 项目管理服务 (project-service)
**职责**: 项目管理、成员管理、资源配置
**技术栈**: Go Gin + GORM
**数据库**: PostgreSQL
**端口**: 8082

**核心功能**:
- 项目创建、更新、删除
- 项目成员管理
- 项目配置管理
- 资源配额管理
- 项目活动记录

**API接口**:
```
POST /api/v1/projects
GET  /api/v1/projects
GET  /api/v1/projects/{id}
PUT  /api/v1/projects/{id}
DELETE /api/v1/projects/{id}
POST /api/v1/projects/{id}/members
```

#### 2.1.3 模型管理服务 (model-service)
**职责**: 模型注册、版本管理、部署管理
**技术栈**: Go Gin + GORM + MinIO
**数据库**: PostgreSQL + MinIO
**端口**: 8083

**核心功能**:
- 模型注册和元数据管理
- 模型版本控制
- 模型文件管理
- 模型部署和实例管理
- 模型性能监控

**API接口**:
```
POST /api/v1/models
GET  /api/v1/models
GET  /api/v1/models/{id}
POST /api/v1/models/{id}/versions
GET  /api/v1/models/{id}/deployments
```

#### 2.1.4 推理服务 (inference-service)
**职责**: 模型推理、负载均衡、结果缓存
**技术栈**: FastAPI + vLLM + Redis
**数据库**: Redis + PostgreSQL
**端口**: 8084

**核心功能**:
- 单次推理、批量推理、流式推理
- 智能负载均衡
- 推理结果缓存
- 推理参数配置
- 推理性能监控

**API接口**:
```
POST /api/v1/inference/chat
POST /api/v1/inference/batch
POST /api/v1/inference/stream
GET  /api/v1/inference/configs
GET  /api/v1/inference/metrics
```

#### 2.1.5 成本管理服务 (cost-service)
**职责**: 成本计算、预算管理、计费规则
**技术栈**: Go Gin + GORM
**数据库**: PostgreSQL + Redis
**端口**: 8085

**核心功能**:
- 成本记录和统计
- 预算设置和监控
- 计费规则管理
- 成本优化建议
- 成本预测分析

**API接口**:
```
GET  /api/v1/costs/records
POST /api/v1/costs/records
GET  /api/v1/costs/budgets
POST /api/v1/costs/budgets
GET  /api/v1/costs/statistics
```

#### 2.1.6 监控服务 (monitoring-service)
**职责**: 系统监控、告警管理、日志收集
**技术栈**: Go Gin + Prometheus + ELK Stack
**数据库**: InfluxDB + Elasticsearch
**端口**: 8086

**核心功能**:
- 系统指标收集
- 告警规则管理
- 告警事件处理
- 日志收集和分析
- 审计日志记录

**API接口**:
```
GET  /api/v1/monitoring/metrics
POST /api/v1/monitoring/metrics
GET  /api/v1/monitoring/alerts/rules
POST /api/v1/monitoring/alerts/rules
GET  /api/v1/monitoring/logs
```

#### 2.1.7 评测服务 (evaluation-service)
**职责**: 模型评测、测试数据集管理
**技术栈**: Go Gin + Python + MLflow
**数据库**: PostgreSQL + MongoDB
**端口**: 8087

**核心功能**:
- 评测任务管理
- 测试数据集管理
- 评测结果分析
- 评测指标定义
- 人工反馈收集

**API接口**:
```
POST /api/v1/evaluation/tasks
GET  /api/v1/evaluation/tasks
POST /api/v1/evaluation/datasets
GET  /api/v1/evaluation/results
GET  /api/v1/evaluation/reports
```

#### 2.1.8 知识库服务 (knowledge-service)
**职责**: 知识库管理、文档处理、语义检索
**技术栈**: FastAPI + LangChain + ChromaDB
**数据库**: PostgreSQL + ChromaDB + MinIO
**端口**: 8088

**核心功能**:
- 知识库创建和管理
- 文档上传和处理
- 文档分块和向量化
- 语义检索和相似度搜索
- RAG会话管理

**API接口**:
```
POST /api/v1/knowledge/bases
GET  /api/v1/knowledge/bases
POST /api/v1/knowledge/bases/{id}/documents
POST /api/v1/knowledge/bases/{id}/search
POST /api/v1/knowledge/bases/{id}/sessions
```

### 2.2 基础设施服务

#### 2.2.1 API网关服务 (api-gateway)
**职责**: 统一入口、路由转发、限流熔断
**技术栈**: Kong + Nginx
**端口**: 80, 443

**核心功能**:
- 统一API入口
- 请求路由和负载均衡
- 限流和熔断保护
- 认证授权验证
- 请求日志记录

#### 2.2.2 配置服务 (config-service)
**职责**: 配置管理、服务发现
**技术栈**: Consul + Go Viper
**端口**: 8500

**核心功能**:
- 服务注册和发现
- 配置集中管理
- 配置动态更新
- 健康检查
- 服务监控

#### 2.2.3 消息服务 (message-service)
**职责**: 异步消息处理、事件驱动
**技术栈**: Apache Kafka + Go Sarama
**端口**: 9092

**核心功能**:
- 异步消息处理
- 事件驱动架构
- 消息持久化
- 消息重试机制
- 死信队列处理

#### 2.2.4 文件服务 (file-service)
**职责**: 文件存储、文件管理
**技术栈**: MinIO + Go Gin
**端口**: 9000

**核心功能**:
- 文件上传下载
- 文件存储管理
- 文件访问控制
- 文件版本管理
- 文件备份恢复

## 三、服务间通信

### 3.1 同步通信

#### 3.1.1 HTTP/REST API
**使用场景**: 实时数据查询、用户交互
**技术实现**: Go Gin, FastAPI
**协议**: HTTP/1.1, HTTP/2
**数据格式**: JSON

**示例**:
```go
// UserController 用户控制器
type UserController struct {
    userService services.UserService
}

// GetUser 获取用户信息
func (c *UserController) GetUser(ctx *gin.Context) {
    idStr := ctx.Param("id")
    id, err := strconv.ParseUint(idStr, 10, 32)
    if err != nil {
        ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid user id"})
        return
    }
    
    user, err := c.userService.FindByID(uint(id))
    if err != nil {
        ctx.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
        return
    }
    
    ctx.JSON(http.StatusOK, user)
}
```

#### 3.1.2 gRPC
**使用场景**: 高性能内部服务通信
**技术实现**: gRPC + Protocol Buffers
**协议**: HTTP/2
**数据格式**: Protocol Buffers

**示例**:
```protobuf
syntax = "proto3";

service UserService {
    rpc GetUser(GetUserRequest) returns (GetUserResponse);
    rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
}

message GetUserRequest {
    int64 user_id = 1;
}

message GetUserResponse {
    User user = 1;
}
```

### 3.2 异步通信

#### 3.2.1 消息队列
**使用场景**: 异步处理、事件驱动
**技术实现**: Apache Kafka, RabbitMQ
**消息格式**: JSON, Avro

**示例**:
```go
// UserEventHandler 用户事件处理器
type UserEventHandler struct {
    notificationService services.NotificationService
    auditService        services.AuditService
    logger              logger.Logger
}

// HandleUserCreated 处理用户创建事件
func (h *UserEventHandler) HandleUserCreated(event *events.UserCreatedEvent) error {
    h.logger.Info("Processing user created event", 
        "user_id", event.UserID,
        "username", event.Username)
    
    // 发送欢迎邮件
    if err := h.notificationService.SendWelcomeEmail(event.UserID); err != nil {
        h.logger.Error("Failed to send welcome email", "error", err)
        return err
    }
    
    // 记录审计日志
    if err := h.auditService.LogUserCreation(event); err != nil {
        h.logger.Error("Failed to log user creation", "error", err)
        return err
    }
    
    return nil
}

// 注册Kafka消费者
func (h *UserEventHandler) RegisterConsumer(consumer kafka.Consumer) {
    consumer.Subscribe("user.created", h.HandleUserCreated)
}
```

#### 3.2.2 事件总线
**使用场景**: 跨服务事件发布订阅
**技术实现**: Go Sarama, Apache Kafka
**事件格式**: CloudEvents

**示例**:
```go
// ProjectService 项目服务
type ProjectService struct {
    projectRepo   repositories.ProjectRepository
    eventPublisher events.EventPublisher
    logger        logger.Logger
}

// CreateProject 创建项目
func (s *ProjectService) CreateProject(project *models.Project) error {
    s.logger.Info("Creating project", "name", project.Name)
    
    // 创建项目
    if err := s.projectRepo.Create(project); err != nil {
        s.logger.Error("Failed to create project", "error", err)
        return err
    }
    
    // 发布项目创建事件
    event := &events.ProjectCreatedEvent{
        ProjectID:   project.ID,
        ProjectName: project.Name,
        OwnerID:     project.OwnerID,
        CreatedAt:   time.Now(),
    }
    
    if err := s.eventPublisher.Publish("project-created", event); err != nil {
        s.logger.Error("Failed to publish project created event", "error", err)
        // 不返回错误，因为项目已经创建成功
    }
    
    return nil
}
```

## 四、数据管理

### 4.1 数据库设计

#### 4.1.1 关系型数据库 (PostgreSQL)
**使用服务**: 用户服务、项目服务、模型服务、成本服务、评测服务
**特点**: ACID事务、复杂查询、数据一致性

**分库分表策略**:
```sql
-- 用户表分片
CREATE TABLE users_shard_0 (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID NOT NULL,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    -- 其他字段
    shard_key INT GENERATED ALWAYS AS (id % 4) STORED
);

-- 创建分片索引
CREATE INDEX idx_users_shard_key ON users_shard_0(shard_key);
```

#### 4.1.2 文档数据库 (MongoDB)
**使用服务**: 知识库服务、评测服务
**特点**: 灵活模式、水平扩展、复杂文档存储

**集合设计**:
```javascript
// 知识库文档集合
db.knowledge_documents.createIndex({
    "knowledge_base_id": 1,
    "status": 1,
    "created_at": -1
});

// 评测结果集合
db.evaluation_results.createIndex({
    "task_id": 1,
    "model_id": 1,
    "created_at": -1
});
```

#### 4.1.3 缓存数据库 (Redis)
**使用服务**: 推理服务、用户服务、配置服务
**特点**: 高性能、内存存储、多种数据结构

**缓存策略**:
```go
// InferenceCacheService 推理缓存服务
type InferenceCacheService struct {
    redis  redis.Client
    logger logger.Logger
}

// CacheInferenceResult 缓存推理结果
func (s *InferenceCacheService) CacheInferenceResult(key string, result *models.InferenceResult) error {
    cacheKey := fmt.Sprintf("inference:%s", key)
    
    // 序列化结果
    data, err := json.Marshal(result)
    if err != nil {
        s.logger.Error("Failed to marshal inference result", "error", err)
        return err
    }
    
    // 设置缓存，TTL为1小时
    if err := s.redis.Set(cacheKey, data, time.Hour).Err(); err != nil {
        s.logger.Error("Failed to cache inference result", "error", err)
        return err
    }
    
    s.logger.Debug("Cached inference result", "key", cacheKey)
    return nil
}

// GetCachedResult 获取缓存的推理结果
func (s *InferenceCacheService) GetCachedResult(key string) (*models.InferenceResult, error) {
    cacheKey := fmt.Sprintf("inference:%s", key)
    
    data, err := s.redis.Get(cacheKey).Result()
    if err != nil {
        if err == redis.Nil {
            return nil, nil // 缓存未命中
        }
        s.logger.Error("Failed to get cached result", "error", err)
        return nil, err
    }
    
    var result models.InferenceResult
    if err := json.Unmarshal([]byte(data), &result); err != nil {
        s.logger.Error("Failed to unmarshal cached result", "error", err)
        return nil, err
    }
    
    return &result, nil
}
```

#### 4.1.4 向量数据库 (ChromaDB)
**使用服务**: 知识库服务
**特点**: 向量存储、相似度搜索、语义检索

**向量存储**:
```python
import chromadb
from chromadb.config import Settings

# 创建向量数据库客户端
client = chromadb.Client(Settings(
    chroma_db_impl="duckdb+parquet",
    persist_directory="./chroma_db"
))

# 创建知识库集合
collection = client.create_collection(
    name="knowledge_base_1",
    metadata={"description": "Customer service knowledge base"}
)

# 添加文档向量
collection.add(
    documents=["How to reset password", "Account recovery process"],
    metadatas=[{"source": "faq.pdf"}, {"source": "guide.pdf"}],
    ids=["doc1", "doc2"]
)
```

### 4.2 数据一致性

#### 4.2.1 分布式事务
**技术实现**: Saga模式、两阶段提交
**使用场景**: 跨服务数据一致性

**Saga模式示例**:
```go
// ProjectCreationSaga 项目创建Saga
type ProjectCreationSaga struct {
    commandGateway   commands.CommandGateway
    eventStore       events.EventStore
    logger           logger.Logger
}

// StartProjectCreation 开始项目创建Saga
func (s *ProjectCreationSaga) StartProjectCreation(event *events.ProjectCreatedEvent) error {
    s.logger.Info("Starting project creation saga", "project_id", event.ProjectID)
    
    // 1. 创建项目资源
    command := &commands.CreateProjectResourceCommand{
        ProjectID: event.ProjectID,
        OwnerID:   event.OwnerID,
    }
    
    if err := s.commandGateway.Send(command); err != nil {
        s.logger.Error("Failed to send create project resource command", "error", err)
        return err
    }
    
    return nil
}

// HandleProjectResourceCreated 处理项目资源创建事件
func (s *ProjectCreationSaga) HandleProjectResourceCreated(event *events.ProjectResourceCreatedEvent) error {
    s.logger.Info("Handling project resource created", "project_id", event.ProjectID)
    
    // 2. 分配项目配额
    command := &commands.AllocateProjectQuotaCommand{
        ProjectID: event.ProjectID,
        Quota:     event.Quota,
    }
    
    if err := s.commandGateway.Send(command); err != nil {
        s.logger.Error("Failed to send allocate quota command", "error", err)
        return err
    }
    
    return nil
}

// HandleProjectQuotaAllocated 处理项目配额分配事件
func (s *ProjectCreationSaga) HandleProjectQuotaAllocated(event *events.ProjectQuotaAllocatedEvent) error {
    s.logger.Info("Handling project quota allocated", "project_id", event.ProjectID)
    
    // 3. 完成项目创建
    command := &commands.CompleteProjectCreationCommand{
        ProjectID: event.ProjectID,
    }
    
    if err := s.commandGateway.Send(command); err != nil {
        s.logger.Error("Failed to send complete project creation command", "error", err)
        return err
    }
    
    return nil
}
```

#### 4.2.2 最终一致性
**技术实现**: 事件驱动、补偿机制
**使用场景**: 非关键业务数据

**事件驱动示例**:
```go
// CostCalculationService 成本计算服务
type CostCalculationService struct {
    costRepo   repositories.CostRepository
    logger     logger.Logger
    workerPool *worker.Pool
}

// HandleInferenceCompleted 处理推理完成事件
func (s *CostCalculationService) HandleInferenceCompleted(event *events.InferenceCompletedEvent) error {
    s.logger.Info("Handling inference completed event", 
        "project_id", event.ProjectID,
        "model_id", event.ModelID)
    
    // 异步计算成本
    s.workerPool.Submit(func() {
        if err := s.calculateAndSaveCost(event); err != nil {
            s.logger.Error("Failed to calculate cost", "error", err)
        }
    })
    
    return nil
}

// calculateAndSaveCost 计算并保存成本
func (s *CostCalculationService) calculateAndSaveCost(event *events.InferenceCompletedEvent) error {
    // 计算成本
    cost := s.calculateCost(event)
    
    // 保存成本记录
    if err := s.costRepo.Create(cost); err != nil {
        return err
    }
    
    // 更新项目成本统计
    if err := s.updateProjectCostStatistics(event.ProjectID, cost); err != nil {
        s.logger.Error("Failed to update project cost statistics", "error", err)
        // 不返回错误，因为成本记录已经保存
    }
    
    return nil
}
```

## 五、服务治理

### 5.1 服务注册与发现

#### 5.1.1 Consul配置
```yaml
# consul.yml
server: true
bootstrap_expect: 3
datacenter: "llmops-dc"
data_dir: "/opt/consul/data"
log_level: "INFO"
node_name: "consul-server-1"
retry_join: ["consul-server-2", "consul-server-3"]

services:
  - name: "user-service"
    port: 8081
    check:
      http: "http://localhost:8081/health"
      interval: "10s"
      timeout: "3s"
```

#### 5.1.2 服务注册
```go
// UserServiceApplication 用户服务应用
type UserServiceApplication struct {
    consulClient *consul.Client
    config       *config.Config
    logger       logger.Logger
}

// NewUserServiceApplication 创建用户服务应用
func NewUserServiceApplication() *UserServiceApplication {
    config := config.LoadConfig()
    logger := logger.NewLogger()
    
    // 创建Consul客户端
    consulConfig := consul.DefaultConfig()
    consulConfig.Address = config.Consul.Address
    consulClient, _ := consul.NewClient(consulConfig)
    
    return &UserServiceApplication{
        consulClient: consulClient,
        config:       config,
        logger:       logger,
    }
}

// RegisterService 注册服务到Consul
func (app *UserServiceApplication) RegisterService() error {
    registration := &consul.AgentServiceRegistration{
        ID:      fmt.Sprintf("user-service-%s", app.config.Server.Port),
        Name:    "user-service",
        Tags:    []string{"user", "auth", "api"},
        Port:    app.config.Server.Port,
        Address: app.config.Server.Host,
        Check: &consul.AgentServiceCheck{
            HTTP:                           fmt.Sprintf("http://%s:%d/health", app.config.Server.Host, app.config.Server.Port),
            Timeout:                        "3s",
            Interval:                       "10s",
            DeregisterCriticalServiceAfter: "30s",
        },
    }
    
    return app.consulClient.Agent().ServiceRegister(registration)
}

// Start 启动服务
func (app *UserServiceApplication) Start() error {
    // 注册服务
    if err := app.RegisterService(); err != nil {
        return err
    }
    
    // 启动HTTP服务器
    router := gin.Default()
    // 配置路由...
    
    app.logger.Info("Starting user service", "port", app.config.Server.Port)
    return router.Run(fmt.Sprintf(":%d", app.config.Server.Port))
}
```

### 5.2 配置管理

#### 5.2.1 配置中心
```yaml
# config.yaml
consul:
  host: localhost
  port: 8500
  service:
    name: user-service
    instance_id: user-service:8081
  config:
    enabled: true
    format: yaml
    data_key: configuration
    default_context: application

server:
  host: 0.0.0.0
  port: 8081

database:
  host: localhost
  port: 5432
  name: llmops
  user: llmops
  password: password

redis:
  host: localhost
  port: 6379
  password: ""
  db: 0
```

#### 5.2.2 动态配置
```go
// ConfigController 配置控制器
type ConfigController struct {
    configService services.ConfigService
    logger        logger.Logger
}

// NewConfigController 创建配置控制器
func NewConfigController(configService services.ConfigService) *ConfigController {
    return &ConfigController{
        configService: configService,
        logger:        logger.NewLogger(),
    }
}

// GetFeatureConfig 获取功能配置
func (c *ConfigController) GetFeatureConfig(ctx *gin.Context) {
    featureName := ctx.Query("feature")
    if featureName == "" {
        ctx.JSON(http.StatusBadRequest, gin.H{"error": "feature name is required"})
        return
    }
    
    enabled, err := c.configService.GetFeatureEnabled(featureName)
    if err != nil {
        c.logger.Error("Failed to get feature config", "feature", featureName, "error", err)
        ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get config"})
        return
    }
    
    ctx.JSON(http.StatusOK, gin.H{
        "feature": featureName,
        "enabled": enabled,
    })
}

// UpdateFeatureConfig 更新功能配置
func (c *ConfigController) UpdateFeatureConfig(ctx *gin.Context) {
    var req struct {
        Feature string `json:"feature" binding:"required"`
        Enabled bool   `json:"enabled"`
    }
    
    if err := ctx.ShouldBindJSON(&req); err != nil {
        ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    if err := c.configService.SetFeatureEnabled(req.Feature, req.Enabled); err != nil {
        c.logger.Error("Failed to update feature config", "feature", req.Feature, "error", err)
        ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update config"})
        return
    }
    
    ctx.JSON(http.StatusOK, gin.H{"message": "config updated successfully"})
}
```

### 5.3 负载均衡

#### 5.3.1 客户端负载均衡
```go
// LoadBalancerConfig 负载均衡配置
type LoadBalancerConfig struct {
    consulClient *consul.Client
    logger       logger.Logger
}

// NewLoadBalancerConfig 创建负载均衡配置
func NewLoadBalancerConfig(consulClient *consul.Client) *LoadBalancerConfig {
    return &LoadBalancerConfig{
        consulClient: consulClient,
        logger:       logger.NewLogger(),
    }
}

// GetServiceInstances 获取服务实例
func (c *LoadBalancerConfig) GetServiceInstances(serviceName string) ([]*consul.ServiceEntry, error) {
    services, _, err := c.consulClient.Health().Service(serviceName, "", true, nil)
    if err != nil {
        c.logger.Error("Failed to get service instances", "service", serviceName, "error", err)
        return nil, err
    }
    
    return services, nil
}

// RoundRobinLoadBalancer 轮询负载均衡器
type RoundRobinLoadBalancer struct {
    services map[string][]*consul.ServiceEntry
    counters map[string]int
    mutex    sync.RWMutex
}

// NewRoundRobinLoadBalancer 创建轮询负载均衡器
func NewRoundRobinLoadBalancer() *RoundRobinLoadBalancer {
    return &RoundRobinLoadBalancer{
        services: make(map[string][]*consul.ServiceEntry),
        counters: make(map[string]int),
    }
}

// SelectInstance 选择服务实例
func (lb *RoundRobinLoadBalancer) SelectInstance(serviceName string) (*consul.ServiceEntry, error) {
    lb.mutex.RLock()
    instances, exists := lb.services[serviceName]
    lb.mutex.RUnlock()
    
    if !exists || len(instances) == 0 {
        return nil, fmt.Errorf("no instances available for service %s", serviceName)
    }
    
    lb.mutex.Lock()
    defer lb.mutex.Unlock()
    
    index := lb.counters[serviceName] % len(instances)
    lb.counters[serviceName]++
    
    return instances[index], nil
}
```

#### 5.3.2 服务端负载均衡
```yaml
# nginx.conf
upstream user-service {
    server user-service-1:8081 weight=1;
    server user-service-2:8081 weight=1;
    server user-service-3:8081 weight=1;
}

server {
    listen 80;
    server_name api.llmops.com;
    
    location /api/v1/users/ {
        proxy_pass http://user-service;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 5.4 熔断降级

#### 5.4.1 熔断器配置
```go
// CircuitBreaker 熔断器
type CircuitBreaker struct {
    name                string
    maxRequests         uint32
    interval            time.Duration
    timeout             time.Duration
    maxFailures         uint32
    requestCount        uint32
    failureCount        uint32
    lastFailureTime     time.Time
    state               CircuitState
    mutex               sync.RWMutex
    fallbackFunc        func() (interface{}, error)
}

type CircuitState int

const (
    StateClosed CircuitState = iota
    StateOpen
    StateHalfOpen
)

// NewCircuitBreaker 创建熔断器
func NewCircuitBreaker(name string, maxRequests uint32, interval, timeout time.Duration, maxFailures uint32) *CircuitBreaker {
    return &CircuitBreaker{
        name:        name,
        maxRequests: maxRequests,
        interval:    interval,
        timeout:     timeout,
        maxFailures: maxFailures,
        state:       StateClosed,
    }
}

// Execute 执行操作
func (cb *CircuitBreaker) Execute(operation func() (interface{}, error)) (interface{}, error) {
    cb.mutex.Lock()
    defer cb.mutex.Unlock()
    
    if cb.state == StateOpen {
        if time.Since(cb.lastFailureTime) > cb.timeout {
            cb.state = StateHalfOpen
        } else {
            // 执行降级逻辑
            if cb.fallbackFunc != nil {
                return cb.fallbackFunc()
            }
            return nil, fmt.Errorf("circuit breaker is open")
        }
    }
    
    result, err := operation()
    
    if err != nil {
        cb.failureCount++
        cb.lastFailureTime = time.Now()
        
        if cb.failureCount >= cb.maxFailures {
            cb.state = StateOpen
        }
        return nil, err
    }
    
    // 成功时重置计数器
    if cb.state == StateHalfOpen {
        cb.state = StateClosed
        cb.failureCount = 0
    }
    
    return result, nil
}

// ModelServiceClient 模型服务客户端
type ModelServiceClient struct {
    httpClient     *http.Client
    circuitBreaker *CircuitBreaker
    baseURL        string
    logger         logger.Logger
}

// GetModel 获取模型
func (c *ModelServiceClient) GetModel(modelID uint) (*models.Model, error) {
    result, err := c.circuitBreaker.Execute(func() (interface{}, error) {
        return c.callModelService(modelID)
    })
    
    if err != nil {
        // 执行降级逻辑
        return c.getModelFallback(modelID), nil
    }
    
    return result.(*models.Model), nil
}

// getModelFallback 降级方法
func (c *ModelServiceClient) getModelFallback(modelID uint) *models.Model {
    c.logger.Warn("Using fallback model", "model_id", modelID)
    return &models.Model{
        ID:     modelID,
        Name:   "Default Model",
        Status: "unavailable",
    }
}
```

## 六、监控与运维

### 6.1 健康检查

#### 6.1.1 Go服务健康检查
```yaml
# config.yaml
health:
  endpoints:
    - health
    - info
    - metrics
    - prometheus
  show_details: always
  checks:
    database:
      enabled: true
    redis:
      enabled: true
    consul:
      enabled: true
```

#### 6.1.2 自定义健康检查
```go
// HealthChecker 健康检查器接口
type HealthChecker interface {
    CheckHealth() HealthStatus
}

// HealthStatus 健康状态
type HealthStatus struct {
    Status    string                 `json:"status"`
    Details   map[string]interface{} `json:"details,omitempty"`
    Timestamp time.Time              `json:"timestamp"`
}

// ModelServiceHealthChecker 模型服务健康检查器
type ModelServiceHealthChecker struct {
    modelService services.ModelService
    logger       logger.Logger
}

// NewModelServiceHealthChecker 创建模型服务健康检查器
func NewModelServiceHealthChecker(modelService services.ModelService) *ModelServiceHealthChecker {
    return &ModelServiceHealthChecker{
        modelService: modelService,
        logger:       logger.NewLogger(),
    }
}

// CheckHealth 检查健康状态
func (h *ModelServiceHealthChecker) CheckHealth() HealthStatus {
    status := HealthStatus{
        Timestamp: time.Now(),
        Details:   make(map[string]interface{}),
    }
    
    // 检查模型服务状态
    isHealthy, err := h.modelService.IsHealthy()
    if err != nil {
        status.Status = "DOWN"
        status.Details["model-service"] = fmt.Sprintf("Error: %s", err.Error())
        h.logger.Error("Model service health check failed", "error", err)
        return status
    }
    
    if isHealthy {
        status.Status = "UP"
        status.Details["model-service"] = "Available"
    } else {
        status.Status = "DOWN"
        status.Details["model-service"] = "Unavailable"
    }
    
    return status
}

// HealthController 健康检查控制器
type HealthController struct {
    checkers []HealthChecker
    logger   logger.Logger
}

// NewHealthController 创建健康检查控制器
func NewHealthController(checkers ...HealthChecker) *HealthController {
    return &HealthController{
        checkers: checkers,
        logger:   logger.NewLogger(),
    }
}

// Health 健康检查端点
func (c *HealthController) Health(ctx *gin.Context) {
    overallStatus := "UP"
    details := make(map[string]interface{})
    
    for _, checker := range c.checkers {
        status := checker.CheckHealth()
        if status.Status == "DOWN" {
            overallStatus = "DOWN"
        }
        details[reflect.TypeOf(checker).Elem().Name()] = status.Details
    }
    
    response := gin.H{
        "status":    overallStatus,
        "details":   details,
        "timestamp": time.Now(),
    }
    
    if overallStatus == "UP" {
        ctx.JSON(http.StatusOK, response)
    } else {
        ctx.JSON(http.StatusServiceUnavailable, response)
    }
}
```

### 6.2 链路追踪

#### 6.2.1 Jaeger配置
```yaml
# jaeger.yml
server:
  port: 14268

jaeger:
  endpoint: http://localhost:14268/api/traces
  sampler:
    type: const
    param: 1
  reporter:
    log_spans: true
    local_agent_host_port: localhost:6831
```

#### 6.2.2 链路追踪实现
```go
// Tracer 链路追踪器接口
type Tracer interface {
    StartSpan(name string, opts ...SpanOption) Span
    Inject(span Span, carrier interface{}) error
    Extract(carrier interface{}) (Span, error)
}

// Span 链路追踪跨度
type Span interface {
    SetTag(key, value string) Span
    SetBaggageItem(key, value string) Span
    Finish()
    Context() SpanContext
}

// SpanContext 跨度上下文
type SpanContext interface {
    TraceID() string
    SpanID() string
}

// UserController 用户控制器
type UserController struct {
    userService services.UserService
    tracer      Tracer
    logger      logger.Logger
}

// NewUserController 创建用户控制器
func NewUserController(userService services.UserService, tracer Tracer) *UserController {
    return &UserController{
        userService: userService,
        tracer:      tracer,
        logger:      logger.NewLogger(),
    }
}

// GetUser 获取用户信息
func (c *UserController) GetUser(ctx *gin.Context) {
    idStr := ctx.Param("id")
    id, err := strconv.ParseUint(idStr, 10, 32)
    if err != nil {
        ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid user id"})
        return
    }
    
    // 开始链路追踪
    span := c.tracer.StartSpan("get-user")
    defer span.Finish()
    
    // 设置标签
    span.SetTag("user.id", idStr)
    span.SetTag("http.method", "GET")
    span.SetTag("http.url", ctx.Request.URL.String())
    
    // 将span注入到上下文中
    ctx.Set("span", span)
    
    // 查找用户
    user, err := c.userService.FindByID(uint(id))
    if err != nil {
        span.SetTag("error", "true")
        span.SetTag("error.message", err.Error())
        c.logger.Error("Failed to find user", "user_id", id, "error", err)
        ctx.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
        return
    }
    
    // 设置成功标签
    span.SetTag("user.found", "true")
    span.SetTag("user.status", user.Status)
    
    ctx.JSON(http.StatusOK, user)
}

// TracingMiddleware 链路追踪中间件
func TracingMiddleware(tracer Tracer) gin.HandlerFunc {
    return func(ctx *gin.Context) {
        // 从请求头中提取追踪信息
        span, err := tracer.Extract(ctx.Request.Header)
        if err != nil {
            // 如果没有追踪信息，创建新的span
            span = tracer.StartSpan("http-request")
        }
        
        defer span.Finish()
        
        // 设置HTTP相关标签
        span.SetTag("http.method", ctx.Request.Method)
        span.SetTag("http.url", ctx.Request.URL.String())
        span.SetTag("http.user_agent", ctx.Request.UserAgent())
        
        // 将span存储到上下文中
        ctx.Set("span", span)
        
        // 继续处理请求
        ctx.Next()
        
        // 设置响应状态码
        span.SetTag("http.status_code", ctx.Writer.Status())
    }
}
```

### 6.3 日志管理

#### 6.3.1 结构化日志
```go
// InferenceController 推理控制器
type InferenceController struct {
    inferenceService services.InferenceService
    logger           logger.Logger
}

// NewInferenceController 创建推理控制器
func NewInferenceController(inferenceService services.InferenceService) *InferenceController {
    return &InferenceController{
        inferenceService: inferenceService,
        logger:           logger.NewLogger(),
    }
}

// Chat 聊天推理
func (c *InferenceController) Chat(ctx *gin.Context) {
    var req dto.InferenceRequest
    if err := ctx.ShouldBindJSON(&req); err != nil {
        c.logger.Error("Invalid inference request", "error", err)
        ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    // 设置请求上下文
    requestLogger := c.logger.WithFields(logger.Fields{
        "request_id": req.RequestID,
        "user_id":    req.UserID,
        "model":      req.Model,
    })
    
    requestLogger.Info("Processing inference request",
        "tokens_count", len(req.Tokens),
        "temperature", req.Temperature,
        "max_tokens", req.MaxTokens)
    
    startTime := time.Now()
    
    // 处理推理请求
    response, err := c.inferenceService.Process(&req)
    if err != nil {
        requestLogger.Error("Inference failed",
            "error", err,
            "duration", time.Since(startTime))
        ctx.JSON(http.StatusInternalServerError, gin.H{"error": "inference failed"})
        return
    }
    
    // 记录成功日志
    requestLogger.Info("Inference completed successfully",
        "response_time", time.Since(startTime),
        "tokens_generated", response.TokensGenerated,
        "finish_reason", response.FinishReason)
    
    ctx.JSON(http.StatusOK, response)
}

// LoggingMiddleware 日志中间件
func LoggingMiddleware(logger logger.Logger) gin.HandlerFunc {
    return func(ctx *gin.Context) {
        startTime := time.Now()
        requestID := ctx.GetHeader("X-Request-ID")
        if requestID == "" {
            requestID = generateRequestID()
        }
        
        // 设置请求上下文
        requestLogger := logger.WithFields(logger.Fields{
            "request_id": requestID,
            "method":     ctx.Request.Method,
            "path":       ctx.Request.URL.Path,
            "user_agent": ctx.Request.UserAgent(),
            "ip":         ctx.ClientIP(),
        })
        
        // 将logger存储到上下文中
        ctx.Set("logger", requestLogger)
        ctx.Set("request_id", requestID)
        
        // 记录请求开始
        requestLogger.Info("Request started")
        
        // 处理请求
        ctx.Next()
        
        // 记录请求完成
        requestLogger.Info("Request completed",
            "status_code", ctx.Writer.Status(),
            "duration", time.Since(startTime),
            "response_size", ctx.Writer.Size())
    }
}

// generateRequestID 生成请求ID
func generateRequestID() string {
    return fmt.Sprintf("%d-%d", time.Now().UnixNano(), rand.Intn(10000))
}
```

#### 6.3.2 日志配置
```go
// LogConfig 日志配置
type LogConfig struct {
    Level      string `yaml:"level"`
    Format     string `yaml:"format"`
    Output     string `yaml:"output"`
    FilePath   string `yaml:"file_path"`
    MaxSize    int    `yaml:"max_size"`
    MaxBackups int    `yaml:"max_backups"`
    MaxAge     int    `yaml:"max_age"`
}

// InitLogger 初始化日志
func InitLogger(config LogConfig) *logrus.Logger {
    logger := logrus.New()
    
    level, err := logrus.ParseLevel(config.Level)
    if err != nil {
        level = logrus.InfoLevel
    }
    logger.SetLevel(level)
    
    if config.Format == "json" {
        logger.SetFormatter(&logrus.JSONFormatter{
            TimestampFormat: time.RFC3339,
        })
    }
    
    if config.Output == "file" {
        writer, err := rotatelogs.New(
            config.FilePath+".%Y%m%d%H%M",
            rotatelogs.WithLinkName(config.FilePath),
            rotatelogs.WithMaxAge(time.Duration(config.MaxAge)*24*time.Hour),
            rotatelogs.WithRotationTime(time.Hour),
        )
        if err != nil {
            log.Fatal("Failed to create log file", err)
        }
        logger.SetOutput(writer)
    }
    
    return logger
}
```

## 七、安全设计

### 7.1 认证授权

#### 7.1.1 JWT Token管理
```go
// JWTTokenService JWT Token服务
type JWTTokenService struct {
    secretKey     string
    tokenValidity time.Duration
    logger        *logrus.Logger
}

// NewJWTTokenService 创建JWT Token服务
func NewJWTTokenService(secretKey string) *JWTTokenService {
    return &JWTTokenService{
        secretKey:     secretKey,
        tokenValidity: time.Hour,
        logger:        logrus.New(),
    }
}

// GenerateToken 生成JWT Token
func (s *JWTTokenService) GenerateToken(user *models.User) (string, error) {
    claims := jwt.MapClaims{
        "user_id":  user.ID,
        "username": user.Username,
        "roles":    user.Roles,
        "iat":      time.Now().Unix(),
        "exp":      time.Now().Add(s.tokenValidity).Unix(),
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS512, claims)
    tokenString, err := token.SignedString([]byte(s.secretKey))
    if err != nil {
        s.logger.Error("Failed to generate token", "error", err)
        return "", err
    }
    
    return tokenString, nil
}

// ValidateToken 验证JWT Token
func (s *JWTTokenService) ValidateToken(tokenString string) (*jwt.Token, error) {
    token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
        }
        return []byte(s.secretKey), nil
    })
    
    if err != nil {
        s.logger.Error("Failed to validate token", "error", err)
        return nil, err
    }
    
    return token, nil
}

// ExtractClaims 提取Token中的Claims
func (s *JWTTokenService) ExtractClaims(tokenString string) (jwt.MapClaims, error) {
    token, err := s.ValidateToken(tokenString)
    if err != nil {
        return nil, err
    }
    
    if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
        return claims, nil
    }
    
    return nil, fmt.Errorf("invalid token claims")
}
```

#### 7.1.2 权限控制
```go
// PermissionService 权限服务
type PermissionService struct {
    userRepo   repositories.UserRepository
    roleRepo   repositories.RoleRepository
    logger     *logrus.Logger
}

// NewPermissionService 创建权限服务
func NewPermissionService(userRepo repositories.UserRepository, roleRepo repositories.RoleRepository) *PermissionService {
    return &PermissionService{
        userRepo: userRepo,
        roleRepo: roleRepo,
        logger:   logrus.New(),
    }
}

// HasPermission 检查用户权限
func (s *PermissionService) HasPermission(userID uint, resource string, action string) (bool, error) {
    user, err := s.userRepo.GetByID(userID)
    if err != nil {
        return false, err
    }
    
    for _, role := range user.Roles {
        if s.roleRepo.HasPermission(role.ID, resource, action) {
            return true, nil
        }
    }
    
    return false, nil
}

// ProjectController 项目控制器
type ProjectController struct {
    projectService  services.ProjectService
    permissionService *PermissionService
    logger         *logrus.Logger
}

// GetProject 获取项目信息
func (c *ProjectController) GetProject(ctx *gin.Context) {
    projectIDStr := ctx.Param("id")
    projectID, err := strconv.ParseUint(projectIDStr, 10, 32)
    if err != nil {
        ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid project id"})
        return
    }
    
    // 获取当前用户ID
    userID := ctx.GetUint("user_id")
    
    // 检查权限
    hasPermission, err := c.permissionService.HasPermission(userID, "PROJECT", "READ")
    if err != nil || !hasPermission {
        ctx.JSON(http.StatusForbidden, gin.H{"error": "insufficient permissions"})
        return
    }
    
    project, err := c.projectService.GetByID(uint(projectID))
    if err != nil {
        ctx.JSON(http.StatusNotFound, gin.H{"error": "project not found"})
        return
    }
    
    ctx.JSON(http.StatusOK, project)
}

// ModelController 模型控制器
type ModelController struct {
    modelService     services.ModelService
    permissionService *PermissionService
    logger          *logrus.Logger
}

// CreateModel 创建模型
func (c *ModelController) CreateModel(ctx *gin.Context) {
    var req dto.CreateModelRequest
    if err := ctx.ShouldBindJSON(&req); err != nil {
        ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    // 获取当前用户ID
    userID := ctx.GetUint("user_id")
    
    // 检查权限
    hasPermission, err := c.permissionService.HasPermission(userID, "MODEL", "MANAGE")
    if err != nil || !hasPermission {
        ctx.JSON(http.StatusForbidden, gin.H{"error": "insufficient permissions"})
        return
    }
    
    model, err := c.modelService.Create(&req)
    if err != nil {
        ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create model"})
        return
    }
    
    ctx.JSON(http.StatusCreated, model)
}
```

### 7.2 数据加密

#### 7.2.1 敏感数据加密
```go
// EncryptionService 加密服务
type EncryptionService struct {
    key    []byte
    logger *logrus.Logger
}

// NewEncryptionService 创建加密服务
func NewEncryptionService(key string) *EncryptionService {
    return &EncryptionService{
        key:    []byte(key),
        logger: logrus.New(),
    }
}

// EncryptSensitiveData 加密敏感数据
func (s *EncryptionService) EncryptSensitiveData(data string) (string, error) {
    block, err := aes.NewCipher(s.key)
    if err != nil {
        s.logger.Error("Failed to create cipher", "error", err)
        return "", err
    }
    
    gcm, err := cipher.NewGCM(block)
    if err != nil {
        s.logger.Error("Failed to create GCM", "error", err)
        return "", err
    }
    
    nonce := make([]byte, gcm.NonceSize())
    if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
        s.logger.Error("Failed to generate nonce", "error", err)
        return "", err
    }
    
    ciphertext := gcm.Seal(nonce, nonce, []byte(data), nil)
    return base64.StdEncoding.EncodeToString(ciphertext), nil
}

// DecryptSensitiveData 解密敏感数据
func (s *EncryptionService) DecryptSensitiveData(encryptedData string) (string, error) {
    data, err := base64.StdEncoding.DecodeString(encryptedData)
    if err != nil {
        s.logger.Error("Failed to decode base64", "error", err)
        return "", err
    }
    
    block, err := aes.NewCipher(s.key)
    if err != nil {
        s.logger.Error("Failed to create cipher", "error", err)
        return "", err
    }
    
    gcm, err := cipher.NewGCM(block)
    if err != nil {
        s.logger.Error("Failed to create GCM", "error", err)
        return "", err
    }
    
    nonceSize := gcm.NonceSize()
    if len(data) < nonceSize {
        return "", fmt.Errorf("ciphertext too short")
    }
    
    nonce, ciphertext := data[:nonceSize], data[nonceSize:]
    plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
    if err != nil {
        s.logger.Error("Failed to decrypt", "error", err)
        return "", err
    }
    
    return string(plaintext), nil
}

// User 用户模型
type User struct {
    ID           uint   `json:"id" gorm:"primaryKey"`
    Username     string `json:"username" gorm:"uniqueIndex"`
    Email        string `json:"email" gorm:"uniqueIndex"`
    Phone        string `json:"phone"`
    PasswordHash string `json:"-" gorm:"column:password_hash"`
    CreatedAt    time.Time `json:"created_at"`
    UpdatedAt    time.Time `json:"updated_at"`
}

// BeforeCreate GORM钩子：创建前加密敏感数据
func (u *User) BeforeCreate(tx *gorm.DB) error {
    encryptionService := NewEncryptionService("your-secret-key")
    
    if u.Email != "" {
        encryptedEmail, err := encryptionService.EncryptSensitiveData(u.Email)
        if err != nil {
            return err
        }
        u.Email = encryptedEmail
    }
    
    if u.Phone != "" {
        encryptedPhone, err := encryptionService.EncryptSensitiveData(u.Phone)
        if err != nil {
            return err
        }
        u.Phone = encryptedPhone
    }
    
    return nil
}

// AfterFind GORM钩子：查询后解密敏感数据
func (u *User) AfterFind(tx *gorm.DB) error {
    encryptionService := NewEncryptionService("your-secret-key")
    
    if u.Email != "" {
        decryptedEmail, err := encryptionService.DecryptSensitiveData(u.Email)
        if err != nil {
            return err
        }
        u.Email = decryptedEmail
    }
    
    if u.Phone != "" {
        decryptedPhone, err := encryptionService.DecryptSensitiveData(u.Phone)
        if err != nil {
            return err
        }
        u.Phone = decryptedPhone
    }
    
    return nil
}
```

### 7.3 网络安全

#### 7.3.1 HTTPS配置
```go
// HTTPSConfig HTTPS配置
type HTTPSConfig struct {
    CertFile string `yaml:"cert_file"`
    KeyFile  string `yaml:"key_file"`
    Port     int    `yaml:"port"`
}

// ServerConfig 服务器配置
type ServerConfig struct {
    Host string     `yaml:"host"`
    Port int        `yaml:"port"`
    HTTPS HTTPSConfig `yaml:"https"`
}

// StartHTTPS 启动HTTPS服务器
func StartHTTPS(config ServerConfig, router *gin.Engine) error {
    if config.HTTPS.CertFile == "" || config.HTTPS.KeyFile == "" {
        return fmt.Errorf("HTTPS certificate files not configured")
    }
    
    addr := fmt.Sprintf("%s:%d", config.Host, config.HTTPS.Port)
    logrus.Info("Starting HTTPS server", "address", addr)
    
    return router.RunTLS(addr, config.HTTPS.CertFile, config.HTTPS.KeyFile)
}
```

#### 7.3.2 防火墙规则
```bash
# iptables规则
# 允许HTTPS流量
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 允许内部服务通信
iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT

# 拒绝其他入站流量
iptables -A INPUT -j DROP
```

## 八、性能优化

### 8.1 缓存策略

#### 8.1.1 多级缓存
```go
// CacheService 缓存服务
type CacheService struct {
    redis  *redis.Client
    logger *logrus.Logger
}

// NewCacheService 创建缓存服务
func NewCacheService(redis *redis.Client) *CacheService {
    return &CacheService{
        redis:  redis,
        logger: logrus.New(),
    }
}

// GetModel 获取模型（带缓存）
func (s *CacheService) GetModel(modelID uint) (*models.Model, error) {
    cacheKey := fmt.Sprintf("model:%d", modelID)
    
    // 尝试从缓存获取
    cachedData, err := s.redis.Get(cacheKey).Result()
    if err == nil {
        var model models.Model
        if err := json.Unmarshal([]byte(cachedData), &model); err == nil {
            s.logger.Debug("Cache hit", "key", cacheKey)
            return &model, nil
        }
    }
    
    // 缓存未命中，从数据库获取
    s.logger.Debug("Cache miss", "key", cacheKey)
    model, err := s.getModelFromDB(modelID)
    if err != nil {
        return nil, err
    }
    
    // 写入缓存
    if modelData, err := json.Marshal(model); err == nil {
        s.redis.Set(cacheKey, modelData, time.Hour)
    }
    
    return model, nil
}

// UpdateModel 更新模型（清除缓存）
func (s *CacheService) UpdateModel(model *models.Model) error {
    // 更新数据库
    if err := s.updateModelInDB(model); err != nil {
        return err
    }
    
    // 清除缓存
    cacheKey := fmt.Sprintf("model:%d", model.ID)
    s.redis.Del(cacheKey)
    s.logger.Debug("Cache invalidated", "key", cacheKey)
    
    return nil
}

// getModelFromDB 从数据库获取模型
func (s *CacheService) getModelFromDB(modelID uint) (*models.Model, error) {
    // 实现数据库查询逻辑
    return &models.Model{}, nil
}

// updateModelInDB 在数据库中更新模型
func (s *CacheService) updateModelInDB(model *models.Model) error {
    // 实现数据库更新逻辑
    return nil
}
```

#### 8.1.2 缓存预热
```go
// CacheWarmupService 缓存预热服务
type CacheWarmupService struct {
    modelService services.ModelService
    cacheService *CacheService
    logger       *logrus.Logger
}

// NewCacheWarmupService 创建缓存预热服务
func NewCacheWarmupService(modelService services.ModelService, cacheService *CacheService) *CacheWarmupService {
    return &CacheWarmupService{
        modelService: modelService,
        cacheService: cacheService,
        logger:       logrus.New(),
    }
}

// WarmupCache 预热缓存
func (s *CacheWarmupService) WarmupCache() error {
    s.logger.Info("Starting cache warmup")
    
    // 预热热门模型缓存
    popularModels, err := s.modelService.GetPopularModels()
    if err != nil {
        s.logger.Error("Failed to get popular models", "error", err)
        return err
    }
    
    for _, model := range popularModels {
        if _, err := s.cacheService.GetModel(model.ID); err != nil {
            s.logger.Error("Failed to warmup model cache", "model_id", model.ID, "error", err)
        } else {
            s.logger.Debug("Model cache warmed up", "model_id", model.ID)
        }
    }
    
    s.logger.Info("Cache warmup completed", "models_count", len(popularModels))
    return nil
}

// StartWarmup 启动预热（应用启动时调用）
func (s *CacheWarmupService) StartWarmup() {
    go func() {
        // 延迟5秒后开始预热，确保服务完全启动
        time.Sleep(5 * time.Second)
        if err := s.WarmupCache(); err != nil {
            s.logger.Error("Cache warmup failed", "error", err)
        }
    }()
}
```

### 8.2 数据库优化

#### 8.2.1 连接池配置
```go
// DatabaseConfig 数据库配置
type DatabaseConfig struct {
    Host            string        `yaml:"host"`
    Port            int           `yaml:"port"`
    User            string        `yaml:"user"`
    Password        string        `yaml:"password"`
    DBName          string        `yaml:"dbname"`
    SSLMode         string        `yaml:"sslmode"`
    MaxOpenConns    int           `yaml:"max_open_conns"`
    MaxIdleConns    int           `yaml:"max_idle_conns"`
    ConnMaxLifetime time.Duration `yaml:"conn_max_lifetime"`
    ConnMaxIdleTime time.Duration `yaml:"conn_max_idle_time"`
}

// InitDatabase 初始化数据库连接
func InitDatabase(config DatabaseConfig) (*gorm.DB, error) {
    dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
        config.Host, config.Port, config.User, config.Password, config.DBName, config.SSLMode)
    
    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
        Logger: logger.Default.LogMode(logger.Info),
    })
    if err != nil {
        return nil, err
    }
    
    sqlDB, err := db.DB()
    if err != nil {
        return nil, err
    }
    
    // 配置连接池
    sqlDB.SetMaxOpenConns(config.MaxOpenConns)
    sqlDB.SetMaxIdleConns(config.MaxIdleConns)
    sqlDB.SetConnMaxLifetime(config.ConnMaxLifetime)
    sqlDB.SetConnMaxIdleTime(config.ConnMaxIdleTime)
    
    return db, nil
}
```

#### 8.2.2 查询优化
```go
// UserRepository 用户仓储
type UserRepository struct {
    db     *gorm.DB
    logger *logrus.Logger
}

// NewUserRepository 创建用户仓储
func NewUserRepository(db *gorm.DB) *UserRepository {
    return &UserRepository{
        db:     db,
        logger: logrus.New(),
    }
}

// FindActiveUserByEmail 查找活跃用户（带缓存提示）
func (r *UserRepository) FindActiveUserByEmail(email string) (*models.User, error) {
    var user models.User
    
    // 使用索引优化查询
    err := r.db.Where("email = ? AND status = ?", email, "ACTIVE").
        First(&user).Error
    
    if err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, nil
        }
        r.logger.Error("Failed to find active user by email", "email", email, "error", err)
        return nil, err
    }
    
    return &user, nil
}

// FindRecentUsers 查找最近用户
func (r *UserRepository) FindRecentUsers(since time.Time, limit int) ([]*models.User, error) {
    var users []*models.User
    
    err := r.db.Where("created_at >= ?", since).
        Order("created_at DESC").
        Limit(limit).
        Find(&users).Error
    
    if err != nil {
        r.logger.Error("Failed to find recent users", "since", since, "limit", limit, "error", err)
        return nil, err
    }
    
    return users, nil
}

// FindUsersWithPagination 分页查询用户
func (r *UserRepository) FindUsersWithPagination(page, pageSize int, filters map[string]interface{}) ([]*models.User, int64, error) {
    var users []*models.User
    var total int64
    
    query := r.db.Model(&models.User{})
    
    // 应用过滤条件
    for key, value := range filters {
        query = query.Where(fmt.Sprintf("%s = ?", key), value)
    }
    
    // 获取总数
    if err := query.Count(&total).Error; err != nil {
        return nil, 0, err
    }
    
    // 分页查询
    offset := (page - 1) * pageSize
    err := query.Offset(offset).Limit(pageSize).
        Order("created_at DESC").
        Find(&users).Error
    
    if err != nil {
        r.logger.Error("Failed to find users with pagination", "page", page, "pageSize", pageSize, "error", err)
        return nil, 0, err
    }
    
    return users, total, nil
}
```

### 8.3 异步处理

#### 8.3.1 异步任务
```go
// InferenceService 推理服务
type InferenceService struct {
    workerPool *WorkerPool
    logger     *logrus.Logger
}

// NewInferenceService 创建推理服务
func NewInferenceService() *InferenceService {
    return &InferenceService{
        workerPool: NewWorkerPool(10, 50, 100),
        logger:     logrus.New(),
    }
}

// ProcessAsync 异步处理推理请求
func (s *InferenceService) ProcessAsync(request *dto.InferenceRequest) <-chan *dto.InferenceResult {
    resultChan := make(chan *dto.InferenceResult, 1)
    
    s.workerPool.Submit(func() {
        defer close(resultChan)
        
        result, err := s.processInference(request)
        if err != nil {
            s.logger.Error("Inference processing failed", "error", err)
            resultChan <- &dto.InferenceResult{Error: err}
            return
        }
        
        resultChan <- result
    })
    
    return resultChan
}

// processInference 执行推理
func (s *InferenceService) processInference(request *dto.InferenceRequest) (*dto.InferenceResult, error) {
    // 实现推理逻辑
    s.logger.Info("Processing inference request", "request_id", request.RequestID)
    
    // 模拟推理处理
    time.Sleep(time.Second * 2)
    
    return &dto.InferenceResult{
        RequestID: request.RequestID,
        Result:    "Inference completed",
        Tokens:    100,
    }, nil
}

// WorkerPool 工作池
type WorkerPool struct {
    workers    int
    maxWorkers int
    queueSize  int
    taskQueue  chan func()
    quit       chan bool
    wg         sync.WaitGroup
}

// NewWorkerPool 创建工作池
func NewWorkerPool(workers, maxWorkers, queueSize int) *WorkerPool {
    wp := &WorkerPool{
        workers:    workers,
        maxWorkers: maxWorkers,
        queueSize:  queueSize,
        taskQueue:  make(chan func(), queueSize),
        quit:       make(chan bool),
    }
    
    // 启动工作协程
    for i := 0; i < workers; i++ {
        wp.wg.Add(1)
        go wp.worker(i)
    }
    
    return wp
}

// Submit 提交任务
func (wp *WorkerPool) Submit(task func()) {
    select {
    case wp.taskQueue <- task:
        // 任务已提交
    default:
        // 队列已满，可以考虑拒绝或等待
        go func() {
            wp.taskQueue <- task
        }()
    }
}

// worker 工作协程
func (wp *WorkerPool) worker(id int) {
    defer wp.wg.Done()
    
    for {
        select {
        case task := <-wp.taskQueue:
            task()
        case <-wp.quit:
            return
        }
    }
}

// Shutdown 关闭工作池
func (wp *WorkerPool) Shutdown() {
    close(wp.quit)
    wp.wg.Wait()
}
```

## 九、部署架构

### 9.1 容器化部署

#### 9.1.1 Dockerfile
```dockerfile
# Dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app

# 复制go mod文件
COPY go.mod go.sum ./
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/user-service

# 运行阶段
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

# 复制构建的二进制文件
COPY --from=builder /app/main .

# 复制配置文件
COPY --from=builder /app/configs ./configs

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/health || exit 1

CMD ["./main"]
```

#### 9.1.2 Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  consul:
    image: consul:1.15
    ports:
      - "8500:8500"
    command: agent -server -bootstrap-expect=1 -ui -client=0.0.0.0
    
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: llmops
      POSTGRES_USER: llmops
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
      
  user-service:
    build: ./user-service
    ports:
      - "8081:8081"
    environment:
      - ENVIRONMENT=docker
      - CONSUL_HOST=consul
      - DB_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - consul
      - postgres
      - redis
      
  project-service:
    build: ./project-service
    ports:
      - "8082:8082"
    environment:
      - ENVIRONMENT=docker
      - CONSUL_HOST=consul
      - DB_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - consul
      - postgres
      - redis
      
  model-service:
    build: ./model-service
    ports:
      - "8083:8083"
    environment:
      - ENVIRONMENT=docker
      - CONSUL_HOST=consul
      - DB_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - consul
      - postgres
      - redis

volumes:
  postgres_data:
  redis_data:
```

### 9.2 Kubernetes部署

#### 9.2.1 Deployment配置
```yaml
# user-service-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  labels:
    app: user-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: llmops/user-service:1.0.0
        ports:
        - containerPort: 8081
        env:
        - name: ENVIRONMENT
          value: "k8s"
        - name: CONSUL_HOST
          value: "consul-service"
        - name: DB_HOST
          value: "postgres-service"
        - name: REDIS_HOST
          value: "redis-service"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8081
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8081
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### 9.2.2 Service配置
```yaml
# user-service-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8081
  type: ClusterIP
```

#### 9.2.3 Ingress配置
```yaml
# api-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - api.llmops.com
    secretName: api-tls
  rules:
  - host: api.llmops.com
    http:
      paths:
      - path: /api/v1/users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 80
      - path: /api/v1/projects
        pathType: Prefix
        backend:
          service:
            name: project-service
            port:
              number: 80
```

## 十、总结

### 10.1 架构优势

1. **高可用性**: 服务冗余、故障隔离、自动恢复
2. **可扩展性**: 水平扩展、独立部署、弹性伸缩
3. **可维护性**: 模块化设计、清晰边界、独立演进
4. **性能优化**: 缓存策略、异步处理、负载均衡
5. **安全可靠**: 多层防护、数据加密、访问控制

### 10.2 技术特点

- **微服务架构**: 8个核心业务服务 + 4个基础设施服务
- **多语言支持**: Go Gin (主要) + Python FastAPI (AI/ML服务)
- **多数据库**: PostgreSQL + MongoDB + Redis + ChromaDB
- **容器化部署**: Docker + Kubernetes
- **服务治理**: Consul + Kong + Zipkin

### 10.3 部署规模

- **服务实例**: 50+ 个微服务实例
- **数据库**: 10+ 个数据库实例
- **缓存**: 5+ 个Redis集群
- **消息队列**: 3+ 个Kafka集群
- **存储**: 分布式文件存储系统

---

**文档维护**: 本文档应随系统架构变化持续更新，保持与系统实现的一致性。

**版本历史**:
- v1.0 (2025-10-17): 初始版本，微服务架构详细设计

