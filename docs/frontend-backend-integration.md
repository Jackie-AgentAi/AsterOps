# LLMOps前端后端集成文档

## 概述

本文档描述了LLMOps平台前端与后端微服务的完整集成方案，包括API配置、缓存策略、错误处理、WebSocket连接、健康检查等。

## 架构设计

### 集成架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    前端应用 (Vue 3)                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │  用户界面   │ │  状态管理   │ │  路由管理   │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTP/WebSocket
┌─────────────────────▼───────────────────────────────────────┐
│                   API网关 (Kong)                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │  路由转发   │ │  认证授权   │ │  限流熔断   │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                   微服务集群                               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│  │ 用户服务 │ │ 项目服务 │ │ 模型服务 │ │ 推理服务 │          │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│  │ 成本服务 │ │ 监控服务 │ │ 评测服务 │ │ 知识服务 │          │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                   基础设施层                               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│  │PostgreSQL│ │  Redis  │ │ Consul  │ │ MinIO  │          │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │
└─────────────────────────────────────────────────────────────┘
```

## 技术栈

### 前端技术栈
- **框架**: Vue 3.4 + TypeScript
- **构建工具**: Vite
- **UI库**: Element Plus
- **状态管理**: Pinia
- **路由**: Vue Router 4
- **HTTP客户端**: Axios
- **图表**: ECharts + Vue-ECharts
- **缓存**: 内存缓存 + LocalStorage
- **WebSocket**: 原生WebSocket API

### 后端技术栈
- **API网关**: Kong + Go Gin
- **微服务**: Go + Gin, Python + FastAPI
- **数据库**: PostgreSQL
- **缓存**: Redis
- **服务发现**: Consul
- **对象存储**: MinIO
- **消息队列**: Apache Kafka
- **监控**: Prometheus + Grafana

## 核心功能

### 1. API配置管理

#### 环境配置
```typescript
// src/config/env.ts
export const env = {
  API_BASE_URL: 'http://localhost:8080/api',
  GATEWAY_URL: 'http://localhost:8080',
  USER_SERVICE_URL: 'http://localhost:8081',
  PROJECT_SERVICE_URL: 'http://localhost:8082',
  MODEL_SERVICE_URL: 'http://localhost:8083',
  INFERENCE_SERVICE_URL: 'http://localhost:8084',
  COST_SERVICE_URL: 'http://localhost:8085',
  MONITORING_SERVICE_URL: 'http://localhost:8086',
  WS_URL: 'ws://localhost:8080/ws'
}
```

#### API路由配置
```typescript
// API路由映射
export const apiRoutes = {
  auth: {
    login: '/v1/auth/login',
    logout: '/v1/auth/logout'
  },
  users: {
    list: '/v1/users',
    detail: (id: string) => `/v1/users/${id}`
  },
  projects: {
    list: '/v6/projects',
    detail: (id: string) => `/v6/projects/${id}`
  }
  // ... 其他服务路由
}
```

### 2. 请求拦截器

#### 请求拦截器
```typescript
// src/api/request.ts
request.interceptors.request.use(
  (config) => {
    // 添加认证头
    const token = userStore.token
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    
    // 添加请求ID
    config.headers['X-Request-ID'] = generateRequestId()
    
    // 防止缓存
    if (config.method === 'get') {
      config.params = { ...config.params, timestamp: Date.now() }
    }
    
    return config
  }
)
```

#### 响应拦截器
```typescript
request.interceptors.response.use(
  (response) => {
    const { code, message, data } = response.data
    
    if (code === 200) {
      return data
    }
    
    if (code === 401) {
      userStore.logoutAction()
      window.location.href = '/login'
    }
    
    ElMessage.error(message || '请求失败')
    return Promise.reject(new Error(message))
  }
)
```

### 3. 缓存策略

#### 多级缓存
```typescript
// src/utils/cache.ts
class CacheManager {
  private memoryCache: Map<string, CacheItem> = new Map()
  private config: CacheConfig
  
  set<T>(prefix: string, key: string, data: T, ttl?: number): void {
    const cacheKey = this.generateKey(prefix, key)
    const item: CacheItem<T> = {
      data,
      timestamp: Date.now(),
      ttl: ttl || this.config.defaultTTL,
      key: cacheKey
    }
    
    // 内存缓存
    this.memoryCache.set(cacheKey, item)
    
    // 本地存储
    localStorage.setItem(cacheKey, JSON.stringify(item))
  }
}
```

#### 缓存失效策略
```typescript
// 智能缓存失效
CacheInvalidation.registerRule('user:update', ['user:list', 'user:me'])
CacheInvalidation.registerRule('project:create', ['project:list'])

