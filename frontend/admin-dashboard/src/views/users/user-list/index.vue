<template>
  <div class="user-list-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>用户列表</h2>
    </div>

    <!-- 操作栏 -->
    <div class="action-bar">
      <div class="action-left">
        <el-button type="success" @click="handleAdd">
          <el-icon><Plus /></el-icon>
          创建
        </el-button>
        <el-dropdown @command="handleMoreActions">
          <el-button>
            更多操作<el-icon><ArrowDown /></el-icon>
          </el-button>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="import">导入用户</el-dropdown-item>
              <el-dropdown-item command="export">导出用户</el-dropdown-item>
              <el-dropdown-item command="batchDelete">批量删除</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
      <div class="action-right">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索用户"
          class="search-input"
          @input="handleSearch"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        <el-button circle @click="handleRefresh">
          <el-icon><Refresh /></el-icon>
        </el-button>
        <el-button circle @click="handleSettings">
          <el-icon><Setting /></el-icon>
        </el-button>
        <el-button circle @click="handleExport">
          <el-icon><Download /></el-icon>
        </el-button>
        <el-button circle @click="handleImport">
          <el-icon><Upload /></el-icon>
        </el-button>
      </div>
    </div>

    <!-- 用户列表表格 -->
    <el-card class="table-card">
      <el-table
        :data="userList"
        :loading="loading"
        @selection-change="handleSelectionChange"
        style="width: 100%"
      >
        <!-- 选择列 -->
        <el-table-column type="selection" width="55" />
        
        <!-- 名称列 -->
        <el-table-column prop="username" label="名称" sortable>
          <template #default="{ row }">
            <el-link type="primary" @click="handleView(row)">
              {{ row.username }}
            </el-link>
          </template>
        </el-table-column>
        
        <!-- 用户名列 -->
        <el-table-column prop="username" label="用户名" />
        
        <!-- 用户组名列 -->
        <el-table-column prop="groupName" label="用户组名">
          <template #default="{ row }">
            {{ row.groupName || '未分配' }}
          </template>
        </el-table-column>
        
        <!-- 角色列 -->
        <el-table-column prop="role" label="角色">
          <template #default="{ row }">
            <el-tag type="info" size="small">{{ row.role }}</el-tag>
          </template>
        </el-table-column>
        
        <!-- 用户来源列 -->
        <el-table-column prop="source" label="用户来源">
          <template #default="{ row }">
            <el-select v-model="row.source" size="small" style="width: 100px">
              <el-option label="数据库" value="database" />
              <el-option label="LDAP" value="ldap" />
              <el-option label="OAuth" value="oauth" />
            </el-select>
          </template>
        </el-table-column>
        
        <!-- 有效状态列 -->
        <el-table-column prop="status" label="有效" width="80">
          <template #default="{ row }">
            <el-icon v-if="row.status === 'active'" color="#67C23A">
              <Check />
            </el-icon>
            <el-icon v-else color="#F56C6C">
              <Close />
            </el-icon>
          </template>
        </el-table-column>
        
        <!-- 操作列 -->
        <el-table-column label="操作" width="200">
          <template #default="{ row }">
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
                  <el-dropdown-item command="resetPassword">重置密码</el-dropdown-item>
                  <el-dropdown-item command="disable" v-if="row.status === 'active'">禁用</el-dropdown-item>
                  <el-dropdown-item command="enable" v-if="row.status === 'inactive'">启用</el-dropdown-item>
                  <el-dropdown-item 
                    command="delete" 
                    divided
                    v-if="row.username !== 'admin'"
                  >
                    删除
                  </el-dropdown-item>
                  <el-dropdown-item 
                    v-if="row.username === 'admin'"
                    disabled
                    style="color: #999;"
                  >
                    admin用户不可删除
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
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
          @current-change="handlePageChange"
        />
      </div>
    </el-card>

    <!-- 用户详情对话框 -->
    <el-dialog
      v-model="detailVisible"
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
        <el-form-item label="用户名" prop="username">
          <el-input v-model="formData.username" :disabled="isView"></el-input>
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="formData.email" :disabled="isView"></el-input>
        </el-form-item>
        <el-form-item label="密码" prop="password" v-if="!isView">
          <el-input 
            v-model="formData.password" 
            type="password" 
            placeholder="请输入密码"
            show-password
          ></el-input>
        </el-form-item>
        <el-form-item label="角色" prop="role">
          <el-select v-model="formData.role" placeholder="请选择角色" :disabled="isView">
            <el-option label="管理员" value="admin"></el-option>
            <el-option label="开发者" value="developer"></el-option>
            <el-option label="普通用户" value="user"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="formData.status" :disabled="isView">
            <el-radio label="active">启用</el-radio>
            <el-radio label="inactive">禁用</el-radio>
          </el-radio-group>
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
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  Plus, 
  ArrowDown, 
  Search, 
  Refresh, 
  Setting, 
  Download, 
  Upload,
  Check,
  Close
} from '@element-plus/icons-vue'
import { 
  getUserList, 
  createUser, 
  updateUser, 
  deleteUser
} from '@/api/user'
import type { UserInfo, UserForm } from '@/types'

