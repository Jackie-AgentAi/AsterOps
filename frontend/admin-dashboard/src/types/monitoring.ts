export interface Alert {
  id: number
  title: string
  message: string
  level: 'info' | 'warning' | 'error' | 'critical'
  status: 'active' | 'acknowledged' | 'resolved' | 'ignored'
  source: string
  target: string
  triggeredAt: string
  acknowledgedAt?: string
  resolvedAt?: string
  acknowledgedBy?: string
  resolvedBy?: string
  tags: string[]
}

export interface AlertRule {
  id: number
  name: string
  description: string
  metric: string
  condition: string
  threshold: number
  level: 'info' | 'warning' | 'error' | 'critical'
  enabled: boolean
  createdAt: string
  updatedAt: string
}

export interface SystemMetrics {
  timestamp: string
  cpu: {
    usage: number
    cores: number
    load: number[]
  }
  memory: {
    total: number
    used: number
    free: number
    usage: number
  }
  gpu: Array<{
    id: number
    name: string
    usage: number
    memory: {
      total: number
      used: number
      free: number
    }
    temperature: number
  }>
  disk: Array<{
    name: string
    total: number
    used: number
    free: number
    usage: number
  }>
  network: {
    bytesIn: number
    bytesOut: number
    packetsIn: number
    packetsOut: number
  }
}

export interface ServiceStatus {
  name: string
  status: 'healthy' | 'unhealthy' | 'unknown'
  uptime: number
  version: string
  lastCheck: string
  metrics: {
    responseTime: number
    errorRate: number
    qps: number
  }
}

export interface LogEntry {
  id: string
  timestamp: string
  level: 'debug' | 'info' | 'warn' | 'error'
  service: string
  message: string
  context: Record<string, any>
  traceId?: string
  spanId?: string
}

export interface LogQueryParams {
  page: number
  pageSize: number
  service?: string
  level?: string
  startTime?: string
  endTime?: string
  keyword?: string
  traceId?: string
}
