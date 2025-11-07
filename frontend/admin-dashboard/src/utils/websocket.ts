import { env, wsEvents } from '@/config/env'

export interface WebSocketMessage {
  type: string
  data: any
  timestamp: number
}

export interface WebSocketOptions {
  url?: string
  reconnectInterval?: number
  maxReconnectAttempts?: number
  heartbeatInterval?: number
}

class WebSocketManager {
  private ws: WebSocket | null = null
  private url: string
  private reconnectInterval: number
  private maxReconnectAttempts: number
  private heartbeatInterval: number
  private reconnectAttempts: number = 0
  private heartbeatTimer: number | null = null
  private listeners: Map<string, Set<(data: any) => void>> = new Map()
  private isConnecting: boolean = false

  constructor(options: WebSocketOptions = {}) {
    this.url = options.url || env.WS_URL
    this.reconnectInterval = options.reconnectInterval || 5000
    this.maxReconnectAttempts = options.maxReconnectAttempts || 10
    this.heartbeatInterval = options.heartbeatInterval || 30000
  }

  // 连接WebSocket
  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      if (this.ws?.readyState === WebSocket.OPEN) {
        resolve()
        return
      }

      if (this.isConnecting) {
        return
      }

      this.isConnecting = true

      try {
        // 暂时禁用WebSocket连接，因为后端服务不支持
        console.log('WebSocket连接已禁用，因为后端服务不支持')
        this.isConnecting = false
        resolve()
        return

        this.ws.onopen = () => {
          console.log('WebSocket连接已建立')
          this.isConnecting = false
          this.reconnectAttempts = 0
          this.startHeartbeat()
          resolve()
        }

        this.ws.onmessage = (event) => {
          try {
            const message: WebSocketMessage = JSON.parse(event.data)
            this.handleMessage(message)
          } catch (error) {
            console.error('WebSocket消息解析失败:', error)
          }
        }

        this.ws.onclose = (event) => {
          console.log('WebSocket连接已关闭:', event.code, event.reason)
          this.isConnecting = false
          this.stopHeartbeat()
          
          if (event.code !== 1000 && this.reconnectAttempts < this.maxReconnectAttempts) {
            this.scheduleReconnect()
          }
        }

        this.ws.onerror = (error) => {
          console.error('WebSocket连接错误:', error)
          this.isConnecting = false
          reject(error)
        }
      } catch (error) {
        this.isConnecting = false
        reject(error)
      }
    })
  }

  // 断开连接
  disconnect(): void {
    this.stopHeartbeat()
    if (this.ws) {
      this.ws.close(1000, '主动断开连接')
      this.ws = null
    }
  }

  // 发送消息
  send(type: string, data: any): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      const message: WebSocketMessage = {
        type,
        data,
        timestamp: Date.now()
      }
      this.ws.send(JSON.stringify(message))
    } else {
      console.warn('WebSocket未连接，无法发送消息')
    }
  }

  // 订阅事件
  subscribe(event: string, callback: (data: any) => void): void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set())
    }
    this.listeners.get(event)!.add(callback)
  }

  // 取消订阅
  unsubscribe(event: string, callback: (data: any) => void): void {
    const eventListeners = this.listeners.get(event)
    if (eventListeners) {
      eventListeners.delete(callback)
      if (eventListeners.size === 0) {
        this.listeners.delete(event)
      }
    }
  }

  // 处理消息
  private handleMessage(message: WebSocketMessage): void {
    const { type, data } = message
    const listeners = this.listeners.get(type)
    
    if (listeners) {
      listeners.forEach(callback => {
        try {
          callback(data)
        } catch (error) {
          console.error(`WebSocket事件处理错误 [${type}]:`, error)
        }
      })
    }
  }

  // 启动心跳
  private startHeartbeat(): void {
    this.stopHeartbeat()
    this.heartbeatTimer = window.setInterval(() => {
      this.send('ping', { timestamp: Date.now() })
    }, this.heartbeatInterval)
  }

  // 停止心跳
  private stopHeartbeat(): void {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer)
      this.heartbeatTimer = null
    }
  }

  // 安排重连
  private scheduleReconnect(): void {
    setTimeout(() => {
      if (this.reconnectAttempts < this.maxReconnectAttempts) {
        this.reconnectAttempts++
        console.log(`WebSocket重连尝试 ${this.reconnectAttempts}/${this.maxReconnectAttempts}`)
        this.connect().catch(error => {
          console.error('WebSocket重连失败:', error)
        })
      } else {
        console.error('WebSocket重连次数已达上限')
      }
    }, this.reconnectInterval)
  }

  // 获取连接状态
  get isConnected(): boolean {
    return this.ws?.readyState === WebSocket.OPEN
  }

  // 获取重连次数
  get reconnectCount(): number {
    return this.reconnectAttempts
  }
}

// 创建全局WebSocket实例
export const wsManager = new WebSocketManager()

// 便捷的事件订阅函数
export const subscribeToEvent = (event: string, callback: (data: any) => void) => {
  wsManager.subscribe(event, callback)
}

export const unsubscribeFromEvent = (event: string, callback: (data: any) => void) => {
  wsManager.unsubscribe(event, callback)
}

// 便捷的消息发送函数
export const sendMessage = (type: string, data: any) => {
  wsManager.send(type, data)
}

// 预定义的事件订阅函数
export const subscribeToSystemStatus = (callback: (data: any) => void) => {
  subscribeToEvent(wsEvents.SYSTEM_STATUS, callback)
}

export const subscribeToSystemMetrics = (callback: (data: any) => void) => {
  subscribeToEvent(wsEvents.SYSTEM_METRICS, callback)
}

export const subscribeToAlerts = (callback: (data: any) => void) => {
  subscribeToEvent(wsEvents.ALERT_TRIGGERED, callback)
  subscribeToEvent(wsEvents.ALERT_RESOLVED, callback)
}

export const subscribeToInference = (callback: (data: any) => void) => {
  subscribeToEvent(wsEvents.INFERENCE_STARTED, callback)
  subscribeToEvent(wsEvents.INFERENCE_COMPLETED, callback)
  subscribeToEvent(wsEvents.INFERENCE_FAILED, callback)
}

export const subscribeToCosts = (callback: (data: any) => void) => {
  subscribeToEvent(wsEvents.COST_THRESHOLD, callback)
  subscribeToEvent(wsEvents.BUDGET_EXCEEDED, callback)
}

export default wsManager
