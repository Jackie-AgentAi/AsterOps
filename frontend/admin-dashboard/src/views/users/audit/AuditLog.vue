<template>
  <div class="audit-log">
    <div class="log-header">
      <div class="header-left">
        <h3>审计日志</h3>
        <p>查看系统操作记录和安全事件</p>
      </div>
      <div class="header-right">
        <el-button @click="handleRefresh">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
        <el-button @click="handleExport">
          <el-icon><Download /></el-icon>
          导出
        </el-button>
      </div>
    </div>
    
    <!-- 筛选条件 -->
    <el-card class="filter-card">
      <el-form :model="filterForm" inline>
        <el-form-item label="用户">
          <el-select v-model="filterForm.user_id" placeholder="选择用户" clearable>
            <el-option
              v-for="user in userOptions"
              :key="user.id"
              :label="user.username"
              :value="user.id"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item label="操作类型">
          <el-select v-model="filterForm.action" placeholder="选择操作类型" clearable>
            <el-option label="登录" value="login" />
            <el-option label="登出" value="logout" />
            <el-option label="创建用户" value="create_user" />
            <el-option label="更新用户" value="update_user" />
            <el-option label="删除用户" value="delete_user" />
            <el-option label="权限变更" value="permission_change" />
            <el-option label="密码重置" value="password_reset" />
          </el-select>
        </el-form-item>
        
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="filterForm.dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            format="YYYY-MM-DD HH:mm:ss"
            value-format="YYYY-MM-DD HH:mm:ss"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button type="primary" @click="handleFilter">
            <el-icon><Search /></el-icon>
            搜索
          </el-button>
          <el-button @click="handleResetFilter">
            <el-icon><Refresh /></el-icon>
            重置
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>
    
    <el-card class="table-card">
      <DataTable
        :data="logList"
        :columns="columns"
        :loading="loading"
        :total="total"
        :current-page="currentPage"
        :page-size="pageSize"
        :show-actions="true"
        @view="handleView"
        @page-change="handlePageChange"
        @sort-change="handleSortChange"
      >
        <!-- 用户列 -->
        <template #user="{ row }">
          <div class="user-info">
            <el-avatar :size="24" :src="row.user?.avatar">
              {{ row.user?.username?.charAt(0).toUpperCase() }}
            </el-avatar>
            <span class="username">{{ row.user?.username || '系统' }}</span>
          </div>
        </template>
        
        <!-- 操作类型列 -->
        <template #action="{ row }">
          <el-tag :type="getActionTagType(row.action)">
            {{ getActionText(row.action) }}
          </el-tag>
        </template>
        
        <!-- 资源信息列 -->
        <template #resource="{ row }">
          <div v-if="row.resource_type" class="resource-info">
            <el-tag size="small">{{ row.resource_type }}</el-tag>
            <span class="resource-id">{{ row.resource_id }}</span>
          </div>
          <span v-else class="no-resource">-</span>
        </template>
        
        <!-- 详细信息列 -->
        <template #details="{ row }">
          <el-button type="primary" link @click="handleViewDetails(row)">
            查看详情
          </el-button>
        </template>
        
        <!-- 操作列 -->
        <template #actions="{ row, index }">
          <el-button type="primary" link @click="handleView(row, index)">
            查看
          </el-button>
        </template>
      </DataTable>
    </el-card>
    
    <!-- 详情对话框 -->
    <el-dialog
      v-model="detailVisible"
      title="审计日志详情"
      width="800px"
      :close-on-click-modal="false"
    >
      <div v-if="selectedLog" class="log-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="日志ID">
            {{ selectedLog.id }}
          </el-descriptions-item>
          <el-descriptions-item label="操作用户">
            {{ selectedLog.user?.username || '系统' }}
          </el-descriptions-item>
          <el-descriptions-item label="操作类型">
            <el-tag :type="getActionTagType(selectedLog.action)">
              {{ getActionText(selectedLog.action) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="资源类型">
            {{ selectedLog.resource_type || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="资源ID">
            {{ selectedLog.resource_id || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="IP地址">
            {{ selectedLog.ip_address || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="用户代理">
            {{ selectedLog.user_agent || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="操作时间">
            {{ formatDate(selectedLog.created_at) }}
          </el-descriptions-item>
        </el-descriptions>
        
        <div v-if="selectedLog.details" class="details-section">
          <h4>详细信息</h4>
          <el-input
            v-model="detailsJson"
            type="textarea"
            :rows="8"
            readonly
          />
        </div>
      </div>
      
      <template #footer>
        <el-button @click="detailVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh, Download, Search } from '@element-plus/icons-vue'
import DataTable from '@/components/DataTable/index.vue'
import { getAuditLogs, getAuditLogById } from '@/api/user'
import { formatDate } from '@/utils'
import type { AuditLog, TableColumn } from '@/types'

// 响应式数据
const loading = ref(false)
const logList = ref<AuditLog[]>([])
const total = ref(0)
const currentPage = ref(1)
const pageSize = ref(10)
const userOptions = ref([])
const detailVisible = ref(false)
const selectedLog = ref<AuditLog | null>(null)
const detailsJson = ref('')

// 筛选表单
const filterForm = reactive({
  user_id: '',
  action: '',
  dateRange: []
})

// 表格列配置
const columns: TableColumn[] = [
  { prop: 'id', label: 'ID', width: 80 },
  { prop: 'user', label: '用户', width: 120, slot: 'user' },
  { prop: 'action', label: '操作类型', width: 120, slot: 'action' },
  { prop: 'resource', label: '资源信息', width: 150, slot: 'resource' },
  { prop: 'ip_address', label: 'IP地址', width: 120 },
  { prop: 'created_at', label: '操作时间', width: 180, sortable: true },
  { prop: 'details', label: '详细信息', width: 100, slot: 'details' }
]

// 获取审计日志列表
const fetchLogList = async () => {
  loading.value = true
  try {
    const params = {
      page: currentPage.value,
      pageSize: pageSize.value,
      user_id: filterForm.user_id,
      action: filterForm.action,
      start_date: filterForm.dateRange[0],
      end_date: filterForm.dateRange[1]
    }
    
    const response = await getAuditLogs(params)
    logList.value = response.items
    total.value = response.pagination.total
  } catch (error) {
    ElMessage.error('获取审计日志失败')
  } finally {
    loading.value = false
  }
}

// 搜索处理
const handleFilter = () => {
  currentPage.value = 1
  fetchLogList()
}

// 重置筛选
const handleResetFilter = () => {
  Object.assign(filterForm, {
    user_id: '',
    action: '',
    dateRange: []
  })
  handleFilter()
}

// 分页处理
const handlePageChange = (page: number, size: number) => {
  currentPage.value = page
  pageSize.value = size
  fetchLogList()
}

// 排序处理
const handleSortChange = (sortBy: string, sortOrder: string) => {
  console.log('排序:', sortBy, sortOrder)
  // 实现排序逻辑
}

// 查看日志
const handleView = (row: AuditLog, index: number) => {
  selectedLog.value = row
  detailsJson.value = row.details ? JSON.stringify(row.details, null, 2) : ''
  detailVisible.value = true
}

// 查看详情
const handleViewDetails = (row: AuditLog) => {
  handleView(row, 0)
}

// 刷新数据
const handleRefresh = () => {
  fetchLogList()
}

// 导出数据
const handleExport = () => {
  ElMessage.info('导出功能开发中...')
}

// 工具函数
const getActionText = (action: string) => {
  const actionMap: Record<string, string> = {
    login: '登录',
    logout: '登出',
    create_user: '创建用户',
    update_user: '更新用户',
    delete_user: '删除用户',
    permission_change: '权限变更',
    password_reset: '密码重置'
  }
  return actionMap[action] || action
}

const getActionTagType = (action: string) => {
  const typeMap: Record<string, string> = {
    login: 'success',
    logout: 'info',
    create_user: 'primary',
    update_user: 'warning',
    delete_user: 'danger',
    permission_change: 'warning',
    password_reset: 'danger'
  }
  return typeMap[action] || 'info'
}

// 初始化
onMounted(() => {
  fetchLogList()
})
</script>

<style lang="scss" scoped>
.audit-log {
  .log-header {
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
    
    .header-right {
      .el-button {
        margin-left: 8px;
      }
    }
  }
  
  .filter-card {
    margin-bottom: 20px;
  }
  
  .table-card {
    .user-info {
      display: flex;
      align-items: center;
      
      .username {
        margin-left: 8px;
        font-size: 14px;
      }
    }
    
    .resource-info {
      display: flex;
      align-items: center;
      gap: 8px;
      
      .resource-id {
        font-size: 12px;
        color: #909399;
      }
    }
    
    .no-resource {
      color: #c0c4cc;
    }
  }
  
  .log-detail {
    .details-section {
      margin-top: 20px;
      
      h4 {
        margin: 0 0 12px 0;
        color: #303133;
      }
    }
  }
}
</style>
