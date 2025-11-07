<template>
  <div class="dashboard">
    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :span="6">
        <StatusCard
          title="总用户数"
          :value="stats.totalUsers"
          icon="User"
          status="success"
          :trend="12.5"
          description="较上月增长12.5%"
        />
      </el-col>
      
      <el-col :span="6">
        <StatusCard
          title="模型数量"
          :value="stats.totalModels"
          icon="Box"
          status="info"
          :trend="8.2"
          description="较上月增长8.2%"
        />
      </el-col>
      
      <el-col :span="6">
        <StatusCard
          title="推理次数"
          :value="stats.totalInferences"
          unit="次"
          icon="Cpu"
          status="warning"
          :trend="-5.3"
          description="较上月下降5.3%"
        />
      </el-col>
      
      <el-col :span="6">
        <StatusCard
          title="总成本"
          :value="stats.totalCost"
          unit="元"
          icon="Money"
          status="error"
          :trend="15.8"
          description="较上月增长15.8%"
        />
      </el-col>
    </el-row>

    <!-- 图表区域 -->
    <el-row :gutter="20" class="charts-row">
      <el-col :span="12">
        <el-card class="chart-card">
          <template #header>
            <div class="card-header">
              <span>推理请求趋势</span>
              <el-button type="text" @click="refreshInferenceChart">刷新</el-button>
            </div>
          </template>
          <div class="chart-container">
            <Chart :option="inferenceChartOption" :height="300" />
          </div>
        </el-card>
      </el-col>
      
      <el-col :span="12">
        <el-card class="chart-card">
          <template #header>
            <div class="card-header">
              <span>成本分析</span>
              <el-button type="text" @click="refreshCostChart">刷新</el-button>
            </div>
          </template>
          <div class="chart-container">
            <Chart :option="costChartOption" :height="300" />
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 服务状态 -->
    <el-row :gutter="20" class="services-row">
      <el-col :span="24">
        <el-card class="services-card">
          <template #header>
            <div class="card-header">
              <span>服务状态</span>
              <el-button type="text" @click="refreshServices">刷新</el-button>
            </div>
          </template>
          <div class="services-grid">
            <div
              v-for="service in services"
              :key="service.name"
              class="service-item"
              :class="{ 'service-down': service.status === 'down' }"
            >
              <div class="service-icon">
                <el-icon v-if="service.status === 'up'"><Check /></el-icon>
                <el-icon v-else><Close /></el-icon>
              </div>
              <div class="service-info">
                <div class="service-name">{{ service.name }}</div>
                <div class="service-status">{{ service.statusText }}</div>
                <div class="service-response-time">响应时间: {{ service.responseTime }}ms</div>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 最近活动 -->
    <el-row :gutter="20" class="activities-row">
      <el-col :span="12">
        <el-card class="activities-card">
          <template #header>
            <div class="card-header">
              <span>最近活动</span>
              <el-button type="text" @click="refreshActivities">刷新</el-button>
            </div>
          </template>
          <div class="activities-list">
            <div
              v-for="activity in activities"
              :key="activity.id"
              class="activity-item"
            >
              <div class="activity-icon">
                <el-icon><Bell /></el-icon>
              </div>
              <div class="activity-content">
                <div class="activity-title">{{ activity.title }}</div>
                <div class="activity-time">{{ activity.time }}</div>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :span="12">
        <el-card class="alerts-card">
          <template #header>
            <div class="card-header">
              <span>系统告警</span>
              <el-button type="text" @click="refreshAlerts">刷新</el-button>
            </div>
          </template>
          <div class="alerts-list">
            <div
              v-for="alert in alerts"
              :key="alert.id"
              class="alert-item"
              :class="`alert-${alert.level}`"
            >
              <div class="alert-icon">
                <el-icon v-if="alert.level === 'critical'"><Warning /></el-icon>
                <el-icon v-else-if="alert.level === 'warning'"><InfoFilled /></el-icon>
                <el-icon v-else><SuccessFilled /></el-icon>
              </div>
              <div class="alert-content">
                <div class="alert-title">{{ alert.title }}</div>
                <div class="alert-message">{{ alert.message }}</div>
                <div class="alert-time">{{ alert.time }}</div>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useBackendStore } from '@/stores/backend'
import StatusCard from '@/components/StatusCard/index.vue'
import Chart from '@/components/Chart/index.vue'


// 后端状态
const backendStore = useBackendStore()

// 统计数据
const stats = ref({
  totalUsers: 1250,
  totalModels: 45,
  totalInferences: 125000,
  totalCost: 12500.50
})

// 后端健康状态
const backendHealth = computed(() => backendStore.integrationStatus)
const isBackendHealthy = computed(() => backendStore.isHealthy)

// 推理请求趋势图表
const inferenceChartOption = ref({
  tooltip: {
    trigger: 'axis'
  },
  xAxis: {
    type: 'category',
    data: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '24:00']
  },
  yAxis: {
    type: 'value'
  },
  series: [
    {
      name: '推理请求',
      type: 'line',
      data: [120, 200, 150, 80, 70, 110, 130],
      smooth: true,
      areaStyle: {
        color: {
          type: 'linear',
          x: 0,
          y: 0,
          x2: 0,
          y2: 1,
          colorStops: [
            { offset: 0, color: 'rgba(24, 144, 255, 0.3)' },
            { offset: 1, color: 'rgba(24, 144, 255, 0.1)' }
          ]
        }
      }
    }
  ]
})

