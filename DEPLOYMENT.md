# LLMOps平台部署指南

## 概述

LLMOps运营管理平台是一个基于微服务架构的LLM运营管理平台，提供用户管理、项目管理、模型管理、推理服务、成本管理等核心功能。

## 系统要求

- Docker 20.10+
- Docker Compose 2.0+
- 至少4GB内存
- 至少10GB磁盘空间

## 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd AsterOps
```

### 2. 一键部署

```bash
# 部署所有服务
./scripts/deploy.sh

# 清理部署（删除旧镜像）
./scripts/deploy.sh --clean
```

### 3. 验证部署

```bash
# 运行健康检查
./scripts/health-check-all.sh

# 运行API测试
./scripts/api-test.sh

# 运行服务集成测试
./scripts/service-integration.sh
```

## 服务架构

### 微服务列表

| 服务名称 | 端口 | 技术栈 | 状态 |
|---------|------|--------|------|
| user-service | 8081 | Go + Gin | ✅ 运行中 |
| project-service | 8082 | Go + Gin | ✅ 完整实现 |
| model-service | 8083 | Python + FastAPI | ✅ 运行中 |
| inference-service | 8084 | Python + FastAPI | ✅ 运行中 |
| cost-service | 8085 | Go + Gin | ✅ 运行中 |
| monitoring-service | 8086 | Python + FastAPI | ✅ 运行中 |

### 基础设施服务

| 服务名称 | 端口 | 状态 |
|---------|------|------|
| PostgreSQL | 5433 | ✅ 运行中 |
| Redis | 6380 | ✅ 运行中 |
| Consul | 8500 | ✅ 运行中 |
| Prometheus | 9090 | ✅ 运行中 |
| Grafana | 3000 | ✅ 运行中 |

## API接口

### 项目管理服务 (完整实现)

#### 创建项目
```bash
curl -X POST http://localhost:8082/api/v1/projects \
  -H "Content-Type: application/json" \
  -d '{
    "name": "测试项目",
    "description": "这是一个测试项目",
    "owner_id": "550e8400-e29b-41d4-a716-446655440000",
    "tenant_id": "550e8400-e29b-41d4-a716-446655440000"
  }'
```

#### 获取项目列表
```bash
curl "http://localhost:8082/api/v1/projects?tenant_id=550e8400-e29b-41d4-a716-446655440000"
```

#### 获取项目详情
```bash
curl "http://localhost:8082/api/v1/projects/{project_id}"
```

### 其他服务 (简化实现)

所有服务都提供健康检查接口：
```bash
curl http://localhost:8081/health  # 用户服务
curl http://localhost:8082/health  # 项目管理服务
curl http://localhost:8083/health  # 模型服务
curl http://localhost:8084/health  # 推理服务
curl http://localhost:8085/health  # 成本服务
curl http://localhost:8086/health  # 监控服务
```

## 监控和日志

### Prometheus监控
- 访问地址: http://localhost:9090
- 监控所有微服务的健康状态和性能指标

### Grafana仪表板
- 访问地址: http://localhost:3000
- 默认用户名/密码: admin/admin
- 提供可视化的监控仪表板

### Consul服务发现
- 访问地址: http://localhost:8500
- 管理服务注册和发现

## 开发指南

### 本地开发

1. 启动基础设施服务：
```bash
docker-compose up -d postgres redis consul
```

2. 运行特定服务：
```bash
# Go服务
cd services/project-service
go run cmd/server/main.go

# Python服务
cd services/model-service
python simple_main.py
```

### 添加新服务

1. 在`services/`目录下创建新服务
2. 添加Dockerfile和docker-compose配置
3. 更新健康检查脚本
4. 添加API测试用例

## 故障排除

### 常见问题

1. **端口冲突**
   - 检查端口是否被占用：`netstat -tlnp | grep :8081`
   - 修改docker-compose.yml中的端口映射

2. **数据库连接失败**
   - 检查PostgreSQL是否启动：`docker ps | grep postgres`
   - 检查数据库配置：`docker logs asterops-postgres-1`

3. **服务启动失败**
   - 查看服务日志：`docker logs asterops-{service-name}-1`
   - 检查配置文件和环境变量

### 日志查看

```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs project-service

# 实时查看日志
docker-compose logs -f project-service
```

## 维护操作

### 停止所有服务
```bash
docker-compose down
```

### 重启特定服务
```bash
docker-compose restart project-service
```

### 更新服务
```bash
docker-compose up -d --build project-service
```

### 清理资源
```bash
# 清理未使用的镜像
docker system prune -f

# 清理所有数据（谨慎使用）
docker-compose down -v
```

## 性能优化

1. **数据库优化**
   - 调整PostgreSQL配置
   - 添加数据库索引
   - 使用连接池

2. **缓存优化**
   - 配置Redis缓存策略
   - 使用适当的缓存过期时间

3. **监控优化**
   - 配置Prometheus告警规则
   - 设置Grafana仪表板
   - 监控关键业务指标

## 安全考虑

1. **网络安全**
   - 使用防火墙限制端口访问
   - 配置HTTPS/TLS加密

2. **数据安全**
   - 定期备份数据库
   - 使用强密码
   - 加密敏感配置

3. **服务安全**
   - 实现身份认证和授权
   - 使用JWT令牌
   - 配置CORS策略

## 联系支持

如有问题，请查看：
- 项目文档：`docs/`目录
- 日志文件：`logs/`目录
- 配置文件：`configs/`目录
