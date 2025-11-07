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
      label-width="100px"
    >
      <el-form-item label="组织名称" prop="name">
        <el-input v-model="formData.name" placeholder="请输入组织名称" />
      </el-form-item>
      
      <el-form-item label="组织代码" prop="code">
        <el-input v-model="formData.code" placeholder="请输入组织代码" />
      </el-form-item>
      
      <el-form-item label="描述" prop="description">
        <el-input
          v-model="formData.description"
          type="textarea"
          :rows="3"
          placeholder="请输入组织描述"
        />
      </el-form-item>
      
      <el-form-item label="父级组织" prop="parent_id">
        <el-tree-select
          v-model="formData.parent_id"
          :data="parentOptions"
          :props="treeSelectProps"
          placeholder="请选择父级组织"
          clearable
          check-strictly
        />
      </el-form-item>
      
      <el-form-item label="组织类型" prop="type">
        <el-select v-model="formData.type" placeholder="请选择组织类型">
          <el-option label="公司" value="company" />
          <el-option label="部门" value="department" />
          <el-option label="团队" value="team" />
          <el-option label="项目组" value="project" />
        </el-select>
      </el-form-item>
      
      <el-form-item label="状态" prop="status">
        <el-select v-model="formData.status" placeholder="请选择状态">
          <el-option label="启用" value="active" />
          <el-option label="禁用" value="inactive" />
        </el-select>
      </el-form-item>
      
      <el-form-item label="设置" prop="settings">
        <el-input
          v-model="settingsJson"
          type="textarea"
          :rows="4"
          placeholder="请输入JSON格式的设置"
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
import { createOrganization, updateOrganization, getOrganizationTree } from '@/api/user'
import type { Organization } from '@/types'

interface Props {
  modelValue: boolean
  organization?: Organization
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: false,
  organization: undefined
})

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  success: []
}>()

const formRef = ref()
const loading = ref(false)
const parentOptions = ref([])

const visible = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const dialogTitle = computed(() => {
  return props.organization ? '编辑组织' : '新增组织'
})

const formData = reactive<Partial<Organization>>({
  name: '',
  code: '',
  description: '',
  parent_id: undefined,
  type: 'department',
  status: 'active',
  settings: {}
})

const settingsJson = ref('{}')

const rules = {
  name: [
    { required: true, message: '请输入组织名称', trigger: 'blur' },
    { min: 2, max: 50, message: '组织名称长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  code: [
    { required: true, message: '请输入组织代码', trigger: 'blur' },
    { min: 2, max: 20, message: '组织代码长度在 2 到 20 个字符', trigger: 'blur' }
  ],
  type: [
    { required: true, message: '请选择组织类型', trigger: 'change' }
  ],
  status: [
    { required: true, message: '请选择状态', trigger: 'change' }
  ]
}

const treeSelectProps = {
  value: 'id',
  label: 'name',
  children: 'children'
}

// 获取组织树
const fetchOrganizationTree = async () => {
  try {
    const response = await getOrganizationTree()
    parentOptions.value = response || []
  } catch (error) {
    console.error('获取组织树失败:', error)
  }
}

// 初始化表单数据
const initFormData = () => {
  if (props.organization) {
    Object.assign(formData, {
      name: props.organization.name,
      code: props.organization.code,
      description: props.organization.description,
      parent_id: props.organization.parent_id,
      type: props.organization.type,
      status: props.organization.status,
      settings: props.organization.settings || {}
    })
    settingsJson.value = JSON.stringify(props.organization.settings || {}, null, 2)
  } else {
    Object.assign(formData, {
      name: '',
      code: '',
      description: '',
      parent_id: undefined,
      type: 'department',
      status: 'active',
      settings: {}
    })
    settingsJson.value = '{}'
  }
}

// 处理设置JSON
const handleSettingsJson = () => {
  try {
    formData.settings = JSON.parse(settingsJson.value)
  } catch (error) {
    ElMessage.error('设置格式不正确，请输入有效的JSON')
    return false
  }
  return true
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid: boolean) => {
    if (valid) {
      if (!handleSettingsJson()) return
      
      loading.value = true
      try {
        if (props.organization) {
          await updateOrganization(props.organization.id, formData)
          ElMessage.success('更新成功')
        } else {
          await createOrganization(formData)
          ElMessage.success('创建成功')
        }
        emit('success')
        handleClose()
      } catch (error) {
        ElMessage.error(props.organization ? '更新失败' : '创建失败')
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
    fetchOrganizationTree()
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
