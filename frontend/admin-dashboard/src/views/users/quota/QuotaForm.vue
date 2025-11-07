<template>
  <el-dialog
    v-model="visible"
    :title="dialogTitle"
    width="600px"
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form
      ref="formRef"
      :model="formData"
      :rules="rules"
      label-width="120px"
    >
      <el-form-item label="用户" prop="user_id">
        <el-select v-model="formData.user_id" placeholder="请选择用户" filterable>
          <el-option
            v-for="user in userOptions"
            :key="user.id"
            :label="user.username"
            :value="user.id"
          />
        </el-select>
      </el-form-item>
      
      <el-form-item label="资源类型" prop="resource_type">
        <el-select v-model="formData.resource_type" placeholder="请选择资源类型">
          <el-option label="API调用次数" value="api_calls" />
          <el-option label="存储空间(MB)" value="storage" />
          <el-option label="计算资源(小时)" value="compute" />
          <el-option label="模型推理次数" value="inference" />
          <el-option label="数据上传次数" value="upload" />
        </el-select>
      </el-form-item>
      
      <el-form-item label="配额限制" prop="quota_limit">
        <el-input-number
          v-model="formData.quota_limit"
          :min="0"
          :max="999999999"
          placeholder="请输入配额限制"
          style="width: 100%"
        />
      </el-form-item>
      
      <el-form-item label="已使用量" prop="used_amount">
        <el-input-number
          v-model="formData.used_amount"
          :min="0"
          :max="formData.quota_limit"
          placeholder="请输入已使用量"
          style="width: 100%"
        />
      </el-form-item>
      
      <el-form-item label="周期类型" prop="period_type">
        <el-select v-model="formData.period_type" placeholder="请选择周期类型">
          <el-option label="每日" value="daily" />
          <el-option label="每周" value="weekly" />
          <el-option label="每月" value="monthly" />
          <el-option label="每年" value="yearly" />
          <el-option label="永久" value="permanent" />
        </el-select>
      </el-form-item>
      
      <el-form-item label="备注" prop="description">
        <el-input
          v-model="formData.description"
          type="textarea"
          :rows="3"
          placeholder="请输入备注"
        />
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
import { createUserQuota, updateUserQuota, getUserList } from '@/api/user'
import type { UserQuota, UserInfo } from '@/types'

interface Props {
  modelValue: boolean
  quota?: UserQuota
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: false,
  quota: undefined
})

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  success: []
}>()

const formRef = ref()
const loading = ref(false)
const userOptions = ref<UserInfo[]>([])

const visible = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const dialogTitle = computed(() => {
  return props.quota ? '编辑配额' : '新增配额'
})

const formData = reactive<Partial<UserQuota>>({
  user_id: '',
  resource_type: '',
  quota_limit: 0,
  used_amount: 0,
  period_type: 'monthly',
  description: ''
})

const rules = {
  user_id: [
    { required: true, message: '请选择用户', trigger: 'change' }
  ],
  resource_type: [
    { required: true, message: '请选择资源类型', trigger: 'change' }
  ],
  quota_limit: [
    { required: true, message: '请输入配额限制', trigger: 'blur' },
    { type: 'number', min: 0, message: '配额限制必须大于等于0', trigger: 'blur' }
  ],
  used_amount: [
    { required: true, message: '请输入已使用量', trigger: 'blur' },
    { type: 'number', min: 0, message: '已使用量必须大于等于0', trigger: 'blur' }
  ],
  period_type: [
    { required: true, message: '请选择周期类型', trigger: 'change' }
  ]
}

// 获取用户选项
const fetchUsers = async () => {
  try {
    const response = await getUserList({ page: 1, pageSize: 1000 })
    userOptions.value = response.items || []
  } catch (error) {
    console.error('获取用户列表失败:', error)
  }
}

// 初始化表单数据
const initFormData = () => {
  if (props.quota) {
    Object.assign(formData, {
      user_id: props.quota.user_id,
      resource_type: props.quota.resource_type,
      quota_limit: props.quota.quota_limit,
      used_amount: props.quota.used_amount,
      period_type: props.quota.period_type,
      description: props.quota.description || ''
    })
  } else {
    Object.assign(formData, {
      user_id: '',
      resource_type: '',
      quota_limit: 0,
      used_amount: 0,
      period_type: 'monthly',
      description: ''
    })
  }
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid: boolean) => {
    if (valid) {
      loading.value = true
      try {
        if (props.quota) {
          await updateUserQuota(props.quota.id, formData)
          ElMessage.success('更新成功')
        } else {
          await createUserQuota(formData)
          ElMessage.success('创建成功')
        }
        emit('success')
        handleClose()
      } catch (error) {
        ElMessage.error(props.quota ? '更新失败' : '创建失败')
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

// 监听对话框显示状态
watch(visible, (newVal) => {
  if (newVal) {
    initFormData()
    fetchUsers()
  }
})
</script>

<style lang="scss" scoped>
.el-form {
  .el-form-item {
    margin-bottom: 20px;
  }
}
</style>
