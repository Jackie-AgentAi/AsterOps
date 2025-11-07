<template>
  <div class="settings-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>账户设置</h2>
      <p>管理您的账户安全和偏好设置</p>
    </div>

    <div class="settings-content">
      <!-- 密码安全 -->
        <el-card class="settings-card">
          <template #header>
          <div class="card-header">
            <span>密码安全</span>
            <el-button type="primary" @click="handleChangePassword">
              修改密码
            </el-button>
          </div>
          </template>
          
        <div class="security-info">
          <div class="info-item">
            <label>当前密码</label>
            <span>••••••••</span>
          </div>
          <div class="info-item">
            <label>最后修改</label>
            <span>{{ formatDate(userStore.userInfo?.updated_at) }}</span>
          </div>
        </div>
        </el-card>

      <!-- 修改密码对话框 -->
      <el-dialog
        v-model="passwordDialogVisible"
        title="修改密码"
        width="500px"
        :before-close="handleClosePasswordDialog"
      >
        <el-form
          :model="passwordForm"
          :rules="passwordRules"
          ref="passwordFormRef"
          label-width="100px"
        >
          <el-form-item label="当前密码" prop="currentPassword">
            <el-input
              v-model="passwordForm.currentPassword"
              type="password"
              placeholder="请输入当前密码"
              show-password
            ></el-input>
                </el-form-item>
          <el-form-item label="新密码" prop="newPassword">
            <el-input
              v-model="passwordForm.newPassword"
              type="password"
              placeholder="请输入新密码"
              show-password
            ></el-input>
                </el-form-item>
          <el-form-item label="确认密码" prop="confirmPassword">
              <el-input 
              v-model="passwordForm.confirmPassword"
              type="password"
              placeholder="请再次输入新密码"
              show-password
            ></el-input>
            </el-form-item>
          </el-form>
        <template #footer>
          <el-button @click="handleClosePasswordDialog">取消</el-button>
          <el-button type="primary" @click="handleSavePassword" :loading="passwordLoading">
            确定
          </el-button>
        </template>
      </el-dialog>

      <!-- 通知设置 -->
        <el-card class="settings-card">
          <template #header>
          <span>通知设置</span>
          </template>
          
        <div class="notification-settings">
          <div class="setting-item">
            <div class="setting-info">
              <h4>系统通知</h4>
              <p>接收系统更新、维护等重要通知</p>
            </div>
            <el-switch v-model="notificationSettings.system" />
          </div>
          <div class="setting-item">
            <div class="setting-info">
              <h4>邮件通知</h4>
              <p>通过邮件接收重要通知和提醒</p>
            </div>
            <el-switch v-model="notificationSettings.email" />
          </div>
          <div class="setting-item">
            <div class="setting-info">
              <h4>安全提醒</h4>
              <p>接收登录异常、密码修改等安全相关提醒</p>
            </div>
            <el-switch v-model="notificationSettings.security" />
          </div>
        </div>
        </el-card>

      <!-- 偏好设置 -->
        <el-card class="settings-card">
          <template #header>
          <span>偏好设置</span>
          </template>
          
        <div class="preference-settings">
          <div class="setting-item">
            <div class="setting-info">
              <h4>语言设置</h4>
              <p>选择界面显示语言</p>
            </div>
            <el-select v-model="preferenceSettings.language" style="width: 120px">
              <el-option label="中文" value="zh-CN" />
              <el-option label="English" value="en-US" />
            </el-select>
          </div>
          <div class="setting-item">
            <div class="setting-info">
              <h4>时区设置</h4>
              <p>选择您所在的时区</p>
            </div>
            <el-select v-model="preferenceSettings.timezone" style="width: 200px">
              <el-option label="北京时间 (UTC+8)" value="Asia/Shanghai" />
              <el-option label="东京时间 (UTC+9)" value="Asia/Tokyo" />
              <el-option label="纽约时间 (UTC-5)" value="America/New_York" />
              <el-option label="伦敦时间 (UTC+0)" value="Europe/London" />
            </el-select>
          </div>
          <div class="setting-item">
            <div class="setting-info">
              <h4>主题设置</h4>
              <p>选择界面主题风格</p>
            </div>
            <el-radio-group v-model="preferenceSettings.theme">
              <el-radio label="light">浅色主题</el-radio>
              <el-radio label="dark">深色主题</el-radio>
              <el-radio label="auto">跟随系统</el-radio>
            </el-radio-group>
          </div>
        </div>
        </el-card>

      <!-- 数据管理 -->
        <el-card class="settings-card">
          <template #header>
          <span>数据管理</span>
          </template>
          
        <div class="data-management">
          <div class="setting-item">
            <div class="setting-info">
              <h4>导出数据</h4>
              <p>导出您的个人数据和设置</p>
            </div>
            <el-button @click="handleExportData">导出数据</el-button>
          </div>
          <div class="setting-item">
            <div class="setting-info">
              <h4>清除缓存</h4>
              <p>清除浏览器缓存和临时数据</p>
            </div>
            <el-button @click="handleClearCache">清除缓存</el-button>
          </div>
          <div class="setting-item danger">
            <div class="setting-info">
              <h4>删除账户</h4>
              <p>永久删除您的账户和所有相关数据</p>
            </div>
            <el-button type="danger" @click="handleDeleteAccount">删除账户</el-button>
            </div>
          </div>
        </el-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useUserStore } from '@/stores/user'
