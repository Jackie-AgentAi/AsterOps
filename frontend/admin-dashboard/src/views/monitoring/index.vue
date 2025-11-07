<template>
  <div class="monitoring-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>监控告警</h2>
      <p>系统监控、告警管理和日志查询</p>
    </div>

    <!-- 系统状态概览 -->
    <el-row :gutter="20" class="status-overview">
      <el-col :span="6">
        <StatusCard
          title="系统状态"
          :value="systemStatus.overall"
          icon="Monitor"
          :status="getSystemStatusType(systemStatus.overall)"
          :description="systemStatus.message"
        />
      </el-col>
      
      <el-col :span="6">
        <StatusCard
          title="活跃告警"
          :value="alertSummary.activeCount"
          unit="个"
          icon="Warning"
          status="error"
          :description="`${alertSummary.criticalCount}个严重告警`"
        />
      </el-col>
      
      <el-col :span="6">
        <StatusCard
          title="服务可用性"
          :value="systemMetrics.availability"
          unit="%"
          icon="Check"
          status="success"
          :trend="2.5"
          description="较昨日提升2.5%"
        />
      </el-col>
      
      <el-col :span="6">
        <StatusCard
          title="平均响应时间"
          :value="systemMetrics.avgResponseTime"
          unit="ms"
          icon="Timer"
          status="info"
          :trend="-5.2"
          description="较昨日下降5.2%"
        />
      </el-col>
    </el-row>

    <!-- 标签页 -->
    <el-tabs v-model="activeTab" type="border-card" class="main-tabs">
      <!-- 系统监控 -->
      <el-tab-pane label="系统监控" name="system">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-card class="chart-card">
              <template #header>
                <div class="card-header">
                  <span>服务状态</span>
                  <el-button type="primary" size="small" @click="refreshServiceStatus">
                    <el-icon><Refresh /></el-icon>
                    刷新
                  </el-button>
                </div>
              </template>
              <div class="service-status">
                <div 
                  v-for="service in serviceList" 
                  :key="service.name"
                  class="service-item"
                >
                  <div class="service-info">
                    <div class="service-name">{{ service.name }}</div>
                    <div class="service-description">{{ service.description }}</div>
                  </div>
                  <div class="service-status-indicator">
                    <el-tag :type="getServiceStatusType(service.status)">
                      {{ getServiceStatusText(service.status) }}
                    </el-tag>
                    <div class="service-uptime">{{ service.uptime }}</div>
                  </div>
                </div>
              </div>
            </el-card>
          </el-col>
          
          <el-col :span="12">
            <el-card class="chart-card">
              <template #header>
                <span>资源使用率</span>
              </template>
              <Chart :option="resourceChartOption" :height="300" />
            </el-card>
          </el-col>
        </el-row>

        <el-row :gutter="20" style="margin-top: 20px;">
          <el-col :span="8">
            <el-card class="metric-card">
              <template #header>
                <span>CPU使用率</span>
              </template>
              <div class="metric-content">
                <el-progress 
                  :percentage="systemMetrics.cpuUsage" 
                  :status="systemMetrics.cpuUsage > 80 ? 'exception' : systemMetrics.cpuUsage > 60 ? 'warning' : 'success'"
                />
                <div class="metric-details">
                  <span>当前: {{ systemMetrics.cpuUsage }}%</span>
                  <span>峰值: {{ systemMetrics.cpuPeak }}%</span>
                </div>
              </div>
            </el-card>
          </el-col>
          
          <el-col :span="8">
            <el-card class="metric-card">
              <template #header>
                <span>内存使用率</span>
              </template>
              <div class="metric-content">
                <el-progress 
                  :percentage="systemMetrics.memoryUsage" 
                  :status="systemMetrics.memoryUsage > 80 ? 'exception' : systemMetrics.memoryUsage > 60 ? 'warning' : 'success'"
                />
                <div class="metric-details">
                  <span>当前: {{ systemMetrics.memoryUsage }}%</span>
                  <span>峰值: {{ systemMetrics.memoryPeak }}%</span>
                </div>
              </div>
            </el-card>
          </el-col>
          
          <el-col :span="8">
            <el-card class="metric-card">
              <template #header>
                <span>磁盘使用率</span>
              </template>
              <div class="metric-content">
                <el-progress 
                  :percentage="systemMetrics.diskUsage" 
                  :status="systemMetrics.diskUsage > 80 ? 'exception' : systemMetrics.diskUsage > 60 ? 'warning' : 'success'"
                />
                <div class="metric-details">
                  <span>当前: {{ systemMetrics.diskUsage }}%</span>
                  <span>峰值: {{ systemMetrics.diskPeak }}%</span>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <el-row :gutter="20" style="margin-top: 20px;">
          <el-col :span="12">
            <el-card class="chart-card">
              <template #header>
                <span>QPS趋势</span>
              </template>
              <Chart :option="qpsChartOption" :height="300" />
            </el-card>
          </el-col>
          
          <el-col :span="12">
            <el-card class="chart-card">
              <template #header>
                <span>响应时间分布</span>
              </template>
              <Chart :option="responseTimeChartOption" :height="300" />
            </el-card>
          </el-col>
        </el-row>
      </el-tab-pane>

      <!-- 告警管理 -->
      <el-tab-pane label="告警管理" name="alerts">
        <el-card class="alerts-card">
          <template #header>
            <div class="card-header">
              <span>告警列表</span>
              <div class="header-actions">
                <el-select v-model="alertFilter.level" placeholder="告警级别" clearable style="width: 120px; margin-right: 10px;">
                  <el-option label="全部" value="" />
                  <el-option label="严重" value="critical" />
                  <el-option label="警告" value="warning" />
                  <el-option label="信息" value="info" />
                </el-select>
                <el-select v-model="alertFilter.status" placeholder="告警状态" clearable style="width: 120px; margin-right: 10px;">
                  <el-option label="全部" value="" />
                  <el-option label="活跃" value="firing" />
                  <el-option label="已解决" value="resolved" />
                </el-select>
                <el-button type="primary" @click="refreshAlerts">
                  <el-icon><Refresh /></el-icon>
                  刷新
                </el-button>
                <el-button type="success" @click="handleBatchResolve">
                  <el-icon><Check /></el-icon>
                  批量解决
                </el-button>
              </div>
            </div>
          </template>

          <DataTable
            :data="alertList"
            :columns="alertColumns"
            :loading="alertLoading"
            :total="alertTotal"
            :current-page="alertPage"
            :page-size="alertPageSize"
            :show-search="true"
            :show-actions="true"
            :show-selection="true"
            @search="handleAlertSearch"
            @page-change="handleAlertPageChange"
            @row-edit="handleAlertEdit"
            @row-delete="handleAlertDelete"
          >
            <!-- 告警级别 -->
            <template #level="{ row }">
              <el-tag :type="getAlertLevelType(row.level)">
                {{ getAlertLevelText(row.level) }}
              </el-tag>
            </template>

            <!-- 告警状态 -->
            <template #status="{ row }">
              <el-tag :type="getAlertStatusType(row.status)">
                {{ getAlertStatusText(row.status) }}
              </el-tag>
            </template>

            <!-- 触发时间 -->
            <template #triggeredAt="{ row }">
              {{ formatDate(row.triggeredAt) }}
            </template>

            <!-- 操作列 -->
            <template #actions="{ row, index }">
              <el-button type="primary" link @click="viewAlertDetail(row)">
                查看详情
              </el-button>
              <el-button 
                v-if="row.status === 'firing'" 
                type="success" 
                link 
                @click="resolveAlert(row)"
              >
                解决
              </el-button>
              <el-button type="danger" link @click="deleteAlert(row)">
                删除
              </el-button>
            </template>
          </DataTable>
        </el-card>
      </el-tab-pane>

      <!-- 告警规则 -->
      <el-tab-pane label="告警规则" name="rules">
        <el-card class="rules-card">
          <template #header>
            <div class="card-header">
              <span>告警规则</span>
              <el-button type="primary" @click="handleCreateRule">
                <el-icon><Plus /></el-icon>
                创建规则
              </el-button>
            </div>
          </template>

          <el-table :data="ruleList" style="width: 100%">
            <el-table-column prop="name" label="规则名称" />
            <el-table-column prop="description" label="描述" />
            <el-table-column prop="level" label="级别" width="100">
              <template #default="{ row }">
                <el-tag :type="getAlertLevelType(row.level)">
                  {{ getAlertLevelText(row.level) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="condition" label="触发条件" />
            <el-table-column prop="status" label="状态" width="100">
              <template #default="{ row }">
                <el-switch v-model="row.enabled" @change="toggleRule(row)" />
              </template>
            </el-table-column>
            <el-table-column prop="createdAt" label="创建时间" width="160">
              <template #default="{ row }">
                {{ formatDate(row.createdAt) }}
              </template>
            </el-table-column>
            <el-table-column label="操作" width="200">
              <template #default="{ row }">
                <el-button type="primary" link @click="editRule(row)">
                  编辑
                </el-button>
                <el-button type="success" link @click="testRule(row)">
                  测试
                </el-button>
                <el-button type="danger" link @click="deleteRule(row)">
                  删除
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-tab-pane>

      <!-- 日志管理 -->
      <el-tab-pane label="日志管理" name="logs">
        <el-card class="logs-card">
          <template #header>
            <div class="card-header">
              <span>系统日志</span>
              <div class="header-actions">
                <el-select v-model="logFilter.level" placeholder="日志级别" clearable style="width: 120px; margin-right: 10px;">
                  <el-option label="全部" value="" />
                  <el-option label="ERROR" value="error" />
                  <el-option label="WARN" value="warn" />
                  <el-option label="INFO" value="info" />
                  <el-option label="DEBUG" value="debug" />
                </el-select>
                <el-select v-model="logFilter.service" placeholder="服务" clearable style="width: 120px; margin-right: 10px;">
                  <el-option label="全部" value="" />
                  <el-option label="API Gateway" value="api-gateway" />
                  <el-option label="User Service" value="user-service" />
                  <el-option label="Model Service" value="model-service" />
                  <el-option label="Inference Service" value="inference-service" />
                </el-select>
                <el-date-picker
                  v-model="logDateRange"
                  type="datetimerange"
                  range-separator="至"
                  start-placeholder="开始时间"
                  end-placeholder="结束时间"
                  @change="handleLogDateChange"
                />
                <el-button type="primary" @click="searchLogs">
                  <el-icon><Search /></el-icon>
                  搜索
                </el-button>
                <el-button @click="exportLogs">
                  <el-icon><Download /></el-icon>
                  导出
                </el-button>
              </div>
            </div>
          </template>

          <DataTable
            :data="logList"
            :columns="logColumns"
            :loading="logLoading"
            :total="logTotal"
            :current-page="logPage"
            :page-size="logPageSize"
            :show-search="true"
            :show-actions="false"
            @search="handleLogSearch"
            @page-change="handleLogPageChange"
          >
            <!-- 日志级别 -->
            <template #level="{ row }">
              <el-tag :type="getLogLevelType(row.level)">
                {{ row.level.toUpperCase() }}
              </el-tag>
            </template>

            <!-- 时间戳 -->
            <template #timestamp="{ row }">
              {{ formatDate(row.timestamp) }}
            </template>

            <!-- 消息内容 -->
            <template #message="{ row }">
              <el-tooltip :content="row.message" placement="top">
                <span class="log-message">{{ row.message.substring(0, 100) }}...</span>
              </el-tooltip>
            </template>
          </DataTable>
        </el-card>
      </el-tab-pane>

      <!-- 性能分析 -->
      <el-tab-pane label="性能分析" name="performance">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-card class="chart-card">
              <template #header>
                <span>慢查询分析</span>
              </template>
              <Chart :option="slowQueryChartOption" :height="300" />
            </el-card>
          </el-col>
          
          <el-col :span="12">
            <el-card class="chart-card">
              <template #header>
                <span>接口性能排行</span>
              </template>
              <div class="performance-ranking">
                <div 
                  v-for="(item, index) in performanceRanking" 
                  :key="item.endpoint"
                  class="ranking-item"
                >
                  <div class="ranking-number">{{ index + 1 }}</div>
                  <div class="ranking-content">
                    <div class="ranking-name">{{ item.endpoint }}</div>
                    <div class="ranking-method">{{ item.method }}</div>
                  </div>
                  <div class="ranking-metrics">
                    <div class="metric-item">
                      <span class="metric-label">平均响应时间:</span>
                      <span class="metric-value">{{ item.avgResponseTime }}ms</span>
                    </div>
                    <div class="metric-item">
                      <span class="metric-label">调用次数:</span>
                      <span class="metric-value">{{ item.callCount }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <el-row :gutter="20" style="margin-top: 20px;">
          <el-col :span="24">
            <el-card class="chart-card">
              <template #header>
                <span>调用链追踪</span>
              </template>
              <Chart :option="traceChartOption" :height="400" />
            </el-card>
          </el-col>
        </el-row>
      </el-tab-pane>
    </el-tabs>

    <!-- 告警详情对话框 -->
    <el-dialog
      v-model="alertDetailVisible"
      title="告警详情"
      width="800px"
    >
      <div v-if="currentAlert" class="alert-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="告警ID">{{ currentAlert.id }}</el-descriptions-item>
          <el-descriptions-item label="告警级别">
            <el-tag :type="getAlertLevelType(currentAlert.level)">
              {{ getAlertLevelText(currentAlert.level) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="告警名称">{{ currentAlert.name }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="getAlertStatusType(currentAlert.status)">
              {{ getAlertStatusText(currentAlert.status) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="触发时间">{{ formatDate(currentAlert.triggeredAt) }}</el-descriptions-item>
          <el-descriptions-item label="解决时间">
            {{ currentAlert.resolvedAt ? formatDate(currentAlert.resolvedAt) : '-' }}
          </el-descriptions-item>
        </el-descriptions>

        <el-divider content-position="left">告警描述</el-divider>
        <p>{{ currentAlert.description }}</p>

        <el-divider content-position="left">告警标签</el-divider>
        <div class="alert-labels">
          <el-tag 
            v-for="(value, key) in currentAlert.labels" 
            :key="key"
            style="margin-right: 8px; margin-bottom: 8px;"
          >
            {{ key }}: {{ value }}
          </el-tag>
        </div>

        <el-divider content-position="left">处理建议</el-divider>
        <p>{{ currentAlert.suggestions || '暂无处理建议' }}</p>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import DataTable from '@/components/DataTable/index.vue'
import StatusCard from '@/components/StatusCard/index.vue'
import Chart from '@/components/Chart/index.vue'
import { 
  getServiceStatus,
  getSystemMetrics,
  getAlertList,
  resolveAlert,
  deleteAlert,
  getAlertRuleList,
  createAlertRule,
  updateAlertRule,
  deleteAlertRule,
  testAlertRule,
  getLogList,
  exportLogs,
  getPerformanceDashboard
} from '@/api/monitoring'
import { formatDate } from '@/utils'
import type { Alert, AlertRule, LogEntry, TableColumn } from '@/types'

// 响应式数据
const activeTab = ref('system')

// 系统状态
const systemStatus = ref({
  overall: 'healthy',
  message: '所有服务运行正常'
})

const systemMetrics = ref({
  availability: 99.9,
  avgResponseTime: 120,
  cpuUsage: 45,
  cpuPeak: 78,
  memoryUsage: 62,
  memoryPeak: 85,
  diskUsage: 38,
  diskPeak: 55
})

const serviceList = ref([
  { name: 'API Gateway', description: 'API网关服务', status: 'healthy', uptime: '99.9%' },
  { name: 'User Service', description: '用户管理服务', status: 'healthy', uptime: '99.8%' },
  { name: 'Model Service', description: '模型管理服务', status: 'healthy', uptime: '99.7%' },
  { name: 'Inference Service', description: '推理服务', status: 'warning', uptime: '98.5%' },
  { name: 'Cost Service', description: '成本管理服务', status: 'healthy', uptime: '99.6%' },
  { name: 'Monitoring Service', description: '监控服务', status: 'healthy', uptime: '99.9%' }
])

// 告警管理
const alertSummary = ref({
  activeCount: 3,
  criticalCount: 1
})

const alertList = ref<Alert[]>([])
const alertTotal = ref(0)
const alertPage = ref(1)
const alertPageSize = ref(10)
const alertLoading = ref(false)
const alertFilter = reactive({
  level: '',
  status: ''
})

const alertDetailVisible = ref(false)
const currentAlert = ref<Alert | null>(null)

// 告警规则
const ruleList = ref<AlertRule[]>([])

// 日志管理
const logList = ref<LogEntry[]>([])
const logTotal = ref(0)
const logPage = ref(1)
const logPageSize = ref(10)
const logLoading = ref(false)
const logFilter = reactive({
  level: '',
  service: ''
})
const logDateRange = ref<[Date, Date] | null>(null)

// 性能分析
const performanceRanking = ref([
  { endpoint: '/api/v1/inference', method: 'POST', avgResponseTime: 1250, callCount: 15420 },
  { endpoint: '/api/v1/models', method: 'GET', avgResponseTime: 45, callCount: 8930 },
  { endpoint: '/api/v1/users', method: 'GET', avgResponseTime: 32, callCount: 6720 },
  { endpoint: '/api/v1/projects', method: 'POST', avgResponseTime: 180, callCount: 2340 },
  { endpoint: '/api/v1/costs', method: 'GET', avgResponseTime: 95, callCount: 1890 }
])

// 表格列配置
const alertColumns: TableColumn[] = [
  { prop: 'id', label: '告警ID', width: 120 },
  { prop: 'name', label: '告警名称', minWidth: 150 },
  { prop: 'level', label: '级别', width: 100 },
  { prop: 'status', label: '状态', width: 100 },
  { prop: 'triggeredAt', label: '触发时间', width: 160 },
  { prop: 'description', label: '描述', minWidth: 200 }
]

const logColumns: TableColumn[] = [
  { prop: 'id', label: 'ID', width: 80 },
  { prop: 'timestamp', label: '时间', width: 160 },
  { prop: 'level', label: '级别', width: 80 },
  { prop: 'service', label: '服务', width: 120 },
  { prop: 'message', label: '消息', minWidth: 300 }
]

// 图表配置
const resourceChartOption = ref({
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: [] },
  yAxis: { type: 'value', max: 100 },
  series: [
    { name: 'CPU', type: 'line', data: [] },
    { name: '内存', type: 'line', data: [] },
    { name: '磁盘', type: 'line', data: [] }
  ]
})

const qpsChartOption = ref({
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: [] },
  yAxis: { type: 'value' },
  series: [{
    name: 'QPS',
    type: 'line',
    data: [],
    smooth: true
  }]
})

const responseTimeChartOption = ref({
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: [] },
  yAxis: { type: 'value' },
  series: [{
    name: '响应时间(ms)',
    type: 'bar',
    data: []
  }]
})

const slowQueryChartOption = ref({
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: [] },
  yAxis: { type: 'value' },
  series: [{
    name: '慢查询数量',
    type: 'bar',
    data: []
  }]
})

const traceChartOption = ref({
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: [] },
  yAxis: { type: 'value' },
  series: [{
    name: '调用链',
    type: 'line',
    data: []
  }]
})

// 获取系统状态
const fetchSystemStatus = async () => {
  try {
    const response = await getServiceStatus()
    systemStatus.value = response
  } catch (error) {
    ElMessage.error('获取系统状态失败')
  }
}

// 获取系统指标
const fetchSystemMetrics = async () => {
  try {
    const response = await getSystemMetrics()
    systemMetrics.value = response
  } catch (error) {
    ElMessage.error('获取系统指标失败')
  }
}

// 获取服务列表
const fetchServiceList = async () => {
  try {
    const response = await getServiceStatus()
    serviceList.value = response
  } catch (error) {
    ElMessage.error('获取服务列表失败')
  }
}

// 获取告警列表
const fetchAlertList = async () => {
  alertLoading.value = true
  try {
    const response = await getAlertList({
      page: alertPage.value,
      pageSize: alertPageSize.value,
      level: alertFilter.level,
      status: alertFilter.status
    })
    alertList.value = response.items
    alertTotal.value = response.pagination.total
  } catch (error) {
    ElMessage.error('获取告警列表失败')
  } finally {
    alertLoading.value = false
  }
}

// 获取告警规则
const fetchRuleList = async () => {
  try {
    const response = await getAlertRuleList()
    ruleList.value = response
  } catch (error) {
    ElMessage.error('获取告警规则失败')
  }
}

// 获取日志列表
const fetchLogList = async () => {
  logLoading.value = true
  try {
    const response = await getLogList({
      page: logPage.value,
      pageSize: logPageSize.value,
      level: logFilter.level,
      service: logFilter.service,
      startDate: logDateRange.value?.[0]?.toISOString(),
      endDate: logDateRange.value?.[1]?.toISOString()
    })
    logList.value = response.items
    logTotal.value = response.pagination.total
  } catch (error) {
    ElMessage.error('获取日志列表失败')
  } finally {
    logLoading.value = false
  }
}

// 获取性能指标
const fetchPerformanceMetrics = async () => {
  try {
    const response = await getPerformanceDashboard()
    
    // 更新图表数据
    resourceChartOption.value.xAxis.data = response.resourceUsage.map(item => item.timestamp)
    resourceChartOption.value.series[0].data = response.resourceUsage.map(item => item.cpu)
    resourceChartOption.value.series[1].data = response.resourceUsage.map(item => item.memory)
    resourceChartOption.value.series[2].data = response.resourceUsage.map(item => item.disk)
    
    qpsChartOption.value.xAxis.data = response.qps.map(item => item.timestamp)
    qpsChartOption.value.series[0].data = response.qps.map(item => item.value)
    
    responseTimeChartOption.value.xAxis.data = response.responseTime.map(item => item.timestamp)
    responseTimeChartOption.value.series[0].data = response.responseTime.map(item => item.avg)
  } catch (error) {
    ElMessage.error('获取性能指标失败')
  }
}

// 事件处理
const refreshServiceStatus = () => {
  fetchServiceList()
  fetchSystemStatus()
  fetchSystemMetrics()
}

const refreshAlerts = () => {
  fetchAlertList()
}

const handleAlertSearch = (keyword: string) => {
  // 实现搜索逻辑
  fetchAlertList()
}

const handleAlertPageChange = (page: number, size: number) => {
  alertPage.value = page
  alertPageSize.value = size
  fetchAlertList()
}

const viewAlertDetail = (alert: Alert) => {
  currentAlert.value = alert
  alertDetailVisible.value = true
}

const resolveAlert = async (alert: Alert) => {
  try {
    await resolveAlert(alert.id)
    ElMessage.success('告警已解决')
    fetchAlertList()
  } catch (error) {
    ElMessage.error('解决告警失败')
  }
}

const deleteAlert = async (alert: Alert) => {
  try {
    await ElMessageBox.confirm('确定要删除该告警吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await deleteAlert(alert.id)
    ElMessage.success('告警删除成功')
    fetchAlertList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

const handleBatchResolve = () => {
  ElMessage.info('批量解决功能开发中')
}

const handleCreateRule = () => {
  ElMessage.info('创建告警规则功能开发中')
}

const editRule = (rule: AlertRule) => {
  ElMessage.info('编辑告警规则功能开发中')
}

const testRule = (rule: AlertRule) => {
  ElMessage.info('测试告警规则功能开发中')
}

const deleteRule = async (rule: AlertRule) => {
  try {
    await ElMessageBox.confirm('确定要删除该规则吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await deleteAlertRule(rule.id)
    ElMessage.success('规则删除成功')
    fetchRuleList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

const toggleRule = async (rule: AlertRule) => {
  try {
    await updateAlertRule(rule.id, { enabled: rule.enabled })
    ElMessage.success('规则状态已更新')
  } catch (error) {
    ElMessage.error('更新规则状态失败')
  }
}

const handleLogSearch = (keyword: string) => {
  // 实现搜索逻辑
  fetchLogList()
}

const handleLogPageChange = (page: number, size: number) => {
  logPage.value = page
  logPageSize.value = size
  fetchLogList()
}

const handleLogDateChange = () => {
  logPage.value = 1
  fetchLogList()
}

const searchLogs = () => {
  logPage.value = 1
  fetchLogList()
}

const exportLogs = () => {
  ElMessage.info('导出日志功能开发中')
}

// 工具函数
const getSystemStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    healthy: 'success',
    warning: 'warning',
    error: 'danger'
  }
  return statusMap[status] || 'info'
}

const getServiceStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    healthy: 'success',
    warning: 'warning',
    error: 'danger'
  }
  return statusMap[status] || 'info'
}

const getServiceStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    healthy: '正常',
    warning: '警告',
    error: '错误'
  }
  return statusMap[status] || '未知'
}

const getAlertLevelType = (level: string) => {
  const levelMap: Record<string, string> = {
    critical: 'danger',
    warning: 'warning',
    info: 'info'
  }
  return levelMap[level] || 'info'
}

const getAlertLevelText = (level: string) => {
  const levelMap: Record<string, string> = {
    critical: '严重',
    warning: '警告',
    info: '信息'
  }
  return levelMap[level] || '未知'
}

const getAlertStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    firing: 'danger',
    resolved: 'success'
  }
  return statusMap[status] || 'info'
}

const getAlertStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    firing: '活跃',
    resolved: '已解决'
  }
  return statusMap[status] || '未知'
}

