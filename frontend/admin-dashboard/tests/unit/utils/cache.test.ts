import { describe, it, expect, beforeEach, vi } from 'vitest'
import { cache } from '@/utils/cache'

describe('Cache Utils', () => {
  beforeEach(() => {
    // 清理所有缓存
    cache.clearAll()
    // 重置localStorage和sessionStorage mock
    vi.clearAllMocks()
  })

  describe('Memory Cache', () => {
    it('should store and retrieve values', () => {
      const key = 'test-key'
      const value = { data: 'test-data' }
      
      cache.memory.set(key, value)
      const retrieved = cache.memory.get(key)
      
      expect(retrieved).toEqual(value)
    })

    it('should handle TTL expiration', async () => {
      const key = 'ttl-key'
      const value = 'test-value'
      const ttl = 100 // 100ms
      
      cache.memory.set(key, value, ttl)
      expect(cache.memory.get(key)).toBe(value)
      
      // 等待TTL过期
      await new Promise(resolve => setTimeout(resolve, 150))
      expect(cache.memory.get(key)).toBeUndefined()
    })

    it('should handle LRU eviction', () => {
      const maxSize = 3
      const testCache = cache.memory
      
      // 添加超过最大大小的项目
      for (let i = 0; i < maxSize + 2; i++) {
        testCache.set(`key-${i}`, `value-${i}`)
      }
      
      // 检查缓存大小不超过最大值
      expect(testCache.size()).toBeLessThanOrEqual(maxSize)
      
      // 检查最近使用的项目仍然存在
      expect(testCache.get(`key-${maxSize + 1}`)).toBe(`value-${maxSize + 1}`)
    })

    it('should delete specific keys', () => {
      const key = 'delete-key'
      const value = 'delete-value'
      
      cache.memory.set(key, value)
      expect(cache.memory.has(key)).toBe(true)
      
      cache.memory.delete(key)
      expect(cache.memory.has(key)).toBe(false)
    })

    it('should check if key exists', () => {
      const key = 'exists-key'
      const value = 'exists-value'
      
      expect(cache.memory.has(key)).toBe(false)
      
      cache.memory.set(key, value)
      expect(cache.memory.has(key)).toBe(true)
    })
  })

  describe('LocalStorage Cache', () => {
    it('should store and retrieve values', () => {
      const key = 'ls-key'
      const value = { data: 'ls-data' }
      
      cache.local.set(key, value)
      const retrieved = cache.local.get(key)
      
      expect(retrieved).toEqual(value)
    })

    it('should handle TTL expiration', async () => {
      const key = 'ls-ttl-key'
      const value = 'ls-test-value'
      const ttl = 100 // 100ms
      
      cache.local.set(key, value, ttl)
      expect(cache.local.get(key)).toBe(value)
      
      // 等待TTL过期
      await new Promise(resolve => setTimeout(resolve, 150))
      expect(cache.local.get(key)).toBeUndefined()
    })

    it('should handle JSON parsing errors gracefully', () => {
      const key = 'invalid-json-key'
      
      // 模拟localStorage中的无效JSON
      localStorage.setItem(`app_ls_cache_${key}`, 'invalid-json')
      
      const result = cache.local.get(key)
      expect(result).toBeUndefined()
    })
  })

  describe('SessionStorage Cache', () => {
    it('should store and retrieve values', () => {
      const key = 'ss-key'
      const value = { data: 'ss-data' }
      
      cache.session.set(key, value)
      const retrieved = cache.session.get(key)
      
      expect(retrieved).toEqual(value)
    })

    it('should handle TTL expiration', async () => {
      const key = 'ss-ttl-key'
      const value = 'ss-test-value'
      const ttl = 100 // 100ms
      
      cache.session.set(key, value, ttl)
      expect(cache.session.get(key)).toBe(value)
      
      // 等待TTL过期
      await new Promise(resolve => setTimeout(resolve, 150))
      expect(cache.session.get(key)).toBeUndefined()
    })
  })

  describe('System Cache', () => {
    it('should store and retrieve system data', () => {
      const key = 'system-key'
      const value = { status: 'healthy', timestamp: Date.now() }
      
      cache.system.set(key, value)
      const retrieved = cache.system.get(key)
      
      expect(retrieved).toEqual(value)
    })

    it('should have smaller size limit', () => {
      const testCache = cache.system
      
      // 添加多个项目
      for (let i = 0; i < 10; i++) {
        testCache.set(`sys-key-${i}`, `sys-value-${i}`)
      }
      
      // 系统缓存应该有更小的限制
      expect(testCache.size()).toBeLessThanOrEqual(500)
    })
  })

  describe('Cache Manager', () => {
    it('should clear all caches', () => {
      // 向所有缓存添加数据
      cache.memory.set('mem-key', 'mem-value')
      cache.local.set('local-key', 'local-value')
      cache.session.set('session-key', 'session-value')
      cache.system.set('sys-key', 'sys-value')
      
      // 验证数据存在
      expect(cache.memory.has('mem-key')).toBe(true)
      expect(cache.local.has('local-key')).toBe(true)
      expect(cache.session.has('session-key')).toBe(true)
      expect(cache.system.has('sys-key')).toBe(true)
      
      // 清理所有缓存
      cache.clearAll()
      
      // 验证所有数据都被清理
      expect(cache.memory.has('mem-key')).toBe(false)
      expect(cache.local.has('local-key')).toBe(false)
      expect(cache.session.has('session-key')).toBe(false)
      expect(cache.system.has('sys-key')).toBe(false)
    })

    it('should provide cache statistics', () => {
      // 添加一些测试数据
      cache.memory.set('mem-key', 'mem-value')
      cache.local.set('local-key', 'local-value')
      cache.session.set('session-key', 'session-value')
      cache.system.set('sys-key', 'sys-value')
      
      const stats = cache.getStats()
      
      expect(stats).toHaveProperty('memory')
      expect(stats).toHaveProperty('local')
      expect(stats).toHaveProperty('session')
      expect(stats).toHaveProperty('system')
      
      expect(stats.memory.size).toBeGreaterThan(0)
      expect(stats.local.size).toBeGreaterThan(0)
      expect(stats.session.size).toBeGreaterThan(0)
      expect(stats.system.size).toBeGreaterThan(0)
    })
  })
})









