import request from './request'
import type { 
  Alert, 
  AlertRule,
  SystemMetrics,
  ServiceStatus,
  LogEntry,
  LogQueryParams
} from '@/types'

// 告警管理
export const getAlertList = (params: { page: number; pageSize: number; status?: string; level?: string }) => {
  return request.get<{
    items: Alert[]
    pagination: {
      page: number
      pageSize: number
      total: number
      totalPages: number
    }
  }>('/v5/alerts', { params })
}

export const getAlertById = (id: number) => {
  return request.get<Alert>(`/v5/alerts/${id}`)
}

export const acknowledgeAlert = (id: number) => {
  return request.patch(`/v5/alerts/${id}/acknowledge`)
}

export const resolveAlert = (id: number) => {
  return request.patch(`/v5/alerts/${id}/resolve`)
}

export const ignoreAlert = (id: number) => {
  return request.patch(`/v5/alerts/${id}/ignore`)
}

export const getAlertStats = () => {
  return request.get<{
    total: number
    active: number
    acknowledged: number
    resolved: number
    byLevel: Array<{
      level: string
      count: number
    }>
  }>('/alerts/stats')
}

// 告警规则
export const getAlertRuleList = () => {
  return request.get<AlertRule[]>('/alert-rules')
}

export const getAlertRuleById = (id: number) => {
  return request.get<AlertRule>(`/alert-rules/${id}`)
}

export const createAlertRule = (data: Omit<AlertRule, 'id' | 'createdAt' | 'updatedAt'>) => {
  return request.post<AlertRule>('/alert-rules', data)
}

export const updateAlertRule = (id: number, data: Partial<AlertRule>) => {
  return request.put<AlertRule>(`/alert-rules/${id}`, data)
}

export const deleteAlertRule = (id: number) => {
  return request.delete(`/alert-rules/${id}`)
}

export const testAlertRule = (id: number) => {
  return request.post<{
    triggered: boolean
    message: string
  }>(`/alert-rules/${id}/test`)
}

// 系统监控
export const getSystemMetrics = (params: {
  startTime?: string
  endTime?: string
  granularity?: 'minute' | 'hour' | 'day'
}) => {
  return request.get<SystemMetrics[]>('/monitoring/metrics', { params })
}

export const getServiceStatus = () => {
  return request.get<ServiceStatus[]>('/monitoring/services')
}

export const getServiceMetrics = (serviceName: string, params: {
  startTime?: string
  endTime?: string
}) => {
  return request.get<{
    responseTime: Array<{ timestamp: string; value: number }>
    errorRate: Array<{ timestamp: string; value: number }>
    qps: Array<{ timestamp: string; value: number }>
    cpu: Array<{ timestamp: string; value: number }>
    memory: Array<{ timestamp: string; value: number }>
  }>(`/monitoring/services/${serviceName}/metrics`, { params })
}

// 日志管理
export const getLogList = (params: LogQueryParams) => {
  return request.get<{
    items: LogEntry[]
    pagination: {
      page: number
      pageSize: number
      total: number
      totalPages: number
    }
  }>('/logs', { params })
}

export const getLogById = (id: string) => {
  return request.get<LogEntry>(`/logs/${id}`)
}

export const exportLogs = (params: Partial<LogQueryParams>) => {
  return request.get('/logs/export', { 
    params,
    responseType: 'blob'
  })
}

export const getLogStats = (params: {
  startTime?: string
  endTime?: string
  service?: string
}) => {
  return request.get<{
    totalLogs: number
    errorLogs: number
    warningLogs: number
    infoLogs: number
    debugLogs: number
    byService: Array<{
      service: string
      count: number
    }>
    byLevel: Array<{
      level: string
      count: number
    }>
    hourlyStats: Array<{
      hour: string
      count: number
    }>
  }>('/logs/stats', { params })
}

// 性能分析
export const getPerformanceDashboard = () => {
  return request.get<{
    systemHealth: {
      cpu: number
      memory: number
      disk: number
      network: number
    }
    serviceHealth: Array<{
      name: string
      status: string
      responseTime: number
      errorRate: number
    }>
    topSlowQueries: Array<{
      query: string
      avgTime: number
      count: number
    }>
    resourceUsage: {
      cpu: Array<{ timestamp: string; value: number }>
      memory: Array<{ timestamp: string; value: number }>
      disk: Array<{ timestamp: string; value: number }>
    }
  }>('/monitoring/dashboard')
}

export const getSlowQueries = (params: {
  startTime?: string
  endTime?: string
  limit?: number
}) => {
  return request.get<Array<{
    query: string
    avgTime: number
    count: number
    lastExecuted: string
  }>>('/monitoring/slow-queries', { params })
}

// 健康检查
export const getHealthCheck = () => {
  return request.get<{
    status: 'healthy' | 'unhealthy' | 'degraded'
    services: Array<{
      name: string
      status: string
      responseTime: number
      lastCheck: string
    }>
    overall: {
      uptime: number
      version: string
      environment: string
    }
  }>('/monitoring/health')
}
