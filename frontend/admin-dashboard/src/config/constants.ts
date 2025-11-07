/**
 * 应用常量配置
 */

// API配置
export const API_CONFIG = {
  BASE_URL: import.meta.env.VITE_API_BASE_URL || 'http://172.16.10.3:8087',
  GATEWAY_URL: import.meta.env.VITE_GATEWAY_URL || 'http://172.16.10.3:8087',
  WS_URL: import.meta.env.VITE_WS_URL || 'ws://172.16.10.3:8087/ws',
  TIMEOUT: 30000,
  RETRY_TIMES: 3,
  RETRY_DELAY: 1000,
  HEADERS: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
} as const

// 应用配置
export const APP_CONFIG = {
  NAME: 'LLMOps管理后台',
  VERSION: '1.0.0',
  DESCRIPTION: 'LLMOps平台管理后台',
  PAGINATION: {
    DEFAULT_PAGE_SIZE: 20,
    PAGE_SIZES: [10, 20, 50, 100],
    MAX_PAGE_SIZE: 1000
  },
  CACHE: {
    TOKEN_KEY: 'llmops_token',
    USER_KEY: 'llmops_user',
    THEME_KEY: 'llmops_theme',
    LANG_KEY: 'llmops_lang',
    TTL: 30 * 60 * 1000
  },
  THEME: {
    DEFAULT: 'light',
    OPTIONS: ['light', 'dark', 'auto']
  },
  LANG: {
    DEFAULT: 'zh-CN',
    OPTIONS: ['zh-CN', 'en-US']
  }
} as const

// 路由配置
export const ROUTE_CONFIG = {
  PATHS: {
    LOGIN: '/login',
    DASHBOARD: '/dashboard',
    USERS: '/users',
    PROJECTS: '/projects',
    MODELS: '/models',
    INFERENCE: '/inference',
    COSTS: '/costs',
    MONITORING: '/monitoring',
    SETTINGS: '/settings',
    ERROR_404: '/404'
  },
  NAMES: {
    LOGIN: 'Login',
    DASHBOARD: 'Dashboard',
    USERS: 'Users',
    PROJECTS: 'Projects',
    MODELS: 'Models',
    INFERENCE: 'Inference',
    COSTS: 'Costs',
    MONITORING: 'Monitoring',
    SETTINGS: 'Settings',
    ERROR_404: 'Error404'
  }
} as const

// 状态码配置
export const STATUS_CODE = {
  SUCCESS: 200,
  CREATED: 201,
  NO_CONTENT: 204,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  UNPROCESSABLE_ENTITY: 422,
  INTERNAL_SERVER_ERROR: 500,
  BAD_GATEWAY: 502,
  SERVICE_UNAVAILABLE: 503
} as const

// 用户角色配置
export const USER_ROLES = {
  SUPER_ADMIN: 'super_admin',
  ADMIN: 'admin',
  DEVELOPER: 'developer',
  OPERATOR: 'operator',
  VIEWER: 'viewer'
} as const

// 权限配置
export const PERMISSIONS = {
  USER_VIEW: 'user:view',
  USER_CREATE: 'user:create',
  USER_UPDATE: 'user:update',
  USER_DELETE: 'user:delete',
  PROJECT_VIEW: 'project:view',
  PROJECT_CREATE: 'project:create',
  PROJECT_UPDATE: 'project:update',
  PROJECT_DELETE: 'project:delete',
  MODEL_VIEW: 'model:view',
  MODEL_CREATE: 'model:create',
  MODEL_UPDATE: 'model:update',
  MODEL_DELETE: 'model:delete',
  INFERENCE_VIEW: 'inference:view',
  INFERENCE_CREATE: 'inference:create',
  INFERENCE_UPDATE: 'inference:update',
  INFERENCE_DELETE: 'inference:delete',
  COST_VIEW: 'cost:view',
  COST_CREATE: 'cost:create',
  COST_UPDATE: 'cost:update',
  COST_DELETE: 'cost:delete',
  MONITORING_VIEW: 'monitoring:view',
  MONITORING_CREATE: 'monitoring:create',
  MONITORING_UPDATE: 'monitoring:update',
  MONITORING_DELETE: 'monitoring:delete',
  SETTINGS_VIEW: 'settings:view',
  SETTINGS_UPDATE: 'settings:update'
} as const

// 服务状态配置
export const SERVICE_STATUS = {
  HEALTHY: 'healthy',
  UNHEALTHY: 'unhealthy',
  UNKNOWN: 'unknown',
  STARTING: 'starting',
  STOPPING: 'stopping',
  STOPPED: 'stopped'
} as const

// 通知类型配置
export const NOTIFICATION_TYPES = {
  SUCCESS: 'success',
  WARNING: 'warning',
  ERROR: 'error',
  INFO: 'info'
} as const

// 图表配置
export const CHART_CONFIG = {
  COLORS: [
    '#409EFF', '#67C23A', '#E6A23C', '#F56C6C',
    '#909399', '#C0C4CC', '#5DADE2', '#58D68D',
    '#F7DC6F', '#BB8FCE', '#85C1E9', '#F8C471'
  ],
  GRID: {
    left: '3%',
    right: '4%',
    bottom: '3%',
    containLabel: true
  },
  TOOLTIP: {
    trigger: 'axis',
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    borderColor: 'rgba(255, 255, 255, 0.2)',
    textStyle: {
      color: '#fff'
    }
  },
  LEGEND: {
    type: 'scroll',
    orient: 'horizontal',
    bottom: 0
  }
} as const

// 文件上传配置
export const UPLOAD_CONFIG = {
  MAX_SIZE: 100 * 1024 * 1024,
  ALLOWED_TYPES: [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/svg+xml',
    'application/pdf',
    'text/plain',
    'application/json',
    'text/csv'
  ],
  CHUNK_SIZE: 1024 * 1024,
  CONCURRENT_UPLOADS: 3
} as const

// 表格配置
export const TABLE_CONFIG = {
  DEFAULT_PAGE_SIZE: 20,
  PAGE_SIZES: [10, 20, 50, 100],
  MAX_PAGE_SIZE: 1000,
  SORT_ORDERS: ['asc', 'desc'] as const,
  FILTER_OPERATORS: ['eq', 'ne', 'gt', 'gte', 'lt', 'lte', 'like', 'in', 'nin'] as const
} as const

// 日期时间格式
export const DATE_FORMATS = {
  DATE: 'YYYY-MM-DD',
  TIME: 'HH:mm:ss',
  DATETIME: 'YYYY-MM-DD HH:mm:ss',
  TIMESTAMP: 'YYYY-MM-DD HH:mm:ss.SSS',
  ISO: 'YYYY-MM-DDTHH:mm:ss.SSSZ'
} as const

// 正则表达式
export const REGEX = {
  EMAIL: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  PHONE: /^1[3-9]\d{9}$/,
  PASSWORD: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/,
  USERNAME: /^[a-zA-Z0-9_-]{3,20}$/,
  URL: /^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$/
} as const

export default {
  API_CONFIG,
  APP_CONFIG,
  ROUTE_CONFIG,
  STATUS_CODE,
  USER_ROLES,
  PERMISSIONS,
  SERVICE_STATUS,
  NOTIFICATION_TYPES,
  CHART_CONFIG,
  UPLOAD_CONFIG,
  TABLE_CONFIG,
  DATE_FORMATS,
  REGEX
}
