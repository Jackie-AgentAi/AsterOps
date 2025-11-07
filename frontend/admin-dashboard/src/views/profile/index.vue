<template>
  <div class="profile-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>个人资料</h2>
      <p>管理您的个人信息和头像</p>
    </div>

    <div class="profile-content">
      <!-- 基本信息卡片 -->
      <el-card class="profile-card">
        <template #header>
          <div class="card-header">
            <span>基本信息</span>
            <el-button type="primary" @click="handleEditProfile" v-if="!isEditing">
              编辑资料
            </el-button>
            <div v-else>
              <el-button type="success" @click="handleSaveProfile">保存</el-button>
              <el-button @click="handleCancelEdit">取消</el-button>
            </div>
          </div>
        </template>

        <div class="profile-form">
          <!-- 头像区域 -->
          <div class="avatar-section">
            <div class="profile-avatar" :style="avatarStyle">
              <span class="avatar-text">{{ avatarText }}</span>
            </div>
            <div class="avatar-actions" v-if="isEditing">
              <el-button type="primary" size="small" @click="handleUploadAvatar">
                更换头像
              </el-button>
              <el-button size="small" @click="handleRemoveAvatar">
                移除头像
              </el-button>
            </div>
          </div>

          <!-- 表单区域 -->
          <el-form
            :model="formData"
            :rules="formRules"
            ref="formRef"
            label-width="100px"
            class="profile-form-content"
          >
            <el-row :gutter="20">
              <el-col :span="12">
                <el-form-item label="用户名" prop="username">
                  <el-input v-model="formData.username" :disabled="!isEditing"></el-input>
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="邮箱" prop="email">
                  <el-input v-model="formData.email" :disabled="!isEditing"></el-input>
                </el-form-item>
              </el-col>
            </el-row>

            <el-row :gutter="20">
              <el-col :span="12">
                <el-form-item label="姓名" prop="name">
                  <el-input v-model="formData.name" :disabled="!isEditing"></el-input>
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="电话" prop="phone">
                  <el-input v-model="formData.phone" :disabled="!isEditing"></el-input>
                </el-form-item>
              </el-col>
            </el-row>

            <el-row :gutter="20">
              <el-col :span="12">
                <el-form-item label="部门" prop="department">
                  <el-input v-model="formData.department" :disabled="!isEditing"></el-input>
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="角色" prop="role">
                  <el-input v-model="formData.role" disabled></el-input>
                </el-form-item>
              </el-col>
            </el-row>

            <el-form-item label="个人简介" prop="bio">
              <el-input
                v-model="formData.bio"
                type="textarea"
                :rows="3"
                placeholder="请输入个人简介"
                :disabled="!isEditing"
              ></el-input>
            </el-form-item>
          </el-form>
        </div>
      </el-card>

      <!-- 登录信息卡片 -->
      <el-card class="info-card">
        <template #header>
          <span>登录信息</span>
        </template>
        <div class="info-grid">
          <div class="info-item">
            <label>用户ID</label>
            <span>{{ userStore.userInfo?.id }}</span>
          </div>
          <div class="info-item">
            <label>租户ID</label>
            <span>{{ userStore.userInfo?.tenant_id }}</span>
          </div>
          <div class="info-item">
            <label>创建时间</label>
            <span>{{ formatDate(userStore.userInfo?.created_at) }}</span>
          </div>
          <div class="info-item">
            <label>最后登录</label>
            <span>{{ formatDate(userStore.userInfo?.lastLoginAt) || '从未登录' }}</span>
          </div>
          <div class="info-item">
            <label>账户状态</label>
            <el-tag :type="userStore.userInfo?.status === 'active' ? 'success' : 'danger'">
              {{ userStore.userInfo?.status === 'active' ? '正常' : '禁用' }}
            </el-tag>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useUserStore } from '@/stores/user'
import { updateUserProfile } from '@/api/user'
import type { UserInfo } from '@/types/user'
import dayjs from 'dayjs'

const userStore = useUserStore()

// 响应式数据
const isEditing = ref(false)
const formRef = ref()
const loading = ref(false)

// 表单数据
const formData = reactive({
  username: '',
  email: '',
  name: '',
  phone: '',
  department: '',
  bio: '',
  avatar: '',
  role: ''
})

// 表单验证规则
const formRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '用户名长度在 3 到 20 个字符', trigger: 'blur' }
  ],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱格式', trigger: ['blur', 'change'] }
  ],
  phone: [
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号码', trigger: 'blur' }
  ]
}

// 初始化表单数据
const initFormData = () => {
  const userInfo = userStore.userInfo
  if (userInfo) {
    Object.assign(formData, {
      username: userInfo.username || '',
      email: userInfo.email || '',
      name: userInfo.name || '',
      phone: userInfo.phone || '',
      department: userInfo.department || '',
      bio: userInfo.bio || '',
      avatar: userInfo.avatar || '',
      role: userInfo.role || ''
    })
  }
}

// 编辑资料
const handleEditProfile = () => {
  isEditing.value = true
}

// 取消编辑
const handleCancelEdit = () => {
  isEditing.value = false
  initFormData() // 重置表单数据
}

// 保存资料
const handleSaveProfile = async () => {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
    loading.value = true
    
    await updateUserProfile(formData)
    ElMessage.success('个人资料更新成功')
    
    // 更新用户信息
    await userStore.initUser()
    isEditing.value = false
  } catch (error) {
    console.error('更新个人资料失败:', error)
    ElMessage.error('更新个人资料失败')
  } finally {
    loading.value = false
  }
}

// 上传头像
const handleUploadAvatar = () => {
  ElMessage.info('头像上传功能开发中')
}

// 移除头像
const handleRemoveAvatar = () => {
  formData.avatar = ''
}

// 格式化日期
const formatDate = (date: string | undefined) => {
  if (!date) return ''
  return dayjs(date).format('YYYY-MM-DD HH:mm:ss')
}

// 生成头像文本
const avatarText = computed(() => {
  const name = formData.name || formData.username || 'U'
  return name.charAt(0).toUpperCase()
})

// 生成头像样式
const avatarStyle = computed(() => {
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
  
  // 根据用户名生成一致的背景色
  const hash = (formData.username || 'user').split('').reduce((a, b) => {
    a = ((a << 5) - a) + b.charCodeAt(0)
    return a & a
  }, 0)
  
  const colorIndex = Math.abs(hash) % colors.length
  const background = colors[colorIndex]
  
  return {
    background,
    width: '120px',
    height: '120px',
    borderRadius: '50%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
    border: '3px solid #fff'
  }
})

// 初始化
onMounted(() => {
  initFormData()
})
</script>

<style lang="scss" scoped>

.profile-page {
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

  .profile-content {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: 24px;

    @media (max-width: 768px) {
      grid-template-columns: 1fr;
    }
  }

  .profile-card {
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .profile-form {
      .avatar-section {
        display: flex;
        align-items: center;
        margin-bottom: 24px;
        padding: 16px;
        background: #f8f9fa;
        border-radius: 4px;

        .profile-avatar {
          margin-right: 16px;
          position: relative;
          
          .avatar-text {
            font-size: 48px;
            font-weight: bold;
            color: white;
            text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
            user-select: none;
          }
        }

        .avatar-actions {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }
      }

      .profile-form-content {
        .el-form-item {
          margin-bottom: 16px;
        }
      }
    }
  }

  .info-card {
    .info-grid {
      display: grid;
      gap: 16px;

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
  }
}
</style>
