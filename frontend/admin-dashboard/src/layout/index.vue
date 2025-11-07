<template>
  <div class="layout-container">
    <!-- 侧边栏 -->
    <el-aside :width="isCollapse ? '64px' : '200px'" class="sidebar">
      <div class="logo">
        <span v-if="!isCollapse">LLMOps管理后台</span>
        <span v-else>LLM</span>
      </div>
      
      <el-menu
        :default-active="activeMenu"
        :collapse="isCollapse"
        :unique-opened="true"
        :default-openeds="defaultOpeneds"
        router
        class="sidebar-menu"
        @open="handleMenuOpen"
        @close="handleMenuClose"
      >
        <el-menu-item index="/dashboard">
          <el-icon><Odometer /></el-icon>
          <span>仪表板</span>
        </el-menu-item>
        
        <el-sub-menu index="users">
          <template #title>
            <el-icon><User /></el-icon>
            <span>用户管理</span>
          </template>
          <el-menu-item index="/users/user-list">
            <el-icon><User /></el-icon>
            <span>用户列表</span>
          </el-menu-item>
          <el-menu-item index="/users/user-groups">
            <el-icon><UserFilled /></el-icon>
            <span>用户组</span>
          </el-menu-item>
        </el-sub-menu>
        
        <el-menu-item index="/models">
          <el-icon><Box /></el-icon>
          <span>模型管理</span>
        </el-menu-item>
        
        <el-menu-item index="/inference">
          <el-icon><Cpu /></el-icon>
          <span>推理服务</span>
        </el-menu-item>
        
        <el-menu-item index="/costs">
          <el-icon><Money /></el-icon>
          <span>成本管理</span>
        </el-menu-item>
        
        <el-menu-item index="/monitoring">
          <el-icon><Monitor /></el-icon>
          <span>监控告警</span>
        </el-menu-item>
        
        <el-menu-item index="/projects">
          <el-icon><Folder /></el-icon>
          <span>项目管理</span>
        </el-menu-item>
        
        <el-menu-item index="/settings">
          <el-icon><Setting /></el-icon>
          <span>系统设置</span>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <!-- 主内容区 -->
    <el-container class="main-container">
      <!-- 顶部导航 -->
      <el-header class="header">
        <div class="header-left">
          <el-button
            type="text"
            @click="toggleCollapse"
            class="collapse-btn"
          >
            <el-icon><Fold v-if="!isCollapse" /><Expand v-else /></el-icon>
          </el-button>
          
          <el-breadcrumb separator="/">
            <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item>{{ currentPageTitle }}</el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        
        <div class="header-right">
          <!-- 后端状态 -->
          <BackendStatus :show-details="true" :auto-refresh="true" />
          
          <!-- 通知 -->
          <el-badge :value="notificationCount" class="notification-badge">
            <el-button type="text" @click="showNotifications">
              <el-icon><Bell /></el-icon>
            </el-button>
          </el-badge>
          
          <!-- 用户信息 -->
          <el-dropdown @command="handleUserCommand">
            <div class="user-info">
              <div class="user-avatar" :style="userAvatarStyle">
                {{ userAvatarText }}
              </div>
              <span class="username">{{ userStore.userInfo?.username }}</span>
              <el-icon><ArrowDown /></el-icon>
            </div>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">个人资料</el-dropdown-item>
                <el-dropdown-item command="settings">账户设置</el-dropdown-item>
                <el-dropdown-item divided command="logout">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <!-- 内容区域 -->
      <el-main class="main-content">
        <router-view />
      </el-main>
    </el-container>

    <!-- 通知面板 -->
    <el-drawer
      v-model="notificationVisible"
      title="通知"
      direction="rtl"
      size="400px"
    >
      <div class="notification-list">
        <div
          v-for="notification in notifications"
          :key="notification.id"
          class="notification-item"
        >
          <div class="notification-content">
            <div class="notification-title">{{ notification.title }}</div>
            <div class="notification-message">{{ notification.message }}</div>
            <div class="notification-time">{{ notification.time }}</div>
          </div>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage, ElMessageBox } from 'element-plus'
import BackendStatus from '@/components/BackendStatus/index.vue'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const isCollapse = ref(false)
const notificationVisible = ref(false)
const notificationCount = ref(3)
const defaultOpeneds = ref<string[]>([])
const menuOpenState = ref<Record<string, boolean>>({})

const notifications = ref([
  {
    id: 1,
    title: '系统通知',
    message: '系统将在今晚进行维护',
    time: '2小时前',
    type: 'info'
  },
  {
    id: 2,
    title: '成本告警',
    message: '项目A的成本已超过预算',
    time: '4小时前',
    type: 'warning'
  },
  {
    id: 3,
    title: '模型更新',
    message: '模型v2.1.0已发布',
    time: '1天前',
    type: 'success'
  }
])

const activeMenu = computed(() => route.path)
const currentPageTitle = computed(() => {
  const routeMap: Record<string, string> = {
    '/dashboard': '仪表板',
    '/users': '用户管理',
    '/models': '模型管理',
    '/inference': '推理服务',
    '/costs': '成本管理',
    '/monitoring': '监控告警',
    '/projects': '项目管理',
    '/settings': '系统设置'
  }
  return routeMap[route.path] || '未知页面'
})

const toggleCollapse = () => {
  isCollapse.value = !isCollapse.value
}

const showNotifications = () => {
  notificationVisible.value = true
}

// 生成用户头像文本
const userAvatarText = computed(() => {
  const username = userStore.userInfo?.username || 'U'
  return username.charAt(0).toUpperCase()
})