// 触发失效
CacheInvalidation.invalidate('user:update')
```

### 4. 错误处理与重试

#### 重试机制
```typescript
// src/utils/api-retry.ts
export function withRetry<T extends (...args: any[]) => Promise<any>>(
  fn: T,
  config: RetryConfig = {}
): T {
  const retryConfig = { ...defaultRetryConfig, ...config }
  
  return (async (...args: Parameters<T>) => {
    for (let attempt = 1; attempt <= retryConfig.maxRetries; attempt++) {
      try {
        return await fn(...args)
      } catch (error) {
        if (attempt === retryConfig.maxRetries || !retryConfig.retryCondition!(error)) {
          break
        }
        
        const delay = calculateDelay(attempt, retryConfig.retryDelay)
        await new Promise(resolve => setTimeout(resolve, delay))
      }
    }
    throw lastError
  }) as T
}
```

#### 错误分类
```typescript
// 网络错误检查
export const isNetworkError = (error: any): boolean => {
  return !error.response && (
    error.code === 'ECONNABORTED' ||
    error.code === 'ENOTFOUND' ||
    error.message.includes('Network Error')
  )
}

// 服务器错误检查
export const isServerError = (error: any): boolean => {
  return error.response && error.response.status >= 500
}
```

### 5. WebSocket连接

#### WebSocket管理器
```typescript
// src/utils/websocket.ts
class WebSocketManager {
  private ws: WebSocket | null = null
  private listeners: Map<string, Set<(data: any) => void>> = new Map()
  
  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(this.url)
      
      this.ws.onopen = () => {
        this.startHeartbeat()
        resolve()
      }
      
      this.ws.onmessage = (event) => {
        const message = JSON.parse(event.data)
        this.handleMessage(message)
      }
    })
  }
  
  subscribe(event: string, callback: (data: any) => void): void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set())
    }
    this.listeners.get(event)!.add(callback)
  }
}
```

#### 事件订阅
```typescript
// 预定义事件订阅
export const subscribeToSystemStatus = (callback: (data: any) => void) => {
  subscribeToEvent(wsEvents.SYSTEM_STATUS, callback)
}

export const subscribeToAlerts = (callback: (data: any) => void) => {
  subscribeToEvent(wsEvents.ALERT_TRIGGERED, callback)
  subscribeToEvent(wsEvents.ALERT_RESOLVED, callback)
}
```

### 6. 健康检查

#### 后端集成状态管理
```typescript
// src/stores/backend.ts
export const useBackendStore = defineStore('backend', () => {
  const integrationStatus = ref<IntegrationStatus>({
    apiGateway: false,
    services: {},
    database: false,
    cache: false,
    websocket: false,
    overall: 'unhealthy'
  })
  
  const performHealthCheck = async (): Promise<void> => {
    const status = await backendIntegration.performHealthCheck()
    integrationStatus.value = status
  }
  
  return {
    integrationStatus,
    performHealthCheck
  }
})
```

#### 服务健康检查
```typescript
// src/utils/backend-integration.ts
class BackendIntegration {
  async performHealthCheck(): Promise<IntegrationStatus> {
    const [
      apiGateway,
      database,
      cacheStatus,
      websocket,
      servicesHealth
    ] = await Promise.allSettled([
      this.checkApiGateway(),
      this.checkDatabase(),
      this.checkCache(),
      this.checkWebSocket(),
      checkAllServicesHealth()
    ])
    
    return {
      apiGateway: apiGateway.status === 'fulfilled' && apiGateway.value,
      services: servicesHealth.status === 'fulfilled' ? servicesHealth.value : {},
      database: database.status === 'fulfilled' && database.value,
      cache: cacheStatus.status === 'fulfilled' && cacheStatus.value,
      websocket: websocket.status === 'fulfilled' && websocket.value,
      overall: 'healthy'
    }
  }
}
```

## 部署配置

### Docker Compose配置

```yaml
# docker-compose.frontend.yml
version: '3.8'

services:
  frontend:
    build: ./frontend/admin-dashboard
    ports:
      - "3000:80"
    environment:
      - VITE_API_BASE_URL=http://localhost:8080/api
      - VITE_GATEWAY_URL=http://localhost:8080
      - VITE_WS_URL=ws://localhost:8080/ws
    depends_on:
      - api-gateway

  api-gateway:
    build: ./infrastructure/api-gateway
    ports:
      - "8080:8080"
    environment:
      - CONSUL_HOST=consul
      - REDIS_HOST=redis
    depends_on:
      - consul
      - redis
      - user-service
      - project-service
      - model-service
      - inference-service
      - cost-service
      - monitoring-service

  # ... 其他微服务配置
