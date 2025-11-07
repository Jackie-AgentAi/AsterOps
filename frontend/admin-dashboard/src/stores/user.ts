import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { userApiService } from '@/api/user'
import type { LoginForm, UserInfo } from '@/types/user'

export const useUserStore = defineStore('user', () => {
  const token = ref<string>(localStorage.getItem('token') || '')
  const userInfo = ref<UserInfo | null>(null)
  const permissions = ref<string[]>([])

  const isLoggedIn = computed(() => !!token.value)

  const loginAction = async (loginForm: LoginForm) => {
    try {
      const response = await userApiService.login(loginForm)
      token.value = response.data.access_token
      userInfo.value = response.data.user
      permissions.value = response.data.permissions || []
      
      localStorage.setItem('token', token.value)
      localStorage.setItem('userInfo', JSON.stringify(userInfo.value))
      
      ElMessage.success('登录成功')
      return true
    } catch (error) {
      ElMessage.error('登录失败')
      return false
    }
  }

  const logoutAction = async () => {
    try {
      await userApiService.logout()
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      token.value = ''
      userInfo.value = null
      permissions.value = []
      
      localStorage.removeItem('token')
      localStorage.removeItem('userInfo')
      
      ElMessage.success('退出成功')
    }
  }

  const initUser = async () => {
    if (token.value) {
      try {
        // 从localStorage加载用户信息
        const savedUserInfo = localStorage.getItem('userInfo')
        if (savedUserInfo) {
          userInfo.value = JSON.parse(savedUserInfo)
        }
        
        // 尝试获取最新的用户信息（可选）
        try {
          const response = await userApiService.getUserInfo()
          userInfo.value = response.user
          permissions.value = response.permissions || []
        } catch (apiError) {
          // 如果API调用失败，使用localStorage中的数据
          console.warn('无法获取最新用户信息，使用本地缓存:', apiError)
        }
      } catch (error) {
        console.error('Init user error:', error)
        // 不要自动登出，保持用户登录状态
      }
    }
  }

  const hasPermission = (permission: string) => {
    return permissions.value.includes(permission)
  }

  return {
    token,
    userInfo,
    permissions,
    isLoggedIn,
    loginAction,
    logoutAction,
    initUser,
    hasPermission
  }
})



