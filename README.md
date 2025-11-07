# LLMOps运营管理平台

## 项目概述

LLMOps运营管理平台是一个基于微服务架构的LLM运营管理平台，提供用户管理、项目管理、模型管理、推理服务、成本管理等核心功能。

## 架构设计

### 微服务架构
```
┌─────────────────────────────────────────────────────────────┐
│                        API Gateway                          │
│                    (Kong/Nginx/Envoy)                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
┌───▼───┐         ┌───▼───┐         ┌───▼───┐
│ User  │         │Project│         │ Model │
│Service│         │Service│         │Service│
│ :8081 │         │ :8082 │         │ :8083 │
└───────┘         └───────┘         └───────┘
    │                 │                 │
┌───▼───┐         ┌───▼───┐         ┌───▼───┐
│ User  │         │Project│         │ Model │
│  DB   │         │  DB   │         │  DB   │
└───────┘         └───────┘         └───────┘

┌─────────────────────────────────────────────────────────────┐
│                    Shared Infrastructure                     │
│  Redis Cache  │  Message Queue  │  Service Discovery        │
└─────────────────────────────────────────────────────────────┘
```

## 项目结构

```
AsterOps/
├── services/                    # 微服务目录
│   ├── user-service/           # 用户权限服务 (端口: 8081)
│   ├── project-service/        # 项目管理服务 (端口: 8082)
│   ├── model-service/          # 模型管理服务 (端口: 8083)
│   ├── inference-service/       # 推理服务 (端口: 8084)
│   ├── cost-service/           # 成本管理服务 (端口: 8085)
│   └── monitoring-service/     # 监控服务 (端口: 8086)
├── infrastructure/             # 基础设施
│   ├── api-gateway/           # API网关
│   ├── service-discovery/     # 服务发现
│   ├── monitoring/            # 监控系统
│   └── deployment/            # 部署配置
├── shared/                     # 共享组件
│   ├── pkg/                   # 共享包
│   ├── proto/                 # gRPC协议定义
│   └── schemas/               # 数据模式
├── docs/                       # 文档
├── scripts/                    # 脚本
├── backup/                     # 备份目录
└── docker-compose.yml          # 整体编排
```

## 微服务列表

### 已实现服务

#### 1. 用户权限服务 (user-service) ✅
- **端口**: 8081
- **技术栈**: Go + Gin + GORM + PostgreSQL + Redis
- **功能**: 用户管理、认证授权、角色权限、多租户支持
- **状态**: 完整实现，可独立部署

#### 2. 模型管理服务 (model-service) ✅
- **端口**: 8083
- **技术栈**: Python + FastAPI + SQLAlchemy + PostgreSQL + Redis
- **功能**: 模型注册、版本管理、部署管理、性能监控
- **状态**: 完整实现，可独立部署

#### 3. 推理服务 (inference-service) ✅
- **端口**: 8084
- **技术栈**: Python + FastAPI + vLLM + PostgreSQL + Redis
- **功能**: 模型推理、负载均衡、性能监控、GPU支持
- **状态**: 完整实现，可独立部署

#### 4. 成本管理服务 (cost-service) ✅
- **端口**: 8085
- **技术栈**: Go + Gin + GORM + PostgreSQL + Redis
- **功能**: 成本记录、预算管理、成本分析、优化建议
- **状态**: 完整实现，可独立部署

#### 5. 监控服务 (monitoring-service) ✅
- **端口**: 8086
- **技术栈**: Python + FastAPI + Prometheus + Grafana + PostgreSQL + Redis
- **功能**: 系统监控、告警管理、性能分析、日志聚合
- **状态**: 完整实现，可独立部署

### 已实现服务

#### 6. 项目管理服务 (project-service) ✅
- **端口**: 8082
- **技术栈**: Go + Gin + GORM + PostgreSQL + Redis
- **功能**: 项目管理、成员管理、资源配额、项目模板
- **状态**: 完整实现，可独立部署

## 快速开始

### 环境要求
- Docker & Docker Compose
- 至少4GB内存
- 至少10GB磁盘空间

### 一键部署
```bash
# 克隆项目
git clone <repository-url>
cd AsterOps

# 快速启动（推荐）
./quick-start.sh

# 或者分步部署
./scripts/deploy.sh
```

### 功能演示
```bash
# 运行完整功能演示
./scripts/demo.sh

# 健康检查
./scripts/health-check-all.sh

# API测试
./scripts/api-test.sh

# 综合测试
./scripts/comprehensive-test.sh
```

### 手动启动服务
```bash
# 启动所有微服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 服务访问地址
- **🌐 前端界面**: http://localhost/ (主要访问入口)
- **🔌 API网关**: http://localhost:8087/ (统一API入口)
- **👤 用户服务**: http://localhost:8081
- **📁 项目管理服务**: http://localhost:8082
- **🤖 模型服务**: http://localhost:8083
- **⚡ 推理服务**: http://localhost:8084
- **💰 成本服务**: http://localhost:8085
- **📊 监控服务**: http://localhost:8086
- **📈 Prometheus**: http://localhost:9090
- **📊 Grafana**: http://localhost:3000
- **🔍 Consul**: http://localhost:8500

### 当前状态
✅ **完整的LLMOps运营管理平台已部署运行**
- **微服务架构**: 6个微服务 + API网关 + 前端界面
- **项目管理服务**: 完整实现，支持项目CRUD、成员管理、资源配额
- **API网关**: 统一API入口，支持服务发现和代理
- **前端界面**: 实时监控面板，支持服务状态可视化
- **监控系统**: Prometheus + Grafana 完整监控体系
- **基础设施**: PostgreSQL、Redis、Consul、Nginx 全部运行
- **容器化**: 100% Docker化部署，一键启动

## 开发指南

### 添加新服务
1. 在`services/`目录下创建新的服务目录
2. 按照现有服务的结构组织代码
3. 更新`docker-compose.yml`配置
4. 更新文档

### 服务开发规范
1. **代码结构**: 遵循DDD分层架构
2. **API设计**: 遵循RESTful API设计原则
3. **错误处理**: 统一错误响应格式
4. **日志记录**: 结构化日志输出
5. **测试覆盖**: 单元测试和集成测试

### 部署规范
1. **容器化**: 每个服务独立的Dockerfile
2. **配置管理**: 环境变量和配置文件
3. **健康检查**: 服务状态监控
4. **优雅关闭**: 信号处理和资源清理

## 监控和运维

### 健康检查
- 每个服务提供`/health`端点
- 支持服务发现和注册
- 自动故障检测和恢复

### 日志管理
- 结构化日志输出
- 集中日志收集
- 日志分析和查询

### 性能监控
- 请求数量和响应时间
- 错误率和成功率
- 资源使用情况

## 安全考虑

### 数据安全
- 敏感数据加密存储
- 数据库连接加密
- 传输层安全

### 访问控制
- JWT token认证
- 基于角色的权限控制
- API限流和防护

### 审计日志
- 用户操作记录
- 权限变更追踪
- 安全事件记录

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

- 项目链接: [https://github.com/llmops/llmops-platform](https://github.com/llmops/llmops-platform)
- 问题反馈: [Issues](https://github.com/llmops/llmops-platform/issues)

---

**项目版本**: 1.0.0  
**创建时间**: 2024-01-01  
**更新时间**: 2024-01-01  
**维护者**: LLMOps开发团队
