import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useUserStore } from './user'

export interface MenuItem {
  id: string
  title: string
  icon: string
  path: string
  children?: MenuItem[]
  permission?: string
  visible?: boolean
}

export const useMenuStore = defineStore('menu', () => {
  const menuItems = ref<MenuItem[]>([
    {
      id: 'dashboard',
      title: '仪表板',
      icon: 'Odometer',
      path: '/dashboard',
      permission: 'dashboard:view'
    },
    {
      id: 'users',
      title: '用户管理',
      icon: 'User',
      path: '/users',
      permission: 'user:view'
    },
    {
      id: 'projects',
      title: '项目管理',
      icon: 'Folder',
      path: '/projects',
      permission: 'project:view'
    },
    {
      id: 'models',
      title: '模型管理',
      icon: 'Box',
      path: '/models',
      permission: 'model:view'
    },
    {
      id: 'inference',
      title: '推理服务',
      icon: 'Cpu',
      path: '/inference',
      permission: 'inference:view'
    },
    {
      id: 'costs',
      title: '成本管理',
      icon: 'Money',
      path: '/costs',
      permission: 'cost:view'
    },
    {
      id: 'monitoring',
      title: '监控告警',
      icon: 'Monitor',
      path: '/monitoring',
      permission: 'monitoring:view'
    },
    {
      id: 'settings',
      title: '系统设置',
      icon: 'Setting',
      path: '/settings',
      permission: 'system:view'
    }
  ])

  const userStore = useUserStore()

  const visibleMenuItems = computed(() => {
    return menuItems.value.filter(item => {
      // 检查权限
      if (item.permission && !userStore.hasPermission(item.permission)) {
        return false
      }
      
      // 检查可见性
      if (item.visible === false) {
        return false
      }
      
      return true
    })
  })

  const getMenuByPath = (path: string) => {
    const findMenu = (items: MenuItem[]): MenuItem | null => {
      for (const item of items) {
        if (item.path === path) {
          return item
        }
        if (item.children) {
          const found = findMenu(item.children)
          if (found) return found
        }
      }
      return null
    }
    return findMenu(menuItems.value)
  }

  const getBreadcrumb = (path: string) => {
    const breadcrumb: MenuItem[] = []
    const findPath = (items: MenuItem[], targetPath: string, currentPath: MenuItem[] = []): boolean => {
      for (const item of items) {
        const newPath = [...currentPath, item]
        if (item.path === targetPath) {
          breadcrumb.push(...newPath)
          return true
        }
        if (item.children && findPath(item.children, targetPath, newPath)) {
          return true
        }
      }
      return false
    }
    
    findPath(menuItems.value, path)
    return breadcrumb
  }

  return {
    menuItems,
    visibleMenuItems,
    getMenuByPath,
    getBreadcrumb
  }
})
