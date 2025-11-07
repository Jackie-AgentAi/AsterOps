import { cache, CACHE_PREFIXES } from './cache'

export interface CacheOptions {
  ttl?: number
  key?: string
  prefix?: string
  condition?: (result: any) => boolean
  force?: boolean
}

// 缓存装饰器
export function withCache<T extends (...args: any[]) => Promise<any>>(
  fn: T,
  options: CacheOptions = {}
): T {
  const {
    ttl = 300000, // 默认5分钟
    key,
    prefix = 'api',
    condition = () => true,
    force = false
  } = options

  return (async (...args: Parameters<T>) => {
    // 生成缓存键
    const cacheKey = key || `${fn.name}:${JSON.stringify(args)}`
    
    // 如果不强制刷新，尝试从缓存获取
    if (!force) {
      const cached = cache.system.get(cacheKey)
      if (cached) {
        console.log(`缓存命中: ${cacheKey}`)
        return cached
      }
    }

    try {
      // 执行原函数
      const result = await fn(...args)
      
      // 检查是否应该缓存结果
      if (condition(result)) {
        cache.system.set(cacheKey, result, ttl)
        console.log(`结果已缓存: ${cacheKey}`)
      }
      
      return result
    } catch (error) {
      // 如果请求失败，尝试返回缓存的结果
      if (!force) {
        const cached = cache.system.get(cacheKey)
        if (cached) {
          console.log(`请求失败，返回缓存结果: ${cacheKey}`)
          return cached
        }
      }
      throw error
    }
  }) as T
}

// 不同模块的缓存配置
export const cacheConfigs = {
  user: {
    ttl: 300000, // 5分钟
    prefix: CACHE_PREFIXES.USER
  },
  project: {
    ttl: 600000, // 10分钟
    prefix: CACHE_PREFIXES.PROJECT
  },
  model: {
    ttl: 1800000, // 30分钟
    prefix: CACHE_PREFIXES.MODEL
  },
  inference: {
    ttl: 60000, // 1分钟
    prefix: CACHE_PREFIXES.INFERENCE
  },
  cost: {
    ttl: 300000, // 5分钟
    prefix: CACHE_PREFIXES.COST
  },
  monitoring: {
    ttl: 30000, // 30秒
    prefix: CACHE_PREFIXES.MONITORING
  }
}

// 创建带缓存的API函数
export function createCachedApi<T extends (...args: any[]) => Promise<any>>(
  fn: T,
  module: keyof typeof cacheConfigs,
  customOptions: Partial<CacheOptions> = {}
): T {
  const config = cacheConfigs[module]
  const options: CacheOptions = {
    ttl: config.ttl,
    prefix: config.prefix,
    ...customOptions
  }
  
  return withCache(fn, options)
}

// 缓存失效策略
export class CacheInvalidation {
  private static invalidationRules: Map<string, string[]> = new Map()

  // 注册失效规则
  static registerRule(trigger: string, affected: string[]): void {
    this.invalidationRules.set(trigger, affected)
  }

  // 触发缓存失效
  static invalidate(trigger: string): void {
    const affected = this.invalidationRules.get(trigger)
    if (affected) {
      affected.forEach(key => {
        cache.system.delete(key)
        console.log(`缓存已失效: ${key}`)
      })
    }
  }

  // 批量失效
  static invalidateBatch(triggers: string[]): void {
    triggers.forEach(trigger => this.invalidate(trigger))
  }
}

// 注册缓存失效规则
CacheInvalidation.registerRule('user:update', ['user:list', 'user:me'])
CacheInvalidation.registerRule('user:delete', ['user:list', 'user:me'])
CacheInvalidation.registerRule('project:create', ['project:list'])
CacheInvalidation.registerRule('project:update', ['project:list', 'project:detail'])
CacheInvalidation.registerRule('project:delete', ['project:list', 'project:detail'])
CacheInvalidation.registerRule('model:upload', ['model:list'])
CacheInvalidation.registerRule('model:update', ['model:list', 'model:detail'])
CacheInvalidation.registerRule('model:delete', ['model:list', 'model:detail'])
CacheInvalidation.registerRule('inference:create', ['inference:list', 'inference:history'])
CacheInvalidation.registerRule('cost:update', ['cost:list', 'cost:summary'])
CacheInvalidation.registerRule('monitoring:alert', ['monitoring:alerts'])

// 智能缓存策略
export class SmartCache {
  private static requestCounts: Map<string, number> = new Map()
  private static lastAccess: Map<string, number> = new Map()

  // 记录请求
  static recordRequest(key: string): void {
    const count = this.requestCounts.get(key) || 0
    this.requestCounts.set(key, count + 1)
    this.lastAccess.set(key, Date.now())
  }

  // 获取请求频率
  static getRequestFrequency(key: string): number {
    const count = this.requestCounts.get(key) || 0
    const lastAccess = this.lastAccess.get(key) || 0
    const timeDiff = Date.now() - lastAccess
    
    if (timeDiff === 0) return 0
    return count / (timeDiff / 1000) // 每秒请求数
  }

  // 动态调整TTL
  static getDynamicTTL(key: string, baseTTL: number): number {
    const frequency = this.getRequestFrequency(key)
    
    if (frequency > 1) {
      // 高频请求，延长缓存时间
      return baseTTL * 2
    } else if (frequency < 0.1) {
      // 低频请求，缩短缓存时间
      return baseTTL / 2
    }
    
    return baseTTL
  }

  // 清理过期记录
  static cleanup(): void {
    const now = Date.now()
    const maxAge = 3600000 // 1小时
    
    for (const [key, timestamp] of this.lastAccess.entries()) {
      if (now - timestamp > maxAge) {
        this.requestCounts.delete(key)
        this.lastAccess.delete(key)
      }
    }
  }
}

// 定期清理
setInterval(() => {
  SmartCache.cleanup()
}, 300000) // 5分钟清理一次

// 缓存预热
export class CacheWarmup {
  private static warmupTasks: Array<() => Promise<any>> = []

  // 添加预热任务
  static addTask(task: () => Promise<any>): void {
    this.warmupTasks.push(task)
  }

  // 执行预热
  static async execute(): Promise<void> {
    console.log('开始缓存预热...')
    
    const promises = this.warmupTasks.map(async (task, index) => {
      try {
        await task()
        console.log(`预热任务 ${index + 1} 完成`)
      } catch (error) {
        console.warn(`预热任务 ${index + 1} 失败:`, error)
      }
    })
    
    await Promise.allSettled(promises)
    console.log('缓存预热完成')
  }
}

// 缓存统计
export class CacheStats {
  static getStats(): {
    hitRate: number
    missRate: number
    totalRequests: number
    cacheSize: number
    topKeys: Array<{ key: string; count: number }>
  } {
    const stats = cache.stats()
    const totalRequests = Array.from(SmartCache.requestCounts.values()).reduce((a, b) => a + b, 0)
    
    return {
      hitRate: 0, // 需要实现命中率统计
      missRate: 0,
      totalRequests,
      cacheSize: stats.memorySize,
      topKeys: Array.from(SmartCache.requestCounts.entries())
        .map(([key, count]) => ({ key, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 10)
    }
  }
}

export default withCache
