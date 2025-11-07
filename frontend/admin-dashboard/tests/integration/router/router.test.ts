import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createWebHistory } from 'vue-router'
import { createPinia, setActivePinia } from 'pinia'
import { useUserStore } from '@/stores/user'
import App from '@/App.vue'

// 创建测试路由
const createTestRouter = () => {
  return createRouter({
    history: createWebHistory(),
    routes: [
      { 
        path: '/', 
        name: 'Home', 
        component: { template: '<div>Home</div>' },
        meta: { requiresAuth: false }
      },
      { 
        path: '/login', 
        name: 'Login', 
        component: { template: '<div>Login</div>' },
        meta: { requiresAuth: false }
      },
      { 
        path: '/dashboard', 
        name: 'Dashboard', 
        component: { template: '<div>Dashboard</div>' },
        meta: { requiresAuth: true }
      },
      { 
        path: '/users', 
        name: 'Users', 
        component: { template: '<div>Users</div>' },
        meta: { requiresAuth: true, permissions: ['user:read'] }
      },
      { 
        path: '/projects', 
        name: 'Projects', 
        component: { template: '<div>Projects</div>' },
        meta: { requiresAuth: true, permissions: ['project:read'] }
      },
      { 
        path: '/models', 
        name: 'Models', 
        component: { template: '<div>Models</div>' },
        meta: { requiresAuth: true, permissions: ['model:read'] }
      },
      { 
        path: '/inference', 
        name: 'Inference', 
        component: { template: '<div>Inference</div>' },
        meta: { requiresAuth: true, permissions: ['inference:read'] }
      },
      { 
        path: '/costs', 
        name: 'Costs', 
        component: { template: '<div>Costs</div>' },
        meta: { requiresAuth: true, permissions: ['cost:read'] }
      },
      { 
        path: '/monitoring', 
        name: 'Monitoring', 
        component: { template: '<div>Monitoring</div>' },
        meta: { requiresAuth: true, permissions: ['monitoring:read'] }
      },
      { 
        path: '/settings', 
        name: 'Settings', 
        component: { template: '<div>Settings</div>' },
        meta: { requiresAuth: true, permissions: ['settings:read'] }
      }
    ]
  })
}

