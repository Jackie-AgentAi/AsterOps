import { http, HttpResponse } from 'msw'
import { createTestData } from '../utils/test-utils'

// 模拟API响应数据
const mockUsers = [
  createTestData.user({ id: 1, username: 'admin', role: 'admin' }),
  createTestData.user({ id: 2, username: 'user1', role: 'user' }),
  createTestData.user({ id: 3, username: 'user2', role: 'user' })
]

const mockProjects = [
  createTestData.project({ id: 1, name: 'Project 1' }),
  createTestData.project({ id: 2, name: 'Project 2' }),
  createTestData.project({ id: 3, name: 'Project 3' })
]

const mockModels = [
  createTestData.model({ id: 1, name: 'Model 1', version: '1.0.0' }),
  createTestData.model({ id: 2, name: 'Model 2', version: '2.0.0' }),
  createTestData.model({ id: 3, name: 'Model 3', version: '1.5.0' })
]

const mockInferenceTasks = [
  createTestData.inferenceTask({ id: 'task-1', status: 'completed' }),
  createTestData.inferenceTask({ id: 'task-2', status: 'running' }),
  createTestData.inferenceTask({ id: 'task-3', status: 'failed' })
]

const mockCostRecords = [
  createTestData.costRecord({ id: 1, amount: 100.50 }),
  createTestData.costRecord({ id: 2, amount: 250.75 }),
  createTestData.costRecord({ id: 3, amount: 75.25 })
]

const mockAlerts = [
  createTestData.alert({ id: 1, level: 'warning' }),
  createTestData.alert({ id: 2, level: 'error' }),
  createTestData.alert({ id: 3, level: 'info' })
]

