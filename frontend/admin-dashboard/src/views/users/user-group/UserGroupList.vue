<template>
  <div class="user-group-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>用户组</h2>
    </div>

    <!-- 操作栏 -->
    <div class="action-bar">
      <div class="action-left">
        <!-- 创建按钮 -->
        <el-button type="success" @click="handleAdd" class="action-btn">
          <el-icon><Plus /></el-icon>
          创建
        </el-button>
        
        <!-- 更多操作下拉菜单 -->
        <el-dropdown @command="handleMoreActions" class="action-btn">
          <el-button>
            更多操作<el-icon><ArrowDown /></el-icon>
          </el-button>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="import">导入用户组</el-dropdown-item>
              <el-dropdown-item command="export">导出用户组</el-dropdown-item>
              <el-dropdown-item command="batchDelete">批量删除</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
      
      <div class="action-right">
        <!-- 搜索框 -->
        <el-input
          v-model="searchKeyword"
          placeholder="搜索"
          class="search-input"
          @input="handleSearchInput"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        
        <!-- 功能按钮组 -->
        <el-button circle @click="handleRefresh" class="function-btn">
          <el-icon><Refresh /></el-icon>
        </el-button>
        <el-button circle @click="handleSettings" class="function-btn">
          <el-icon><Setting /></el-icon>
        </el-button>
        <el-button circle @click="handleExport" class="function-btn">
          <el-icon><Download /></el-icon>
        </el-button>
        <el-button circle @click="handleImport" class="function-btn">
          <el-icon><Upload /></el-icon>
        </el-button>
      </div>
    </div>

    <!-- 数据表格 -->
    <el-card class="table-card">
      <el-table
        :data="groupList"
        :loading="loading"
        @selection-change="handleSelectionChange"
        style="width: 100%"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column prop="name" label="名称" sortable>
          <template #default="{ row }">
            <el-link type="primary" @click="handleView(row)">
              {{ row.name }}
            </el-link>
          </template>
        </el-table-column>
        <el-table-column prop="member_count" label="用户" width="200">
          <template #default="{ row }">
            <div class="user-list">
              <span v-if="row.member_count === 0" class="no-users">暂无用户</span>
              <div v-else class="user-count">
                <el-tag size="small" type="info">{{ row.member_count }} 个用户</el-tag>
                <el-button 
                  type="primary" 
                  size="small" 
                  link 
                  @click="handleViewMembers(row)"
                  style="margin-left: 8px;"
                >
                  查看成员
                </el-button>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="备注" />
        <el-table-column label="操作" width="200">
          <template #default="{ row }">
            <div class="action-buttons">
              <el-button type="success" size="small" @click="handleEdit(row)">
                更新
              </el-button>
              <el-dropdown @command="(command) => handleRowAction(command, row)">
                <el-button size="small">
                  更多<el-icon><ArrowDown /></el-icon>
                </el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item command="view">查看详情</el-dropdown-item>
                    <el-dropdown-item command="members">管理成员</el-dropdown-item>
                    <el-dropdown-item 
                      command="delete" 
                      divided
                      v-if="!isAdminGroup(row)"
                    >
                      删除
                    </el-dropdown-item>
                    <el-dropdown-item 
                      v-if="isAdminGroup(row)"
                      disabled
                      style="color: #999;"
                    >
                      admin组不可删除
                    </el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </div>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination-container">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 用户组详情对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="600px"
      :before-close="handleClose"
    >
      <el-form
        :model="formData"
        :rules="formRules"
        ref="formRef"
        label-width="100px"
        v-loading="loading"
      >
        <el-form-item label="用户组名称" prop="name">
          <el-input v-model="formData.name" :disabled="isView"></el-input>
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input 
            v-model="formData.description" 
            type="textarea" 
            :rows="3"
            :disabled="isView"
          ></el-input>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="handleClose">取消</el-button>
        <el-button v-if="!isView" type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { getUserGroups, deleteUserGroup, createUserGroup, updateUserGroup } from '@/api/user'
