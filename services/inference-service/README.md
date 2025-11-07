# 推理服务 (Inference Service)

## 服务概述

推理服务是LLMOps平台的核心推理引擎，负责处理模型推理请求、负载均衡、性能监控等功能。支持多种模型框架和推理方式。

## 技术栈

- **语言**: Python 3.9+
- **框架**: FastAPI
- **推理引擎**: vLLM, Transformers, ONNX Runtime
- **数据库**: PostgreSQL
- **缓存**: Redis
- **端口**: 8084

## 功能特性

### 核心功能
- ✅ **模型推理**: 支持多种模型框架的推理
- ✅ **负载均衡**: 智能请求分发和负载均衡
- ✅ **性能监控**: 推理性能指标监控
- ✅ **缓存管理**: 推理结果缓存和优化
- ✅ **并发控制**: 请求并发限制和队列管理
- ✅ **模型热加载**: 动态模型加载和卸载

### 技术特性
- ✅ **微服务架构**: 独立部署和扩展
- ✅ **服务发现**: Consul注册和发现
- ✅ **健康检查**: 服务健康状态监控
- ✅ **API文档**: 自动生成Swagger文档
- ✅ **异步处理**: 异步推理请求处理
- ✅ **GPU支持**: 支持GPU加速推理

## 服务架构

### 分层架构
```
┌─────────────────┐
│   API层         │  FastAPI路由和请求处理
├─────────────────┤
│   Service层      │  业务逻辑处理
├─────────────────┤
│   Engine层       │  推理引擎管理
├─────────────────┤
│   Model层        │  数据模型定义
└─────────────────┘
```

### 核心组件

#### 1. 数据模型 (Models)
- **InferenceRequest**: 推理请求实体
- **InferenceResponse**: 推理响应实体
- **ModelInstance**: 模型实例实体
- **InferenceSession**: 推理会话实体
- **InferenceMetric**: 推理指标实体

#### 2. 推理引擎 (Engine)
- **vLLMEngine**: vLLM推理引擎
- **TransformersEngine**: Transformers推理引擎
- **ONNXEngine**: ONNX推理引擎
- **ModelManager**: 模型管理器

#### 3. 服务层 (Service)
- **InferenceService**: 推理业务逻辑
- **ModelService**: 模型管理业务逻辑
- **MetricsService**: 指标收集业务逻辑

#### 4. API层 (API)
- **InferenceAPI**: 推理HTTP请求处理
- **ModelAPI**: 模型管理HTTP请求处理
- **MetricsAPI**: 指标查询HTTP请求处理

## API接口

### 推理接口
- `POST /api/v1/inference/{model_id}` - 模型推理
- `POST /api/v1/inference/{model_id}/batch` - 批量推理
- `POST /api/v1/inference/{model_id}/stream` - 流式推理
- `GET /api/v1/inference/{model_id}/status` - 推理状态

### 模型管理接口
- `POST /api/v1/models/{model_id}/load` - 加载模型
- `POST /api/v1/models/{model_id}/unload` - 卸载模型
- `GET /api/v1/models/{model_id}/info` - 获取模型信息
- `GET /api/v1/models` - 获取可用模型列表

### 指标接口
- `GET /api/v1/metrics` - 获取推理指标
- `GET /api/v1/metrics/{model_id}` - 获取模型指标
- `GET /api/v1/metrics/health` - 健康检查指标

## 数据库设计

### 核心表结构

#### inference_requests表
```sql
CREATE TABLE inference_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL,
    session_id UUID,
    request_data JSONB NOT NULL,
    response_data JSONB,
    status VARCHAR(50) DEFAULT 'pending',
    processing_time_ms INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);
```

#### model_instances表
```sql
CREATE TABLE model_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL,
    instance_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'loading',
    gpu_memory_used BIGINT,
    cpu_usage FLOAT,
    memory_usage FLOAT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## 部署配置

### Docker配置
```dockerfile
FROM nvidia/cuda:11.8-devel-ubuntu20.04

WORKDIR /app

# 安装Python和依赖
RUN apt-get update && apt-get install -y python3.9 python3-pip
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8084"]
```

### Docker Compose配置
```yaml
inference-service:
  build: ./services/inference-service
  ports:
    - "8084:8084"
  environment:
    - DB_HOST=postgres
    - DB_PORT=5432
    - DB_NAME=inference_db
    - DB_USER=user
    - DB_PASSWORD=password
    - REDIS_HOST=redis
    - REDIS_PORT=6379
    - CONSUL_HOST=consul
    - CONSUL_PORT=8500
  volumes:
    - model_cache:/app/cache
    - model_models:/app/models
  depends_on:
    - postgres
    - redis
    - consul
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
```

## 开发指南

### 本地开发
```bash
# 克隆项目
git clone <repository-url>
cd services/inference-service

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或
venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt

# 启动服务
uvicorn app.main:app --reload --port 8084
```

### 测试
```bash
# 运行单元测试
pytest

# 运行集成测试
pytest tests/integration/

# 测试覆盖率
pytest --cov=app tests/
```

### 构建部署
```bash
# 构建Docker镜像
docker build -t llmops/inference-service:latest .

# 推送到镜像仓库
docker push llmops/inference-service:latest
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
- 推理请求数量和响应时间
- 模型加载状态和内存使用
- GPU利用率和温度
- 错误率和成功率

## 安全考虑

### 数据安全
- 推理数据加密传输
- 敏感数据脱敏
- 模型文件安全存储
- 传输层安全

### 访问控制
- JWT token认证
- 基于角色的权限控制
- API限流和防护
- 跨域资源共享

### 审计日志
- 推理请求记录
- 模型使用统计
- 性能指标记录
- 安全事件记录

## 扩展性

### 水平扩展
- 无状态设计
- 负载均衡支持
- 数据库读写分离
- 缓存集群支持

### 功能扩展
- 支持更多模型框架
- 支持更多推理方式
- 支持模型优化
- 支持分布式推理

---

**文档版本**: 1.0.0  
**创建时间**: 2024-01-01  
**更新时间**: 2024-01-01  
**维护者**: LLMOps开发团队