// 路由
const router = useRouter()

// 响应式数据
const loading = ref(false)
const userList = ref<UserInfo[]>([])
const total = ref(0)
const currentPage = ref(1)
const pageSize = ref(10)
const searchKeyword = ref('')
const selectedUsers = ref<UserInfo[]>([])

// 对话框状态
const detailVisible = ref(false)
const isView = ref(false)
const dialogTitle = ref('')

// 表单数据
const formData = reactive<UserForm>({
  username: '',
  email: '',
  password: '',
  role: 'developer',
  status: 'active',
  tenant_id: '00000000-0000-0000-0000-000000000001' // 默认租户ID
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
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度在 6 到 20 个字符', trigger: 'blur' }
  ]
}

// 获取用户列表
const fetchUserList = async () => {
  console.log('开始获取用户列表...')
  loading.value = true
  try {
    const response = await getUserList({
      page: currentPage.value,
      pageSize: pageSize.value,
      search: searchKeyword.value
    })
    
    if (response && response.data) {
      // 用户API返回的是 response.data.users
      const users = response.data.users || []
      // 为每个用户添加默认字段
      userList.value = users.map(user => ({
        ...user,
        role: user.role || 'user', // 默认角色
        groupName: '未分配', // 默认用户组
        source: 'database' // 默认来源
      }))
      total.value = response.data.total || 0
    } else if (response && response.items) {
      userList.value = response.items || []
      total.value = response.pagination?.total || 0
    } else {
      userList.value = []
      total.value = 0
    }
    console.log('用户列表数据加载完成:', userList.value)
  } catch (error) {
    console.error('获取用户列表失败:', error)
    ElMessage.error('获取用户列表失败')
    userList.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

// 搜索处理
const handleSearch = (keyword: string) => {
  searchKeyword.value = keyword
  currentPage.value = 1
  fetchUserList()
}

// 刷新
const handleRefresh = () => {
  console.log('点击了刷新按钮')
  fetchUserList()
}

// 设置
const handleSettings = () => {
  console.log('点击了设置按钮')
  ElMessage.info('设置功能待实现')
}

// 导出
const handleExport = () => {
  console.log('点击了导出按钮')
  ElMessage.info('导出功能待实现')
}

// 导入
const handleImport = () => {
  console.log('点击了导入按钮')
  ElMessage.info('导入功能待实现')
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
      if (selectedUsers.value.length === 0) {
        ElMessage.warning('请先选择要删除的用户')
        return
      }
      ElMessageBox.confirm(`确定删除选中的 ${selectedUsers.value.length} 个用户吗？`, '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async () => {
        try {
          // 检查是否包含admin用户
          const adminUsers = selectedUsers.value.filter(user => user.username === 'admin')
          if (adminUsers.length > 0) {
            ElMessage.warning('选中的用户中包含admin用户，admin用户不能被删除')
            return
          }
          
          // 批量删除用户
          const deletePromises = selectedUsers.value.map(user => deleteUser(user.id))
          await Promise.all(deletePromises)
          ElMessage.success(`成功删除 ${selectedUsers.value.length} 个用户`)
          selectedUsers.value = []
          fetchUserList()
        } catch (error: any) {
          console.error('批量删除失败:', error)
          ElMessage.error('批量删除失败: ' + (error.response?.data?.message || error.message))
        }
      }).catch(() => {
        ElMessage.info('已取消删除')
      })
      break
  }
}

