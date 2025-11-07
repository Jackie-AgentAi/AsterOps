import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { createWebSocketClient } from '@/utils/websocket'

// Mock WebSocket
const mockWebSocket = {
  send: vi.fn(),
  close: vi.fn(),
  addEventListener: vi.fn(),
  removeEventListener: vi.fn(),
  readyState: WebSocket.OPEN
}

// Mock global WebSocket
global.WebSocket = vi.fn(() => mockWebSocket) as any

describe('WebSocket Utils', () => {
  let wsClient: any

  beforeEach(() => {
    vi.clearAllMocks()
    // 重置WebSocket状态
    mockWebSocket.readyState = WebSocket.OPEN
  })

  afterEach(() => {
    if (wsClient) {
      wsClient.close()
    }
  })

  describe('WebSocketClient', () => {
    it('should create WebSocket connection', () => {
      wsClient = createWebSocketClient({
        url: 'ws://localhost:8080/ws'
      })

      expect(global.WebSocket).toHaveBeenCalledWith('ws://localhost:8080/ws', undefined)
    })

    it('should handle connection open', () => {
      const onOpen = vi.fn()
      wsClient = createWebSocketClient({
        url: 'ws://localhost:8080/ws'
      })

      wsClient.on('open', onOpen)

      // 模拟连接打开
      const openHandler = mockWebSocket.addEventListener.mock.calls.find(
        call => call[0] === 'open'
      )?.[1]
      
      if (openHandler) {
        openHandler()
        expect(onOpen).toHaveBeenCalled()
      }
    })

    it('should handle incoming messages', () => {
      const onMessage = vi.fn()
      wsClient = createWebSocketClient({
        url: 'ws://localhost:8080/ws'
      })

      wsClient.on('message', onMessage)

      // 模拟接收消息
      const messageHandler = mockWebSocket.addEventListener.mock.calls.find(
        call => call[0] === 'message'
      )?.[1]
      
      if (messageHandler) {
        const testMessage = { data: JSON.stringify({ type: 'test', payload: 'data' }) }
        messageHandler(testMessage)
        expect(onMessage).toHaveBeenCalledWith('data')
      }
    })

    it('should handle non-JSON messages', () => {
      const onMessage = vi.fn()
      wsClient = createWebSocketClient({
        url: 'ws://localhost:8080/ws'
      })

      wsClient.on('message', onMessage)

      // 模拟接收非JSON消息
      const messageHandler = mockWebSocket.addEventListener.mock.calls.find(
        call => call[0] === 'message'
      )?.[1]
      
      if (messageHandler) {
        const testMessage = { data: 'plain text message' }
        messageHandler(testMessage)
        expect(onMessage).toHaveBeenCalledWith('plain text message')
      }
    })

    it('should handle connection close', () => {
      const onClose = vi.fn()
      wsClient = createWebSocketClient({
        url: 'ws://localhost:8080/ws'
      })

      wsClient.on('close', onClose)

      // 模拟连接关闭
      const closeHandler = mockWebSocket.addEventListener.mock.calls.find(
        call => call[0] === 'close'
      )?.[1]
      
      if (closeHandler) {
        closeHandler({ code: 1000, reason: 'Normal closure' })
        expect(onClose).toHaveBeenCalledWith({ code: 1000, reason: 'Normal closure' })
      }
    })

    it('should handle connection errors', () => {
      const onError = vi.fn()
      wsClient = createWebSocketClient({
        url: 'ws://localhost:8080/ws'
      })

      wsClient.on('error', onError)

      // 模拟连接错误
      const errorHandler = mockWebSocket.addEventListener.mock.calls.find(
        call => call[0] === 'error'
      )?.[1]
      
      if (errorHandler) {
        const testError = new Error('Connection failed')
        errorHandler(testError)
        expect(onError).toHaveBeenCalledWith(testError)
      }
    })

    it('should send messages', () => {
      wsClient = createWebSocketClient({
        url: 'ws://localhost:8080/ws'
      })

      wsClient.send('test-type', { data: 'test-payload' })

      expect(mockWebSocket.send).toHaveBeenCalledWith(
        JSON.stringify({ type: 'test-type', payload: { data: 'test-payload' } })
      )
    })

    it('should queue messages when not connected', () => {
      mockWebSocket.readyState = WebSocket.CONNECTING
      wsClient = createWebSocketClient({
        url: 'ws://localhost:8080/ws'
      })

      wsClient.send('test-type', { data: 'test-payload' })

      // 消息应该被排队，而不是立即发送
      expect(mockWebSocket.send).not.toHaveBeenCalled()

      // 模拟连接打开
      mockWebSocket.readyState = WebSocket.OPEN
      const openHandler = mockWebSocket.addEventListener.mock.calls.find(
        call => call[0] === 'open'
      )?.[1]
      
      if (openHandler) {
        openHandler()
        // 现在应该发送排队的消息
        expect(mockWebSocket.send).toHaveBeenCalledWith(
          JSON.stringify({ type: 'test-type', payload: { data: 'test-payload' } })
        )
      }
    })

    it('should handle reconnection', async () => {
      const onMaxReconnectAttempts = vi.fn()
      wsClient = createWebSocketClient({
        url: 'ws://localhost:8080/ws',
        maxReconnectAttempts: 2,
        reconnectInterval: 100
      })

      wsClient.on('maxReconnectAttempts', onMaxReconnectAttempts)

      // 模拟连接关闭
      const closeHandler = mockWebSocket.addEventListener.mock.calls.find(
        call => call[0] === 'close'
      )?.[1]
      
      if (closeHandler) {
        closeHandler({ code: 1006, reason: 'Abnormal closure' })
        
        // 等待重连尝试完成
        await new Promise(resolve => setTimeout(resolve, 500))
        
        expect(onMaxReconnectAttempts).toHaveBeenCalled()
      }
    })

    it('should send heartbeat', async () => {
      wsClient = createWebSocketClient({
        url: 'ws://localhost:8080/ws'
      })

      // 模拟连接打开
      const openHandler = mockWebSocket.addEventListener.mock.calls.find(
        call => call[0] === 'open'
      )?.[1]
      
      if (openHandler) {
        openHandler()
        
        // 等待心跳发送
        await new Promise(resolve => setTimeout(resolve, 50))
        
        expect(mockWebSocket.send).toHaveBeenCalledWith(
          expect.stringContaining('"type":"heartbeat"')
        )
      }
    })

    it('should remove event listeners', () => {
      const onMessage = vi.fn()
      wsClient = createWebSocketClient({
        url: 'ws://localhost:8080/ws'
      })

      wsClient.on('message', onMessage)
      wsClient.off('message', onMessage)

      // 模拟接收消息
      const messageHandler = mockWebSocket.addEventListener.mock.calls.find(
        call => call[0] === 'message'
      )?.[1]
      
      if (messageHandler) {
        const testMessage = { data: JSON.stringify({ type: 'test', payload: 'data' }) }
        messageHandler(testMessage)
        expect(onMessage).not.toHaveBeenCalled()
      }
    })

    it('should close connection', () => {
      wsClient = createWebSocketClient({
        url: 'ws://localhost:8080/ws'
      })

      wsClient.close()

      expect(mockWebSocket.close).toHaveBeenCalled()
    })

    it('should provide connection status', () => {
      wsClient = createWebSocketClient({
        url: 'ws://localhost:8080/ws'
      })

      expect(wsClient.readyState).toBe(WebSocket.OPEN)
      expect(wsClient.isConnectedStatus).toBe(true)
    })
  })
})









