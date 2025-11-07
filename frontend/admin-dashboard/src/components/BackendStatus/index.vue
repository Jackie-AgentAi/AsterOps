<template>
  <div class="backend-status">
    <!-- 状态指示器 -->
    <div class="status-indicator" :class="statusClass">
      <el-icon v-if="isHealthy"><SuccessFilled /></el-icon>
      <el-icon v-else-if="isDegraded"><WarningFilled /></el-icon>
      <el-icon v-else><CircleCloseFilled /></el-icon>
      <span class="status-text">{{ statusText }}</span>
    </div>

    <!-- 详细状态 -->
    <el-popover
      v-if="showDetails"
      placement="bottom"
      :width="400"
      trigger="hover"
    >
      <template #reference>
        <el-button type="text" size="small">
          <el-icon><InfoFilled /></el-icon>
          详情
        </el-button>
      </template>
      
      <div class="status-details">
        <h4>后端服务状态</h4>
        
        <!-- 整体状态 -->
        <div class="overall-status">
          <el-tag :type="overallTagType" size="small">
            {{ overallStatusText }}
          </el-tag>
          <span class="health-percentage">{{ serviceHealthPercentage }}%</span>
        </div>

        <!-- 服务列表 -->
        <div class="services-list">
          <div 
            v-for="service in serviceDetails" 
            :key="service.name"
            class="service-item"
          >
            <div class="service-info">
              <span class="service-name">{{ service.name }}</span>
              <span class="service-response-time">{{ service.responseTime }}ms</span>
            </div>
            <el-tag 
              :type="getServiceTagType(service.status)" 
              size="small"
            >
              {{ getServiceStatusText(service.status) }}
            </el-tag>
          </div>
        </div>

        <!-- 错误信息 -->
        <div v-if="connectionErrors.length > 0" class="error-list">
          <h5>连接错误:</h5>
          <ul>
            <li v-for="error in connectionErrors" :key="error" class="error-item">
              {{ error }}
            </li>
          </ul>
        </div>

        <!-- 操作按钮 -->
        <div class="actions">
          <el-button size="small" @click="handleRefresh">刷新</el-button>
          <el-button size="small" @click="handleReconnect">重连</el-button>
          <el-button size="small" @click="handleTest">测试连接</el-button>
        </div>
      </div>
    </el-popover>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { 
  SuccessFilled, 
  WarningFilled, 
  CircleCloseFilled, 
  InfoFilled 
} from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { useBackendStore } from '@/stores/backend'

interface Props {
  showDetails?: boolean
  autoRefresh?: boolean
  refreshInterval?: number
}

const props = withDefaults(defineProps<Props>(), {
  showDetails: true,
  autoRefresh: true,
  refreshInterval: 30000
})

const backendStore = useBackendStore()

// 计算属性
const isHealthy = computed(() => backendStore.isHealthy)
const isDegraded = computed(() => backendStore.isDegraded)
const isUnhealthy = computed(() => backendStore.isUnhealthy)

const statusClass = computed(() => ({
  'status-healthy': isHealthy.value,
  'status-degraded': isDegraded.value,
  'status-unhealthy': isUnhealthy.value
}))

const statusText = computed(() => {
  if (isHealthy.value) return '后端连接正常'
  if (isDegraded.value) return '后端连接异常'
  return '后端连接失败'
})

const overallStatusText = computed(() => {
  if (isHealthy.value) return '健康'
  if (isDegraded.value) return '降级'
  return '异常'
})

const overallTagType = computed(() => {
  if (isHealthy.value) return 'success'
  if (isDegraded.value) return 'warning'
  return 'danger'
})

const serviceHealthPercentage = computed(() => backendStore.serviceHealthPercentage)
const serviceDetails = computed(() => backendStore.serviceDetails)
const connectionErrors = computed(() => backendStore.connectionErrors)

// 方法
const getServiceTagType = (status: string) => {
  switch (status) {
    case 'healthy': return 'success'
    case 'degraded': return 'warning'
    default: return 'danger'
  }
}

const getServiceStatusText = (status: string) => {
  switch (status) {
    case 'healthy': return '正常'
    case 'degraded': return '降级'
    case 'unhealthy': return '异常'
    default: return '未知'
  }
}

const handleRefresh = async () => {
  try {
    await backendStore.performHealthCheck()
    ElMessage.success('状态已刷新')
  } catch (error) {
    ElMessage.error('刷新失败')
  }
}

const handleReconnect = async () => {
  try {
    const success = await backendStore.reconnect()
    if (success) {
      ElMessage.success('重连成功')
    } else {
      ElMessage.error('重连失败')
    }
  } catch (error) {
    ElMessage.error('重连失败')
  }
}

const handleTest = async () => {
  try {
    const result = await backendStore.testConnectivity()
    if (result.success) {
      ElMessage.success(`连接测试成功 (${result.latency}ms)`)
    } else {
      ElMessage.error(`连接测试失败: ${result.error}`)
    }
  } catch (error) {
    ElMessage.error('连接测试失败')
  }
}

// 生命周期
onMounted(async () => {
  // 初始化后端连接
  if (!backendStore.isInitialized) {
    await backendStore.initialize()
  }

  // 设置自动刷新
  if (props.autoRefresh) {
    setInterval(() => {
      backendStore.performHealthCheck()
    }, props.refreshInterval)
  }
})
</script>

<style lang="scss" scoped>
.backend-status {
  display: flex;
  align-items: center;
  gap: 8px;

  .status-indicator {
    display: flex;
    align-items: center;
    gap: 4px;
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 12px;
    font-weight: 500;

    &.status-healthy {
      background-color: #f0f9ff;
      color: #67c23a;
      border: 1px solid #b3e19d;
    }

    &.status-degraded {
      background-color: #fdf6ec;
      color: #e6a23c;
      border: 1px solid #f5dab1;
    }

    &.status-unhealthy {
      background-color: #fef0f0;
      color: #f56c6c;
      border: 1px solid #fbc4c4;
    }

    .status-text {
      font-size: 12px;
    }
  }
}

.status-details {
  .overall-status {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
    padding-bottom: 8px;
    border-bottom: 1px solid #ebeef5;

    .health-percentage {
      font-size: 14px;
      font-weight: 500;
      color: #606266;
    }
  }

  .services-list {
    margin-bottom: 12px;

    .service-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 6px 0;
      border-bottom: 1px solid #f5f7fa;

      &:last-child {
        border-bottom: none;
      }

      .service-info {
        display: flex;
        flex-direction: column;
        gap: 2px;

        .service-name {
          font-size: 13px;
          font-weight: 500;
          color: #303133;
        }

        .service-response-time {
          font-size: 11px;
          color: #909399;
        }
      }
    }
  }

  .error-list {
    margin-bottom: 12px;

    h5 {
      margin: 0 0 6px 0;
      font-size: 12px;
      color: #f56c6c;
    }

    ul {
      margin: 0;
      padding-left: 16px;

      .error-item {
        font-size: 11px;
        color: #f56c6c;
        margin-bottom: 2px;
      }
    }
  }

  .actions {
    display: flex;
    gap: 8px;
    justify-content: flex-end;
    padding-top: 8px;
    border-top: 1px solid #ebeef5;
  }
}
</style>
