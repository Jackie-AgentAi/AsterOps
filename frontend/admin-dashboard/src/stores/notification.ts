import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { NotificationItem } from '@/types/common'

export const useNotificationStore = defineStore('notification', () => {
  const notifications = ref<NotificationItem[]>([])
  const unreadCount = computed(() => notifications.value.filter(n => !n.read).length)

  const addNotification = (notification: Omit<NotificationItem, 'id' | 'createdAt'>) => {
    const newNotification: NotificationItem = {
      ...notification,
      id: Date.now(),
      createdAt: new Date().toISOString()
    }
    notifications.value.unshift(newNotification)
    
    // 限制通知数量，最多保留100条
    if (notifications.value.length > 100) {
      notifications.value = notifications.value.slice(0, 100)
    }
  }

  const markAsRead = (id: number) => {
    const notification = notifications.value.find(n => n.id === id)
    if (notification) {
      notification.read = true
    }
  }

  const markAllAsRead = () => {
    notifications.value.forEach(n => n.read = true)
  }

  const removeNotification = (id: number) => {
    const index = notifications.value.findIndex(n => n.id === id)
    if (index > -1) {
      notifications.value.splice(index, 1)
    }
  }

  const clearAll = () => {
    notifications.value = []
  }

  const getNotifications = (limit?: number) => {
    return limit ? notifications.value.slice(0, limit) : notifications.value
  }

  const getUnreadNotifications = () => {
    return notifications.value.filter(n => !n.read)
  }

  // 模拟通知数据
  const initMockNotifications = () => {
    notifications.value = [
      {
        id: 1,
        title: '系统通知',
        message: '系统将在今晚进行维护',
        type: 'info',
        read: false,
        createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 2,
        title: '成本告警',
        message: '项目A的成本已超过预算',
        type: 'warning',
        read: false,
        createdAt: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString()
      },
      {
        id: 3,
        title: '模型更新',
        message: '模型v2.1.0已发布',
        type: 'success',
        read: true,
        createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
      }
    ]
  }

  return {
    notifications,
    unreadCount,
    addNotification,
    markAsRead,
    markAllAsRead,
    removeNotification,
    clearAll,
    getNotifications,
    getUnreadNotifications,
    initMockNotifications
  }
})
