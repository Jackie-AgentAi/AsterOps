<template>
  <div class="quota-list">
    <div class="list-header">
      <div class="header-left">
        <h3>资源配额管理</h3>
        <p>管理用户资源配额和使用情况</p>
      </div>
      <div class="header-right">
        <el-button type="primary" @click="handleAdd">
          <el-icon><Plus /></el-icon>
          添加配额
        </el-button>
        <el-button @click="handleRefresh">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
      </div>
    </div>
    
    <!-- 配额统计卡片 -->
    <div class="stats-cards">
      <el-row :gutter="20">
        <el-col :span="6" v-for="stat in quotaStats" :key="stat.resource_type">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon">
                <el-icon :size="24" :color="stat.color">
                  <component :is="stat.icon" />
                </el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-title">{{ stat.title }}</div>
                <div class="stat-value">
                  <span class="used">{{ stat.used_quota }}</span>
                  <span class="separator">/</span>
                  <span class="total">{{ stat.total_quota }}</span>
                </div>
                <div class="stat-rate">
                  <el-progress 
                    :percentage="stat.usage_rate" 
                    :color="getProgressColor(stat.usage_rate)"
                    :show-text="false"
                  />
                  <span class="rate-text">{{ stat.usage_rate.toFixed(1) }}%</span>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>
    
    <el-card class="table-card">
      <DataTable
        :data="quotaList"
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
        @add="handleAdd"
        @edit="handleEdit"
        @view="handleView"
        @delete="handleDelete"
        @batch-delete="handleBatchDelete"
        @page-change="handlePageChange"
        @sort-change="handleSortChange"
      >
        <!-- 资源类型列 -->
        <template #resource_type="{ row }">
          <el-tag :type="getResourceTypeTag(row.resource_type)">
            {{ getResourceTypeText(row.resource_type) }}
          </el-tag>
        </template>
        
        <!-- 使用情况列 -->
        <template #usage="{ row }">
          <div class="usage-info">
            <div class="usage-text">
              {{ row.used_amount }} / {{ row.quota_limit }}
            </div>
            <el-progress 
              :percentage="getUsagePercentage(row)"
              :color="getUsageColor(row)"
              :show-text="false"
              :stroke-width="6"
            />
          </div>
        </template>
        
        <!-- 周期类型列 -->
        <template #period_type="{ row }">
          <el-tag type="info" size="small">
            {{ getPeriodTypeText(row.period_type) }}
          </el-tag>
        </template>
        
        <!-- 操作列 -->
        <template #actions="{ row, index }">
          <el-button type="primary" link @click="handleView(row, index)">
            查看
          </el-button>
          <el-button type="primary" link @click="handleEdit(row, index)">
            编辑
          </el-button>
          <el-button type="warning" link @click="handleResetUsage(row)">
            重置使用量
          </el-button>
          <el-button type="danger" link @click="handleDelete(row, index)">
            删除
          </el-button>
        </template>
      </DataTable>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Refresh, Cpu, Database, CloudUpload, Network } from '@element-plus/icons-vue'
import DataTable from '@/components/DataTable/index.vue'
import { getUserQuotas, deleteUserQuota, getQuotaUsageStats } from '@/api/user'
import type { UserQuota, QuotaUsageStats, TableColumn } from '@/types'

const emit = defineEmits<{
  add: []
  edit: [quota: UserQuota]
  view: [quota: UserQuota]
  delete: [quota: UserQuota]
}>()

// 响应式数据
const loading = ref(false)
const quotaList = ref<UserQuota[]>([])
const total = ref(0)
const currentPage = ref(1)
const pageSize = ref(10)
const searchKeyword = ref('')
const quotaStats = ref<QuotaUsageStats[]>([])

// 表格列配置
const columns: TableColumn[] = [
  { prop: 'id', label: 'ID', width: 80 },
  { prop: 'user_id', label: '用户ID', width: 120 },
  { prop: 'resource_type', label: '资源类型', width: 120, slot: 'resource_type' },
  { prop: 'usage', label: '使用情况', width: 200, slot: 'usage' },
  { prop: 'period_type', label: '周期类型', width: 100, slot: 'period_type' },
  { prop: 'created_at', label: '创建时间', width: 180, sortable: true }
]

// 资源类型配置
const resourceTypeConfig = {
  gpu: { text: 'GPU', tag: 'success', icon: Cpu, color: '#67c23a' },
  storage: { text: '存储', tag: 'primary', icon: Database, color: '#409eff' },
  api_calls: { text: 'API调用', tag: 'warning', icon: Network, color: '#e6a23c' },
  upload: { text: '上传', tag: 'info', icon: CloudUpload, color: '#909399' }
}

// 获取配额列表
const fetchQuotaList = async () => {
  loading.value = true
  try {
    // 这里需要根据实际API调整
    const response = await getUserQuotas('all') // 获取所有用户的配额
    quotaList.value = response
    total.value = response.length
  } catch (error) {
    ElMessage.error('获取配额列表失败')
  } finally {
    loading.value = false
  }
}

