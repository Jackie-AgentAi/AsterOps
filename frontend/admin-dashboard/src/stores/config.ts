import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useConfigStore = defineStore('config', () => {
  const systemConfig = ref({
    siteName: 'LLMOps运营管理平台',
    version: '1.0.0',
    environment: 'production',
    apiBaseUrl: import.meta.env.VITE_API_BASE_URL || '/api',
    uploadMaxSize: 100 * 1024 * 1024, // 100MB
    supportedFormats: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'txt', 'json', 'csv'],
    theme: 'light',
    language: 'zh-CN'
  })

  const updateConfig = (newConfig: Partial<typeof systemConfig.value>) => {
    systemConfig.value = { ...systemConfig.value, ...newConfig }
  }

  const getConfig = (key: keyof typeof systemConfig.value) => {
    return systemConfig.value[key]
  }

  return {
    systemConfig,
    updateConfig,
    getConfig
  }
})
