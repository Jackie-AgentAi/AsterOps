import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { backendIntegration } from '@/utils/backend-integration'
import { wsManager } from '@/utils/websocket'
import type { IntegrationStatus, ServiceHealth } from '@/utils/backend-integration'

export const useBackendStore = defineStore('backend', () => {
  // 状态
  const isInitialized = ref(false)
  const isConnecting = ref(false)
  const lastHealthCheck = ref<Date | null>(null)
  const integrationStatus = ref<IntegrationStatus>({
    apiGateway: false,
    services: {},
    database: false,
    cache: false,
    websocket: false,
    overall: 'unhealthy'
  })
  const serviceDetails = ref<ServiceHealth[]>([])
  const connectionErrors = ref<string[]>([])

  // 计算属性
  const isHealthy = computed(() => integrationStatus.value.overall === 'healthy')
  const isDegraded = computed(() => integrationStatus.value.overall === 'degraded')
  const isUnhealthy = computed(() => integrationStatus.value.overall === 'unhealthy')
  
  const healthyServicesCount = computed(() => {
    return Object.values(integrationStatus.value.services).filter(Boolean).length
  })
  
  const totalServicesCount = computed(() => {
    return Object.keys(integrationStatus.value.services).length
  })
  
  const serviceHealthPercentage = computed(() => {
    if (totalServicesCount.value === 0) return 0
    return Math.round((healthyServicesCount.value / totalServicesCount.value) * 100)
  })

  // 动作
  const initialize = async (): Promise<boolean> => {
    if (isConnecting.value) return false
    
    isConnecting.value = true
    connectionErrors.value = []

    try {
      const success = await backendIntegration.initialize()
      isInitialized.value = success
      
      if (success) {
        // 设置WebSocket事件监听
        setupWebSocketListeners()
        
        // 执行初始健康检查
        await performHealthCheck()
      } else {
        connectionErrors.value.push('后端集成初始化失败')
      }
      
      return success
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '未知错误'
      connectionErrors.value.push(errorMessage)
      console.error('后端集成初始化失败:', error)
      return false
    } finally {
      isConnecting.value = false
    }
  }

  const performHealthCheck = async (): Promise<void> => {
    try {
      const status = await backendIntegration.performHealthCheck()
      integrationStatus.value = status
      lastHealthCheck.value = new Date()
      
      // 获取服务详情
      const details = await backendIntegration.getServiceDetails()
      serviceDetails.value = details
      
      // 清除之前的错误
      if (status.overall === 'healthy') {
        connectionErrors.value = []
      }
    } catch (error) {
      console.error('健康检查失败:', error)
      connectionErrors.value.push('健康检查失败')
    }
  }

  const testConnectivity = async (): Promise<{
    success: boolean
    latency: number
    error?: string
  }> => {
    try {
      return await backendIntegration.testApiConnectivity()
    } catch (error) {
      return {
        success: false,
        latency: 0,
        error: error instanceof Error ? error.message : '未知错误'
      }
    }
  }

  const getSystemInfo = async () => {
    try {
      return await backendIntegration.getSystemInfo()
    } catch (error) {
      console.error('获取系统信息失败:', error)
      return null
    }
  }

  const checkApiCompatibility = async () => {
    try {
      return await backendIntegration.checkApiCompatibility()
    } catch (error) {
      console.error('API兼容性检查失败:', error)
      return null
    }
  }

  // WebSocket事件监听设置
  const setupWebSocketListeners = () => {
    // 系统状态更新
    wsManager.subscribe('system:status', (data) => {
      console.log('收到系统状态更新:', data)
      // 可以在这里更新相关状态
    })

    // 服务状态更新
    wsManager.subscribe('service:status', (data) => {
      console.log('收到服务状态更新:', data)
      // 更新服务状态
      if (data.serviceName && typeof data.status === 'boolean') {
        integrationStatus.value.services[data.serviceName] = data.status
      }
    })

    // 告警事件
    wsManager.subscribe('alert:triggered', (data) => {
      console.log('收到告警:', data)
      // 可以在这里显示告警通知
    })

    // 连接状态变化
    wsManager.subscribe('connection:status', (data) => {
      console.log('WebSocket连接状态:', data)
      if (data.connected) {
        integrationStatus.value.websocket = true
      } else {
        integrationStatus.value.websocket = false
      }
    })
  }

  // 重连
  const reconnect = async (): Promise<boolean> => {
    if (isConnecting.value) return false
    
    isConnecting.value = true
    
    try {
      // 断开现有连接
      wsManager.disconnect()
      
      // 重新初始化
      const success = await initialize()
      
      if (success) {
        connectionErrors.value = []
      }
      
      return success
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '重连失败'
      connectionErrors.value.push(errorMessage)
      console.error('重连失败:', error)
      return false
    } finally {
      isConnecting.value = false
    }
  }

  // 清理
  const cleanup = () => {
    backendIntegration.cleanup()
    isInitialized.value = false
    integrationStatus.value = {
      apiGateway: false,
      services: {},
      database: false,
      cache: false,
      websocket: false,
      overall: 'unhealthy'
    }
    serviceDetails.value = []
    connectionErrors.value = []
    lastHealthCheck.value = null
  }

  // 获取服务状态
  const getServiceStatus = (serviceName: string): boolean => {
    return integrationStatus.value.services[serviceName] || false
  }

  // 获取服务详情
  const getServiceDetail = (serviceName: string): ServiceHealth | undefined => {
    return serviceDetails.value.find(service => service.name === serviceName)
  }

  // 检查特定服务健康状态
  const isServiceHealthy = (serviceName: string): boolean => {
    const detail = getServiceDetail(serviceName)
    return detail?.status === 'healthy' || false
  }

  // 获取连接统计
  const getConnectionStats = () => {
    return {
      isInitialized: isInitialized.value,
      isConnecting: isConnecting.value,
      isHealthy: isHealthy.value,
      isDegraded: isDegraded.value,
      isUnhealthy: isUnhealthy.value,
      healthyServicesCount: healthyServicesCount.value,
      totalServicesCount: totalServicesCount.value,
      serviceHealthPercentage: serviceHealthPercentage.value,
      lastHealthCheck: lastHealthCheck.value,
      errorCount: connectionErrors.value.length
    }
  }

  return {
    // 状态
    isInitialized,
    isConnecting,
    lastHealthCheck,
    integrationStatus,
    serviceDetails,
    connectionErrors,
    
    // 计算属性
    isHealthy,
    isDegraded,
    isUnhealthy,
    healthyServicesCount,
    totalServicesCount,
    serviceHealthPercentage,
    
    // 动作
    initialize,
    performHealthCheck,
    testConnectivity,
    getSystemInfo,
    checkApiCompatibility,
    reconnect,
    cleanup,
    getServiceStatus,
    getServiceDetail,
    isServiceHealthy,
    getConnectionStats
  }
})