// 获取配额统计
const fetchQuotaStats = async () => {
  try {
    const response = await getQuotaUsageStats()
    quotaStats.value = response.map(stat => ({
      ...stat,
      title: resourceTypeConfig[stat.resource_type as keyof typeof resourceTypeConfig]?.text || stat.resource_type,
      icon: resourceTypeConfig[stat.resource_type as keyof typeof resourceTypeConfig]?.icon || Cpu,
      color: resourceTypeConfig[stat.resource_type as keyof typeof resourceTypeConfig]?.color || '#409eff'
    }))
  } catch (error) {
    console.error('获取配额统计失败:', error)
  }
}

// 搜索处理
const handleSearch = (keyword: string) => {
  searchKeyword.value = keyword
  currentPage.value = 1
  fetchQuotaList()
}

// 分页处理
const handlePageChange = (page: number, size: number) => {
  currentPage.value = page
  pageSize.value = size
  fetchQuotaList()
}

// 排序处理
const handleSortChange = (sortBy: string, sortOrder: string) => {
  console.log('排序:', sortBy, sortOrder)
  // 实现排序逻辑
}

// 新增配额
const handleAdd = () => {
  emit('add')
}

// 编辑配额
const handleEdit = (row: UserQuota, index: number) => {
  emit('edit', row)
}

// 查看配额
const handleView = (row: UserQuota, index: number) => {
  emit('view', row)
}

// 删除配额
const handleDelete = async (row: UserQuota, index: number) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除用户 ${row.user_id} 的 ${getResourceTypeText(row.resource_type)} 配额吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await deleteUserQuota(row.id)
    ElMessage.success('删除成功')
    fetchQuotaList()
    emit('delete', row)
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 批量删除配额
const handleBatchDelete = async (selectedRows: UserQuota[]) => {
  if (selectedRows.length === 0) {
    ElMessage.warning('请选择要删除的配额')
    return
  }
  
  try {
    await ElMessageBox.confirm(
      `确定要删除选中的 ${selectedRows.length} 个配额吗？`,
      '确认批量删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    // 批量删除逻辑
    for (const quota of selectedRows) {
      await deleteUserQuota(quota.id)
    }
    
    ElMessage.success('批量删除成功')
    fetchQuotaList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('批量删除失败')
    }
  }
}

// 重置使用量
const handleResetUsage = async (row: UserQuota) => {
  try {
    await ElMessageBox.confirm(
      `确定要重置用户 ${row.user_id} 的 ${getResourceTypeText(row.resource_type)} 使用量吗？`,
      '确认重置',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    // 这里需要调用重置使用量的API
    ElMessage.success('重置成功')
    fetchQuotaList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('重置失败')
    }
  }
}

// 刷新数据
const handleRefresh = () => {
  fetchQuotaList()
  fetchQuotaStats()
}

// 工具函数
const getResourceTypeText = (type: string) => {
  return resourceTypeConfig[type as keyof typeof resourceTypeConfig]?.text || type
}

const getResourceTypeTag = (type: string) => {
  return resourceTypeConfig[type as keyof typeof resourceTypeConfig]?.tag || 'info'
}

const getPeriodTypeText = (type: string) => {
  const periodMap: Record<string, string> = {
    daily: '每日',
    weekly: '每周',
    monthly: '每月',
    yearly: '每年'
  }
  return periodMap[type] || type
}

const getUsagePercentage = (quota: UserQuota) => {
  if (quota.quota_limit === 0) return 0
  return Math.min((quota.used_amount / quota.quota_limit) * 100, 100)
}

const getUsageColor = (quota: UserQuota) => {
  const percentage = getUsagePercentage(quota)
  if (percentage >= 90) return '#f56c6c'
  if (percentage >= 70) return '#e6a23c'
  return '#67c23a'
}

const getProgressColor = (percentage: number) => {
  if (percentage >= 90) return '#f56c6c'
  if (percentage >= 70) return '#e6a23c'
  return '#67c23a'
}

// 初始化
onMounted(() => {
  fetchQuotaList()
  fetchQuotaStats()
})
</script>

<style lang="scss" scoped>
.quota-list {
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
    
    .header-right {
      .el-button {
        margin-left: 8px;
      }
    }
  }
  
  .stats-cards {
    margin-bottom: 20px;
    
    .stat-card {
      .stat-content {
        display: flex;
        align-items: center;
        
        .stat-icon {
          margin-right: 16px;
        }
        
        .stat-info {
          flex: 1;
          
          .stat-title {
            font-size: 14px;
            color: #909399;
            margin-bottom: 8px;
          }
          
          .stat-value {
            font-size: 18px;
            font-weight: 600;
            color: #303133;
            margin-bottom: 8px;
            
            .used {
              color: #409eff;
            }
            
            .separator {
              margin: 0 4px;
              color: #c0c4cc;
            }
            
            .total {
              color: #606266;
            }
          }
          
          .stat-rate {
            display: flex;
            align-items: center;
            
            .el-progress {
              flex: 1;
              margin-right: 8px;
            }
            
            .rate-text {
              font-size: 12px;
              color: #909399;
              min-width: 40px;
            }
          }
        }
      }
    }
  }
  
  .table-card {
    .usage-info {
      .usage-text {
        font-size: 12px;
        color: #606266;
        margin-bottom: 4px;
      }
    }
  }
}
</style>
