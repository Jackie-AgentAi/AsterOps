<template>
  <el-dialog
    v-model="visible"
    :title="dialogTitle"
    width="700px"
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form
      ref="formRef"
      :model="formData"
      :rules="rules"
      label-width="120px"
    >
      <el-form-item label="策略类型" prop="policy_type">
        <el-select v-model="formData.policy_type" placeholder="请选择策略类型">
          <el-option label="密码策略" value="password_policy" />
          <el-option label="登录策略" value="login_policy" />
          <el-option label="会话策略" value="session_policy" />
          <el-option label="访问控制策略" value="access_control" />
          <el-option label="数据保护策略" value="data_protection" />
        </el-select>
      </el-form-item>
      
      <el-form-item label="策略名称" prop="name">
        <el-input v-model="formData.name" placeholder="请输入策略名称" />
      </el-form-item>
      
      <el-form-item label="策略描述" prop="description">
        <el-input
          v-model="formData.description"
          type="textarea"
          :rows="3"
          placeholder="请输入策略描述"
        />
      </el-form-item>
      
      <el-form-item label="策略配置" prop="policy_config">
        <div class="policy-config">
          <el-tabs v-model="activeTab" type="border-card">
            <!-- 密码策略 -->
            <el-tab-pane label="密码策略" name="password" v-if="formData.policy_type === 'password_policy'">
              <el-form-item label="最小长度">
                <el-input-number v-model="formData.policy_config.min_length" :min="6" :max="32" />
              </el-form-item>
              <el-form-item label="必须包含数字">
                <el-switch v-model="formData.policy_config.require_digit" />
              </el-form-item>
              <el-form-item label="必须包含大写字母">
                <el-switch v-model="formData.policy_config.require_uppercase" />
              </el-form-item>
              <el-form-item label="必须包含小写字母">
                <el-switch v-model="formData.policy_config.require_lowercase" />
              </el-form-item>
              <el-form-item label="必须包含特殊字符">
                <el-switch v-model="formData.policy_config.require_special" />
              </el-form-item>
              <el-form-item label="密码有效期(天)">
                <el-input-number v-model="formData.policy_config.password_expiry" :min="0" />
              </el-form-item>
            </el-tab-pane>
            
            <!-- 登录策略 -->
            <el-tab-pane label="登录策略" name="login" v-if="formData.policy_type === 'login_policy'">
              <el-form-item label="最大失败次数">
                <el-input-number v-model="formData.policy_config.max_failed_attempts" :min="3" :max="10" />
              </el-form-item>
              <el-form-item label="锁定时间(分钟)">
                <el-input-number v-model="formData.policy_config.lockout_duration" :min="5" :max="1440" />
              </el-form-item>
              <el-form-item label="启用IP白名单">
                <el-switch v-model="formData.policy_config.enable_ip_whitelist" />
              </el-form-item>
              <el-form-item label="IP白名单" v-if="formData.policy_config.enable_ip_whitelist">
                <el-input
                  v-model="ipWhitelistText"
                  type="textarea"
                  :rows="3"
                  placeholder="每行一个IP地址或IP段，如：192.168.1.1 或 192.168.1.0/24"
                />
              </el-form-item>
            </el-tab-pane>
            
            <!-- 会话策略 -->
            <el-tab-pane label="会话策略" name="session" v-if="formData.policy_type === 'session_policy'">
              <el-form-item label="会话超时时间(分钟)">
                <el-input-number v-model="formData.policy_config.session_timeout" :min="5" :max="1440" />
              </el-form-item>
              <el-form-item label="最大并发会话数">
                <el-input-number v-model="formData.policy_config.max_concurrent_sessions" :min="1" :max="10" />
              </el-form-item>
              <el-form-item label="启用会话固定">
                <el-switch v-model="formData.policy_config.enable_session_fixation" />
              </el-form-item>
            </el-tab-pane>
            
            <!-- 访问控制策略 -->
            <el-tab-pane label="访问控制" name="access" v-if="formData.policy_type === 'access_control'">
              <el-form-item label="启用时间限制">
                <el-switch v-model="formData.policy_config.enable_time_restriction" />
              </el-form-item>
              <el-form-item label="允许访问时间" v-if="formData.policy_config.enable_time_restriction">
                <el-time-picker
                  v-model="formData.policy_config.allowed_hours"
                  is-range
                  range-separator="至"
                  start-placeholder="开始时间"
                  end-placeholder="结束时间"
                />
              </el-form-item>
              <el-form-item label="启用地理位置限制">
                <el-switch v-model="formData.policy_config.enable_geo_restriction" />
              </el-form-item>
            </el-tab-pane>
            
            <!-- 数据保护策略 -->
            <el-tab-pane label="数据保护" name="data" v-if="formData.policy_type === 'data_protection'">
              <el-form-item label="启用数据加密">
                <el-switch v-model="formData.policy_config.enable_encryption" />
              </el-form-item>
              <el-form-item label="启用数据脱敏">
                <el-switch v-model="formData.policy_config.enable_data_masking" />
              </el-form-item>
              <el-form-item label="数据保留期限(天)">
                <el-input-number v-model="formData.policy_config.data_retention_days" :min="30" :max="3650" />
              </el-form-item>
            </el-tab-pane>
          </el-tabs>
        </div>
      </el-form-item>
      
      <el-form-item label="是否启用" prop="is_active">
        <el-switch v-model="formData.is_active" />
      </el-form-item>
    </el-form>
    
    <template #footer>
      <el-button @click="handleClose">取消</el-button>
      <el-button type="primary" @click="handleSubmit" :loading="loading">
        确定
      </el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { createSecurityPolicy, updateSecurityPolicy } from '@/api/user'
