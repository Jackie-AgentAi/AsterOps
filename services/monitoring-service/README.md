# 监控服务 (Monitoring Service)

## 服务概述

监控服务是LLMOps平台的核心监控服务，负责系统监控、告警管理、性能分析、日志聚合等功能。提供全方位的监控和运维能力。

## 技术栈

- **语言**: Python 3.9+
- **框架**: FastAPI
- **监控**: Prometheus + Grafana
- **数据库**: PostgreSQL
- **缓存**: Redis
- **端口**: 8086

## 功能特性

### 核心功能
- ✅ **系统监控**: 服务健康状态、性能指标监控
- ✅ **告警管理**: 智能告警规则、告警通知
- ✅ **性能分析**: 性能指标分析、趋势预测
- ✅ **日志聚合**: 日志收集、分析、检索
- ✅ **仪表板**: 可视化监控仪表板
- ✅ **运维自动化**: 自动故障恢复、扩缩容

### 技术特性
- ✅ **微服务架构**: 独立部署和扩展
- ✅ **服务发现**: Consul注册和发现
- ✅ **健康检查**: 服务健康状态监控
- ✅ **API文档**: 自动生成Swagger文档
- ✅ **实时监控**: 实时指标收集和展示
- ✅ **智能告警**: 基于机器学习的智能告警

## 服务架构

### 分层架构
```
┌─────────────────┐
│   API层         │  FastAPI路由和请求处理
├─────────────────┤
│   Service层      │  业务逻辑处理
├─────────────────┤
│   Monitor层      │  监控指标收集
├─────────────────┤
│   Model层        │  数据模型定义
└─────────────────┘
```

### 核心组件

#### 1. 数据模型 (Models)
- **Metric**: 监控指标实体
- **Alert**: 告警实体
- **Dashboard**: 仪表板实体
- **LogEntry**: 日志条目实体
- **ServiceHealth**: 服务健康实体

#### 2. 监控引擎 (Monitor)
- **PrometheusCollector**: Prometheus指标收集器
- **GrafanaDashboard**: Grafana仪表板管理
- **AlertManager**: 告警管理器
- **LogAggregator**: 日志聚合器

#### 3. 服务层 (Service)
- **MonitoringService**: 监控业务逻辑
- **AlertService**: 告警业务逻辑
- **DashboardService**: 仪表板业务逻辑
- **LogService**: 日志业务逻辑

#### 4. API层 (API)
- **MonitoringAPI**: 监控HTTP请求处理
- **AlertAPI**: 告警HTTP请求处理
- **DashboardAPI**: 仪表板HTTP请求处理
- **LogAPI**: 日志HTTP请求处理

## API接口

### 监控接口
- `GET /api/v1/metrics` - 获取监控指标
- `GET /api/v1/metrics/{service_id}` - 获取服务指标
- `GET /api/v1/health` - 获取服务健康状态
- `GET /api/v1/health/{service_id}` - 获取特定服务健康状态

### 告警接口
- `GET /api/v1/alerts` - 获取告警列表
- `POST /api/v1/alerts` - 创建告警规则
- `PUT /api/v1/alerts/{id}` - 更新告警规则
- `DELETE /api/v1/alerts/{id}` - 删除告警规则
- `POST /api/v1/alerts/{id}/acknowledge` - 确认告警

### 仪表板接口
- `GET /api/v1/dashboards` - 获取仪表板列表
- `POST /api/v1/dashboards` - 创建仪表板
- `GET /api/v1/dashboards/{id}` - 获取仪表板详情
- `PUT /api/v1/dashboards/{id}` - 更新仪表板
- `DELETE /api/v1/dashboards/{id}` - 删除仪表板

### 日志接口
- `GET /api/v1/logs` - 获取日志列表
- `GET /api/v1/logs/search` - 搜索日志
- `GET /api/v1/logs/export` - 导出日志
- `GET /api/v1/logs/aggregate` - 日志聚合分析

## 数据库设计

### 核心表结构

#### metrics表
```sql
CREATE TABLE metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id VARCHAR(255) NOT NULL,
    metric_name VARCHAR(255) NOT NULL,
    metric_value DECIMAL(15,4) NOT NULL,
    metric_unit VARCHAR(50),
    labels JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### alerts表
```sql
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    service_id VARCHAR(255) NOT NULL,
    metric_name VARCHAR(255) NOT NULL,
    threshold DECIMAL(15,4) NOT NULL,
    operator VARCHAR(10) NOT NULL,
    duration INTERVAL,
    severity VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## 部署配置

### Docker配置
```dockerfile
FROM python:3.9-slim

WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 创建非root用户
RUN useradd --create-home --shell /bin/bash appuser && \
    chown -R appuser:appuser /app

# 切换到非root用户
USER appuser

# 暴露端口
EXPOSE 8086

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8086/health || exit 1

# 启动应用
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8086"]
```

### Docker Compose配置
```yaml
monitoring-service:
  build: ./services/monitoring-service
  ports:
    - "8086:8086"
  environment:
    - DB_HOST=postgres
    - DB_PORT=5432
    - DB_NAME=monitoring_db
    - DB_USER=user
    - DB_PASSWORD=password
    - REDIS_HOST=redis
    - REDIS_PORT=6379
    - CONSUL_HOST=consul
    - CONSUL_PORT=8500
    - PROMETHEUS_HOST=prometheus
    - PROMETHEUS_PORT=9090
    - GRAFANA_HOST=grafana
    - GRAFANA_PORT=3000
  volumes:
    - monitoring_data:/app/data
    - monitoring_logs:/app/logs
  depends_on:
    - postgres
    - redis
    - consul
    - prometheus
    - grafana
  networks:
    - llmops-network
  restart: unless-stopped
```

## 开发指南

### 本地开发
```bash
# 克隆项目
git clone <repository-url>
cd services/monitoring-service

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或
venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt

# 启动服务
uvicorn app.main:app --reload --port 8086
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
docker build -t llmops/monitoring-service:latest .

# 推送到镜像仓库
docker push llmops/monitoring-service:latest
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
- 服务健康状态
- 性能指标收集
- 告警规则执行
- 日志处理量

## 安全考虑

### 数据安全
- 监控数据加密存储
- 敏感数据脱敏
- 数据库连接加密
- 传输层安全

### 访问控制
- JWT token认证
- 基于角色的权限控制
- API限流和防护
- 跨域资源共享

### 审计日志
- 监控操作记录
- 告警规则变更
- 仪表板访问记录
- 安全事件记录

## 扩展性

### 水平扩展
- 无状态设计
- 负载均衡支持
- 数据库读写分离
- 缓存集群支持

### 功能扩展
- 支持更多监控指标
- 支持更多告警方式
- 支持更多可视化组件
- 支持更多日志格式

---

**文档版本**: 1.0.0  
**创建时间**: 2024-01-01  
**更新时间**: 2024-01-01  
**维护者**: LLMOps开发团队



