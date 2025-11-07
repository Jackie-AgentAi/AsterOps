<template>
  <div class="audit-log-list">
    <!-- 搜索筛选 -->
    <div class="search-section">
      <el-form :model="searchForm" inline>
        <el-form-item label="用户">
          <el-select v-model="searchForm.user_id" placeholder="请选择用户" clearable>
            <el-option
              v-for="user in userOptions"
              :key="user.id"
              :label="user.username"
              :value="user.id"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item label="操作类型">
          <el-select v-model="searchForm.action" placeholder="请选择操作类型" clearable>
            <el-option label="登录" value="login" />
            <el-option label="登出" value="logout" />
            <el-option label="创建用户" value="create_user" />
            <el-option label="更新用户" value="update_user" />
            <el-option label="删除用户" value="delete_user" />
            <el-option label="重置密码" value="reset_password" />
            <el-option label="分配角色" value="assign_role" />
            <el-option label="其他" value="other" />
          </el-select>
        </el-form-item>
        
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="searchForm.dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            format="YYYY-MM-DD HH:mm:ss"
            value-format="YYYY-MM-DD HH:mm:ss"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button type="primary" @click="handleSearch">
            <el-icon><Search /></el-icon>
            搜索
          </el-button>
          <el-button @click="handleReset">
            <el-icon><Refresh /></el-icon>
            重置
          </el-button>
        </el-form-item>
      </el-form>
    </div>
    
    <!-- 审计日志列表 -->
    <el-card>
      <el-table
        :data="auditLogs"
        :loading="loading"
        style="width: 100%"
        max-height="600"
      >
        <el-table-column prop="user_id" label="用户ID" width="120" />
        <el-table-column prop="action" label="操作类型" width="120">
          <template #default="{ row }">
            <el-tag :type="getActionType(row.action)">
              {{ getActionText(row.action) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="resource_type" label="资源类型" width="120" />
        <el-table-column prop="resource_id" label="资源ID" width="120" />
        <el-table-column prop="details" label="详细信息" min-width="200">
          <template #default="{ row }">
            <el-button type="primary" link @click="showDetails(row)">
              查看详情
            </el-button>
          </template>
        </el-table-column>
        <el-table-column prop="ip_address" label="IP地址" width="140" />
        <el-table-column prop="created_at" label="操作时间" width="180">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>
      </el-table>
      
      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :total="total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>
    
    <!-- 详情对话框 -->
    <el-dialog
      v-model="detailVisible"
      title="审计日志详情"
      width="600px"
    >
      <div class="detail-content">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="用户ID">
            {{ selectedLog?.user_id }}
          </el-descriptions-item>
          <el-descriptions-item label="操作类型">
            <el-tag :type="getActionType(selectedLog?.action)">
              {{ getActionText(selectedLog?.action) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="资源类型">
            {{ selectedLog?.resource_type || '无' }}
          </el-descriptions-item>
          <el-descriptions-item label="资源ID">
            {{ selectedLog?.resource_id || '无' }}
          </el-descriptions-item>
          <el-descriptions-item label="IP地址">
            {{ selectedLog?.ip_address }}
          </el-descriptions-item>
          <el-descriptions-item label="操作时间">
            {{ formatDate(selectedLog?.created_at) }}
          </el-descriptions-item>
          <el-descriptions-item label="详细信息" :span="2">
            <pre class="details-json">{{ JSON.stringify(selectedLog?.details, null, 2) }}</pre>
          </el-descriptions-item>
        </el-descriptions>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Search, Refresh } from '@element-plus/icons-vue'
import { getAuditLogs, getUserList } from '@/api/user'
import { formatDate } from '@/utils'
import type { AuditLog, UserInfo } from '@/types'

const loading = ref(false)
const auditLogs = ref<AuditLog[]>([])
const total = ref(0)
const currentPage = ref(1)
const pageSize = ref(20)
const userOptions = ref<UserInfo[]>([])

// 搜索表单
const searchForm = reactive({
  user_id: '',
  action: '',
  dateRange: []
})

// 详情对话框
const detailVisible = ref(false)
const selectedLog = ref<AuditLog | null>(null)

// 获取审计日志列表
const fetchAuditLogs = async () => {
  loading.value = true
  try {
    const params: any = {
      page: currentPage.value,
      pageSize: pageSize.value
    }
    
    if (searchForm.user_id) {
      params.user_id = searchForm.user_id
    }
    
    if (searchForm.action) {
      params.action = searchForm.action
    }
    
    if (searchForm.dateRange && searchForm.dateRange.length === 2) {
      params.start_time = searchForm.dateRange[0]
      params.end_time = searchForm.dateRange[1]
    }
    
    const response = await getAuditLogs(params)
    auditLogs.value = response.items || []
    total.value = response.pagination?.total || 0
  } catch (error) {
    ElMessage.error('获取审计日志失败')
  } finally {
    loading.value = false
  }
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

// 搜索
const handleSearch = () => {
  currentPage.value = 1
  fetchAuditLogs()
}

// 重置
const handleReset = () => {
  Object.assign(searchForm, {
    user_id: '',
    action: '',
    dateRange: []
  })
  currentPage.value = 1
  fetchAuditLogs()
}

// 分页处理
const handleSizeChange = (size: number) => {
  pageSize.value = size
  currentPage.value = 1
  fetchAuditLogs()
}

const handleCurrentChange = (page: number) => {
  currentPage.value = page
  fetchAuditLogs()
}

// 显示详情
const showDetails = (log: AuditLog) => {
  selectedLog.value = log
  detailVisible.value = true
}

// 获取操作类型
const getActionType = (action: string) => {
  const actionMap: Record<string, string> = {
    login: 'success',
    logout: 'info',
    create_user: 'primary',
    update_user: 'warning',
    delete_user: 'danger',
    reset_password: 'warning',
    assign_role: 'primary',
    other: 'info'
  }
  return actionMap[action] || 'info'
}

// 获取操作文本
const getActionText = (action: string) => {
  const actionMap: Record<string, string> = {
    login: '登录',
    logout: '登出',
    create_user: '创建用户',
    update_user: '更新用户',
    delete_user: '删除用户',
    reset_password: '重置密码',
    assign_role: '分配角色',
    other: '其他'
  }
  return actionMap[action] || action
}

// 初始化
onMounted(() => {
  fetchAuditLogs()
  fetchUsers()
})
</script>

<style lang="scss" scoped>
.audit-log-list {
  .search-section {
    margin-bottom: 20px;
    padding: 16px;
    background: #f5f7fa;
    border-radius: 4px;
  }
  
  .pagination {
    margin-top: 16px;
    text-align: right;
  }
  
  .detail-content {
    .details-json {
      background: #f5f7fa;
      padding: 12px;
      border-radius: 4px;
      font-size: 12px;
      line-height: 1.5;
      max-height: 200px;
      overflow-y: auto;
    }
  }
}
</style>
