# LLMOps 启动脚本说明

本目录包含了多个启动脚本，用于不同场景下的前后端服务启动。

## 脚本概览

### 1. 快速启动脚本

#### `quick-start.sh` - 生产环境快速启动
```bash
./quick-start.sh [--logs] [--aliyun]
```
- **用途**: 一键启动所有服务（生产环境配置）
- **特点**: 使用Docker Compose启动所有服务，包括前端、后端、基础设施和监控
- **参数**: 
  - `--logs`: 启动后显示服务日志
  - `--aliyun`: 使用阿里云镜像源加速

#### `scripts/start-with-aliyun.sh` - 阿里云镜像源启动
```bash
./scripts/start-with-aliyun.sh [--no-mirror] [--logs]
```
- **用途**: 使用阿里云镜像源的全栈启动脚本
- **特点**: 自动配置Docker和npm阿里云镜像源，加速构建和下载
- **参数**: 
  - `--no-mirror`: 跳过镜像源配置
  - `--logs`: 启动后显示服务日志

#### `scripts/quick-start-full.sh` - 完整快速启动
```bash
./scripts/quick-start-full.sh [--logs]
```
- **用途**: 更详细的快速启动脚本
- **特点**: 包含完整的健康检查和状态显示
- **参数**: 
  - `--logs`: 启动后显示服务日志

### 2. 开发环境脚本

#### `scripts/start-dev.sh` - 开发环境启动
```bash
./scripts/start-dev.sh [应用] [--logs]
```
- **用途**: 启动开发环境，支持前端热重载
- **应用参数**:
  - `admin`: 启动管理后台（默认）
  - `portal`: 启动用户门户
  - `mobile`: 启动移动端
  - `all`: 启动所有前端应用
- **参数**: 
  - `--logs`: 启动后显示服务日志

#### `scripts/frontend-dev.sh` - 前端开发工具
```bash
./scripts/frontend-dev.sh [命令] [应用]
```
- **用途**: 前端开发专用工具
- **命令**:
  - `install`: 安装依赖
  - `dev`: 启动开发模式
  - `build`: 构建应用
  - `lint`: 代码检查
  - `type-check`: 类型检查

### 3. 完整启动脚本

#### `scripts/start-full-stack.sh` - 全栈启动
```bash
./scripts/start-full-stack.sh [--logs] [--clean]
```
- **用途**: 完整的全栈启动流程
- **特点**: 包含环境检查、依赖安装、服务启动、健康检查
- **参数**: 
  - `--logs`: 启动后显示服务日志
  - `--clean`: 清理构建缓存

## 使用场景

### 场景1: 快速体验
```bash
# 最简单的启动方式
./quick-start.sh

# 启动并查看日志
./quick-start.sh --logs
```

### 场景2: 开发调试
```bash
# 启动管理后台开发环境
./scripts/start-dev.sh admin

# 启动所有前端应用开发环境
./scripts/start-dev.sh all --logs

# 只启动用户门户
./scripts/start-dev.sh portal
```

### 场景3: 生产部署
```bash
# 使用生产配置启动
./scripts/start-full-stack.sh --clean

# 使用生产配置启动并查看日志
./scripts/start-full-stack.sh --logs
```

### 场景4: 前端开发
```bash
# 安装前端依赖
./scripts/frontend-dev.sh install

# 启动管理后台开发
./scripts/frontend-dev.sh dev admin

# 构建所有前端应用
./scripts/frontend-dev.sh build all

# 代码检查
./scripts/frontend-dev.sh lint all
```

## 服务访问地址

启动后，可以通过以下地址访问各个服务：

### 前端应用
- **管理后台**: http://localhost:3000
- **用户门户**: http://localhost:3001 (开发模式)
- **移动端**: http://localhost:3002 (开发模式)
- **Nginx代理**: http://localhost:80

### 后端API服务
- **用户服务**: http://localhost:8081
- **项目服务**: http://localhost:8082
- **模型服务**: http://localhost:8083
- **推理服务**: http://localhost:8084
- **成本服务**: http://localhost:8085
- **监控服务**: http://localhost:8086

### 基础设施服务
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **Consul**: http://localhost:8500
- **MinIO**: http://localhost:9001

### 监控系统
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3001

## 管理命令

### 查看服务状态
```bash
docker-compose ps
```

### 查看服务日志
```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f [服务名]
```

### 停止服务
```bash
docker-compose down
```

### 重启服务
```bash
docker-compose restart [服务名]
```

### 健康检查
```bash
./scripts/health-check-all.sh
```

### API测试
```bash
./scripts/api-test.sh
```

## 故障排除

### 1. 端口占用
如果遇到端口占用错误，可以：
```bash
# 查看端口占用
lsof -i :端口号

# 停止占用端口的进程
kill -9 PID
```

### 2. Docker服务未启动
```bash
# 启动Docker服务
sudo systemctl start docker

# 设置Docker开机自启
sudo systemctl enable docker
```

### 3. 权限问题
```bash
# 给脚本添加执行权限
chmod +x scripts/*.sh

# 给Docker添加用户权限
sudo usermod -aG docker $USER
```

### 4. 清理环境
```bash
# 停止所有服务
docker-compose down

# 清理Docker资源
docker system prune -f

# 清理数据卷
docker-compose down -v
```

## 注意事项

1. **首次启动**: 第一次启动会下载Docker镜像，可能需要较长时间
2. **内存要求**: 建议至少4GB可用内存
3. **端口冲突**: 确保所需端口未被占用
4. **开发模式**: 开发模式下前端支持热重载，修改代码会自动刷新
5. **生产模式**: 生产模式下前端会被构建为静态文件

## 脚本特性

- ✅ 自动环境检查
- ✅ 智能端口检测
- ✅ 健康状态监控
- ✅ 彩色日志输出
- ✅ 错误处理机制
- ✅ 服务依赖管理
- ✅ 开发/生产模式切换