import { changePassword } from '@/api/user'
import dayjs from 'dayjs'

const userStore = useUserStore()

// 响应式数据
const passwordDialogVisible = ref(false)
const passwordLoading = ref(false)
const passwordFormRef = ref()

// 密码表单
const passwordForm = reactive({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

// 密码验证规则
const passwordRules = {
  currentPassword: [
    { required: true, message: '请输入当前密码', trigger: 'blur' }
  ],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度在 6 到 20 个字符', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    {
      validator: (rule: any, value: string, callback: Function) => {
        if (value !== passwordForm.newPassword) {
          callback(new Error('两次输入的密码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ]
}

// 通知设置
const notificationSettings = reactive({
  system: true,
  email: true,
  security: true
})

// 偏好设置
const preferenceSettings = reactive({
  language: 'zh-CN',
  timezone: 'Asia/Shanghai',
  theme: 'light'
})

// 修改密码
const handleChangePassword = () => {
  passwordDialogVisible.value = true
  Object.assign(passwordForm, {
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  })
}

// 关闭密码对话框
const handleClosePasswordDialog = () => {
  passwordDialogVisible.value = false
  if (passwordFormRef.value) {
    passwordFormRef.value.resetFields()
  }
}

// 保存密码
const handleSavePassword = async () => {
  if (!passwordFormRef.value) return
  
  try {
    await passwordFormRef.value.validate()
    passwordLoading.value = true
    
    await changePassword({
      currentPassword: passwordForm.currentPassword,
      newPassword: passwordForm.newPassword
    })
    
    ElMessage.success('密码修改成功')
    handleClosePasswordDialog()
  } catch (error) {
    console.error('修改密码失败:', error)
    ElMessage.error('修改密码失败')
  } finally {
    passwordLoading.value = false
  }
}

// 导出数据
const handleExportData = () => {
  ElMessage.info('数据导出功能开发中')
}

// 清除缓存
const handleClearCache = async () => {
  try {
    await ElMessageBox.confirm('确定要清除所有缓存吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    // 清除localStorage中的缓存数据
    const keysToKeep = ['token', 'userInfo']
    Object.keys(localStorage).forEach(key => {
      if (!keysToKeep.includes(key)) {
        localStorage.removeItem(key)
      }
    })
    
    ElMessage.success('缓存清除成功')
  } catch (error) {
    // 用户取消操作
  }
}

// 删除账户
const handleDeleteAccount = async () => {
  try {
    await ElMessageBox.confirm(
      '删除账户是不可逆的操作，将永久删除您的所有数据。确定要继续吗？',
      '危险操作',
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        type: 'error',
        confirmButtonClass: 'el-button--danger'
      }
    )
    
    ElMessage.error('账户删除功能开发中，请联系管理员')
  } catch (error) {
    // 用户取消操作
  }
}

// 格式化日期
const formatDate = (date: string | undefined) => {
  if (!date) return '未知'
  return dayjs(date).format('YYYY-MM-DD HH:mm:ss')
}

// 初始化设置
const initSettings = () => {
  // 从localStorage加载用户设置
  const savedNotificationSettings = localStorage.getItem('notificationSettings')
  if (savedNotificationSettings) {
    Object.assign(notificationSettings, JSON.parse(savedNotificationSettings))
  }
  
  const savedPreferenceSettings = localStorage.getItem('preferenceSettings')
  if (savedPreferenceSettings) {
    Object.assign(preferenceSettings, JSON.parse(savedPreferenceSettings))
  }
}

// 保存设置
const saveSettings = () => {
  localStorage.setItem('notificationSettings', JSON.stringify(notificationSettings))
  localStorage.setItem('preferenceSettings', JSON.stringify(preferenceSettings))
}

// 监听设置变化
const watchSettings = () => {
  // 这里可以添加设置变化的监听逻辑
}

// 初始化
onMounted(() => {
  initSettings()
  watchSettings()
})
</script>

<style lang="scss" scoped>

.settings-page {
  padding: 24px;

  .page-header {
    margin-bottom: 24px;
    
    h2 {
      font-size: 24px;
      color: #303133;
      margin: 0 0 8px 0;
    }
    
    p {
      color: #909399;
      margin: 0;
    }
  }

  .settings-content {
    display: grid;
    gap: 24px;
  }

    .settings-card {
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .security-info {
        .info-item {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 8px 0;
          border-bottom: 1px solid #f0f0f0;

          &:last-child {
            border-bottom: none;
          }

          label {
            font-weight: 500;
            color: #909399;
          }

          span {
            color: #303133;
          }
        }
    }

    .notification-settings,
    .preference-settings,
    .data-management {
      .setting-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 16px 0;
        border-bottom: 1px solid #f0f0f0;

        &:last-child {
          border-bottom: none;
        }

        &.danger {
          .setting-info h4 {
            color: #f56c6c;
          }
        }

        .setting-info {
          flex: 1;

          h4 {
            margin: 0 0 8px 0;
            color: #303133;
            font-size: 16px;
          }

          p {
            margin: 0;
            color: #909399;
            font-size: 14px;
          }
        }
      }
    }
  }
}
</style>