<template>
  <div class="login-container">
    <!-- 背景装饰 -->
    <div class="bg-decoration">
      <div class="circle circle-1"></div>
      <div class="circle circle-2"></div>
      <div class="circle circle-3"></div>
    </div>
    
    <!-- 登录卡片 -->
    <div class="login-card">
      <!-- 头部 -->
      <div class="login-header">
        <div class="logo">
          <div class="logo-icon">🤖</div>
          <h1>LLMOps</h1>
        </div>
        <p class="subtitle">智能运营管理平台</p>
      </div>
      
      <!-- 登录表单 -->
      <el-form 
        :model="form" 
        :rules="rules" 
        ref="loginForm"
        class="login-form"
        size="large"
      >
        <el-form-item prop="username">
          <el-input
            v-model="form.username"
            placeholder="请输入用户名"
            :prefix-icon="User"
            clearable
          />
        </el-form-item>
        
        <el-form-item prop="password">
          <el-input
            v-model="form.password"
            type="password"
            placeholder="请输入密码"
            :prefix-icon="Lock"
            show-password
            clearable
            @keyup.enter="handleLogin"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button
            type="primary"
            :loading="loading"
            @click="handleLogin"
            class="login-btn"
            size="large"
          >
            <span v-if="!loading">登录</span>
            <span v-else>登录中...</span>
          </el-button>
        </el-form-item>
      </el-form>
      
      <!-- 底部信息 -->
      <div class="login-footer">
        <p class="help-text">
          <el-icon><InfoFilled /></el-icon>
          默认用户名: admin，密码: admin123
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock, InfoFilled } from '@element-plus/icons-vue'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()

const form = reactive({
  username: '',
  password: ''
})

const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' }
  ]
}

const loading = ref(false)
const loginForm = ref()

const handleLogin = async () => {
  if (!loginForm.value) return
  
  await loginForm.value.validate(async (valid: boolean) => {
    if (valid) {
      loading.value = true
      try {
        const success = await userStore.loginAction(form)
        if (success) {
          // 成功消息已在 userStore.loginAction 中显示，这里不需要重复显示
          router.push('/dashboard')
        } else {
          ElMessage.error('登录失败')
        }
      } catch (error: any) {
        console.error('登录错误:', error)
        ElMessage.error('登录失败：' + (error.response?.data?.message || error.message || '网络错误'))
      } finally {
        loading.value = false
      }
    }
  })
}
</script>

<style scoped lang="scss">
.login-container {
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  overflow: hidden;
}

.bg-decoration {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  
  .circle {
    position: absolute;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.1);
    animation: float 6s ease-in-out infinite;
    
    &.circle-1 {
      width: 200px;
      height: 200px;
      top: 10%;
      left: 10%;
      animation-delay: 0s;
    }
    
    &.circle-2 {
      width: 150px;
      height: 150px;
      top: 60%;
      right: 10%;
      animation-delay: 2s;
    }
    
    &.circle-3 {
      width: 100px;
      height: 100px;
      bottom: 20%;
      left: 20%;
      animation-delay: 4s;
    }
  }
}

@keyframes float {
  0%, 100% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-20px);
  }
}

.login-card {
  position: relative;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  padding: 50px 40px;
  border-radius: 20px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  width: 420px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  z-index: 1;
}

.login-header {
  text-align: center;
  margin-bottom: 40px;
  
  .logo {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
    margin-bottom: 16px;
    
    .logo-icon {
      font-size: 32px;
      animation: pulse 2s ease-in-out infinite;
    }
    
    h1 {
      font-size: 28px;
      font-weight: 700;
      background: linear-gradient(135deg, #667eea, #764ba2);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      margin: 0;
    }
  }
  
  .subtitle {
    color: #666;
    font-size: 14px;
    margin: 0;
  }
}

@keyframes pulse {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.1);
  }
}

.login-form {
  .el-form-item {
    margin-bottom: 24px;
  }
  
  .el-input {
    height: 48px;
    
    :deep(.el-input__wrapper) {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      border: 1px solid #e0e0e0;
      transition: all 0.3s ease;
      
      &:hover {
        border-color: #667eea;
        box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
      }
      
      &.is-focus {
        border-color: #667eea;
        box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
      }
    }
  }
  
  .login-btn {
    width: 100%;
    height: 48px;
    border-radius: 12px;
    font-size: 16px;
    font-weight: 600;
    background: linear-gradient(135deg, #667eea, #764ba2);
    border: none;
    transition: all 0.3s ease;
    
    &:hover {
      transform: translateY(-2px);
      box-shadow: 0 8px 20px rgba(102, 126, 234, 0.3);
    }
    
    &:active {
      transform: translateY(0);
    }
  }
}

.login-footer {
  margin-top: 30px;
  text-align: center;
  
  .help-text {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    color: #666;
    font-size: 13px;
    margin: 0;
    padding: 12px;
    background: rgba(102, 126, 234, 0.1);
    border-radius: 8px;
    border: 1px solid rgba(102, 126, 234, 0.2);
  }
}

// 响应式设计
@media (max-width: 480px) {
  .login-card {
    width: 90%;
    padding: 30px 20px;
  }
  
  .login-header .logo h1 {
    font-size: 24px;
  }
}
</style>