// 生成用户头像样式
const userAvatarStyle = computed(() => {
  const colors = [
    'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
    'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
    'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
    'linear-gradient(135deg, #fa709a 0%, #fee140 100%)',
    'linear-gradient(135deg, #a8edea 0%, #fed6e3 100%)',
    'linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%)',
    'linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%)'
  ]
  
  const username = userStore.userInfo?.username || 'user'
  const hash = username.split('').reduce((a, b) => {
    a = ((a << 5) - a) + b.charCodeAt(0)
    return a & a
  }, 0)
  
  const colorIndex = Math.abs(hash) % colors.length
  const background = colors[colorIndex]
  
  return {
    background,
    width: '32px',
    height: '32px',
    borderRadius: '50%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: '14px',
    fontWeight: 'bold',
    color: 'white',
    textShadow: '0 1px 2px rgba(0, 0, 0, 0.3)',
    userSelect: 'none',
    boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)'
  }
})

const handleUserCommand = async (command: string) => {
  switch (command) {
    case 'profile':
      router.push('/profile')
      break
    case 'settings':
      router.push('/settings')
      break
    case 'logout':
      try {
        await ElMessageBox.confirm('确定要退出登录吗？', '提示', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        })
        await userStore.logoutAction()
        router.push('/login')
      } catch {
        // 用户取消
      }
      break
  }
}

// 菜单交互处理
const handleMenuOpen = (index: string) => {
  menuOpenState.value[index] = true
}

const handleMenuClose = (index: string) => {
  menuOpenState.value[index] = false
}

// 点击外部区域关闭菜单
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  const sidebar = document.querySelector('.sidebar')
  const menu = document.querySelector('.sidebar-menu')
  
  if (sidebar && menu && !sidebar.contains(target)) {
    // 关闭所有打开的菜单
    Object.keys(menuOpenState.value).forEach(key => {
      if (menuOpenState.value[key]) {
        menuOpenState.value[key] = false
      }
    })
    defaultOpeneds.value = []
  }
}

// 监听点击事件
onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<style lang="scss" scoped>
.layout-container {
  display: flex;
  height: 100vh;
}

.sidebar {
  background: #fff;
  transition: width 0.3s;
  border-right: 1px solid #e8e8e8;
  
  .logo {
    display: flex;
    align-items: center;
    justify-content: center;
    height: 60px;
    color: #333;
    font-size: 18px;
    font-weight: bold;
    border-bottom: 1px solid #e8e8e8;
    
    img {
      width: 32px;
      height: 32px;
      margin-right: 8px;
    }
  }
  
  .sidebar-menu {
    border: none;
    background: #fff;
    
    :deep(.el-menu-item) {
      color: #333;
      font-size: 14px;
      margin: 4px 8px;
      padding: 12px;
      border-radius: 2px;
      transition: all 0.3s;
      
      &:hover {
        background: #f5f7fa;
        color: #1890ff;
        text-decoration: underline;
      }
      
      &.is-active {
        background: #f5f7fa;
        color: #1890ff;
      }
    }
    
    :deep(.el-sub-menu) {
      .el-sub-menu__title {
        color: #333;
        font-size: 14px;
        margin: 4px 8px;
        padding: 12px;
        border-radius: 2px;
        transition: all 0.3s;
        
        &:hover {
          background: #f5f7fa;
          color: #1890ff;
          text-decoration: underline;
        }
      }
      
      .el-menu {
        background: #fff;
        transition: all 0.3s ease-in-out;
        opacity: 1;
        transform: translateY(0);
        
        .el-menu-item {
          color: #333;
          font-size: 14px;
          margin: 4px 8px;
          padding: 12px 12px 12px 32px;
          border-radius: 2px;
          transition: all 0.3s;
          
          &:hover {
            background: #f5f7fa;
            color: #1890ff;
            text-decoration: underline;
          }
          
          &.is-active {
            background: #f5f7fa;
            color: #1890ff;
          }
        }
      }
      
      // 下拉动画
      &.is-opened {
        .el-menu {
          animation: slideDown 0.3s ease-in-out;
        }
      }
      
      &.is-closed {
        .el-menu {
          animation: slideUp 0.3s ease-in-out;
        }
      }
    }
    
    // 动画关键帧
    @keyframes slideDown {
      from {
        opacity: 0;
        transform: translateY(-10px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }
    
    @keyframes slideUp {
      from {
        opacity: 1;
        transform: translateY(0);
      }
      to {
        opacity: 0;
        transform: translateY(-10px);
      }
    }
  }
}

.main-container {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  background: white;
  border-bottom: 1px solid #e8e8e8;
  
  .header-left {
    display: flex;
    align-items: center;
    
    .collapse-btn {
      margin-right: 20px;
      font-size: 18px;
    }
  }
  
  .header-right {
    display: flex;
    align-items: center;
    gap: 20px;
    
    .notification-badge {
      cursor: pointer;
    }
    
    .user-info {
      display: flex;
      align-items: center;
      gap: 8px;
      cursor: pointer;
      
      .username {
        font-size: 14px;
      }
    }
  }
}

.main-content {
  background: #f5f5f5;
  padding: 20px;
  overflow-y: auto;
}

.notification-list {
  .notification-item {
    padding: 16px;
    border-bottom: 1px solid #e8e8e8;
    
    &:last-child {
      border-bottom: none;
    }
    
    .notification-content {
      .notification-title {
        font-weight: bold;
        margin-bottom: 4px;
      }
      
      .notification-message {
        color: #666;
        margin-bottom: 8px;
      }
      
      .notification-time {
        font-size: 12px;
        color: #999;
      }
    }
  }
}
</style>



