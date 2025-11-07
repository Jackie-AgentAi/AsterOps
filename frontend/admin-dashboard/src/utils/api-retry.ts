import { ElMessage } from 'element-plus'

export interface RetryConfig {
  maxRetries: number
  retryDelay: number
  retryCondition?: (error: any) => boolean
  onRetry?: (attempt: number, error: any) => void
  onMaxRetriesReached?: (error: any) => void
}

// 默认重试配置
const defaultRetryConfig: RetryConfig = {
  maxRetries: 3,
  retryDelay: 1000,
  retryCondition: (error) => {
    // 网络错误或5xx服务器错误时重试
    return !error.response || error.response.status >= 500
  },
  onRetry: (attempt, error) => {
    console.warn(`API重试 ${attempt} 次:`, error.message)
  },
  onMaxRetriesReached: (error) => {
    ElMessage.error('请求失败，请稍后重试')
    console.error('API重试次数已达上限:', error)
  }
}

// 指数退避延迟计算
const calculateDelay = (attempt: number, baseDelay: number): number => {
  return Math.min(baseDelay * Math.pow(2, attempt - 1), 10000) // 最大10秒
}

// 重试装饰器
export function withRetry<T extends (...args: any[]) => Promise<any>>(
  fn: T,
  config: Partial<RetryConfig> = {}
): T {
  const retryConfig = { ...defaultRetryConfig, ...config }
  
  return (async (...args: Parameters<T>) => {
    let lastError: any
    
    for (let attempt = 1; attempt <= retryConfig.maxRetries; attempt++) {
      try {
        return await fn(...args)
      } catch (error) {
        lastError = error
        
        // 检查是否应该重试
        if (attempt === retryConfig.maxRetries || !retryConfig.retryCondition!(error)) {
          break
        }
        
        // 执行重试回调
        if (retryConfig.onRetry) {
          retryConfig.onRetry(attempt, error)
        }
        
        // 等待重试延迟
        const delay = calculateDelay(attempt, retryConfig.retryDelay)
        await new Promise(resolve => setTimeout(resolve, delay))
      }
    }
    
    // 达到最大重试次数
    if (retryConfig.onMaxRetriesReached) {
      retryConfig.onMaxRetriesReached(lastError)
    }
    
    throw lastError
  }) as T
}

// 网络错误检查
export const isNetworkError = (error: any): boolean => {
  return (
    !error.response &&
    (error.code === 'ECONNABORTED' ||
     error.code === 'ENOTFOUND' ||
     error.code === 'ECONNREFUSED' ||
     error.message.includes('Network Error'))
  )
}

// 服务器错误检查
export const isServerError = (error: any): boolean => {
  return error.response && error.response.status >= 500
}

// 临时错误检查
export const isTemporaryError = (error: any): boolean => {
  if (isNetworkError(error)) return true
  if (isServerError(error)) return true
  
  // 429 Too Many Requests
  if (error.response && error.response.status === 429) return true
  
  // 408 Request Timeout
  if (error.response && error.response.status === 408) return true
  
  return false
}

// 创建重试配置
export const createRetryConfig = (overrides: Partial<RetryConfig> = {}): RetryConfig => {
  return {
    ...defaultRetryConfig,
    ...overrides,
    retryCondition: (error) => {
      // 网络错误或临时错误时重试
      return isTemporaryError(error)
    }
  }
}

// 不同服务的重试配置
export const serviceRetryConfigs: Record<string, Partial<RetryConfig>> = {
  user: {
    maxRetries: 3,
    retryDelay: 1000
  },
  project: {
    maxRetries: 3,
    retryDelay: 1000
  },
  model: {
    maxRetries: 2,
    retryDelay: 2000 // 模型服务可能较慢
  },
  inference: {
    maxRetries: 1, // 推理服务不重试，避免重复推理
    retryDelay: 1000
  },
  cost: {
    maxRetries: 3,
    retryDelay: 1000
  },
  monitoring: {
    maxRetries: 2,
    retryDelay: 1500
  }
}

// 获取服务重试配置
export const getServiceRetryConfig = (serviceName: string): RetryConfig => {
  const serviceConfig = serviceRetryConfigs[serviceName] || {}
  return createRetryConfig(serviceConfig)
}

// 重试状态管理
export class RetryManager {
  private retryCounts: Map<string, number> = new Map()
  private retryTimers: Map<string, NodeJS.Timeout> = new Map()
  
  // 记录重试
  recordRetry(key: string): void {
    const count = this.retryCounts.get(key) || 0
    this.retryCounts.set(key, count + 1)
  }
  
  // 重置重试计数
  resetRetry(key: string): void {
    this.retryCounts.delete(key)
    const timer = this.retryTimers.get(key)
    if (timer) {
      clearTimeout(timer)
      this.retryTimers.delete(key)
    }
  }
  
  // 获取重试次数
  getRetryCount(key: string): number {
    return this.retryCounts.get(key) || 0
  }
  
  // 设置重试定时器
  setRetryTimer(key: string, delay: number, callback: () => void): void {
    this.clearRetryTimer(key)
    const timer = setTimeout(() => {
      this.retryTimers.delete(key)
      callback()
    }, delay)
    this.retryTimers.set(key, timer)
  }
  
  // 清除重试定时器
  clearRetryTimer(key: string): void {
    const timer = this.retryTimers.get(key)
    if (timer) {
      clearTimeout(timer)
      this.retryTimers.delete(key)
    }
  }
  
  // 清理所有定时器
  cleanup(): void {
    this.retryTimers.forEach(timer => clearTimeout(timer))
    this.retryTimers.clear()
    this.retryCounts.clear()
  }
}

// 全局重试管理器
export const retryManager = new RetryManager()

// 页面卸载时清理
window.addEventListener('beforeunload', () => {
  retryManager.cleanup()
})

export default withRetry
