import { describe, it, expect, vi, beforeEach } from 'vitest'
import { withRetry, createRetryConfig } from '@/utils/api-retry'

describe('API Retry Utils', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('createRetryConfig', () => {
    it('should create default retry config', () => {
      const config = createRetryConfig()
      
      expect(config.maxRetries).toBe(3)
      expect(config.retryDelay).toBe(1000)
      expect(config.factor).toBe(2)
      expect(config.shouldRetry).toBeDefined()
    })

    it('should merge with custom config', () => {
      const customConfig = {
        maxRetries: 5,
        retryDelay: 2000
      }
      
      const config = createRetryConfig(customConfig)
      
      expect(config.maxRetries).toBe(5)
      expect(config.retryDelay).toBe(2000)
      expect(config.factor).toBe(2) // 默认值
    })
  })

  describe('withRetry', () => {
    it('should succeed on first attempt', async () => {
      const mockFn = vi.fn().mockResolvedValue('success')
      const retryFn = withRetry(mockFn)
      
      const result = await retryFn()
      
      expect(result).toBe('success')
      expect(mockFn).toHaveBeenCalledTimes(1)
    })

    it('should retry on network errors', async () => {
      const networkError = new Error('Network Error')
      ;(networkError as any).code = 'ECONNABORTED'
      
      const mockFn = vi.fn()
        .mockRejectedValueOnce(networkError)
        .mockRejectedValueOnce(networkError)
        .mockResolvedValue('success')
      
      const retryFn = withRetry(mockFn)
      
      const result = await retryFn()
      
      expect(result).toBe('success')
      expect(mockFn).toHaveBeenCalledTimes(3)
    })

    it('should retry on 5xx server errors', async () => {
      const serverError = new Error('Server Error')
      ;(serverError as any).response = { status: 500 }
      
      const mockFn = vi.fn()
        .mockRejectedValueOnce(serverError)
        .mockRejectedValueOnce(serverError)
        .mockResolvedValue('success')
      
      const retryFn = withRetry(mockFn)
      
      const result = await retryFn()
      
      expect(result).toBe('success')
      expect(mockFn).toHaveBeenCalledTimes(3)
    })

    it('should not retry on 4xx client errors', async () => {
      const clientError = new Error('Client Error')
      ;(clientError as any).response = { status: 400 }
      
      const mockFn = vi.fn().mockRejectedValue(clientError)
      const retryFn = withRetry(mockFn)
      
      await expect(retryFn()).rejects.toThrow('Client Error')
      expect(mockFn).toHaveBeenCalledTimes(1)
    })

    it('should respect max retries limit', async () => {
      const networkError = new Error('Network Error')
      ;(networkError as any).code = 'ECONNABORTED'
      
      const mockFn = vi.fn().mockRejectedValue(networkError)
      const retryFn = withRetry(mockFn, createRetryConfig({ maxRetries: 2 }))
      
      await expect(retryFn()).rejects.toThrow('Network Error')
      expect(mockFn).toHaveBeenCalledTimes(3) // 1 initial + 2 retries
    })

    it('should use exponential backoff', async () => {
      const networkError = new Error('Network Error')
      ;(networkError as any).code = 'ECONNABORTED'
      
      const mockFn = vi.fn().mockRejectedValue(networkError)
      const retryFn = withRetry(mockFn, createRetryConfig({ 
        maxRetries: 2, 
        retryDelay: 100,
        factor: 2 
      }))
      
      const startTime = Date.now()
      
      try {
        await retryFn()
      } catch (error) {
        // 忽略错误，只关心重试时间
      }
      
      const endTime = Date.now()
      const totalTime = endTime - startTime
      
      // 应该至少等待 100ms + 200ms = 300ms
      expect(totalTime).toBeGreaterThanOrEqual(300)
    })

    it('should use custom shouldRetry function', async () => {
      const customError = new Error('Custom Error')
      const shouldRetry = vi.fn().mockReturnValue(false)
      
      const mockFn = vi.fn().mockRejectedValue(customError)
      const retryFn = withRetry(mockFn, createRetryConfig({ shouldRetry }))
      
      await expect(retryFn()).rejects.toThrow('Custom Error')
      expect(mockFn).toHaveBeenCalledTimes(1)
      expect(shouldRetry).toHaveBeenCalledWith(customError)
    })

    it('should pass arguments to wrapped function', async () => {
      const mockFn = vi.fn().mockResolvedValue('success')
      const retryFn = withRetry(mockFn)
      
      await retryFn('arg1', 'arg2', { key: 'value' })
      
      expect(mockFn).toHaveBeenCalledWith('arg1', 'arg2', { key: 'value' })
    })

    it('should handle async functions', async () => {
      const asyncMockFn = vi.fn().mockImplementation(async () => {
        await new Promise(resolve => setTimeout(resolve, 10))
        return 'async success'
      })
      
      const retryFn = withRetry(asyncMockFn)
      const result = await retryFn()
      
      expect(result).toBe('async success')
      expect(asyncMockFn).toHaveBeenCalledTimes(1)
    })
  })
})









