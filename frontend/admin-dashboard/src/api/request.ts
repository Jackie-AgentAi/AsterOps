import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useUserStore } from '@/stores/user'
import { withRetry, createRetryConfig } from '@/utils/api-retry'
import { cache } from '@/utils/cache'
import { CacheInvalidation } from '@/utils/api-cache'
import { API_CONFIG } from '@/config/constants'
import type { ApiResponse } from '@/types/common'

// 创建axios实例
const request: AxiosInstance = axios.create({
  baseURL: '/api', // 使用相对路径，通过Vite代理访问
  timeout: API_CONFIG.TIMEOUT,
  headers: API_CONFIG.HEADERS
})

// 请求拦截器
request.interceptors.request.use(
  (config: AxiosRequestConfig) => {
    const userStore = useUserStore()
    const token = userStore.token
    
    if (token) {
      config.headers = {
        ...config.headers,
        Authorization: `Bearer ${token}` // 添加Bearer前缀
      }
    }
    
    // 添加请求ID用于追踪
    config.headers = {
      ...config.headers,
      'X-Request-ID': generateRequestId()
    }
    
    // 添加时间戳防止缓存
    if (config.method === 'get' && !config.params?.timestamp) {
      config.params = {
        ...config.params,
        timestamp: Date.now()
      }
    }
    
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 响应拦截器
request.interceptors.response.use(
  (response: AxiosResponse<any>) => {
    const responseData = response.data
    
    // 检查是否是成功响应格式
    if (responseData.success === true) {
      return responseData
    }
    
    // 检查是否有code字段（旧格式）
    if (responseData.code) {
      const { code, message, data } = responseData
      
      // 成功响应
      if (code === 200) {
        return data
      }
      
      // 业务错误
      if (code === 401) {
        // 未授权，跳转登录
        const userStore = useUserStore()
        userStore.logoutAction()
        window.location.href = '/login'
        return Promise.reject(new Error(message))
      }
      
      if (code === 403) {
        ElMessage.error('权限不足')
        return Promise.reject(new Error(message))
      }
      
      ElMessage.error(message || '请求失败')
      return Promise.reject(new Error(message))
    }
    
    // 直接返回响应数据
    return responseData
  },
  (error) => {
    // 网络错误
    if (error.code === 'ECONNABORTED') {
      ElMessage.error('请求超时')
    } else if (error.response) {
      const { status, data } = error.response
      
      switch (status) {
        case 401:
          ElMessage.error('未授权，请重新登录')
          const userStore = useUserStore()
          userStore.logoutAction()
          window.location.href = '/login'
          break
        case 403:
          ElMessage.error('权限不足')
          break
        case 404:
          ElMessage.error('请求的资源不存在')
          break
        case 500:
          ElMessage.error('服务器内部错误')
          break
        default:
          ElMessage.error(data?.message || '请求失败')
      }
    } else {
      ElMessage.error('网络错误，请检查网络连接')
    }
    
    return Promise.reject(error)
  }
)

// 生成请求ID
function generateRequestId(): string {
  return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
}

// 带重试的请求方法
export const requestWithRetry = withRetry(request.request.bind(request), createRetryConfig({
  maxRetries: 3,
  retryDelay: 1000
}))

// 带缓存的GET请求
export const cachedGet = async <T = any>(url: string, config?: AxiosRequestConfig): Promise<T> => {
  const cacheKey = `get:${url}:${JSON.stringify(config?.params || {})}`
  
  // 尝试从缓存获取
  const cached = cache.system.get(cacheKey)
  if (cached) {
    return cached
  }
  
  try {
    const response = await request.get<T>(url, config)
    // 缓存结果
    cache.system.set(cacheKey, response, 300000) // 5分钟缓存
    return response
  } catch (error) {
    // 如果请求失败，尝试返回缓存结果
    const cached = cache.system.get(cacheKey)
    if (cached) {
      return cached
    }
    throw error
  }
}

// 带缓存失效的POST请求
export const invalidatingPost = async <T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> => {
  const response = await request.post<T>(url, data, config)
  
  // 根据URL触发缓存失效
  if (url.includes('/users')) {
    CacheInvalidation.invalidate('user:update')
  } else if (url.includes('/projects')) {
    CacheInvalidation.invalidate('project:create')
  } else if (url.includes('/models')) {
    CacheInvalidation.invalidate('model:upload')
  } else if (url.includes('/inference')) {
    CacheInvalidation.invalidate('inference:create')
  } else if (url.includes('/costs')) {
    CacheInvalidation.invalidate('cost:update')
  }
  
  return response
}

// 带缓存失效的PUT请求
export const invalidatingPut = async <T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> => {
  const response = await request.put<T>(url, data, config)
  
  // 根据URL触发缓存失效
  if (url.includes('/users/')) {
    CacheInvalidation.invalidate('user:update')
  } else if (url.includes('/projects/')) {
    CacheInvalidation.invalidate('project:update')
  } else if (url.includes('/models/')) {
    CacheInvalidation.invalidate('model:update')
  }
  
  return response
}

// 带缓存失效的DELETE请求
export const invalidatingDelete = async <T = any>(url: string, config?: AxiosRequestConfig): Promise<T> => {
  const response = await request.delete<T>(url, config)
  
  // 根据URL触发缓存失效
  if (url.includes('/users/')) {
    CacheInvalidation.invalidate('user:delete')
  } else if (url.includes('/projects/')) {
    CacheInvalidation.invalidate('project:delete')
  } else if (url.includes('/models/')) {
    CacheInvalidation.invalidate('model:delete')
  }
  
  return response
}

// 导出增强的请求方法
export const enhancedRequest = {
  get: cachedGet,
  post: invalidatingPost,
  put: invalidatingPut,
  delete: invalidatingDelete,
  request: requestWithRetry
}

export default request
