<template>
  <div class="projects-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>项目管理</h2>
      <p>管理项目、成员和资源配额</p>
    </div>

    <!-- 项目列表 -->
    <el-card class="table-card">
      <DataTable
        :data="projectList"
        :columns="columns"
        :loading="loading"
        :total="total"
        :current-page="currentPage"
        :page-size="pageSize"
        :show-search="true"
        :show-actions="true"
        :show-selection="true"
        :show-batch-delete="true"
        :show-export="true"
        @search="handleSearch"
        @add="handleAdd"
        @edit="handleEdit"
        @view="handleView"
        @delete="handleDelete"
        @batch-delete="handleBatchDelete"
        @export="handleExport"
        @page-change="handlePageChange"
        @sort-change="handleSortChange"
      >
        <!-- 状态列 -->
        <template #status="{ row }">
          <el-tag :type="getStatusType(row.status)">
            {{ getStatusText(row.status) }}
          </el-tag>
        </template>

        <!-- 成员数列 -->
        <template #memberCount="{ row }">
          <el-button type="primary" link @click="handleManageMembers(row)">
            {{ row.memberCount }} 人
          </el-button>
        </template>

        <!-- 模型数列 -->
        <template #modelCount="{ row }">
          <el-button type="primary" link @click="handleViewModels(row)">
            {{ row.modelCount }} 个
          </el-button>
        </template>

        <!-- 资源配额 -->
        <template #quota="{ row }">
          <div class="quota-info">
            <div>CPU: {{ row.quota.usedCpu }}/{{ row.quota.cpu }}</div>
            <div>内存: {{ row.quota.usedMemory }}/{{ row.quota.memory }}GB</div>
            <div>GPU: {{ row.quota.usedGpu }}/{{ row.quota.gpu }}</div>
          </div>
        </template>

        <!-- 操作列 -->
        <template #actions="{ row, index }">
          <el-button type="primary" link @click="handleView(row, index)">
            查看
          </el-button>
          <el-button type="primary" link @click="handleEdit(row, index)">
            编辑
          </el-button>
          <el-button type="primary" link @click="handleManageMembers(row)">
            成员
          </el-button>
          <el-button type="primary" link @click="handleManageQuota(row)">
            配额
          </el-button>
          <el-button 
            type="warning" 
            link 
            @click="handleToggleStatus(row)"
          >
            {{ row.status === 'active' ? '归档' : '激活' }}
          </el-button>
          <el-button type="danger" link @click="handleDelete(row, index)">
            删除
          </el-button>
        </template>
      </DataTable>
    </el-card>

    <!-- 项目详情对话框 -->
    <el-dialog
      v-model="detailVisible"
      :title="dialogTitle"
      width="800px"
      :close-on-click-modal="false"
    >
      <el-form
        ref="formRef"
        :model="formData"
        :rules="formRules"
        label-width="100px"
      >
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="项目名称" prop="name">
              <el-input v-model="formData.name" :disabled="isView" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="项目状态" prop="status">
              <el-select v-model="formData.status" :disabled="isView" style="width: 100%">
                <el-option label="活跃" value="active" />
                <el-option label="非活跃" value="inactive" />
                <el-option label="已归档" value="archived" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="项目描述" prop="description">
          <el-input 
            v-model="formData.description" 
            type="textarea" 
            :rows="3"
            :disabled="isView"
          />
        </el-form-item>

        <el-form-item label="项目标签" prop="tags">
          <el-select
            v-model="formData.tags"
            multiple
            filterable
            allow-create
            placeholder="请选择或输入标签"
            :disabled="isView"
            style="width: 100%"
          >
            <el-option label="AI研究" value="ai-research" />
            <el-option label="产品开发" value="product-dev" />
            <el-option label="实验项目" value="experiment" />
            <el-option label="生产环境" value="production" />
          </el-select>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="detailVisible = false">取消</el-button>
        <el-button v-if="!isView" type="primary" @click="handleSubmit">
          确定
        </el-button>
      </template>
    </el-dialog>

    <!-- 成员管理对话框 -->
    <el-dialog
      v-model="membersVisible"
      title="成员管理"
      width="900px"
    >
      <div class="members-header">
        <el-button type="primary" @click="handleAddMember">
          <el-icon><Plus /></el-icon>
          添加成员
        </el-button>
      </div>

      <el-table :data="memberList" style="width: 100%">
        <el-table-column prop="username" label="用户名" />
        <el-table-column prop="email" label="邮箱" />
        <el-table-column prop="role" label="角色" width="120">
          <template #default="{ row }">
            <el-tag :type="getRoleType(row.role)">{{ getRoleText(row.role) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="joinedAt" label="加入时间" width="160" />
        <el-table-column label="操作" width="120">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleEditMember(row)">
              编辑
            </el-button>
            <el-button type="danger" link @click="handleRemoveMember(row)">
              移除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-dialog>

    <!-- 资源配额管理对话框 -->
    <el-dialog
      v-model="quotaVisible"
      title="资源配额管理"
      width="600px"
    >
      <el-form ref="quotaFormRef" :model="quotaData" label-width="120px">
        <el-form-item label="CPU配额">
          <el-input-number 
            v-model="quotaData.cpu" 
            :min="0" 
            :max="1000"
            style="width: 100%"
          />
        </el-form-item>
        
        <el-form-item label="内存配额(GB)">
          <el-input-number 
            v-model="quotaData.memory" 
            :min="0" 
            :max="10000"
            style="width: 100%"
          />
        </el-form-item>
        
        <el-form-item label="GPU配额">
          <el-input-number 
            v-model="quotaData.gpu" 
            :min="0" 
            :max="100"
            style="width: 100%"
          />
        </el-form-item>
        
        <el-form-item label="存储配额(GB)">
          <el-input-number 
            v-model="quotaData.storage" 
            :min="0" 
            :max="100000"
            style="width: 100%"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="quotaVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveQuota">保存</el-button>
      </template>
    </el-dialog>

    <!-- 添加成员对话框 -->
    <el-dialog
      v-model="addMemberVisible"
      title="添加成员"
      width="500px"
    >
      <el-form ref="addMemberFormRef" :model="addMemberData" label-width="80px">
        <el-form-item label="用户" prop="userId">
          <el-select 
            v-model="addMemberData.userId" 
            filterable 
            remote
            placeholder="搜索用户"
            style="width: 100%"
            @search="handleSearchUser"
          >
            <el-option
              v-for="user in userOptions"
              :key="user.id"
              :label="user.username"
              :value="user.id"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item label="角色" prop="role">
          <el-select v-model="addMemberData.role" style="width: 100%">
            <el-option label="所有者" value="owner" />
            <el-option label="管理员" value="admin" />
            <el-option label="开发者" value="developer" />
            <el-option label="查看者" value="viewer" />
          </el-select>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="addMemberVisible = false">取消</el-button>
        <el-button type="primary" @click="handleAddMemberSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import DataTable from '@/components/DataTable/index.vue'
import { 
  getProjectList, 
  createProject, 
  updateProject, 
  deleteProject,
  getProjectMembers,
  addProjectMember,
  updateProjectMember,
  removeProjectMember,
  updateProjectQuota
} from '@/api/project'
import { formatDate } from '@/utils'
import type { Project, ProjectForm, ProjectMember, ProjectQuota, TableColumn } from '@/types'

// 响应式数据
const loading = ref(false)
const projectList = ref<Project[]>([])
const total = ref(0)
const currentPage = ref(1)
const pageSize = ref(10)
const searchKeyword = ref('')

// 对话框状态
const detailVisible = ref(false)
const membersVisible = ref(false)
const quotaVisible = ref(false)
const addMemberVisible = ref(false)
const isView = ref(false)
const dialogTitle = ref('')

// 当前项目
const currentProject = ref<Project | null>(null)

// 表单数据
const formData = reactive<ProjectForm>({
  name: '',
  description: '',
  tags: []
})

const quotaData = reactive<ProjectQuota>({
  cpu: 0,
  memory: 0,
  gpu: 0,
  storage: 0,
  usedCpu: 0,
  usedMemory: 0,
  usedGpu: 0,
  usedStorage: 0
})

const addMemberData = reactive({
  userId: 0,
  role: 'developer'
})

// 成员列表
const memberList = ref<ProjectMember[]>([])
const userOptions = ref<Array<{ id: number; username: string }>>([])

// 表格列配置
const columns: TableColumn[] = [
  { prop: 'id', label: 'ID', width: 80 },
  { prop: 'name', label: '项目名称', minWidth: 150 },
  { prop: 'description', label: '描述', minWidth: 200 },
  { prop: 'status', label: '状态', width: 100 },
  { prop: 'ownerName', label: '负责人', width: 120 },
  { prop: 'memberCount', label: '成员数', width: 100 },
  { prop: 'modelCount', label: '模型数', width: 100 },
  { prop: 'quota', label: '资源配额', width: 200 },
  { prop: 'createdAt', label: '创建时间', width: 160 }
]

// 表单验证规则
const formRules = {
  name: [
    { required: true, message: '请输入项目名称', trigger: 'blur' },
    { min: 2, max: 50, message: '项目名称长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  description: [
    { required: true, message: '请输入项目描述', trigger: 'blur' }
  ]
}

// 获取项目列表
const fetchProjectList = async () => {
  loading.value = true
  try {
    const response = await getProjectList({
      page: currentPage.value,
      pageSize: pageSize.value,
      search: searchKeyword.value
    })
    projectList.value = response.items
    total.value = response.pagination.total
  } catch (error) {
    ElMessage.error('获取项目列表失败')
  } finally {
    loading.value = false
  }
}

// 搜索处理
const handleSearch = (keyword: string) => {
  searchKeyword.value = keyword
  currentPage.value = 1
  fetchProjectList()
}

// 分页处理
const handlePageChange = (page: number, size: number) => {
  currentPage.value = page
  pageSize.value = size
  fetchProjectList()
}

// 排序处理
const handleSortChange = (sortBy: string, sortOrder: string) => {
  console.log('排序:', sortBy, sortOrder)
}

// 新增项目
const handleAdd = () => {
  isView.value = false
  dialogTitle.value = '新增项目'
  Object.assign(formData, {
    name: '',
    description: '',
    tags: []
  })
  detailVisible.value = true
}

// 编辑项目
const handleEdit = (row: Project, index: number) => {
  isView.value = false
  dialogTitle.value = '编辑项目'
  Object.assign(formData, {
    name: row.name,
    description: row.description,
    tags: row.tags
  })
  detailVisible.value = true
}

// 查看项目
const handleView = (row: Project, index: number) => {
  isView.value = true
  dialogTitle.value = '项目详情'
  Object.assign(formData, {
    name: row.name,
    description: row.description,
    tags: row.tags
  })
  detailVisible.value = true
}

// 删除项目
const handleDelete = async (row: Project, index: number) => {
  try {
    await ElMessageBox.confirm('确定要删除该项目吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await deleteProject(row.id)
    ElMessage.success('删除成功')
    fetchProjectList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 批量删除
const handleBatchDelete = async (rows: Project[]) => {
  try {
    await ElMessageBox.confirm(`确定要删除选中的 ${rows.length} 个项目吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    // 实现批量删除逻辑
    ElMessage.success('批量删除成功')
    fetchProjectList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('批量删除失败')
    }
  }
}

// 导出项目
const handleExport = () => {
  ElMessage.info('导出功能开发中')
}

// 切换项目状态
const handleToggleStatus = async (row: Project) => {
  const newStatus = row.status === 'active' ? 'archived' : 'active'
  const action = newStatus === 'active' ? '激活' : '归档'
  
  try {
    await ElMessageBox.confirm(`确定要${action}该项目吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await updateProject(row.id, { status: newStatus })
    ElMessage.success(`${action}成功`)
    fetchProjectList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(`${action}失败`)
    }
  }
}

// 管理成员
const handleManageMembers = async (row: Project) => {
  currentProject.value = row
  try {
    const response = await getProjectMembers(row.id)
    memberList.value = response
    membersVisible.value = true
  } catch (error) {
    ElMessage.error('获取成员列表失败')
  }
}

// 查看模型
const handleViewModels = (row: Project) => {
  ElMessage.info('跳转到模型管理页面')
}

// 管理配额
const handleManageQuota = (row: Project) => {
  currentProject.value = row
  Object.assign(quotaData, row.quota)
  quotaVisible.value = true
}

// 添加成员
const handleAddMember = () => {
  addMemberData.userId = 0
  addMemberData.role = 'developer'
  addMemberVisible.value = true
}

// 搜索用户
const handleSearchUser = (query: string) => {
  // 实现用户搜索逻辑
  console.log('搜索用户:', query)
}

// 编辑成员
const handleEditMember = (row: ProjectMember) => {
  ElMessage.info('编辑成员功能开发中')
}

// 移除成员
const handleRemoveMember = async (row: ProjectMember) => {
  try {
    await ElMessageBox.confirm('确定要移除该成员吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    if (currentProject.value) {
      await removeProjectMember(currentProject.value.id, row.userId)
      ElMessage.success('移除成功')
      handleManageMembers(currentProject.value)
    }
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('移除失败')
    }
  }
}

// 提交表单
const handleSubmit = async () => {
  try {
    if (formData.name && formData.description) {
      if (isView.value) return
      
      // 这里需要根据实际情况判断是新增还是编辑
      await createProject(formData)
      ElMessage.success('操作成功')
      detailVisible.value = false
      fetchProjectList()
    }
  } catch (error) {
    ElMessage.error('操作失败')
  }
}

// 添加成员提交
const handleAddMemberSubmit = async () => {
  try {
    if (currentProject.value && addMemberData.userId) {
      await addProjectMember(currentProject.value.id, addMemberData.userId, addMemberData.role)
      ElMessage.success('添加成员成功')
      addMemberVisible.value = false
      handleManageMembers(currentProject.value)
    }
  } catch (error) {
    ElMessage.error('添加成员失败')
  }
}

// 保存配额
const handleSaveQuota = async () => {
  try {
    if (currentProject.value) {
      await updateProjectQuota(currentProject.value.id, quotaData)
      ElMessage.success('配额更新成功')
      quotaVisible.value = false
      fetchProjectList()
    }
  } catch (error) {
    ElMessage.error('配额更新失败')
  }
}

// 工具函数
const getStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    active: 'success',
    inactive: 'warning',
    archived: 'info'
  }
  return statusMap[status] || 'info'
}

const getStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    active: '活跃',
    inactive: '非活跃',
    archived: '已归档'
  }
  return statusMap[status] || '未知'
}

const getRoleType = (role: string) => {
  const roleMap: Record<string, string> = {
    owner: 'danger',
    admin: 'warning',
    developer: 'primary',
    viewer: 'info'
  }
  return roleMap[role] || 'info'
}

const getRoleText = (role: string) => {
  const roleMap: Record<string, string> = {
    owner: '所有者',
    admin: '管理员',
    developer: '开发者',
    viewer: '查看者'
  }
  return roleMap[role] || '未知'
}

// 初始化
onMounted(() => {
  fetchProjectList()
})
</script>

<style lang="scss" scoped>
.projects-page {
  .page-header {
    margin-bottom: 20px;
    
    h2 {
      margin: 0 0 8px 0;
      color: #333;
    }
    
    p {
      margin: 0;
      color: #666;
      font-size: 14px;
    }
  }
  
  .table-card {
    .el-card__body {
      padding: 0;
    }
  }
  
  .quota-info {
    font-size: 12px;
    line-height: 1.4;
    
    div {
      margin-bottom: 2px;
    }
  }
  
  .members-header {
    margin-bottom: 16px;
  }
}
</style>
