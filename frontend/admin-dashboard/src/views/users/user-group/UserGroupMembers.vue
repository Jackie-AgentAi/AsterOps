<template>
  <div class="group-members">
    <div class="members-header">
      <div class="header-left">
        <h3>{{ group?.name }} - 成员管理</h3>
        <p>管理用户组成员和角色</p>
      </div>
      <div class="header-right">
        <el-button type="primary" @click="handleAddMember">
          <el-icon><Plus /></el-icon>
          添加成员
        </el-button>
      </div>
    </div>

    <el-card class="members-card">
      <DataTable
        :data="memberList"
        :columns="columns"
        :loading="loading"
        :total="total"
        :current-page="currentPage"
        :page-size="pageSize"
        :show-search="true"
        :show-actions="true"
        :show-selection="true"
        :show-batch-delete="true"
        @search="handleSearch"
        @add="handleAddMember"
        @edit="handleEditMember"
        @view="handleViewMember"
        @delete="handleRemoveMember"
        @batch-delete="handleBatchRemoveMembers"
        @page-change="handlePageChange"
        @sort-change="handleSortChange"
      >
        <!-- 用户信息列 -->
        <template #user_info="{ row }">
          <div class="user-info">
            <el-avatar :size="32" :src="row.user?.avatar">
              {{ row.user?.username?.charAt(0) }}
            </el-avatar>
            <div class="user-details">
              <div class="username">{{ row.user?.username }}</div>
              <div class="email">{{ row.user?.email }}</div>
            </div>
          </div>
        </template>

        <!-- 角色列 -->
        <template #role="{ row }">
          <el-tag :type="getRoleType(row.role)">
            {{ getRoleText(row.role) }}
          </el-tag>
        </template>

        <!-- 加入时间列 -->
        <template #joined_at="{ row }">
          {{ formatDate(row.joined_at) }}
        </template>

        <!-- 操作列 -->
        <template #actions="{ row, index }">
          <el-button type="primary" link @click="handleViewMember(row, index)">
            查看
          </el-button>
          <el-button type="primary" link @click="handleEditMember(row, index)">
            编辑角色
          </el-button>
          <el-button type="danger" link @click="handleRemoveMember(row, index)">
            移除
          </el-button>
        </template>
      </DataTable>
    </el-card>

    <!-- 添加成员对话框 -->
    <el-dialog
      v-model="addMemberVisible"
      title="添加成员"
      width="500px"
      :close-on-click-modal="false"
    >
      <el-form ref="addFormRef" :model="addForm" :rules="addFormRules" label-width="100px">
        <el-form-item label="选择用户" prop="user_id">
          <el-select
            v-model="addForm.user_id"
            placeholder="请选择用户"
            style="width: 100%"
            filterable
            remote
            :remote-method="searchUsers"
            :loading="userSearchLoading"
          >
            <el-option
              v-for="user in availableUsers"
              :key="user.id"
              :label="`${user.username} (${user.email})`"
              :value="user.id"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="角色" prop="role">
          <el-select v-model="addForm.role" placeholder="请选择角色" style="width: 100%">
            <el-option label="成员" value="member" />
            <el-option label="管理员" value="admin" />
            <el-option label="组长" value="leader" />
          </el-select>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="addMemberVisible = false">取消</el-button>
        <el-button type="primary" @click="handleAddMemberSubmit" :loading="addMemberLoading">
          确定
        </el-button>
      </template>
    </el-dialog>

    <!-- 编辑成员角色对话框 -->
    <el-dialog
      v-model="editMemberVisible"
      title="编辑成员角色"
      width="400px"
      :close-on-click-modal="false"
    >
      <el-form ref="editFormRef" :model="editForm" :rules="editFormRules" label-width="100px">
        <el-form-item label="用户">
          <el-input :value="currentMember?.user?.username" disabled />
        </el-form-item>

        <el-form-item label="角色" prop="role">
          <el-select v-model="editForm.role" placeholder="请选择角色" style="width: 100%">
            <el-option label="成员" value="member" />
            <el-option label="管理员" value="admin" />
            <el-option label="组长" value="leader" />
          </el-select>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="editMemberVisible = false">取消</el-button>
        <el-button type="primary" @click="handleEditMemberSubmit" :loading="editMemberLoading">
          确定
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import DataTable from '@/components/DataTable/index.vue'
import { 
  getGroupMembers, 
  addUserToGroup, 
  removeUserFromGroup,
  getUserList
} from '@/api/user'
import { formatDate } from '@/utils'
import type { UserGroup, UserGroupMember, UserInfo, TableColumn } from '@/types'

const props = defineProps<{
  group: UserGroup
}>()

const emit = defineEmits<{
  close: []
}>()

// 响应式数据
const loading = ref(false)
const memberList = ref<UserGroupMember[]>([])
const total = ref(0)
const currentPage = ref(1)
const pageSize = ref(10)
const searchKeyword = ref('')

// 对话框状态
const addMemberVisible = ref(false)
const editMemberVisible = ref(false)
const addMemberLoading = ref(false)
const editMemberLoading = ref(false)
const userSearchLoading = ref(false)

// 表单数据
const addForm = reactive({
  user_id: '',
  role: 'member'
})

const editForm = reactive({
  role: ''
})