import type { UserGroup } from '@/types'

const emit = defineEmits<{
  add: []
  edit: [group: UserGroup]
  view: [group: UserGroup]
  delete: [group: UserGroup]
  manageMembers: [group: UserGroup]
}>()

// 响应式数据
const loading = ref(false)
const groupList = ref<UserGroup[]>([])
const total = ref(0)
const currentPage = ref(1)
const pageSize = ref(10)
const searchKeyword = ref('')

// 对话框相关
const dialogVisible = ref(false)
const dialogTitle = ref('')
const isView = ref(false)
const submitLoading = ref(false)
const formRef = ref()
const editingGroup = ref<UserGroup | null>(null)

// 表单数据
const formData = reactive({
  name: '',
  description: ''
})

// 表单验证规则
const formRules = {
  name: [
    { required: true, message: '请输入用户组名称', trigger: 'blur' },
    { min: 2, max: 50, message: '用户组名称长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  description: [
    { max: 200, message: '描述不能超过 200 个字符', trigger: 'blur' }
  ]
}

// 获取用户组列表
const fetchGroupList = async () => {
  loading.value = true
  try {
    // 将page和pageSize转换为offset和limit
    const offset = (currentPage.value - 1) * pageSize.value
    const limit = pageSize.value
    
    const response = await getUserGroups({
      offset,
      limit,
      search: searchKeyword.value
    })
    
    if (response && response.data) {
      // 用户组API返回的是 response.data.groups
      groupList.value = response.data.groups || []
      total.value = response.data.total || 0
    } else if (response && response.items) {
      groupList.value = response.items || []
      total.value = response.pagination?.total || 0
    } else {
      groupList.value = []
      total.value = 0
    }
    console.log('用户组数据加载完成:', groupList.value)
  } catch (error) {
    console.error('获取用户组列表失败:', error)
    ElMessage.error('获取用户组列表失败')
    groupList.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

// 搜索输入处理
const handleSearchInput = () => {
  currentPage.value = 1
  fetchGroupList()
}

// 分页大小变化处理
const handleSizeChange = (size: number) => {
  pageSize.value = size
  currentPage.value = 1
  fetchGroupList()
}

// 当前页变化处理
const handleCurrentChange = (page: number) => {
  currentPage.value = page
  fetchGroupList()
}

// 新增用户组
const handleAdd = () => {
  dialogTitle.value = '新增用户组'
  isView.value = false
  Object.assign(formData, {
    name: '',
    description: ''
  })
  dialogVisible.value = true
}

// 编辑用户组
const handleEdit = (row: UserGroup, index: number) => {
  dialogTitle.value = '编辑用户组'
  isView.value = false
  editingGroup.value = row
  Object.assign(formData, {
    name: row.name,
    description: row.description || ''
  })
  dialogVisible.value = true
}

// 查看用户组
const handleView = (row: UserGroup, index: number) => {
  dialogTitle.value = '查看用户组'
  isView.value = true
  Object.assign(formData, {
    name: row.name,
    description: row.description || ''
  })
  dialogVisible.value = true
}

// 查看成员
const handleViewMembers = (row: UserGroup) => {
  // 跳转到成员管理页面
  window.open(`/user-groups/${row.id}/members`, '_blank')
}

// 管理成员
const handleManageMembers = (row: UserGroup) => {
  // 跳转到成员管理页面
  window.open(`/user-groups/${row.id}/members`, '_blank')
}

// 检查是否为admin组
const isAdminGroup = (row: UserGroup) => {
  // admin组ID: 00000000-0000-0000-0000-000000000002
  // 或者通过名称判断（双重保护）
  return row.id === '00000000-0000-0000-0000-000000000002' || 
         row.name === '管理员组' || 
         row.name === 'admin'
}

// 删除用户组
const handleDelete = async (row: UserGroup) => {
  // 检查是否为admin组
  if (isAdminGroup(row)) {
    ElMessage.warning('admin组不能被删除')
    return
  }
  
  try {
    await ElMessageBox.confirm(
      `确定要删除用户组"${row.name}"吗？删除后不可恢复。`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await deleteUserGroup(row.id)
    ElMessage.success('删除成功')
    fetchGroupList()
    emit('delete', row)
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 批量删除用户组
const handleBatchDelete = async (selectedRows?: UserGroup[]) => {
  const rowsToDelete = selectedRows || []
  if (rowsToDelete.length === 0) {
    ElMessage.warning('请选择要删除的用户组')
    return
  }
  
  // 检查是否包含admin组
  const adminGroups = rowsToDelete.filter(group => isAdminGroup(group))
  if (adminGroups.length > 0) {
    ElMessage.warning('选中的用户组中包含admin组，admin组不能被删除')
    return
  }
  
  try {
    await ElMessageBox.confirm(
      `确定要删除选中的 ${rowsToDelete.length} 个用户组吗？删除后不可恢复。`,
      '确认批量删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    // 批量删除逻辑
    for (const group of rowsToDelete) {
      await deleteUserGroup(group.id)
    }
    
    ElMessage.success('批量删除成功')
    fetchGroupList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('批量删除失败')
    }
  }
}

// 工具函数
const getStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    active: 'success',
    inactive: 'danger'
  }
  return statusMap[status] || 'info'
}

const getStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    active: '活跃',
    inactive: '禁用'
  }
  return statusMap[status] || '未知'
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
    submitLoading.value = true
    
    let response
    if (editingGroup.value) {
      // 更新用户组
      response = await updateUserGroup(editingGroup.value.id, {
        name: formData.name,
        description: formData.description
      })
    } else {
      // 创建用户组
      response = await createUserGroup({
        name: formData.name,
        description: formData.description
      })
    }
    
    if (response && response.data) {
      ElMessage.success(editingGroup.value ? '更新成功' : '创建成功')
      dialogVisible.value = false
      fetchGroupList()
    } else {
      ElMessage.error(editingGroup.value ? '更新失败' : '创建失败')
    }
  } catch (error: any) {
    console.error(editingGroup.value ? '更新用户组失败:' : '创建用户组失败:', error)
    ElMessage.error((editingGroup.value ? '更新失败: ' : '创建失败: ') + (error.response?.data?.message || error.message))
  } finally {
    submitLoading.value = false
  }
}

// 关闭对话框
const handleClose = () => {
  dialogVisible.value = false
  editingGroup.value = null
  formRef.value?.resetFields()
}

// 刷新
const handleRefresh = () => {
  fetchGroupList()
}

// 设置
const handleSettings = () => {
  ElMessage.info('设置功能开发中')
}

// 导出
const handleExport = async () => {
  try {
    const response = await getUserGroups({
      page: 1,
      pageSize: 1000,
      search: searchKeyword.value
    })
    
    if (response && response.data) {
      const groups = response.data.groups || response.data.items || []
      const csvContent = generateCSV(groups)
      downloadCSV(csvContent, 'user-groups.csv')
      ElMessage.success('导出成功')
    }
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('导出失败')
  }
}

// 导入
const handleImport = () => {
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = '.csv,.xlsx,.xls'
  input.onchange = async (e) => {
    const file = (e.target as HTMLInputElement).files?.[0]
    if (file) {
      try {
        const formData = new FormData()
        formData.append('file', file)
        
        // 这里需要实现导入API
        ElMessage.info('导入功能开发中')
      } catch (error) {
        console.error('导入失败:', error)
        ElMessage.error('导入失败')
      }
    }
  }
  input.click()
}

// 生成CSV内容
const generateCSV = (groups: UserGroup[]) => {
  const headers = ['名称', '描述', '成员数量', '创建时间']
  const rows = groups.map(group => [
    group.name,
    group.description || '',
    group.member_count || 0,
    group.created_at || ''
  ])
  
  const csvContent = [headers, ...rows]
    .map(row => row.map(field => `"${field}"`).join(','))
    .join('\n')
  
  return csvContent
}

// 下载CSV文件
const downloadCSV = (content: string, filename: string) => {
  const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  link.setAttribute('href', url)
  link.setAttribute('download', filename)
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}

// 更多操作
const handleMoreActions = (command: string) => {
  switch (command) {
    case 'import':
      handleImport()
      break
    case 'export':
      handleExport()
      break
    case 'batchDelete':
      handleBatchDelete(selectedGroups.value)
      break
    default:
      console.log('未知操作:', command)
  }
}

// 行操作处理
const handleRowAction = (command: string, row: UserGroup) => {
  switch (command) {
    case 'view':
      handleView(row)
      break
    case 'members':
      handleManageMembers(row)
      break
    case 'delete':
      handleDelete(row)
      break
    default:
      console.log('未知行操作:', command)
  }
}

// 选中的用户组
const selectedGroups = ref<UserGroup[]>([])

// 选择变化处理
const handleSelectionChange = (selection: UserGroup[]) => {
  selectedGroups.value = selection
  console.log('选择变化:', selection)
}

// 初始化
onMounted(() => {
  fetchGroupList()
})
</script>

<style lang="scss" scoped>
.user-group-list {
  .list-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    
    .header-left {
      h3 {
        margin: 0 0 4px 0;
        color: #303133;
      }
      
      p {
        margin: 0;
        color: #909399;
        font-size: 14px;
      }
    }
  }
  
  .table-card {
    margin-top: 20px;
  }

  .action-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
    margin-bottom: 20px;
    padding: 8px 0;
    width: 100%;
    flex-wrap: nowrap;

    .action-left {
      display: flex;
      align-items: center;
      gap: 12px;
      flex-shrink: 0;
    }

    .action-right {
      display: flex;
      align-items: center;
      gap: 8px;
      flex-shrink: 0;
    }

    // 操作按钮样式
    .action-btn {
      flex-shrink: 0;
      height: 36px;
      min-width: 80px;
      
      .el-button {
        height: 36px;
        line-height: 1;
        border-radius: 6px;
        font-weight: 500;
      }
    }

    // 搜索框样式 - 固定宽度
    .search-input {
      width: 200px;
      height: 36px;
      flex-shrink: 0;

      :deep(.el-input__wrapper) {
        height: 36px;
        border-radius: 6px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        transition: all 0.3s ease;

        &:hover {
          box-shadow: 0 2px 6px rgba(0, 0, 0, 0.15);
        }

        &.is-focus {
          box-shadow: 0 0 0 2px rgba(64, 158, 255, 0.2);
        }
      }

      :deep(.el-input__inner) {
        height: 36px;
        line-height: 36px;
        font-size: 14px;
      }
    }

    // 功能按钮样式
    .function-btn {
      height: 36px;
      width: 36px;
      border-radius: 6px;
      border: 1px solid #dcdfe6;
      background: #fff;
      color: #606266;
      transition: all 0.3s ease;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      flex-shrink: 0;

      &:hover {
        color: #409eff;
        border-color: #409eff;
        box-shadow: 0 2px 6px rgba(64, 158, 255, 0.2);
        transform: translateY(-1px);
      }

      &:active {
        transform: translateY(0);
      }

      .el-icon {
        font-size: 16px;
      }
    }

    // 响应式设计
    @media (max-width: 768px) {
      flex-wrap: wrap;
      gap: 8px;
      
      .search-input {
        width: 150px;
      }
      
      .function-btn {
        height: 32px;
        width: 32px;
      }
    }
  }

  .user-list {
    .no-users {
      color: #909399;
      font-size: 12px;
    }

    .user-count {
      display: flex;
      align-items: center;
    }
  }

  .action-buttons {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-wrap: nowrap;
  }
}
</style>
