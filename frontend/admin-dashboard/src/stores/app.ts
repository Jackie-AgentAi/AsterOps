/**
 * 应用状态管理
 */
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { APP_CONFIG } from '@/config/constants'

export const useAppStore = defineStore('app', () => {
  // 主题状态
  const theme = ref<string>(
    localStorage.getItem(APP_CONFIG.CACHE.THEME_KEY) || APP_CONFIG.THEME.DEFAULT
  )
  
  // 语言状态
  const language = ref<string>(
    localStorage.getItem(APP_CONFIG.CACHE.LANG_KEY) || APP_CONFIG.LANG.DEFAULT
  )
  
  // 侧边栏状态
  const sidebarCollapsed = ref<boolean>(false)
  
  // 加载状态
  const loading = ref<boolean>(false)
  
  // 页面标题
  const pageTitle = ref<string>(APP_CONFIG.NAME)
  
  // 面包屑导航
  const breadcrumbs = ref<Array<{ title: string; path?: string }>>([])
  
  // 计算属性
  const isDark = computed(() => theme.value === 'dark')
  const isLight = computed(() => theme.value === 'light')
  const isAutoTheme = computed(() => theme.value === 'auto')
  
  // 切换主题
  const toggleTheme = () => {
    const themes = APP_CONFIG.THEME.OPTIONS
    const currentIndex = themes.indexOf(theme.value)
    const nextIndex = (currentIndex + 1) % themes.length
    theme.value = themes[nextIndex]
    localStorage.setItem(APP_CONFIG.CACHE.THEME_KEY, theme.value)
    applyTheme()
  }
  
  // 设置主题
  const setTheme = (newTheme: string) => {
    if (APP_CONFIG.THEME.OPTIONS.includes(newTheme)) {
      theme.value = newTheme
      localStorage.setItem(APP_CONFIG.CACHE.THEME_KEY, theme.value)
      applyTheme()
    }
  }
  
  // 应用主题
  const applyTheme = () => {
    const root = document.documentElement
    if (theme.value === 'dark') {
      root.classList.add('dark')
    } else if (theme.value === 'light') {
      root.classList.remove('dark')
    } else if (theme.value === 'auto') {
      // 自动主题，根据系统偏好设置
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      if (prefersDark) {
        root.classList.add('dark')
      } else {
        root.classList.remove('dark')
      }
    }
  }
  
  // 切换语言
  const toggleLanguage = () => {
    const languages = APP_CONFIG.LANG.OPTIONS
    const currentIndex = languages.indexOf(language.value)
    const nextIndex = (currentIndex + 1) % languages.length
    language.value = languages[nextIndex]
    localStorage.setItem(APP_CONFIG.CACHE.LANG_KEY, language.value)
  }
  
  // 设置语言
  const setLanguage = (newLanguage: string) => {
    if (APP_CONFIG.LANG.OPTIONS.includes(newLanguage)) {
      language.value = newLanguage
      localStorage.setItem(APP_CONFIG.CACHE.LANG_KEY, language.value)
    }
  }
  
  // 切换侧边栏
  const toggleSidebar = () => {
    sidebarCollapsed.value = !sidebarCollapsed.value
  }
  
  // 设置侧边栏状态
  const setSidebarCollapsed = (collapsed: boolean) => {
    sidebarCollapsed.value = collapsed
  }
  
  // 设置加载状态
  const setLoading = (loadingState: boolean) => {
    loading.value = loadingState
  }
  
  // 设置页面标题
  const setPageTitle = (title: string) => {
    pageTitle.value = title
    document.title = `${title} - ${APP_CONFIG.NAME}`
  }
  
  // 设置面包屑
  const setBreadcrumbs = (crumbs: Array<{ title: string; path?: string }>) => {
    breadcrumbs.value = crumbs
  }
  
  // 添加面包屑
  const addBreadcrumb = (crumb: { title: string; path?: string }) => {
    breadcrumbs.value.push(crumb)
  }
  
  // 移除面包屑
  const removeBreadcrumb = (index: number) => {
    breadcrumbs.value.splice(index, 1)
  }
  
  // 清空面包屑
  const clearBreadcrumbs = () => {
    breadcrumbs.value = []
  }
  
  // 初始化应用
  const initApp = () => {
    applyTheme()
    
    // 监听系统主题变化
    if (theme.value === 'auto') {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
      mediaQuery.addEventListener('change', applyTheme)
    }
  }
  
  return {
    // 状态
    theme,
    language,
    sidebarCollapsed,
    loading,
    pageTitle,
    breadcrumbs,
    
    // 计算属性
    isDark,
    isLight,
    isAutoTheme,
    
    // 方法
    toggleTheme,
    setTheme,
    applyTheme,
    toggleLanguage,
    setLanguage,
    toggleSidebar,
    setSidebarCollapsed,
    setLoading,
    setPageTitle,
    setBreadcrumbs,
    addBreadcrumb,
    removeBreadcrumb,
    clearBreadcrumbs,
    initApp
  }
})
