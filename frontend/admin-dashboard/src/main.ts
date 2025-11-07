import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import 'element-plus/theme-chalk/dark/css-vars.css'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'

import App from './App.vue'
import router from './router'
import { useBackendStore } from '@/stores/backend'
import { useUserStore } from '@/stores/user'
import { useAppStore } from '@/stores/app'

// 创建应用
const app = createApp(App)

// 注册Element Plus图标
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

// 使用插件
app.use(createPinia())
app.use(router)
app.use(ElementPlus)

// 全局错误处理
app.config.errorHandler = (err, instance, info) => {
  console.error('全局错误:', err, info)
}

// 全局属性
app.config.globalProperties.$ELEMENT = {
  size: 'default',
  zIndex: 3000
}

// 初始化后端连接
const initializeBackend = async () => {
  try {
    const backendStore = useBackendStore()
    await backendStore.initialize()
    console.log('后端集成初始化完成')
  } catch (error) {
    console.error('后端集成初始化失败:', error)
  }
}

// 初始化用户状态
const initializeUser = async () => {
  try {
    const userStore = useUserStore()
    await userStore.initUser()
  } catch (error) {
    console.error('用户状态初始化失败:', error)
  }
}

// 初始化应用状态
const initializeApp = async () => {
  try {
    const appStore = useAppStore()
    appStore.initApp()
    console.log('应用状态初始化完成')
  } catch (error) {
    console.error('应用状态初始化失败:', error)
  }
}

// 应用启动
const startApp = async () => {
  try {
    // 初始化应用状态
    await initializeApp()
    
    // 初始化用户状态
    await initializeUser()
    
    // 初始化后端连接
    await initializeBackend()
    
    // 挂载应用
    app.mount('#app')
    
    console.log('应用启动完成')
  } catch (error) {
    console.error('应用启动失败:', error)
    // 即使初始化失败也要挂载应用
    app.mount('#app')
  }
}

// 启动应用
startApp()

export default app