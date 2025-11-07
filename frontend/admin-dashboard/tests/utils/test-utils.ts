import { mount, VueWrapper } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import { vi } from 'vitest'
import type { App } from 'vue'

// 测试路由配置
const createTestRouter = () => {
  return createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/', name: 'Home', component: { template: '<div>Home</div>' } },
      { path: '/dashboard', name: 'Dashboard', component: { template: '<div>Dashboard</div>' } },
      { path: '/users', name: 'Users', component: { template: '<div>Users</div>' } },
      { path: '/projects', name: 'Projects', component: { template: '<div>Projects</div>' } },
      { path: '/models', name: 'Models', component: { template: '<div>Models</div>' } },
      { path: '/inference', name: 'Inference', component: { template: '<div>Inference</div>' } },
      { path: '/costs', name: 'Costs', component: { template: '<div>Costs</div>' } },
      { path: '/monitoring', name: 'Monitoring', component: { template: '<div>Monitoring</div>' } },
      { path: '/settings', name: 'Settings', component: { template: '<div>Settings</div>' } }
    ]
  })
}

// 创建测试应用实例
export const createTestApp = () => {
  const pinia = createPinia()
  const router = createTestRouter()
  
  setActivePinia(pinia)
  
  return {
    pinia,
    router
  }
}

// 通用组件挂载函数
export const mountComponent = (
  component: any,
  options: any = {}
): VueWrapper<any> => {
  const { pinia, router } = createTestApp()
  
  return mount(component, {
    global: {
      plugins: [pinia, router],
      stubs: {
        'el-button': true,
        'el-input': true,
        'el-form': true,
        'el-form-item': true,
        'el-select': true,
        'el-option': true,
        'el-table': true,
        'el-table-column': true,
        'el-pagination': true,
        'el-card': true,
        'el-row': true,
        'el-col': true,
        'el-tag': true,
        'el-icon': true,
        'el-dropdown': true,
        'el-dropdown-menu': true,
        'el-dropdown-item': true,
        'el-badge': true,
        'el-tabs': true,
        'el-tab-pane': true,
        'el-dialog': true,
        'el-drawer': true,
        'el-popover': true,
        'el-tooltip': true,
        'el-divider': true,
        'el-empty': true,
        'el-loading': true,
        'el-message': true,
        'el-notification': true,
        'router-link': true,
        'router-view': true
      },
      mocks: {
        $t: (key: string) => key,
        $tc: (key: string) => key,
        $te: (key: string) => true,
        $d: (value: any) => value,
        $n: (value: any) => value
      }
    },
    ...options
  })
}

// Mock API 响应
export const mockApiResponse = (data: any, status = 200) => {
  return {
    data,
    status,
    statusText: 'OK',
    headers: {},
    config: {}
  }
}

// Mock API 错误
export const mockApiError = (message = 'API Error', status = 500) => {
  const error = new Error(message)
  ;(error as any).response = {
    data: { message },
    status,
    statusText: 'Internal Server Error',
    headers: {},
    config: {}
  }
  return error
}

// 等待异步操作
export const waitFor = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

// 模拟用户交互
export const userEvent = {
  click: (element: HTMLElement) => {
    element.click()
  },
  type: (element: HTMLInputElement, text: string) => {
    element.value = text
    element.dispatchEvent(new Event('input', { bubbles: true }))
  },
  select: (element: HTMLSelectElement, value: string) => {
    element.value = value
    element.dispatchEvent(new Event('change', { bubbles: true }))
  }
}

// 测试数据工厂
export const createTestData = {
  user: (overrides = {}) => ({
    id: 1,
    username: 'testuser',
    email: 'test@example.com',
    role: 'admin',
    status: 'active',
    createdAt: '2024-01-01T00:00:00Z',
    lastLoginAt: '2024-01-15T10:00:00Z',
    ...overrides
  }),
  
  project: (overrides = {}) => ({
    id: 1,
    name: 'Test Project',
    description: 'Test project description',
    status: 'active',
    ownerId: 1,
    createdAt: '2024-01-01T00:00:00Z',
    ...overrides
  }),
  
  model: (overrides = {}) => ({
    id: 1,
    name: 'Test Model',
    version: '1.0.0',
    type: 'llm',
    status: 'active',
    projectId: 1,
    createdAt: '2024-01-01T00:00:00Z',
    ...overrides
  }),
  
  inferenceTask: (overrides = {}) => ({
    id: 'task-123',
    modelId: 1,
    status: 'completed',
    input: 'Test input',
    output: 'Test output',
    createdAt: '2024-01-01T00:00:00Z',
    ...overrides
  }),
  
  costRecord: (overrides = {}) => ({
    id: 1,
    projectId: 1,
    modelId: 1,
    amount: 100.50,
    currency: 'CNY',
    type: 'inference',
    createdAt: '2024-01-01T00:00:00Z',
    ...overrides
  }),
  
  alert: (overrides = {}) => ({
    id: 1,
    title: 'Test Alert',
    message: 'Test alert message',
    level: 'warning',
    status: 'active',
    createdAt: '2024-01-01T00:00:00Z',
    ...overrides
  })
}

// 清理函数
export const cleanup = () => {
  vi.clearAllMocks()
  vi.resetAllMocks()
}