// 选择变化
const handleSelectionChange = (selection: UserInfo[]) => {
  selectedUsers.value = selection
}

// 处理分页变化
const handlePageChange = (page: number) => {
  currentPage.value = page
  fetchUserList()
}

// 处理页面大小变化
const handleSizeChange = (size: number) => {
  pageSize.value = size
  currentPage.value = 1
  fetchUserList()
}

// 处理新增用户
const handleAdd = () => {
  dialogTitle.value = '新增用户'
  isView.value = false
  Object.assign(formData, {
    username: '',
    email: '',
    password: '',
    role: 'developer',
    status: 'active',
    tenant_id: '00000000-0000-0000-0000-000000000001'
  })
  detailVisible.value = true
}

// 处理编辑用户
const handleEdit = (row: UserInfo) => {
  dialogTitle.value = '编辑用户'
  isView.value = false
  Object.assign(formData, row)
  detailVisible.value = true
}

// 处理查看用户
const handleView = (row: UserInfo) => {
  dialogTitle.value = '查看用户'
  isView.value = true
  Object.assign(formData, row)
  detailVisible.value = true
}

// 处理行操作
const handleRowAction = (command: string, row: UserInfo) => {
  switch (command) {
    case 'view':
      handleView(row)
      break
    case 'resetPassword':
      ElMessage.info('重置密码功能待实现')
      break
    case 'disable':
      ElMessage.info('禁用用户功能待实现')
      break
    case 'enable':
      ElMessage.info('启用用户功能待实现')
      break
    case 'delete':
      handleDelete(row)
      break
  }
}

// 处理删除用户
const handleDelete = async (row: UserInfo) => {
  // 检查是否为admin用户
  if (row.username === 'admin') {
    ElMessage.warning('admin用户不能被删除')
    return
  }
  
  ElMessageBox.confirm(`确定删除用户 "${row.username}" 吗？`, '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
    .then(async () => {
      await deleteUser(row.id)
      ElMessage.success('删除成功')
      fetchUserList()
    })
    .catch(() => {
      ElMessage.info('已取消删除')
    })
}

// 提交表单
const formRef = ref()
const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate(async (valid: boolean) => {
    if (valid) {
      try {
        if (formData.id) {
          await updateUser(formData.id, formData)
          ElMessage.success('更新成功')
        } else {
          console.log('创建用户数据:', formData)
          await createUser(formData)
          ElMessage.success('新增成功')
        }
        detailVisible.value = false
        fetchUserList()
      } catch (error: any) {
        console.error('提交失败:', error)
        let errorMessage = '提交失败'
        
        if (error.response?.data?.message) {
          if (error.response.data.message.includes('username already exists')) {
            errorMessage = '用户名已存在，请使用其他用户名'
          } else if (error.response.data.message.includes('email already exists')) {
            errorMessage = '邮箱已存在，请使用其他邮箱'
          } else {
            errorMessage = error.response.data.message
          }
        }
        
        ElMessage.error(errorMessage)
      }
    }
  })
}

// 关闭对话框
const handleClose = () => {
  detailVisible.value = false
  formRef.value.resetFields()
}

// 初始化
onMounted(() => {
  console.log('用户列表页面已挂载')
  try {
    fetchUserList()
  } catch (error) {
    console.error('初始化用户列表失败:', error)
  }
})
</script>

<style lang="scss" scoped>
@import "@/styles/variables.scss";

.user-list-page {
  padding: $spacing-large;

  .page-header {
    margin-bottom: $spacing-large;

    h2 {
      font-size: $font-size-extra-large;
      color: $text-primary;
      margin: 0;
    }
  }

  .action-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: $spacing-large;
    padding: $spacing-base;
    background: #fff;
    border-radius: $border-radius-base;
    box-shadow: $box-shadow-base;

    .action-left {
      display: flex;
      gap: $spacing-extra-small;
    }

    .action-right {
      display: flex;
      align-items: center;
      gap: $spacing-extra-small;

      .search-input {
        width: 200px;
      }
    }
  }

  .table-card {
    .pagination-container {
      display: flex;
      justify-content: center;
      margin-top: $spacing-large;
    }
  }
}
</style>