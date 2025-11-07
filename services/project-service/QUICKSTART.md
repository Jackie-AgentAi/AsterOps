# 项目管理服务快速启动指南

## 概述

项目管理服务是LLMOps平台的核心业务服务，提供项目生命周期管理、成员管理、资源配额控制、项目模板等功能。

## 快速启动

### 1. 使用Docker Compose（推荐）

```bash
# 启动项目管理服务及其依赖
cd /data/AsterOps/services/project-service
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f project-service
```

### 2. 本地开发模式

```bash
# 启动依赖服务
docker-compose up -d postgres redis consul

# 运行服务
make run-dev
```

### 3. 构建和运行

```bash
# 构建服务
make build

# 运行服务
make run
```

## 服务验证

### 健康检查

```bash
# 检查服务健康状态
curl http://localhost:8082/health

# 检查服务就绪状态
curl http://localhost:8082/ready
```

### API测试

```bash
# 运行测试脚本
./scripts/test.sh

# 或手动测试API
curl "http://localhost:8082/api/v1/projects?tenant_id=00000000-0000-0000-0000-000000000000"
```

## 主要功能

### 项目管理
- ✅ 创建、更新、删除项目
- ✅ 项目列表查询和搜索
- ✅ 项目详情获取

### 成员管理
- ✅ 添加、移除项目成员
- ✅ 成员角色和权限管理
- ✅ 成员列表查询

### 资源配额
- ✅ 设置项目资源配额
- ✅ 配额使用情况监控
- ✅ 配额检查

### 项目模板
- ✅ 创建、管理项目模板
- ✅ 从模板创建项目
- ✅ 公共模板和分类管理

### 活动日志
- ✅ 记录项目操作日志
- ✅ 活动日志查询

## API文档

服务启动后，可以通过以下方式访问API文档：

- Swagger UI: `http://localhost:8082/swagger/index.html`
- 健康检查: `http://localhost:8082/health`
- 就绪检查: `http://localhost:8082/ready`

## 配置说明

配置文件位于 `configs/config.yaml`，主要配置项：

- **服务器配置**: 端口、超时设置
- **数据库配置**: PostgreSQL连接信息
- **Redis配置**: 缓存连接信息
- **Consul配置**: 服务发现配置
- **日志配置**: 日志级别和格式

## 故障排除

### 常见问题

1. **数据库连接失败**
   - 检查PostgreSQL是否运行
   - 验证数据库连接配置
   - 确认数据库用户权限

2. **服务启动失败**
   - 检查端口是否被占用
   - 查看服务日志
   - 验证配置文件格式

3. **API调用失败**
   - 检查服务是否正常运行
   - 验证请求参数格式
   - 查看服务日志

### 日志查看

```bash
# 查看服务日志
docker-compose logs -f project-service

# 查看所有服务日志
docker-compose logs -f
```

## 开发指南

### 代码结构

```
project-service/
├── cmd/server/          # 主入口
├── internal/
│   ├── app/            # 应用层
│   │   ├── handler/    # HTTP处理器
│   │   ├── middleware/ # 中间件
│   │   └── router/     # 路由配置
│   ├── domain/         # 领域层
│   │   ├── entity/     # 实体
│   │   ├── repository/ # 仓储接口
│   │   └── service/    # 服务接口
│   └── pkg/            # 共享包
│       ├── config/     # 配置管理
│       ├── database/   # 数据库
│       ├── logger/     # 日志
│       └── response/   # 响应处理
├── configs/            # 配置文件
├── scripts/            # 脚本
└── docs/              # 文档
```

### 开发命令

```bash
# 格式化代码
make fmt

# 运行测试
make test

# 代码检查
make lint

# 生成Swagger文档
make swagger
```

## 部署说明

### Docker部署

```bash
# 构建镜像
docker build -t llmops/project-service:latest .

# 运行容器
docker run -p 8082:8082 llmops/project-service:latest
```

### 生产环境

1. 配置环境变量
2. 设置数据库连接
3. 配置Redis缓存
4. 设置服务发现
5. 配置监控和日志

---

**文档版本**: 1.0.0  
**更新时间**: 2024-01-01  
**维护者**: LLMOps开发团队