const getLogLevelType = (level: string) => {
  const levelMap: Record<string, string> = {
    error: 'danger',
    warn: 'warning',
    info: 'info',
    debug: 'info'
  }
  return levelMap[level] || 'info'
}

// 初始化
onMounted(() => {
  fetchSystemStatus()
  fetchSystemMetrics()
  fetchServiceList()
  fetchAlertList()
  fetchRuleList()
  fetchLogList()
  fetchPerformanceMetrics()
})
</script>

<style lang="scss" scoped>
.monitoring-page {
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
  
  .status-overview {
    margin-bottom: 20px;
  }
  
  .main-tabs {
    .chart-card {
      .card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
    }
    
    .service-status {
      .service-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 12px 0;
        border-bottom: 1px solid #f0f0f0;
        
        &:last-child {
          border-bottom: none;
        }
        
        .service-info {
          .service-name {
            font-weight: 500;
            margin-bottom: 4px;
          }
          
          .service-description {
            color: #666;
            font-size: 14px;
          }
        }
        
        .service-status-indicator {
          text-align: right;
          
          .service-uptime {
            color: #999;
            font-size: 12px;
            margin-top: 4px;
          }
        }
      }
    }
    
    .metric-card {
      .metric-content {
        .metric-details {
          display: flex;
          justify-content: space-between;
          margin-top: 12px;
          font-size: 14px;
          color: #666;
        }
      }
    }
    
    .alerts-card {
      .card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        
        .header-actions {
          display: flex;
          gap: 12px;
          align-items: center;
        }
      }
    }
    
    .rules-card {
      .card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
    }
    
    .logs-card {
      .card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        
        .header-actions {
          display: flex;
          gap: 12px;
          align-items: center;
        }
      }
    }
    
    .performance-ranking {
      .ranking-item {
        display: flex;
        align-items: center;
        padding: 12px 0;
        border-bottom: 1px solid #f0f0f0;
        
        &:last-child {
          border-bottom: none;
        }
        
        .ranking-number {
          width: 24px;
          height: 24px;
          border-radius: 50%;
          background: #409eff;
          color: white;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 12px;
          font-weight: bold;
          margin-right: 12px;
        }
        
        .ranking-content {
          flex: 1;
          
          .ranking-name {
            font-weight: 500;
            margin-bottom: 4px;
          }
          
          .ranking-method {
            color: #666;
            font-size: 12px;
          }
        }
        
        .ranking-metrics {
          text-align: right;
          
          .metric-item {
            margin-bottom: 4px;
            
            .metric-label {
              color: #666;
              font-size: 12px;
              margin-right: 8px;
            }
            
            .metric-value {
              color: #333;
              font-weight: 500;
            }
          }
        }
      }
    }
  }
  
  .alert-detail {
    .alert-labels {
      margin-bottom: 16px;
    }
  }
  
  .log-message {
    display: inline-block;
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
}
</style>
