<template>
  <div class="status-card" :class="[`status-${status}`, { loading }]">
    <div class="card-header">
      <div class="icon">
        <el-icon v-if="!loading" :class="iconClass">
          <component :is="icon" />
        </el-icon>
        <el-icon v-else class="is-loading">
          <Loading />
        </el-icon>
      </div>
      <div class="title">{{ title }}</div>
    </div>
    
    <div class="card-content">
      <div class="value">{{ displayValue }}</div>
      <div v-if="unit" class="unit">{{ unit }}</div>
    </div>
    
    <div v-if="trend !== undefined" class="card-trend">
      <el-icon :class="trendClass">
        <component :is="trendIcon" />
      </el-icon>
      <span :class="trendClass">{{ trendText }}</span>
    </div>
    
    <div v-if="description" class="card-description">
      {{ description }}
    </div>
    
    <div v-if="showProgress" class="card-progress">
      <el-progress 
        :percentage="progress" 
        :stroke-width="4"
        :show-text="false"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { formatNumber } from '@/utils'

interface Props {
  title: string
  value: number | string
  unit?: string
  icon: string
  status?: 'success' | 'warning' | 'error' | 'info'
  trend?: number // 趋势值，正数表示上升，负数表示下降
  description?: string
  loading?: boolean
  showProgress?: boolean
  progress?: number
  precision?: number
}

const props = withDefaults(defineProps<Props>(), {
  status: 'info',
  loading: false,
  showProgress: false,
  progress: 0,
  precision: 2
})

const displayValue = computed(() => {
  if (typeof props.value === 'number') {
    return formatNumber(props.value, props.precision)
  }
  return props.value
})

const iconClass = computed(() => {
  return `icon-${props.status}`
})

const trendClass = computed(() => {
  if (props.trend === undefined) return ''
  return props.trend >= 0 ? 'trend-up' : 'trend-down'
})

const trendIcon = computed(() => {
  if (props.trend === undefined) return ''
  return props.trend >= 0 ? 'ArrowUp' : 'ArrowDown'
})

const trendText = computed(() => {
  if (props.trend === undefined) return ''
  const absTrend = Math.abs(props.trend)
  return `${absTrend}%`
})
</script>

<style lang="scss" scoped>
.status-card {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
  
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
  }
  
  &.loading {
    opacity: 0.7;
  }
  
  .card-header {
    display: flex;
    align-items: center;
    margin-bottom: 16px;
    
    .icon {
      margin-right: 12px;
      font-size: 24px;
      
      &.icon-success {
        color: #67c23a;
      }
      
      &.icon-warning {
        color: #e6a23c;
      }
      
      &.icon-error {
        color: #f56c6c;
      }
      
      &.icon-info {
        color: #409eff;
      }
    }
    
    .title {
      font-size: 14px;
      color: #666;
      font-weight: 500;
    }
  }
  
  .card-content {
    display: flex;
    align-items: baseline;
    margin-bottom: 8px;
    
    .value {
      font-size: 28px;
      font-weight: bold;
      color: #333;
      line-height: 1;
    }
    
    .unit {
      font-size: 14px;
      color: #999;
      margin-left: 4px;
    }
  }
  
  .card-trend {
    display: flex;
    align-items: center;
    margin-bottom: 8px;
    
    .el-icon {
      margin-right: 4px;
      font-size: 12px;
    }
    
    .trend-up {
      color: #67c23a;
    }
    
    .trend-down {
      color: #f56c6c;
    }
  }
  
  .card-description {
    font-size: 12px;
    color: #999;
    margin-bottom: 8px;
  }
  
  .card-progress {
    margin-top: 12px;
  }
  
  // 状态样式
  &.status-success {
    border-left: 4px solid #67c23a;
  }
  
  &.status-warning {
    border-left: 4px solid #e6a23c;
  }
  
  &.status-error {
    border-left: 4px solid #f56c6c;
  }
  
  &.status-info {
    border-left: 4px solid #409eff;
  }
}
</style>
