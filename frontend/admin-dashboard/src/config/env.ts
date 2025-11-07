// 环境配置
export const env = {
  // API配置 - 通过Nginx代理访问
  API_BASE_URL: import.meta.env.VITE_API_BASE_URL || 'http://172.16.10.3:3000/api',
  GATEWAY_URL: import.meta.env.VITE_GATEWAY_URL || 'http://172.16.10.3:3000/api',
  
  // 微服务地址 - 通过Nginx代理访问API网关
  USER_SERVICE_URL: import.meta.env.VITE_USER_SERVICE_URL || 'http://172.16.10.3:3000/api',
  PROJECT_SERVICE_URL: import.meta.env.VITE_PROJECT_SERVICE_URL || 'http://172.16.10.3:3000/api',
  MODEL_SERVICE_URL: import.meta.env.VITE_MODEL_SERVICE_URL || 'http://172.16.10.3:3000/api',
  INFERENCE_SERVICE_URL: import.meta.env.VITE_INFERENCE_SERVICE_URL || 'http://172.16.10.3:3000/api',
  COST_SERVICE_URL: import.meta.env.VITE_COST_SERVICE_URL || 'http://172.16.10.3:3000/api',
  MONITORING_SERVICE_URL: import.meta.env.VITE_MONITORING_SERVICE_URL || 'http://172.16.10.3:3000/api',
  
  // WebSocket配置 - 通过Nginx代理访问
  WS_URL: import.meta.env.VITE_WS_URL || 'ws://172.16.10.3:3000/ws',
  
  // 应用配置
  APP_TITLE: import.meta.env.VITE_APP_TITLE || 'LLMOps管理平台',
  APP_VERSION: import.meta.env.VITE_APP_VERSION || '1.0.0',
  APP_ENV: import.meta.env.VITE_APP_ENV || 'development',
  
  // 文件上传配置
  MAX_FILE_SIZE: parseInt(import.meta.env.VITE_MAX_FILE_SIZE || '1073741824'), // 1GB
  ALLOWED_FILE_TYPES: (import.meta.env.VITE_ALLOWED_FILE_TYPES || '.bin,.safetensors,.pt,.pth,.onnx,.h5,.txt,.json,.csv').split(','),
  
  // 分页配置
  DEFAULT_PAGE_SIZE: parseInt(import.meta.env.VITE_DEFAULT_PAGE_SIZE || '10'),
  MAX_PAGE_SIZE: parseInt(import.meta.env.VITE_MAX_PAGE_SIZE || '100'),
  
  // 缓存配置
  CACHE_TTL: parseInt(import.meta.env.VITE_CACHE_TTL || '300000'), // 5分钟
  CACHE_MAX_SIZE: parseInt(import.meta.env.VITE_CACHE_MAX_SIZE || '50'),
  
  // 调试配置
  DEBUG: import.meta.env.VITE_DEBUG === 'true',
  LOG_LEVEL: import.meta.env.VITE_LOG_LEVEL || 'debug'
}

// 开发环境检查
export const isDev = env.APP_ENV === 'development'
export const isProd = env.APP_ENV === 'production'

// API路由配置
export const apiRoutes = {
  // 用户服务 (v1)
  auth: {
    login: '/v1/auth/login',
    logout: '/v1/auth/logout',
    refresh: '/v1/auth/refresh'
  },
  users: {
    list: '/v1/users',
    detail: (id: string) => `/v1/users/${id}`,
    create: '/v1/users',
    update: (id: string) => `/v1/users/${id}`,
    delete: (id: string) => `/v1/users/${id}`
  },
  
  // 项目服务 (v6)
  projects: {
    list: '/v6/projects',
    detail: (id: string) => `/v6/projects/${id}`,
    create: '/v6/projects',
    update: (id: string) => `/v6/projects/${id}`,
    delete: (id: string) => `/v6/projects/${id}`,
    members: (id: string) => `/v6/projects/${id}/members`
  },
  
  // 模型服务 (v2)
  models: {
    list: '/v2/models',
    detail: (id: string) => `/v2/models/${id}`,
    create: '/v2/models',
    update: (id: string) => `/v2/models/${id}`,
    delete: (id: string) => `/v2/models/${id}`,
    upload: (id: string) => `/v2/models/${id}/upload`,
    versions: (id: string) => `/v2/models/${id}/versions`
  },
  
  // 推理服务 (v3)
  inference: {
    tasks: '/v3/inference/tasks',
    task: (id: string) => `/v3/inference/tasks/${id}`,
    create: '/v3/inference/tasks',
    stream: '/v3/inference/stream',
    batch: '/v3/inference/batch',
    history: '/v3/inference/history',
    stats: '/v3/inference/stats',
    metrics: '/v3/inference/metrics'
  },
  
  // 成本服务 (v4)
  costs: {
    list: '/v4/costs',
    detail: (id: string) => `/v4/costs/${id}`,
    summary: '/v4/costs/summary',
    trend: '/v4/costs/trend',
    distribution: '/v4/costs/distribution',
    analysis: '/v4/costs/analysis',
    budgets: '/v4/budgets',
    bills: '/v4/bills'
  },
  
  // 监控服务 (v5)
  monitoring: {
    alerts: '/v5/alerts',
    alert: (id: string) => `/v5/alerts/${id}`,
    rules: '/v5/alert-rules',
    rule: (id: string) => `/v5/alert-rules/${id}`,
    metrics: '/v5/monitoring/metrics',
    services: '/v5/monitoring/services',
    logs: '/v5/logs',
    health: '/v5/monitoring/health'
  }
}

// WebSocket事件配置
export const wsEvents = {
  // 系统事件
  SYSTEM_STATUS: 'system:status',
  SYSTEM_METRICS: 'system:metrics',
  
  // 用户事件
  USER_LOGIN: 'user:login',
  USER_LOGOUT: 'user:logout',
  
  // 项目事件
  PROJECT_CREATED: 'project:created',
  PROJECT_UPDATED: 'project:updated',
  PROJECT_DELETED: 'project:deleted',
  
  // 模型事件
  MODEL_UPLOADED: 'model:uploaded',
  MODEL_DEPLOYED: 'model:deployed',
  MODEL_UPDATED: 'model:updated',
  
  // 推理事件
  INFERENCE_STARTED: 'inference:started',
  INFERENCE_COMPLETED: 'inference:completed',
  INFERENCE_FAILED: 'inference:failed',
  
  // 告警事件
  ALERT_TRIGGERED: 'alert:triggered',
  ALERT_RESOLVED: 'alert:resolved',
  
  // 成本事件
  COST_THRESHOLD: 'cost:threshold',
  BUDGET_EXCEEDED: 'budget:exceeded'
}

export default env
