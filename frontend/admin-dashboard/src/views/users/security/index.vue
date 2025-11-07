<template>
  <div class="security-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <div class="header-left">
        <el-button type="text" @click="goBack" class="back-button">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
        <div class="title-section">
          <h2>安全管理</h2>
          <p>管理用户安全策略和权限设置</p>
        </div>
      </div>
      <div class="header-right">
        <el-button type="primary" @click="handleAddPolicy">
          <el-icon><Plus /></el-icon>
          添加安全策略
        </el-button>
      </div>
    </div>

    <!-- 安全策略内容 -->
    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <template #header>
            <span>密码策略</span>
          </template>
          <div class="policy-content">
            <el-form :model="passwordPolicy" label-width="120px">
              <el-form-item label="最小长度">
                <el-input-number v-model="passwordPolicy.minLength" :min="6" :max="32" />
              </el-form-item>
              <el-form-item label="包含数字">
                <el-switch v-model="passwordPolicy.requireNumber" />
              </el-form-item>
              <el-form-item label="包含特殊字符">
                <el-switch v-model="passwordPolicy.requireSpecial" />
              </el-form-item>
              <el-form-item label="密码有效期(天)">
                <el-input-number v-model="passwordPolicy.expiryDays" :min="0" />
              </el-form-item>
            </el-form>
            <div class="form-actions">
              <el-button type="primary" @click="savePasswordPolicy">保存设置</el-button>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :span="12">
        <el-card>
          <template #header>
            <span>登录策略</span>
          </template>
          <div class="policy-content">
            <el-form :model="loginPolicy" label-width="120px">
              <el-form-item label="最大失败次数">
                <el-input-number v-model="loginPolicy.maxFailures" :min="3" :max="10" />
              </el-form-item>
              <el-form-item label="锁定时间(分钟)">
                <el-input-number v-model="loginPolicy.lockoutTime" :min="5" :max="60" />
              </el-form-item>
              <el-form-item label="会话超时(小时)">
                <el-input-number v-model="loginPolicy.sessionTimeout" :min="1" :max="24" />
              </el-form-item>
              <el-form-item label="启用双因素认证">
                <el-switch v-model="loginPolicy.enable2FA" />
              </el-form-item>
            </el-form>
            <div class="form-actions">
              <el-button type="primary" @click="saveLoginPolicy">保存设置</el-button>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft, Plus } from '@element-plus/icons-vue'

const router = useRouter()

// 密码策略
const passwordPolicy = ref({
  minLength: 8,
  requireNumber: true,
  requireSpecial: true,
  expiryDays: 90
})

// 登录策略
const loginPolicy = ref({
  maxFailures: 5,
  lockoutTime: 30,
  sessionTimeout: 8,
  enable2FA: false
})

// 返回上一页
const goBack = () => {
  router.back()
}

// 添加安全策略
const handleAddPolicy = () => {
  ElMessage.info('添加安全策略功能待实现')
}

// 保存密码策略
const savePasswordPolicy = () => {
  ElMessage.success('密码策略已保存')
}

// 保存登录策略
const saveLoginPolicy = () => {
  ElMessage.success('登录策略已保存')
}
</script>

<style scoped>
.security-page {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.back-button {
  color: #606266;
}

.title-section h2 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}

.title-section p {
  margin: 4px 0 0 0;
  color: #909399;
  font-size: 14px;
}

.header-right {
  display: flex;
  gap: 12px;
}

.policy-content {
  padding: 20px 0;
}

.form-actions {
  margin-top: 20px;
  text-align: right;
}
</style>
