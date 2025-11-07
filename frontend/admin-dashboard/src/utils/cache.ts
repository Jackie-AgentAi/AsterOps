import { env } from '@/config/env'

export interface CacheItem<T = any> {
  data: T
  timestamp: number
  ttl: number
  key: string
}

export interface CacheConfig {
  maxSize: number
  defaultTTL: number
  enableMemoryCache: boolean
  enableLocalStorage: boolean
  enableSessionStorage: boolean
}

// 默认缓存配置
const defaultConfig: CacheConfig = {
  maxSize: env.CACHE_MAX_SIZE,
  defaultTTL: env.CACHE_TTL,
  enableMemoryCache: true,
  enableLocalStorage: true,
  enableSessionStorage: false
}

class CacheManager {
  private memoryCache: Map<string, CacheItem> = new Map()
  private config: CacheConfig
  private accessOrder: string[] = []

  constructor(config: Partial<CacheConfig> = {}) {
    this.config = { ...defaultConfig, ...config }
  }

  // 生成缓存键
  private generateKey(prefix: string, key: string): string {
    return `${prefix}:${key}`
  }

  // 检查缓存是否过期
  private isExpired(item: CacheItem): boolean {
    return Date.now() - item.timestamp > item.ttl
  }

  // 清理过期缓存
  private cleanExpired(): void {
    const now = Date.now()
    for (const [key, item] of this.memoryCache.entries()) {
      if (now - item.timestamp > item.ttl) {
        this.memoryCache.delete(key)
        const index = this.accessOrder.indexOf(key)
        if (index > -1) {
          this.accessOrder.splice(index, 1)
        }
      }
    }
  }

  // LRU清理
  private evictLRU(): void {
    if (this.memoryCache.size >= this.config.maxSize) {
      const oldestKey = this.accessOrder.shift()
      if (oldestKey) {
        this.memoryCache.delete(oldestKey)
      }
    }
  }

  // 更新访问顺序
  private updateAccessOrder(key: string): void {
    const index = this.accessOrder.indexOf(key)
    if (index > -1) {
      this.accessOrder.splice(index, 1)
    }
    this.accessOrder.push(key)
  }

  // 设置缓存
  set<T>(prefix: string, key: string, data: T, ttl?: number): void {
    const cacheKey = this.generateKey(prefix, key)
    const item: CacheItem<T> = {
      data,
      timestamp: Date.now(),
      ttl: ttl || this.config.defaultTTL,
      key: cacheKey
    }

    // 内存缓存
    if (this.config.enableMemoryCache) {
      this.cleanExpired()
      this.evictLRU()
      this.memoryCache.set(cacheKey, item)
      this.updateAccessOrder(cacheKey)
    }

    // 本地存储
    if (this.config.enableLocalStorage) {
      try {
        localStorage.setItem(cacheKey, JSON.stringify(item))
      } catch (error) {
        console.warn('LocalStorage缓存失败:', error)
      }
    }

    // 会话存储
    if (this.config.enableSessionStorage) {
      try {
        sessionStorage.setItem(cacheKey, JSON.stringify(item))
      } catch (error) {
        console.warn('SessionStorage缓存失败:', error)
      }
    }
  }

  // 获取缓存
  get<T>(prefix: string, key: string): T | null {
    const cacheKey = this.generateKey(prefix, key)

    // 优先从内存缓存获取
    if (this.config.enableMemoryCache) {
      const memoryItem = this.memoryCache.get(cacheKey)
      if (memoryItem && !this.isExpired(memoryItem)) {
        this.updateAccessOrder(cacheKey)
        return memoryItem.data as T
      }
    }

    // 从本地存储获取
    if (this.config.enableLocalStorage) {
      try {
        const localItem = localStorage.getItem(cacheKey)
        if (localItem) {
          const item: CacheItem<T> = JSON.parse(localItem)
          if (!this.isExpired(item)) {
            // 回写到内存缓存
            if (this.config.enableMemoryCache) {
              this.memoryCache.set(cacheKey, item)
              this.updateAccessOrder(cacheKey)
            }
            return item.data
          } else {
            localStorage.removeItem(cacheKey)
          }
        }
      } catch (error) {
        console.warn('LocalStorage读取失败:', error)
      }
    }

    // 从会话存储获取
    if (this.config.enableSessionStorage) {
      try {
        const sessionItem = sessionStorage.getItem(cacheKey)
        if (sessionItem) {
          const item: CacheItem<T> = JSON.parse(sessionItem)
          if (!this.isExpired(item)) {
            return item.data
          } else {
            sessionStorage.removeItem(cacheKey)
          }
        }
      } catch (error) {
        console.warn('SessionStorage读取失败:', error)
      }
    }

    return null
  }

