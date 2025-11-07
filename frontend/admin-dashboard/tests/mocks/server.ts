import { setupServer } from 'msw/node'
import { handlers } from './handlers'

// 创建MSW服务器实例
export const server = setupServer(...handlers)

// 启动服务器
export const startMockServer = () => {
  server.listen({
    onUnhandledRequest: 'warn'
  })
}

// 停止服务器
export const stopMockServer = () => {
  server.close()
}

// 重置处理器
export const resetMockServer = () => {
  server.resetHandlers()
}

// 添加新的处理器
export const addMockHandlers = (...newHandlers: any[]) => {
  server.use(...newHandlers)
}

// 移除处理器
export const removeMockHandlers = (...handlersToRemove: any[]) => {
  server.use(...handlersToRemove)
}