// 成本分析图表
const costChartOption = ref({
  tooltip: {
    trigger: 'item'
  },
  legend: {
    orient: 'vertical',
    left: 'left'
  },
  series: [
    {
      name: '成本分布',
      type: 'pie',
      radius: '50%',
      data: [
        { value: 40, name: '计算资源' },
        { value: 30, name: '存储费用' },
        { value: 20, name: '网络费用' },
        { value: 10, name: '其他费用' }
      ],
      emphasis: {
        itemStyle: {
          shadowBlur: 10,
          shadowOffsetX: 0,
          shadowColor: 'rgba(0, 0, 0, 0.5)'
        }
      }
    }
  ]
})

// 服务状态
const services = ref([
  { name: '用户服务', status: 'up', statusText: '正常', responseTime: 45 },
  { name: '模型服务', status: 'up', statusText: '正常', responseTime: 32 },
  { name: '推理服务', status: 'up', statusText: '正常', responseTime: 128 },
  { name: '成本服务', status: 'up', statusText: '正常', responseTime: 28 },
  { name: '监控服务', status: 'up', statusText: '正常', responseTime: 35 },
  { name: '项目服务', status: 'down', statusText: '异常', responseTime: 0 }
])

// 最近活动
const activities = ref([
  { id: 1, title: '用户张三创建了新模型', time: '5分钟前' },
  { id: 2, title: '模型推理服务重启', time: '15分钟前' },
  { id: 3, title: '成本预算告警触发', time: '1小时前' },
  { id: 4, title: '新用户注册', time: '2小时前' },
  { id: 5, title: '系统备份完成', time: '3小时前' }
])

// 系统告警
const alerts = ref([
  {
    id: 1,
    title: '高CPU使用率',
    message: '推理服务CPU使用率超过80%',
    level: 'warning',
    time: '10分钟前'
  },
  {
    id: 2,
    title: '数据库连接异常',
    message: '数据库连接池已满',
    level: 'critical',
    time: '30分钟前'
  },
  {
    id: 3,
    title: '成本预算告警',
    message: '项目A成本已超过预算',
    level: 'warning',
    time: '1小时前'
  }
])

// 刷新方法
const refreshInferenceChart = () => {
  // 刷新推理图表数据
  console.log('刷新推理图表')
}

const refreshCostChart = () => {
  // 刷新成本图表数据
  console.log('刷新成本图表')
}

const refreshServices = () => {
  // 刷新服务状态
  console.log('刷新服务状态')
}

const refreshActivities = () => {
  // 刷新活动列表
  console.log('刷新活动列表')
}

const refreshAlerts = () => {
  // 刷新告警列表
  console.log('刷新告警列表')
}

onMounted(() => {
  // 初始化数据
  console.log('仪表板初始化')
})
</script>

<style lang="scss" scoped>
.dashboard {
  .stats-row {
    margin-bottom: 20px;
    
    .stat-card {
      .stat-content {
        display: flex;
        align-items: center;
        
        .stat-icon {
          width: 60px;
          height: 60px;
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          margin-right: 16px;
          font-size: 24px;
          color: white;
          
          &.users { background: #1890ff; }
          &.models { background: #52c41a; }
          &.inference { background: #fa8c16; }
          &.cost { background: #f5222d; }
        }
        
        .stat-info {
          .stat-value {
            font-size: 24px;
            font-weight: bold;
            color: #262626;
            margin-bottom: 4px;
          }
          
          .stat-label {
            font-size: 14px;
            color: #8c8c8c;
          }
        }
      }
    }
  }
  
  .charts-row {
    margin-bottom: 20px;
    
    .chart-card {
      .card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      
      .chart-container {
        width: 100%;
      }
    }
  }
  
  .services-row {
    margin-bottom: 20px;
    
    .services-card {
      .services-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 16px;
        
        .service-item {
          display: flex;
          align-items: center;
          padding: 16px;
          border: 1px solid #e8e8e8;
          border-radius: 8px;
          transition: all 0.3s;
          
          &:hover {
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
          }
          
          &.service-down {
            border-color: #f5222d;
            background: #fff2f0;
          }
          
          .service-icon {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-right: 12px;
            font-size: 18px;
            color: white;
            background: #52c41a;
          }
          
          &.service-down .service-icon {
            background: #f5222d;
          }
          
          .service-info {
            .service-name {
              font-weight: bold;
              margin-bottom: 4px;
            }
            
            .service-status {
              font-size: 12px;
              color: #52c41a;
              margin-bottom: 2px;
            }
            
            .service-response-time {
              font-size: 12px;
              color: #8c8c8c;
            }
          }
        }
      }
    }
  }
  
  .activities-row {
    .activities-card,
    .alerts-card {
      .card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      
      .activities-list,
      .alerts-list {
        .activity-item,
        .alert-item {
          display: flex;
          align-items: center;
          padding: 12px 0;
          border-bottom: 1px solid #f0f0f0;
          
          &:last-child {
            border-bottom: none;
          }
          
          .activity-icon,
          .alert-icon {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-right: 12px;
            font-size: 14px;
            color: white;
            background: #1890ff;
          }
          
          .alert-icon {
            &.alert-critical { background: #f5222d; }
            &.alert-warning { background: #fa8c16; }
            &.alert-info { background: #1890ff; }
          }
          
          .activity-content,
          .alert-content {
            .activity-title,
            .alert-title {
              font-weight: bold;
              margin-bottom: 4px;
            }
            
            .activity-time,
            .alert-time {
              font-size: 12px;
              color: #8c8c8c;
            }
            
            .alert-message {
              font-size: 12px;
              color: #666;
              margin-bottom: 4px;
            }
          }
        }
      }
    }
  }
}
</style>