  // 删除缓存
  delete(prefix: string, key: string): void {
    const cacheKey = this.generateKey(prefix, key)

    // 从内存缓存删除
    if (this.config.enableMemoryCache) {
      this.memoryCache.delete(cacheKey)
      const index = this.accessOrder.indexOf(cacheKey)
      if (index > -1) {
        this.accessOrder.splice(index, 1)
      }
    }

    // 从本地存储删除
    if (this.config.enableLocalStorage) {
      try {
        localStorage.removeItem(cacheKey)
      } catch (error) {
        console.warn('LocalStorage删除失败:', error)
      }
    }

    // 从会话存储删除
    if (this.config.enableSessionStorage) {
      try {
        sessionStorage.removeItem(cacheKey)
      } catch (error) {
        console.warn('SessionStorage删除失败:', error)
      }
    }
  }

  // 清空缓存
  clear(prefix?: string): void {
    if (prefix) {
      // 清空指定前缀的缓存
      const keysToDelete: string[] = []
      
      // 内存缓存
      if (this.config.enableMemoryCache) {
        for (const key of this.memoryCache.keys()) {
          if (key.startsWith(prefix + ':')) {
            keysToDelete.push(key)
          }
        }
        keysToDelete.forEach(key => {
          this.memoryCache.delete(key)
          const index = this.accessOrder.indexOf(key)
          if (index > -1) {
            this.accessOrder.splice(index, 1)
          }
        })
      }

      // 本地存储
      if (this.config.enableLocalStorage) {
        try {
          for (let i = 0; i < localStorage.length; i++) {
            const key = localStorage.key(i)
            if (key && key.startsWith(prefix + ':')) {
              localStorage.removeItem(key)
            }
          }
        } catch (error) {
          console.warn('LocalStorage清空失败:', error)
        }
      }

      // 会话存储
      if (this.config.enableSessionStorage) {
        try {
          for (let i = 0; i < sessionStorage.length; i++) {
            const key = sessionStorage.key(i)
            if (key && key.startsWith(prefix + ':')) {
              sessionStorage.removeItem(key)
            }
          }
        } catch (error) {
          console.warn('SessionStorage清空失败:', error)
        }
      }
    } else {
      // 清空所有缓存
      if (this.config.enableMemoryCache) {
        this.memoryCache.clear()
        this.accessOrder = []
      }

      if (this.config.enableLocalStorage) {
        try {
          localStorage.clear()
        } catch (error) {
          console.warn('LocalStorage清空失败:', error)
        }
      }

      if (this.config.enableSessionStorage) {
        try {
          sessionStorage.clear()
        } catch (error) {
          console.warn('SessionStorage清空失败:', error)
        }
      }
    }
  }

  // 获取缓存统计
  getStats(): {
    memorySize: number
    memoryKeys: string[]
    localStorageSize: number
    sessionStorageSize: number
  } {
    let localStorageSize = 0
    let sessionStorageSize = 0

    if (this.config.enableLocalStorage) {
      try {
        for (let i = 0; i < localStorage.length; i++) {
          const key = localStorage.key(i)
          if (key) {
            const value = localStorage.getItem(key)
            if (value) {
              localStorageSize += key.length + value.length
            }
          }
        }
      } catch (error) {
        console.warn('LocalStorage统计失败:', error)
      }
    }

    if (this.config.enableSessionStorage) {
      try {
        for (let i = 0; i < sessionStorage.length; i++) {
          const key = sessionStorage.key(i)
          if (key) {
            const value = sessionStorage.getItem(key)
            if (value) {
              sessionStorageSize += key.length + value.length
            }
          }
        }
      } catch (error) {
        console.warn('SessionStorage统计失败:', error)
      }
    }

    return {
      memorySize: this.memoryCache.size,
      memoryKeys: Array.from(this.memoryCache.keys()),
      localStorageSize,
      sessionStorageSize
    }
  }
}