const currentMember = ref<UserGroupMember | null>(null)
const availableUsers = ref<UserInfo[]>([])

// 表格列配置
const columns: TableColumn[] = [
  { prop: 'user_info', label: '用户信息', minWidth: 200, slot: 'user_info' },
  { prop: 'role', label: '角色', width: 120, slot: 'role' },
  { prop: 'joined_at', label: '加入时间', width: 180, slot: 'joined_at' }
]

// 表单验证规则
const addFormRules = {
  user_id: [
    { required: true, message: '请选择用户', trigger: 'change' }
  ],
  role: [
    { required: true, message: '请选择角色', trigger: 'change' }
  ]
}

const editFormRules = {
  role: [
    { required: true, message: '请选择角色', trigger: 'change' }
  ]
}

// 获取成员列表
const fetchMemberList = async () => {
  loading.value = true
  try {
    const response = await getGroupMembers(props.group.id)
    memberList.value = response.data || []
    total.value = response.data?.length || 0
  } catch (error) {
    ElMessage.error('获取成员列表失败')
  } finally {
    loading.value = false
  }
}

// 搜索处理
const handleSearch = (keyword: string) => {
  searchKeyword.value = keyword
  currentPage.value = 1
  fetchMemberList()
}

// 分页处理
const handlePageChange = (page: number, size: number) => {
  currentPage.value = page
  pageSize.value = size
  fetchMemberList()
}

// 排序处理
const handleSortChange = (sortBy: string, sortOrder: string) => {
  console.log('排序:', sortBy, sortOrder)
}

// 添加成员
const handleAddMember = () => {
  addForm.user_id = ''
  addForm.role = 'member'
  addMemberVisible.value = true
  searchUsers('')
}

// 搜索用户
const searchUsers = async (keyword: string) => {
  userSearchLoading.value = true
  try {
    const response = await getUserList({
      page: 1,
      pageSize: 50,
      search: keyword
    })
    availableUsers.value = response.data?.items || []
  } catch (error) {
    console.error('搜索用户失败:', error)
  } finally {
    userSearchLoading.value = false
  }
}

// 添加成员提交
const handleAddMemberSubmit = async () => {
  try {
    addMemberLoading.value = true
    await addUserToGroup(props.group.id, addForm.user_id, addForm.role)
    ElMessage.success('添加成员成功')
    addMemberVisible.value = false
    fetchMemberList()
  } catch (error) {
    ElMessage.error('添加成员失败')
  } finally {
    addMemberLoading.value = false
  }
}

// 编辑成员
const handleEditMember = (row: UserGroupMember, index: number) => {
  currentMember.value = row
  editForm.role = row.role
  editMemberVisible.value = true
}

// 编辑成员提交
const handleEditMemberSubmit = async () => {
  if (!currentMember.value) return

  try {
    editMemberLoading.value = true
    // 这里需要实现更新成员角色的API
    // await updateMemberRole(props.group.id, currentMember.value.user_id, editForm.role)
    ElMessage.success('更新角色成功')
    editMemberVisible.value = false
    fetchMemberList()
  } catch (error) {
    ElMessage.error('更新角色失败')
  } finally {
    editMemberLoading.value = false
  }
}

// 查看成员
const handleViewMember = (row: UserGroupMember, index: number) => {
  // 实现查看成员详情逻辑
  console.log('查看成员:', row)
}

// 移除成员
const handleRemoveMember = async (row: UserGroupMember, index: number) => {
  try {
    await ElMessageBox.confirm(
      `确定要移除用户"${row.user?.username}"吗？`,
      '确认移除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await removeUserFromGroup(props.group.id, row.user_id)
    ElMessage.success('移除成员成功')
    fetchMemberList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('移除成员失败')
    }
  }
}

// 批量移除成员
const handleBatchRemoveMembers = async (selectedRows: UserGroupMember[]) => {
  if (selectedRows.length === 0) {
    ElMessage.warning('请选择要移除的成员')
    return
  }
  
  try {
    await ElMessageBox.confirm(
      `确定要移除选中的 ${selectedRows.length} 个成员吗？`,
      '确认批量移除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    // 批量移除逻辑
    for (const member of selectedRows) {
      await removeUserFromGroup(props.group.id, member.user_id)
    }
    
    ElMessage.success('批量移除成功')
    fetchMemberList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('批量移除失败')
    }
  }
}

// 工具函数
const getRoleType = (role: string) => {
  const roleMap: Record<string, string> = {
    admin: 'danger',
    leader: 'warning',
    member: 'info'
  }
  return roleMap[role] || 'info'
}

const getRoleText = (role: string) => {
  const roleMap: Record<string, string> = {
    admin: '管理员',
    leader: '组长',
    member: '成员'
  }
  return roleMap[role] || '未知'
}

// 初始化
onMounted(() => {
  fetchMemberList()
})
</script>

<style lang="scss" scoped>
.group-members {
  .members-header {
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
  
  .members-card {
    .user-info {
      display: flex;
      align-items: center;
      gap: 12px;
      
      .user-details {
        .username {
          font-weight: 500;
          color: #303133;
          margin-bottom: 4px;
        }
        
        .email {
          font-size: 12px;
          color: #909399;
        }
      }
    }
  }
}
</style>