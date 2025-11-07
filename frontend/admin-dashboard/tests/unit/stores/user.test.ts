import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useUserStore } from '@/stores/user'
import { createTestData } from '../../utils/test-utils'

describe('User Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  describe('Initial State', () => {
    it('should have correct initial state', () => {
      const userStore = useUserStore()
      
      expect(userStore.token).toBe('')
      expect(userStore.userInfo).toBeNull()
      expect(userStore.permissions).toEqual([])
      expect(userStore.isLoggedIn).toBe(false)
    })
  })

  describe('Actions', () => {
    it('should set user info', () => {
      const userStore = useUserStore()
      const userInfo = createTestData.user()
      
      userStore.setUserInfo(userInfo)
      
      expect(userStore.userInfo).toEqual(userInfo)
    })

    it('should set token', () => {
      const userStore = useUserStore()
      const token = 'test-jwt-token'
      
      userStore.setToken(token)
      
      expect(userStore.token).toBe(token)
    })

    it('should set permissions', () => {
      const userStore = useUserStore()
      const permissions = ['read', 'write', 'admin']
      
      userStore.setPermissions(permissions)
      
      expect(userStore.permissions).toEqual(permissions)
    })

    it('should login user', () => {
      const userStore = useUserStore()
      const userInfo = createTestData.user()
      const token = 'test-jwt-token'
      const permissions = ['read', 'write']
      
      userStore.loginAction(userInfo, token, permissions)
      
      expect(userStore.userInfo).toEqual(userInfo)
      expect(userStore.token).toBe(token)
      expect(userStore.permissions).toEqual(permissions)
      expect(userStore.isLoggedIn).toBe(true)
    })

    it('should logout user', () => {
      const userStore = useUserStore()
      
      // 先登录
      const userInfo = createTestData.user()
      const token = 'test-jwt-token'
      const permissions = ['read', 'write']
      userStore.loginAction(userInfo, token, permissions)
      
      // 验证登录状态
      expect(userStore.isLoggedIn).toBe(true)
      
      // 登出
      userStore.logoutAction()
      
      expect(userStore.userInfo).toBeNull()
      expect(userStore.token).toBe('')
      expect(userStore.permissions).toEqual([])
      expect(userStore.isLoggedIn).toBe(false)
    })

    it('should update user info', () => {
      const userStore = useUserStore()
      const userInfo = createTestData.user()
      
      userStore.setUserInfo(userInfo)
      
      const updatedInfo = { ...userInfo, username: 'updated-username' }
      userStore.updateUserInfo(updatedInfo)
      
      expect(userStore.userInfo).toEqual(updatedInfo)
    })
  })

  describe('Getters', () => {
    it('should return correct login status', () => {
      const userStore = useUserStore()
      
      expect(userStore.isLoggedIn).toBe(false)
      
      userStore.setToken('test-token')
      userStore.setUserInfo(createTestData.user())
      
      expect(userStore.isLoggedIn).toBe(true)
    })

    it('should return user role', () => {
      const userStore = useUserStore()
      const userInfo = createTestData.user({ role: 'admin' })
      
      userStore.setUserInfo(userInfo)
      
      expect(userStore.userRole).toBe('admin')
    })

    it('should return null role when no user info', () => {
      const userStore = useUserStore()
      
      expect(userStore.userRole).toBeNull()
    })

    it('should check permissions', () => {
      const userStore = useUserStore()
      const permissions = ['read', 'write', 'admin']
      
      userStore.setPermissions(permissions)
      
      expect(userStore.hasPermission('read')).toBe(true)
      expect(userStore.hasPermission('write')).toBe(true)
      expect(userStore.hasPermission('admin')).toBe(true)
      expect(userStore.hasPermission('delete')).toBe(false)
    })

    it('should check multiple permissions', () => {
      const userStore = useUserStore()
      const permissions = ['read', 'write']
      
      userStore.setPermissions(permissions)
      
      expect(userStore.hasAnyPermission(['read', 'delete'])).toBe(true)
      expect(userStore.hasAnyPermission(['delete', 'admin'])).toBe(false)
      expect(userStore.hasAllPermissions(['read', 'write'])).toBe(true)
      expect(userStore.hasAllPermissions(['read', 'delete'])).toBe(false)
    })
  })

  describe('Persistence', () => {
    it('should persist token to localStorage', () => {
      const userStore = useUserStore()
      const token = 'persistent-token'
      
      userStore.setToken(token)
      
      // 验证token被保存到localStorage
      expect(localStorage.setItem).toHaveBeenCalledWith('user_token', token)
    })

    it('should load token from localStorage on initialization', () => {
      // 模拟localStorage中有token
      vi.mocked(localStorage.getItem).mockReturnValue('stored-token')
      
      const userStore = useUserStore()
      
      expect(userStore.token).toBe('stored-token')
    })

    it('should persist user info to localStorage', () => {
      const userStore = useUserStore()
      const userInfo = createTestData.user()
      
      userStore.setUserInfo(userInfo)
      
      expect(localStorage.setItem).toHaveBeenCalledWith(
        'user_info', 
        JSON.stringify(userInfo)
      )
    })

    it('should load user info from localStorage on initialization', () => {
      const userInfo = createTestData.user()
      vi.mocked(localStorage.getItem).mockReturnValue(JSON.stringify(userInfo))
      
      const userStore = useUserStore()
      
      expect(userStore.userInfo).toEqual(userInfo)
    })

    it('should clear localStorage on logout', () => {
      const userStore = useUserStore()
      
      // 先登录
      userStore.loginAction(createTestData.user(), 'token', ['read'])
      
      // 登出
      userStore.logoutAction()
      
      expect(localStorage.removeItem).toHaveBeenCalledWith('user_token')
      expect(localStorage.removeItem).toHaveBeenCalledWith('user_info')
    })
  })

  describe('Error Handling', () => {
    it('should handle invalid JSON in localStorage', () => {
      vi.mocked(localStorage.getItem).mockReturnValue('invalid-json')
      
      const userStore = useUserStore()
      
      // 应该不会抛出错误，userInfo应该为null
      expect(userStore.userInfo).toBeNull()
    })

    it('should handle null values from localStorage', () => {
      vi.mocked(localStorage.getItem).mockReturnValue(null)
      
      const userStore = useUserStore()
      
      expect(userStore.token).toBe('')
      expect(userStore.userInfo).toBeNull()
    })
  })
})