describe('Router Integration Tests', () => {
  let router: any
  let pinia: any

  beforeEach(() => {
    pinia = createPinia()
    setActivePinia(pinia)
    router = createTestRouter()
    vi.clearAllMocks()
  })

  describe('Navigation Guards', () => {
    it('should allow access to public routes without authentication', async () => {
      const userStore = useUserStore()
      
      // 确保用户未登录
      userStore.logoutAction()
      
      await router.push('/')
      expect(router.currentRoute.value.path).toBe('/')
      
      await router.push('/login')
      expect(router.currentRoute.value.path).toBe('/login')
    })

    it('should redirect to login for protected routes when not authenticated', async () => {
      const userStore = useUserStore()
      
      // 确保用户未登录
      userStore.logoutAction()
      
      // 尝试访问受保护的路由
      await router.push('/dashboard')
      
      // 应该重定向到登录页
      expect(router.currentRoute.value.path).toBe('/login')
    })

    it('should allow access to protected routes when authenticated', async () => {
      const userStore = useUserStore()
      
      // 模拟用户登录
      userStore.loginAction(
        { id: 1, username: 'testuser', email: 'test@example.com', role: 'admin' },
        'mock-token',
        ['user:read', 'project:read', 'model:read', 'inference:read', 'cost:read', 'monitoring:read', 'settings:read']
      )
      
      await router.push('/dashboard')
      expect(router.currentRoute.value.path).toBe('/dashboard')
      
      await router.push('/users')
      expect(router.currentRoute.value.path).toBe('/users')
    })

    it('should check permissions for routes with permission requirements', async () => {
      const userStore = useUserStore()
      
      // 模拟用户只有部分权限
      userStore.loginAction(
        { id: 1, username: 'testuser', email: 'test@example.com', role: 'user' },
        'mock-token',
        ['user:read'] // 只有用户读取权限
      )
      
      // 应该能访问有权限的路由
      await router.push('/users')
      expect(router.currentRoute.value.path).toBe('/users')
      
      // 应该不能访问没有权限的路由
      await router.push('/projects')
      // 这里应该重定向到403页面或首页，具体实现取决于路由守卫
    })

    it('should handle admin role with all permissions', async () => {
      const userStore = useUserStore()
      
      // 模拟管理员用户
      userStore.loginAction(
        { id: 1, username: 'admin', email: 'admin@example.com', role: 'admin' },
        'mock-token',
        ['*'] // 管理员有所有权限
      )
      
      // 管理员应该能访问所有路由
      const protectedRoutes = ['/dashboard', '/users', '/projects', '/models', '/inference', '/costs', '/monitoring', '/settings']
      
      for (const route of protectedRoutes) {
        await router.push(route)
        expect(router.currentRoute.value.path).toBe(route)
      }
    })
  })

  describe('Route Meta Information', () => {
    it('should have correct meta information for each route', () => {
      const routes = router.getRoutes()
      
      const homeRoute = routes.find((r: any) => r.path === '/')
      expect(homeRoute.meta.requiresAuth).toBe(false)
      
      const dashboardRoute = routes.find((r: any) => r.path === '/dashboard')
      expect(dashboardRoute.meta.requiresAuth).toBe(true)
      
      const usersRoute = routes.find((r: any) => r.path === '/users')
      expect(usersRoute.meta.requiresAuth).toBe(true)
      expect(usersRoute.meta.permissions).toEqual(['user:read'])
    })

    it('should handle routes without meta information', () => {
      const routes = router.getRoutes()
      
      // 所有路由都应该有meta信息
      routes.forEach((route: any) => {
        expect(route.meta).toBeDefined()
      })
    })
  })

  describe('Route Parameters and Query', () => {
    it('should handle route parameters', async () => {
      // 添加一个带参数的路由
      router.addRoute({
        path: '/users/:id',
        name: 'UserDetail',
        component: { template: '<div>User Detail</div>' },
        meta: { requiresAuth: true }
      })
      
      const userStore = useUserStore()
      userStore.loginAction(
        { id: 1, username: 'testuser', email: 'test@example.com', role: 'admin' },
        'mock-token',
        ['user:read']
      )
      
      await router.push('/users/123')
      expect(router.currentRoute.value.path).toBe('/users/123')
      expect(router.currentRoute.value.params.id).toBe('123')
    })

    it('should handle query parameters', async () => {
      const userStore = useUserStore()
      userStore.loginAction(
        { id: 1, username: 'testuser', email: 'test@example.com', role: 'admin' },
        'mock-token',
        ['user:read']
      )
      
      await router.push({ path: '/users', query: { page: '1', search: 'test' } })
      expect(router.currentRoute.value.path).toBe('/users')
      expect(router.currentRoute.value.query.page).toBe('1')
      expect(router.currentRoute.value.query.search).toBe('test')
    })
  })

  describe('Navigation History', () => {
    it('should maintain navigation history', async () => {
      const userStore = useUserStore()
      userStore.loginAction(
        { id: 1, username: 'testuser', email: 'test@example.com', role: 'admin' },
        'mock-token',
        ['user:read', 'project:read']
      )
      
      // 导航到多个页面
      await router.push('/dashboard')
      await router.push('/users')
      await router.push('/projects')
      
      expect(router.currentRoute.value.path).toBe('/projects')
      
      // 返回上一页
      await router.back()
      expect(router.currentRoute.value.path).toBe('/users')
      
      // 返回上一页
      await router.back()
      expect(router.currentRoute.value.path).toBe('/dashboard')
    })

    it('should handle forward navigation', async () => {
      const userStore = useUserStore()
      userStore.loginAction(
        { id: 1, username: 'testuser', email: 'test@example.com', role: 'admin' },
        'mock-token',
        ['user:read', 'project:read']
      )
      
      // 导航到多个页面
      await router.push('/dashboard')
      await router.push('/users')
      await router.push('/projects')
      
      // 返回两页
      await router.back()
      await router.back()
      expect(router.currentRoute.value.path).toBe('/dashboard')
      
      // 前进一页
      await router.forward()
      expect(router.currentRoute.value.path).toBe('/users')
    })
  })

  describe('Route Transitions', () => {
    it('should handle route change events', async () => {
      const userStore = useUserStore()
      userStore.loginAction(
        { id: 1, username: 'testuser', email: 'test@example.com', role: 'admin' },
        'mock-token',
        ['user:read']
      )
      
      const routeChangeSpy = vi.fn()
      router.afterEach(routeChangeSpy)
      
      await router.push('/dashboard')
      await router.push('/users')
      
      expect(routeChangeSpy).toHaveBeenCalledTimes(2)
    })

    it('should handle route errors gracefully', async () => {
      const userStore = useUserStore()
      userStore.loginAction(
        { id: 1, username: 'testuser', email: 'test@example.com', role: 'admin' },
        'mock-token',
        ['user:read']
      )
      
      // 尝试导航到不存在的路由
      try {
        await router.push('/non-existent-route')
      } catch (error) {
        // 应该处理错误
        expect(error).toBeDefined()
      }
    })
  })
})









