import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useBackendStore } from '@/stores/backend'

describe('Backend Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  describe('Initial State', () => {
    it('should have correct initial state', () => {
      const backendStore = useBackendStore()
      
      expect(backendStore.backendStatus.status).toBe('unknown')
      expect(backendStore.backendStatus.services).toEqual([])
      expect(backendStore.backendStatus.overall.uptime).toBe(0)
      expect(backendStore.backendStatus.overall.version).toBe('N/A')
      expect(backendStore.backendStatus.overall.environment).toBe('N/A')
    })
  })

  describe('Actions', () => {
    it('should set backend status', () => {
      const backendStore = useBackendStore()
      const status = {
        status: 'healthy' as const,
        services: [
          {
            name: 'api-gateway',
            status: 'healthy' as const,
            lastCheck: '2024-01-01T00:00:00Z',
            responseTime: 100
          },
          {
            name: 'user-service',
            status: 'healthy' as const,
            lastCheck: '2024-01-01T00:00:00Z',
            responseTime: 150
          }
        ],
        overall: {
          uptime: 86400,
          version: '1.0.0',
          environment: 'production'
        }
      }
      
      backendStore.setBackendStatus(status)
      
      expect(backendStore.backendStatus).toEqual(status)
    })

    it('should get service health by name', () => {
      const backendStore = useBackendStore()
      const status = {
        status: 'healthy' as const,
        services: [
          {
            name: 'api-gateway',
            status: 'healthy' as const,
            lastCheck: '2024-01-01T00:00:00Z',
            responseTime: 100
          },
          {
            name: 'user-service',
            status: 'degraded' as const,
            lastCheck: '2024-01-01T00:00:00Z',
            responseTime: 500,
            message: 'High response time'
          }
        ],
        overall: {
          uptime: 86400,
          version: '1.0.0',
          environment: 'production'
        }
      }
      
      backendStore.setBackendStatus(status)
      
      const apiGatewayHealth = backendStore.getServiceHealth('api-gateway')
      const userServiceHealth = backendStore.getServiceHealth('user-service')
      const nonExistentHealth = backendStore.getServiceHealth('non-existent')
      
      expect(apiGatewayHealth).toEqual(status.services[0])
      expect(userServiceHealth).toEqual(status.services[1])
      expect(nonExistentHealth).toBeUndefined()
    })
  })

  describe('Getters', () => {
    it('should return correct backend health status', () => {
      const backendStore = useBackendStore()
      
      // 初始状态
      expect(backendStore.isBackendHealthy).toBe(false)
      
      // 设置为健康状态
      backendStore.setBackendStatus({
        status: 'healthy',
        services: [],
        overall: { uptime: 0, version: '1.0.0', environment: 'test' }
      })
      expect(backendStore.isBackendHealthy).toBe(true)
      
      // 设置为不健康状态
      backendStore.setBackendStatus({
        status: 'unhealthy',
        services: [],
        overall: { uptime: 0, version: '1.0.0', environment: 'test' }
      })
      expect(backendStore.isBackendHealthy).toBe(false)
      
      // 设置为降级状态
      backendStore.setBackendStatus({
        status: 'degraded',
        services: [],
        overall: { uptime: 0, version: '1.0.0', environment: 'test' }
      })
      expect(backendStore.isBackendHealthy).toBe(false)
    })

    it('should return unhealthy services', () => {
      const backendStore = useBackendStore()
      const status = {
        status: 'degraded' as const,
        services: [
          {
            name: 'api-gateway',
            status: 'healthy' as const,
            lastCheck: '2024-01-01T00:00:00Z'
          },
          {
            name: 'user-service',
            status: 'unhealthy' as const,
            lastCheck: '2024-01-01T00:00:00Z',
            message: 'Service down'
          },
          {
            name: 'model-service',
            status: 'degraded' as const,
            lastCheck: '2024-01-01T00:00:00Z',
            message: 'High latency'
          },
          {
            name: 'inference-service',
            status: 'unknown' as const,
            lastCheck: '2024-01-01T00:00:00Z'
          }
        ],
        overall: {
          uptime: 86400,
          version: '1.0.0',
          environment: 'production'
        }
      }
      
      backendStore.setBackendStatus(status)
      
      const unhealthyServices = backendStore.unhealthyServices
      
      expect(unhealthyServices).toHaveLength(3)
      expect(unhealthyServices.map(s => s.name)).toEqual([
        'user-service',
        'model-service',
        'inference-service'
      ])
    })

    it('should return service count', () => {
      const backendStore = useBackendStore()
      
      // 初始状态
      expect(backendStore.serviceCount).toBe(0)
      
      // 添加服务
      backendStore.setBackendStatus({
        status: 'healthy',
        services: [
          { name: 'service1', status: 'healthy', lastCheck: '2024-01-01T00:00:00Z' },
          { name: 'service2', status: 'healthy', lastCheck: '2024-01-01T00:00:00Z' },
          { name: 'service3', status: 'healthy', lastCheck: '2024-01-01T00:00:00Z' }
        ],
        overall: { uptime: 0, version: '1.0.0', environment: 'test' }
      })
      
      expect(backendStore.serviceCount).toBe(3)
    })
  })

  describe('Service Status Types', () => {
    it('should handle all service status types', () => {
      const backendStore = useBackendStore()
      const status = {
        status: 'healthy' as const,
        services: [
          { name: 'healthy-service', status: 'healthy' as const, lastCheck: '2024-01-01T00:00:00Z' },
          { name: 'unhealthy-service', status: 'unhealthy' as const, lastCheck: '2024-01-01T00:00:00Z' },
          { name: 'degraded-service', status: 'degraded' as const, lastCheck: '2024-01-01T00:00:00Z' },
          { name: 'unknown-service', status: 'unknown' as const, lastCheck: '2024-01-01T00:00:00Z' }
        ],
        overall: { uptime: 0, version: '1.0.0', environment: 'test' }
      }
      
      backendStore.setBackendStatus(status)
      
      expect(backendStore.getServiceHealth('healthy-service')?.status).toBe('healthy')
      expect(backendStore.getServiceHealth('unhealthy-service')?.status).toBe('unhealthy')
      expect(backendStore.getServiceHealth('degraded-service')?.status).toBe('degraded')
      expect(backendStore.getServiceHealth('unknown-service')?.status).toBe('unknown')
    })
  })

  describe('Overall Status', () => {
    it('should handle different overall status types', () => {
      const backendStore = useBackendStore()
      
      // 测试健康状态
      backendStore.setBackendStatus({
        status: 'healthy',
        services: [],
        overall: { uptime: 86400, version: '1.0.0', environment: 'production' }
      })
      expect(backendStore.isBackendHealthy).toBe(true)
      
      // 测试不健康状态
      backendStore.setBackendStatus({
        status: 'unhealthy',
        services: [],
        overall: { uptime: 0, version: '1.0.0', environment: 'production' }
      })
      expect(backendStore.isBackendHealthy).toBe(false)
      
      // 测试降级状态
      backendStore.setBackendStatus({
        status: 'degraded',
        services: [],
        overall: { uptime: 43200, version: '1.0.0', environment: 'production' }
      })
      expect(backendStore.isBackendHealthy).toBe(false)
    })
  })

  describe('Service Details', () => {
    it('should handle services with response time', () => {
      const backendStore = useBackendStore()
      const status = {
        status: 'healthy' as const,
        services: [
          {
            name: 'fast-service',
            status: 'healthy' as const,
            lastCheck: '2024-01-01T00:00:00Z',
            responseTime: 50
          },
          {
            name: 'slow-service',
            status: 'degraded' as const,
            lastCheck: '2024-01-01T00:00:00Z',
            responseTime: 2000,
            message: 'High response time'
          }
        ],
        overall: { uptime: 0, version: '1.0.0', environment: 'test' }
      }
      
      backendStore.setBackendStatus(status)
      
      const fastService = backendStore.getServiceHealth('fast-service')
      const slowService = backendStore.getServiceHealth('slow-service')
      
      expect(fastService?.responseTime).toBe(50)
      expect(slowService?.responseTime).toBe(2000)
      expect(slowService?.message).toBe('High response time')
    })
  })
})









