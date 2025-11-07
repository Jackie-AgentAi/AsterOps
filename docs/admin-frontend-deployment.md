# Admin Frontend Docker Compose 部署指南

## 概述

本文档介绍如何通过Docker Compose运行LLMOps管理后台前端(admin-frontend)。

## 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 至少2GB可用内存
- 至少1GB可用磁盘空间

## 快速启动

### 方法一：使用快速启动脚本（推荐）

```bash
# 进入项目根目录
cd /data/AsterOps

# 运行快速启动脚本
./scripts/quick-start-admin.sh
```

### 方法二：使用完整启动脚本

```bash
# 进入项目根目录
cd /data/AsterOps

# 运行完整启动脚本
./scripts/start-admin-frontend.sh
```

### 方法三：手动启动

```bash
# 进入项目根目录
cd /data/AsterOps

# 使用专门的docker-compose文件启动
docker-compose -f docker-compose.admin.yml up -d

# 查看服务状态
docker-compose -f docker-compose.admin.yml ps

# 查看日志
docker-compose -f docker-compose.admin.yml logs -f
```

## 服务架构

### 服务组件

1. **admin-frontend** (端口: 3000)
   - 管理后台前端界面
   - 基于Vue 3 + Element Plus
   - 使用Nginx作为Web服务器

2. **api-gateway** (端口: 8087)
   - API网关服务
   - 统一API入口
   - 请求路由和负载均衡

3. **postgres** (端口: 5432)
   - PostgreSQL数据库
   - 存储应用数据

4. **redis** (端口: 6379)
   - Redis缓存服务
   - 会话存储和缓存

5. **consul** (端口: 8500)
   - 服务发现和配置管理
   - 服务注册中心

### 网络架构

```
┌─────────────────┐    ┌─────────────────┐
│  admin-frontend │────│   api-gateway   │
│   (nginx:3000)  │    │   (go:8087)     │
└─────────────────┘    └─────────────────┘
                                │
                       ┌────────┴────────┐
                       │                 │
                ┌──────▼──────┐  ┌──────▼──────┐
                │  postgres  │  │    redis    │
                │  (5432)    │  │   (6379)    │
                └─────────────┘  └─────────────┘
                       │
                ┌──────▼──────┐
                │   consul    │
                │   (8500)    │
                └─────────────┘
```

## 访问地址

- **Admin Frontend**: http://localhost:3000
- **API Gateway**: http://localhost:8087
- **Consul UI**: http://localhost:8500

## 健康检查

```bash
# 检查admin-frontend健康状态
curl http://localhost:3000/health

# 检查api-gateway健康状态
curl http://localhost:8087/health

# 检查所有服务状态
docker-compose -f docker-compose.admin.yml ps
```

## 常用命令

### 启动服务

```bash
# 启动所有服务
docker-compose -f docker-compose.admin.yml up -d

# 启动特定服务
docker-compose -f docker-compose.admin.yml up -d admin-frontend
```

### 停止服务

```bash
# 停止所有服务
docker-compose -f docker-compose.admin.yml down

# 停止并删除数据卷
docker-compose -f docker-compose.admin.yml down -v
```

### 查看日志

```bash
# 查看所有服务日志
docker-compose -f docker-compose.admin.yml logs -f

# 查看特定服务日志
docker-compose -f docker-compose.admin.yml logs -f admin-frontend
docker-compose -f docker-compose.admin.yml logs -f api-gateway
```

### 重启服务

```bash
# 重启所有服务
docker-compose -f docker-compose.admin.yml restart

# 重启特定服务
docker-compose -f docker-compose.admin.yml restart admin-frontend
```

### 构建镜像

```bash
# 重新构建所有镜像
docker-compose -f docker-compose.admin.yml build

# 重新构建特定服务镜像
docker-compose -f docker-compose.admin.yml build admin-frontend
```

## 配置说明

### 环境变量

admin-frontend服务支持以下环境变量：

- `NODE_ENV`: 运行环境 (production/development)
- `VITE_API_BASE_URL`: API基础URL
- `VITE_GATEWAY_URL`: 网关URL
- `VITE_WS_URL`: WebSocket URL

### Nginx配置

admin-frontend使用Nginx作为Web服务器，配置文件位于：
`frontend/admin-dashboard/nginx.conf`

主要配置：
- 静态资源缓存
- API代理到api-gateway
- WebSocket代理
- CORS支持
- SPA路由支持

## 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 检查端口占用
   netstat -tulpn | grep :3000
   netstat -tulpn | grep :8087
   
   # 修改端口（编辑docker-compose.admin.yml）
   ports:
     - "3001:80"  # 改为3001端口
   ```

2. **服务启动失败**
   ```bash
   # 查看详细日志
   docker-compose -f docker-compose.admin.yml logs admin-frontend
   
   # 检查镜像构建
   docker-compose -f docker-compose.admin.yml build --no-cache admin-frontend
   ```

3. **数据库连接失败**
   ```bash
   # 检查postgres服务状态
   docker-compose -f docker-compose.admin.yml ps postgres
   
   # 查看postgres日志
   docker-compose -f docker-compose.admin.yml logs postgres
   ```

4. **API请求失败**
   ```bash
   # 检查api-gateway服务状态
   docker-compose -f docker-compose.admin.yml ps api-gateway
   
   # 测试API连接
   curl http://localhost:8087/health
   ```

### 日志分析

```bash
# 查看实时日志
docker-compose -f docker-compose.admin.yml logs -f --tail=100

# 查看错误日志
docker-compose -f docker-compose.admin.yml logs | grep -i error

# 查看访问日志
docker-compose -f docker-compose.admin.yml exec admin-frontend tail -f /var/log/nginx/access.log
```

## 性能优化

### 资源限制

在docker-compose.admin.yml中添加资源限制：

```yaml
services:
  admin-frontend:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

### 缓存优化

- 静态资源使用长期缓存
- 启用Gzip压缩
- 使用CDN加速（生产环境）

## 生产部署

### 安全配置

1. 修改默认密码
2. 启用HTTPS
3. 配置防火墙
4. 定期更新镜像

### 监控配置

1. 启用日志收集
2. 配置监控告警
3. 设置健康检查
4. 性能指标收集

## 开发模式

### 本地开发

```bash
# 进入admin-dashboard目录
cd frontend/admin-dashboard

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

### 热重载

开发模式下支持热重载，修改代码后自动刷新页面。

## 更新升级

### 更新代码

```bash
# 拉取最新代码
git pull

# 重新构建镜像
docker-compose -f docker-compose.admin.yml build admin-frontend

# 重启服务
docker-compose -f docker-compose.admin.yml up -d admin-frontend
```

### 数据备份

```bash
# 备份数据库
docker-compose -f docker-compose.admin.yml exec postgres pg_dump -U llmops llmops > backup.sql

# 恢复数据库
docker-compose -f docker-compose.admin.yml exec -T postgres psql -U llmops llmops < backup.sql
```

## 支持与帮助

- 查看项目文档：`docs/`
- 提交问题：GitHub Issues
- 技术交流：项目讨论区

---

**注意**: 本部署方案适用于开发和测试环境，生产环境请参考生产部署文档。