import type { SecurityPolicy } from '@/types'

interface Props {
  modelValue: boolean
  policy?: SecurityPolicy
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: false,
  policy: undefined
})

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  success: []
}>()

const formRef = ref()
const loading = ref(false)
const activeTab = ref('password')
const ipWhitelistText = ref('')

const visible = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const dialogTitle = computed(() => {
  return props.policy ? '编辑安全策略' : '新增安全策略'
})

const formData = reactive<Partial<SecurityPolicy>>({
  policy_type: '',
  name: '',
  description: '',
  policy_config: {},
  is_active: true
})

const rules = {
  policy_type: [
    { required: true, message: '请选择策略类型', trigger: 'change' }
  ],
  name: [
    { required: true, message: '请输入策略名称', trigger: 'blur' },
    { min: 2, max: 50, message: '策略名称长度在 2 到 50 个字符', trigger: 'blur' }
  ]
}

// 初始化表单数据
const initFormData = () => {
  if (props.policy) {
    Object.assign(formData, {
      policy_type: props.policy.policy_type,
      name: props.policy.name,
      description: props.policy.description,
      policy_config: props.policy.policy_config || {},
      is_active: props.policy.is_active
    })
    
    // 处理IP白名单
    if (props.policy.policy_config?.ip_whitelist) {
      ipWhitelistText.value = props.policy.policy_config.ip_whitelist.join('\n')
    }
  } else {
    Object.assign(formData, {
      policy_type: '',
      name: '',
      description: '',
      policy_config: {},
      is_active: true
    })
    ipWhitelistText.value = ''
  }
  
  // 根据策略类型设置默认配置
  setDefaultPolicyConfig()
}

// 设置默认策略配置
const setDefaultPolicyConfig = () => {
  const defaultConfigs: Record<string, any> = {
    password_policy: {
      min_length: 8,
      require_digit: true,
      require_uppercase: true,
      require_lowercase: true,
      require_special: true,
      password_expiry: 90
    },
    login_policy: {
      max_failed_attempts: 5,
      lockout_duration: 30,
      enable_ip_whitelist: false,
      ip_whitelist: []
    },
    session_policy: {
      session_timeout: 30,
      max_concurrent_sessions: 3,
      enable_session_fixation: true
    },
    access_control: {
      enable_time_restriction: false,
      allowed_hours: null,
      enable_geo_restriction: false
    },
    data_protection: {
      enable_encryption: true,
      enable_data_masking: true,
      data_retention_days: 365
    }
  }
  
  if (formData.policy_type && !formData.policy_config || Object.keys(formData.policy_config).length === 0) {
    formData.policy_config = { ...defaultConfigs[formData.policy_type] }
  }
}

// 处理IP白名单
const handleIpWhitelist = () => {
  if (formData.policy_config?.enable_ip_whitelist) {
    formData.policy_config.ip_whitelist = ipWhitelistText.value
      .split('\n')
      .map(ip => ip.trim())
      .filter(ip => ip.length > 0)
  }
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid: boolean) => {
    if (valid) {
      handleIpWhitelist()
      
      loading.value = true
      try {
        if (props.policy) {
          await updateSecurityPolicy(props.policy.id, formData)
          ElMessage.success('更新成功')
        } else {
          await createSecurityPolicy(formData)
          ElMessage.success('创建成功')
        }
        emit('success')
        handleClose()
      } catch (error) {
        ElMessage.error(props.policy ? '更新失败' : '创建失败')
      } finally {
        loading.value = false
      }
    }
  })
}

// 关闭对话框
const handleClose = () => {
  visible.value = false
  formRef.value?.resetFields()
}

// 监听策略类型变化
watch(() => formData.policy_type, (newType) => {
  if (newType) {
    setDefaultPolicyConfig()
  }
})

// 监听对话框显示状态
watch(visible, (newVal) => {
  if (newVal) {
    initFormData()
  }
})
</script>

<style lang="scss" scoped>
.policy-config {
  .el-tabs {
    margin-top: 16px;
  }
  
  .el-form-item {
    margin-bottom: 16px;
  }
}
</style>
