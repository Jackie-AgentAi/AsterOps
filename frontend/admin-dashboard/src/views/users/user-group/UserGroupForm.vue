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
      :rules="formRules"
      label-width="120px"
    >
      <el-form-item label="用户组名称" prop="name">
        <el-input v-model="formData.name" placeholder="请输入用户组名称" />
      </el-form-item>

      <el-form-item label="描述" prop="description">
        <el-input
          v-model="formData.description"
          type="textarea"
          :rows="3"
          placeholder="请输入用户组描述"
        />
      </el-form-item>

      <el-form-item label="所属组织" prop="organization_id">
        <el-select
          v-model="formData.organization_id"
          placeholder="请选择所属组织"
          style="width: 100%"
          clearable
        >
          <el-option
            v-for="org in organizations"
            :key="org.id"
            :label="org.name"
            :value="org.id"
          />
        </el-select>
      </el-form-item>

      <el-form-item label="父级用户组" prop="parent_id">
        <el-select
          v-model="formData.parent_id"
          placeholder="请选择父级用户组"
          style="width: 100%"
          clearable
        >
          <el-option
            v-for="group in parentGroups"
            :key="group.id"
            :label="group.name"
            :value="group.id"
          />
        </el-select>
      </el-form-item>

      <el-form-item label="设置" prop="settings">
        <el-input
          v-model="formData.settings"
          type="textarea"
          :rows="2"
          placeholder="请输入JSON格式的设置信息"
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
import { createUserGroup, updateUserGroup, getOrganizations } from '@/api/user'
import type { UserGroup, Organization } from '@/types'

const emit = defineEmits<{
  success: []
  close: []
}>()

const props = defineProps<{
  visible: boolean
  group?: UserGroup | null
  mode: 'create' | 'edit' | 'view'
}>()

// 响应式数据
const loading = ref(false)
const organizations = ref<Organization[]>([])
const parentGroups = ref<UserGroup[]>([])

// 表单数据
const formData = reactive<Partial<UserGroup>>({
  name: '',
  description: '',
  organization_id: '',
  parent_id: '',
  settings: ''
})

// 表单验证规则
const formRules = {
  name: [
    { required: true, message: '请输入用户组名称', trigger: 'blur' },
    { min: 2, max: 50, message: '用户组名称长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  description: [
    { max: 200, message: '描述长度不能超过 200 个字符', trigger: 'blur' }
  ]
}

// 计算属性
const dialogTitle = computed(() => {
  switch (props.mode) {
    case 'create':
      return '新增用户组'
    case 'edit':
      return '编辑用户组'
    case 'view':
      return '查看用户组'
    default:
      return '用户组'
  }
})

const isView = computed(() => props.mode === 'view')

// 监听visible变化
watch(() => props.visible, (newVal) => {
  if (newVal) {
    initForm()
    loadOrganizations()
    loadParentGroups()
  }
})

// 监听group变化
watch(() => props.group, (newVal) => {
  if (newVal && props.visible) {
    initForm()
  }
})

// 初始化表单
const initForm = () => {
  if (props.group && (props.mode === 'edit' || props.mode === 'view')) {
    Object.assign(formData, {
      name: props.group.name || '',
      description: props.group.description || '',
      organization_id: props.group.organization_id || '',
      parent_id: props.group.parent_id || '',
      settings: props.group.settings || ''
    })
  } else {
    Object.assign(formData, {
      name: '',
      description: '',
      organization_id: '',
      parent_id: '',
      settings: ''
    })
  }
}

// 加载组织列表
const loadOrganizations = async () => {
  try {
    const response = await getOrganizations()
    organizations.value = response.data || []
  } catch (error) {
    console.error('加载组织列表失败:', error)
  }
}

// 加载父级用户组列表
const loadParentGroups = async () => {
  try {
    const response = await getUserGroups({ page: 1, pageSize: 1000 })
    parentGroups.value = response.data?.items || []
  } catch (error) {
    console.error('加载父级用户组列表失败:', error)
  }
}

// 提交表单
const handleSubmit = async () => {
  if (isView.value) return

  try {
    loading.value = true

    if (props.mode === 'create') {
      await createUserGroup(formData)
      ElMessage.success('创建成功')
    } else if (props.mode === 'edit' && props.group) {
      await updateUserGroup(props.group.id, formData)
      ElMessage.success('更新成功')
    }

    emit('success')
    handleClose()
  } catch (error) {
    ElMessage.error('操作失败')
  } finally {
    loading.value = false
  }
}

// 关闭对话框
const handleClose = () => {
  emit('close')
}
</script>

<style lang="scss" scoped>
.el-form {
  .el-form-item {
    margin-bottom: 20px;
  }
}
</style>