// API 处理器
export const handlers = [
  // 认证相关
  http.post('/api/v1/auth/login', () => {
    return HttpResponse.json({
      code: 200,
      message: '登录成功',
      data: {
        token: 'mock-jwt-token',
        user: mockUsers[0],
        permissions: ['read', 'write', 'admin']
      }
    })
  }),

  http.post('/api/v1/auth/logout', () => {
    return HttpResponse.json({
      code: 200,
      message: '退出成功',
      data: null
    })
  }),

  // 用户管理
  http.get('/api/v1/users', ({ request }) => {
    const url = new URL(request.url)
    const page = parseInt(url.searchParams.get('page') || '1')
    const pageSize = parseInt(url.searchParams.get('pageSize') || '10')
    const search = url.searchParams.get('search') || ''
    
    let filteredUsers = mockUsers
    if (search) {
      filteredUsers = mockUsers.filter(user => 
        user.username.includes(search) || user.email.includes(search)
      )
    }
    
    const start = (page - 1) * pageSize
    const end = start + pageSize
    const items = filteredUsers.slice(start, end)
    
    return HttpResponse.json({
      code: 200,
      message: '获取成功',
      data: {
        items,
        pagination: {
          page,
          pageSize,
          total: filteredUsers.length,
          totalPages: Math.ceil(filteredUsers.length / pageSize)
        }
      }
    })
  }),

  http.get('/api/v1/users/me', () => {
    return HttpResponse.json({
      code: 200,
      message: '获取成功',
      data: mockUsers[0]
    })
  }),

  http.post('/api/v1/users', async ({ request }) => {
    const body = await request.json()
    const newUser = {
      id: mockUsers.length + 1,
      ...body,
      createdAt: new Date().toISOString()
    }
    mockUsers.push(newUser)
    
    return HttpResponse.json({
      code: 200,
      message: '创建成功',
      data: newUser
    })
  }),

  http.put('/api/v1/users/:id', async ({ request, params }) => {
    const body = await request.json()
    const id = parseInt(params.id as string)
    const userIndex = mockUsers.findIndex(user => user.id === id)
    
    if (userIndex !== -1) {
      mockUsers[userIndex] = { ...mockUsers[userIndex], ...body }
      return HttpResponse.json({
        code: 200,
        message: '更新成功',
        data: mockUsers[userIndex]
      })
    }
    
    return HttpResponse.json({
      code: 404,
      message: '用户不存在',
      data: null
    }, { status: 404 })
  }),

  http.delete('/api/v1/users/:id', ({ params }) => {
    const id = parseInt(params.id as string)
    const userIndex = mockUsers.findIndex(user => user.id === id)
    
    if (userIndex !== -1) {
      mockUsers.splice(userIndex, 1)
      return HttpResponse.json({
        code: 200,
        message: '删除成功',
        data: null
      })
    }
    
    return HttpResponse.json({
      code: 404,
      message: '用户不存在',
      data: null
    }, { status: 404 })
  }),

  // 项目管理
  http.get('/api/v6/projects', ({ request }) => {
    const url = new URL(request.url)
    const page = parseInt(url.searchParams.get('page') || '1')
    const pageSize = parseInt(url.searchParams.get('pageSize') || '10')
    
    const start = (page - 1) * pageSize
    const end = start + pageSize
    const items = mockProjects.slice(start, end)
    
    return HttpResponse.json({
      code: 200,
      message: '获取成功',
      data: {
        items,
        pagination: {
          page,
          pageSize,
          total: mockProjects.length,
          totalPages: Math.ceil(mockProjects.length / pageSize)
        }
      }
    })
  }),

  // 模型管理
  http.get('/api/v2/models', ({ request }) => {
    const url = new URL(request.url)
    const page = parseInt(url.searchParams.get('page') || '1')
    const pageSize = parseInt(url.searchParams.get('pageSize') || '10')
    
    const start = (page - 1) * pageSize
    const end = start + pageSize
    const items = mockModels.slice(start, end)
    
    return HttpResponse.json({
      code: 200,
      message: '获取成功',
      data: {
        items,
        pagination: {
          page,
          pageSize,
          total: mockModels.length,
          totalPages: Math.ceil(mockModels.length / pageSize)
        }
      }
    })
  }),

  // 推理服务
  http.get('/api/v3/inference/tasks', ({ request }) => {
    const url = new URL(request.url)
    const page = parseInt(url.searchParams.get('page') || '1')
    const pageSize = parseInt(url.searchParams.get('pageSize') || '10')
    
    const start = (page - 1) * pageSize
    const end = start + pageSize
    const items = mockInferenceTasks.slice(start, end)
    
    return HttpResponse.json({
      code: 200,
      message: '获取成功',
      data: {
        items,
        pagination: {
          page,
          pageSize,
          total: mockInferenceTasks.length,
          totalPages: Math.ceil(mockInferenceTasks.length / pageSize)
        }
      }
    })
  }),

  http.post('/api/v3/inference/tasks', async ({ request }) => {
    const body = await request.json()
    const newTask = {
      id: `task-${Date.now()}`,
      ...body,
      status: 'running',
      createdAt: new Date().toISOString()
    }
    mockInferenceTasks.push(newTask)
    
    return HttpResponse.json({
      code: 200,
      message: '创建成功',
      data: newTask
    })
  }),

  // 成本管理
  http.get('/api/v4/costs', ({ request }) => {
    const url = new URL(request.url)
    const page = parseInt(url.searchParams.get('page') || '1')
    const pageSize = parseInt(url.searchParams.get('pageSize') || '10')
    
    const start = (page - 1) * pageSize
    const end = start + pageSize
    const items = mockCostRecords.slice(start, end)
    
    return HttpResponse.json({
      code: 200,
      message: '获取成功',
      data: {
        items,
        pagination: {
          page,
          pageSize,
          total: mockCostRecords.length,
          totalPages: Math.ceil(mockCostRecords.length / pageSize)
        }
      }
    })
  }),

  // 监控告警
  http.get('/api/v5/alerts', ({ request }) => {
    const url = new URL(request.url)
    const page = parseInt(url.searchParams.get('page') || '1')
    const pageSize = parseInt(url.searchParams.get('pageSize') || '10')
    
    const start = (page - 1) * pageSize
    const end = start + pageSize
    const items = mockAlerts.slice(start, end)
    
    return HttpResponse.json({
      code: 200,
      message: '获取成功',
      data: {
        items,
        pagination: {
          page,
          pageSize,
          total: mockAlerts.length,
          totalPages: Math.ceil(mockAlerts.length / pageSize)
        }
      }
    })
  }),

  // 健康检查
  http.get('/health', () => {
    return HttpResponse.json({
      status: 'healthy',
      services: [
        { name: 'api-gateway', status: 'healthy', lastCheck: new Date().toISOString() },
        { name: 'user-service', status: 'healthy', lastCheck: new Date().toISOString() },
        { name: 'project-service', status: 'healthy', lastCheck: new Date().toISOString() },
        { name: 'model-service', status: 'healthy', lastCheck: new Date().toISOString() },
        { name: 'inference-service', status: 'healthy', lastCheck: new Date().toISOString() },
        { name: 'cost-service', status: 'healthy', lastCheck: new Date().toISOString() },
        { name: 'monitoring-service', status: 'healthy', lastCheck: new Date().toISOString() }
      ],
      overall: {
        uptime: 86400,
        version: '1.0.0',
        environment: 'test'
      }
    })
  }),

  // 错误处理
  http.get('/api/*', () => {
    return HttpResponse.json({
      code: 404,
      message: '接口不存在',
      data: null
    }, { status: 404 })
  })
]