// 创建全局缓存管理器
export const cacheManager = new CacheManager()

// 缓存前缀常量
export const CACHE_PREFIXES = {
  USER: 'user',
  PROJECT: 'project',
  MODEL: 'model',
  INFERENCE: 'inference',
  COST: 'cost',
  MONITORING: 'monitoring',
  SYSTEM: 'system'
} as const

// 便捷的缓存操作函数
export const cache = {
  // 用户相关缓存
  user: {
    set: <T>(key: string, data: T, ttl?: number) => 
      cacheManager.set(CACHE_PREFIXES.USER, key, data, ttl),
    get: <T>(key: string) => 
      cacheManager.get<T>(CACHE_PREFIXES.USER, key),
    delete: (key: string) => 
      cacheManager.delete(CACHE_PREFIXES.USER, key),
    clear: () => 
      cacheManager.clear(CACHE_PREFIXES.USER)
  },

  // 项目相关缓存
  project: {
    set: <T>(key: string, data: T, ttl?: number) => 
      cacheManager.set(CACHE_PREFIXES.PROJECT, key, data, ttl),
    get: <T>(key: string) => 
      cacheManager.get<T>(CACHE_PREFIXES.PROJECT, key),
    delete: (key: string) => 
      cacheManager.delete(CACHE_PREFIXES.PROJECT, key),
    clear: () => 
      cacheManager.clear(CACHE_PREFIXES.PROJECT)
  },

  // 模型相关缓存
  model: {
    set: <T>(key: string, data: T, ttl?: number) => 
      cacheManager.set(CACHE_PREFIXES.MODEL, key, data, ttl),
    get: <T>(key: string) => 
      cacheManager.get<T>(CACHE_PREFIXES.MODEL, key),
    delete: (key: string) => 
      cacheManager.delete(CACHE_PREFIXES.MODEL, key),
    clear: () => 
      cacheManager.clear(CACHE_PREFIXES.MODEL)
  },

  // 推理相关缓存
  inference: {
    set: <T>(key: string, data: T, ttl?: number) => 
      cacheManager.set(CACHE_PREFIXES.INFERENCE, key, data, ttl),
    get: <T>(key: string) => 
      cacheManager.get<T>(CACHE_PREFIXES.INFERENCE, key),
    delete: (key: string) => 
      cacheManager.delete(CACHE_PREFIXES.INFERENCE, key),
    clear: () => 
      cacheManager.clear(CACHE_PREFIXES.INFERENCE)
  },

  // 成本相关缓存
  cost: {
    set: <T>(key: string, data: T, ttl?: number) => 
      cacheManager.set(CACHE_PREFIXES.COST, key, data, ttl),
    get: <T>(key: string) => 
      cacheManager.get<T>(CACHE_PREFIXES.COST, key),
    delete: (key: string) => 
      cacheManager.delete(CACHE_PREFIXES.COST, key),
    clear: () => 
      cacheManager.clear(CACHE_PREFIXES.COST)
  },

  // 监控相关缓存
  monitoring: {
    set: <T>(key: string, data: T, ttl?: number) => 
      cacheManager.set(CACHE_PREFIXES.MONITORING, key, data, ttl),
    get: <T>(key: string) => 
      cacheManager.get<T>(CACHE_PREFIXES.MONITORING, key),
    delete: (key: string) => 
      cacheManager.delete(CACHE_PREFIXES.MONITORING, key),
    clear: () => 
      cacheManager.clear(CACHE_PREFIXES.MONITORING)
  },

  // 系统相关缓存
  system: {
    set: <T>(key: string, data: T, ttl?: number) => 
      cacheManager.set(CACHE_PREFIXES.SYSTEM, key, data, ttl),
    get: <T>(key: string) => 
      cacheManager.get<T>(CACHE_PREFIXES.SYSTEM, key),
    delete: (key: string) => 
      cacheManager.delete(CACHE_PREFIXES.SYSTEM, key),
    clear: () => 
      cacheManager.clear(CACHE_PREFIXES.SYSTEM)
  },

  // 全局操作
  clear: () => cacheManager.clear(),
  stats: () => cacheManager.getStats()
}

export default cacheManager
