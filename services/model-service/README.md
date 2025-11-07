# 模型管理服务 (Model Service)

## 服务概述

模型管理服务是LLMOps平台的核心服务，负责模型注册、版本管理、部署管理、性能监控等功能。支持多种模型框架和部署方式。

## 技术栈

- **语言**: Python 3.9+
- **框架**: FastAPI
- **ORM**: SQLAlchemy
- **数据库**: PostgreSQL
- **缓存**: Redis
- **端口**: 8083

## 功能特性

### 核心功能
- ✅ **模型注册**: 支持多种模型框架注册
- ✅ **版本管理**: 模型版本控制和回滚
- ✅ **部署管理**: 模型部署和扩缩容
- ✅ **性能监控**: 模型性能指标监控
- ✅ **模型市场**: 公共模型库和私有模型库
- ✅ **模型评测**: 模型性能评测和基准测试

### 技术特性
- ✅ **微服务架构**: 独立部署和扩展
- ✅ **服务发现**: Consul注册和发现
- ✅ **健康检查**: 服务健康状态监控
- ✅ **API文档**: 自动生成Swagger文档
- ✅ **数据验证**: Pydantic数据验证
- ✅ **异步支持**: 异步请求处理

## 服务架构

### 分层架构
```
┌─────────────────┐
│   API层         │  FastAPI路由和请求处理
├─────────────────┤
│   Service层      │  业务逻辑处理
├─────────────────┤
│   Repository层   │  数据访问层
├─────────────────┤
│   Model层        │  数据模型定义
└─────────────────┘
```

### 核心组件

#### 1. 数据模型 (Models)
- **Model**: 模型实体
- **ModelVersion**: 模型版本实体
- **ModelDeployment**: 模型部署实体
- **ModelEvaluation**: 模型评测实体
- **ModelMetric**: 模型指标实体

#### 2. 仓储层 (Repository)
- **ModelRepository**: 模型数据访问
- **ModelVersionRepository**: 模型版本数据访问
- **ModelDeploymentRepository**: 模型部署数据访问

#### 3. 服务层 (Service)
- **ModelService**: 模型业务逻辑
- **ModelVersionService**: 模型版本业务逻辑
- **ModelDeploymentService**: 模型部署业务逻辑

#### 4. API层 (API)
- **ModelAPI**: 模型HTTP请求处理
- **ModelVersionAPI**: 模型版本HTTP请求处理
- **ModelDeploymentAPI**: 模型部署HTTP请求处理

## API接口

### 模型管理接口
- `POST /api/v1/models` - 注册模型
- `GET /api/v1/models/{id}` - 获取模型详情
- `PUT /api/v1/models/{id}` - 更新模型
- `DELETE /api/v1/models/{id}` - 删除模型
- `GET /api/v1/models` - 获取模型列表
- `GET /api/v1/models/search` - 搜索模型

### 模型版本接口
- `POST /api/v1/models/{id}/versions` - 创建模型版本
- `GET /api/v1/models/{id}/versions` - 获取模型版本列表
- `GET /api/v1/models/{id}/versions/{version}` - 获取模型版本详情
- `PUT /api/v1/models/{id}/versions/{version}` - 更新模型版本
- `DELETE /api/v1/models/{id}/versions/{version}` - 删除模型版本

### 模型部署接口
- `POST /api/v1/models/{id}/deploy` - 部署模型
- `GET /api/v1/models/{id}/deployments` - 获取部署列表
- `PUT /api/v1/models/{id}/deployments/{deployment_id}` - 更新部署
- `DELETE /api/v1/models/{id}/deployments/{deployment_id}` - 删除部署
- `POST /api/v1/models/{id}/deployments/{deployment_id}/scale` - 扩缩容

### 模型评测接口
- `POST /api/v1/models/{id}/evaluate` - 评测模型
- `GET /api/v1/models/{id}/evaluations` - 获取评测结果
- `GET /api/v1/models/{id}/metrics` - 获取模型指标

## 数据库设计

### 核心表结构

#### models表
```sql
CREATE TABLE models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    framework VARCHAR(100) NOT NULL,
    task_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    owner_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    is_public BOOLEAN DEFAULT false,
    tags TEXT[],
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);
```

#### model_versions表
```sql
CREATE TABLE model_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    file_path VARCHAR(500),
    file_size BIGINT,
    checksum VARCHAR(64),
    status VARCHAR(50) DEFAULT 'active',
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(model_id, version)
);
```

## 部署配置

### Docker配置
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8083"]
```

### Docker Compose配置
```yaml
model-service:
  build: ./services/model-service
  ports:
    - "8083:8083"
  environment:
    - DB_HOST=postgres
    - DB_PORT=5432
    - DB_NAME=model_db
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
cd services/model-service

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或
venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt

# 启动服务
uvicorn app.main:app --reload --port 8083
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
docker build -t llmops/model-service:latest .

# 推送到镜像仓库
docker push llmops/model-service:latest
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
- 模型部署状态

## 安全考虑

### 数据安全
- 模型文件加密存储
- 敏感数据脱敏
- 数据库连接加密
- 传输层安全

### 访问控制
- JWT token认证
- 基于角色的权限控制
- API限流和防护
- 跨域资源共享

### 审计日志
- 模型操作记录
- 部署变更追踪
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
- 支持更多部署方式
- 支持模型市场
- 支持模型评测

---

**文档版本**: 1.0.0  
**创建时间**: 2024-01-01  
**更新时间**: 2024-01-01  
**维护者**: LLMOps开发团队