```

### Nginx配置

```nginx
# nginx.conf
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # API代理
    location /api/ {
        proxy_pass http://api-gateway:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket代理
    location /ws/ {
        proxy_pass http://api-gateway:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # SPA路由支持
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

## 启动和测试

### 启动脚本

```bash
# 启动完整集成环境
./scripts/start-frontend-integration.sh

# 测试集成环境
./scripts/test-frontend-integration.sh
```

### 测试覆盖

1. **基础连接测试**
   - API网关健康检查
   - 微服务健康检查
   - 前端应用访问

2. **API响应测试**
   - 认证接口测试
   - 数据接口测试
   - 错误处理测试

3. **WebSocket测试**
   - 连接建立测试
   - 消息收发测试
   - 断线重连测试

4. **性能测试**
   - 响应时间测试
   - 并发请求测试
   - 资源使用测试

5. **集成测试**
   - 端到端流程测试
   - 数据一致性测试
   - 错误恢复测试

## 监控和运维

### 健康监控

```typescript
// 实时健康状态显示
<BackendStatus 
  :show-details="true" 
  :auto-refresh="true" 
  :refresh-interval="30000" 
/>
```

### 日志监控

```bash
# 查看服务日志
docker-compose -f docker-compose.frontend.yml logs -f [服务名]

# 查看错误日志
docker-compose -f docker-compose.frontend.yml logs | grep -i error
```

### 性能监控

```bash
# 查看资源使用
docker stats --no-stream

# 查看服务状态
docker-compose -f docker-compose.frontend.yml ps
```

## 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 检查端口占用
   lsof -i :3000
   lsof -i :8080
   ```

2. **服务启动失败**
   ```bash
   # 查看服务日志
   docker-compose logs [服务名]
   
   # 重启服务
   docker-compose restart [服务名]
   ```

3. **API连接失败**
   ```bash
   # 测试API连接
   curl -f http://localhost:8080/health
   
   # 检查网络连接
   docker network ls
   ```

4. **WebSocket连接失败**
   ```bash
   # 测试WebSocket
   websocat ws://localhost:8080/ws
   ```

### 调试工具

1. **浏览器开发者工具**
   - Network面板查看API请求
   - Console面板查看错误信息
   - Application面板查看缓存状态

2. **Docker调试**
   ```bash
   # 进入容器调试
   docker-compose exec [服务名] sh
   
   # 查看容器状态
   docker inspect [容器名]
   ```

3. **日志分析**
   ```bash
   # 实时日志监控
   docker-compose logs -f --tail=100
   
   # 错误日志过滤
   docker-compose logs | grep -E "(ERROR|FATAL|Exception)"
   ```

## 最佳实践

### 开发最佳实践

1. **API设计**
   - 使用RESTful API设计
   - 统一的错误响应格式
   - 合理的HTTP状态码

2. **缓存策略**
   - 合理设置缓存TTL
   - 及时失效相关缓存
   - 避免缓存雪崩

3. **错误处理**
   - 分类处理不同类型的错误
   - 提供用户友好的错误信息
   - 实现自动重试机制

4. **性能优化**
   - 使用CDN加速静态资源
   - 实现懒加载和代码分割
   - 优化API响应时间

### 运维最佳实践

1. **监控告警**
   - 设置关键指标监控
   - 配置告警规则
   - 建立故障响应流程

2. **日志管理**
   - 结构化日志输出
   - 集中化日志收集
   - 日志轮转和清理

3. **安全防护**
   - API访问控制
   - 数据加密传输
   - 定期安全审计

## 总结

LLMOps前端后端集成方案提供了完整的微服务架构支持，包括：

- ✅ **完整的API集成**: 支持所有微服务的API调用
- ✅ **智能缓存策略**: 多级缓存和智能失效
- ✅ **健壮的错误处理**: 自动重试和降级处理
- ✅ **实时通信**: WebSocket连接和事件订阅
- ✅ **健康监控**: 实时状态监控和告警
- ✅ **容器化部署**: Docker和Docker Compose支持
- ✅ **自动化测试**: 完整的集成测试套件

该方案确保了前端与后端微服务的高效集成，提供了良好的用户体验和运维便利性。
