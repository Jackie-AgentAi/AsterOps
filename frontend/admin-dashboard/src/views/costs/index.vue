<template>
  <div class="costs-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>成本管理</h2>
      <p>成本分析、预算管理和账单管理</p>
    </div>

    <!-- 成本概览卡片 -->
    <el-row :gutter="20" class="overview-cards">
      <el-col :span="6">
        <StatusCard
          title="总成本"
          :value="costSummary.totalCost"
          unit="元"
          icon="Money"
          status="error"
          :trend="costSummary.costGrowth"
          :description="`较上月${costSummary.costGrowth > 0 ? '增长' : '下降'}${Math.abs(costSummary.costGrowth)}%`"
        />
      </el-col>
      
      <el-col :span="6">
        <StatusCard
          title="本月成本"
          :value="costSummary.monthlyCost"
          unit="元"
          icon="Calendar"
          status="warning"
          :trend="8.5"
          description="较上月增长8.5%"
        />
      </el-col>
      
      <el-col :span="6">
        <StatusCard
          title="今日成本"
          :value="costSummary.dailyCost"
          unit="元"
          icon="Timer"
          status="info"
          :trend="-2.3"
          description="较昨日下降2.3%"
        />
      </el-col>
      
      <el-col :span="6">
        <StatusCard
          title="预算使用率"
          :value="budgetUsageRate"
          unit="%"
          icon="PieChart"
          status="success"
          :show-progress="true"
          :progress="budgetUsageRate"
          description="本月预算使用情况"
        />
      </el-col>
    </el-row>

    <!-- 标签页 -->
    <el-tabs v-model="activeTab" type="border-card" class="main-tabs">
      <!-- 成本概览 -->
      <el-tab-pane label="成本概览" name="overview">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-card class="chart-card">
              <template #header>
                <div class="card-header">
                  <span>成本趋势</span>
                  <el-radio-group v-model="trendPeriod" @change="handleTrendPeriodChange">
                    <el-radio-button label="7d">近7天</el-radio-button>
                    <el-radio-button label="30d">近30天</el-radio-button>
                    <el-radio-button label="90d">近90天</el-radio-button>
                  </el-radio-group>
                </div>
              </template>
              <Chart :option="trendChartOption" :height="300" />
            </el-card>
          </el-col>
          
          <el-col :span="12">
            <el-card class="chart-card">
              <template #header>
                <div class="card-header">
                  <span>成本分布</span>
                  <el-radio-group v-model="distributionDimension" @change="handleDistributionChange">
                    <el-radio-button label="project">按项目</el-radio-button>
                    <el-radio-button label="user">按用户</el-radio-button>
                    <el-radio-button label="model">按模型</el-radio-button>
                  </el-radio-group>
                </div>
              </template>
              <Chart :option="distributionChartOption" :height="300" />
            </el-card>
          </el-col>
        </el-row>

        <el-row :gutter="20" style="margin-top: 20px;">
          <el-col :span="8">
            <el-card class="ranking-card">
              <template #header>
                <span>Top消费项目</span>
              </template>
              <div class="ranking-list">
                <div 
                  v-for="(item, index) in costSummary.topProjects" 
                  :key="item.projectId"
                  class="ranking-item"
                >
                  <div class="ranking-number">{{ index + 1 }}</div>
                  <div class="ranking-content">
                    <div class="ranking-name">{{ item.projectName }}</div>
                    <div class="ranking-value">¥{{ item.cost.toFixed(2) }}</div>
                  </div>
                  <div class="ranking-percentage">{{ item.percentage.toFixed(1) }}%</div>
                </div>
              </div>
            </el-card>
          </el-col>
          
          <el-col :span="8">
            <el-card class="ranking-card">
              <template #header>
                <span>Top消费用户</span>
              </template>
              <div class="ranking-list">
                <div 
                  v-for="(item, index) in costSummary.topUsers" 
                  :key="item.userId"
                  class="ranking-item"
                >
                  <div class="ranking-number">{{ index + 1 }}</div>
                  <div class="ranking-content">
                    <div class="ranking-name">{{ item.userName }}</div>
                    <div class="ranking-value">¥{{ item.cost.toFixed(2) }}</div>
                  </div>
                  <div class="ranking-percentage">{{ item.percentage.toFixed(1) }}%</div>
                </div>
              </div>
            </el-card>
          </el-col>
          
          <el-col :span="8">
            <el-card class="ranking-card">
              <template #header>
                <span>Top消费模型</span>
              </template>
              <div class="ranking-list">
                <div 
                  v-for="(item, index) in costSummary.topModels" 
                  :key="item.modelId"
                  class="ranking-item"
                >
                  <div class="ranking-number">{{ index + 1 }}</div>
                  <div class="ranking-content">
                    <div class="ranking-name">{{ item.modelName }}</div>
                    <div class="ranking-value">¥{{ item.cost.toFixed(2) }}</div>
                  </div>
                  <div class="ranking-percentage">{{ item.percentage.toFixed(1) }}%</div>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </el-tab-pane>

      <!-- 成本明细 -->
      <el-tab-pane label="成本明细" name="details">
        <el-card class="details-card">
          <template #header>
            <div class="card-header">
              <span>成本记录</span>
              <div class="header-actions">
                <el-date-picker
                  v-model="detailDateRange"
                  type="datetimerange"
                  range-separator="至"
                  start-placeholder="开始日期"
                  end-placeholder="结束日期"
                  @change="handleDetailDateChange"
                />
                <el-button type="primary" @click="exportCostDetails">
                  <el-icon><Download /></el-icon>
                  导出
                </el-button>
              </div>
            </div>
          </template>

          <DataTable
            :data="costList"
            :columns="costColumns"
            :loading="costLoading"
            :total="costTotal"
            :current-page="costPage"
            :page-size="costPageSize"
            :show-search="true"
            :show-actions="false"
            @search="handleCostSearch"
            @page-change="handleCostPageChange"
          >
            <!-- 成本类型 -->
            <template #type="{ row }">
              <el-tag :type="getCostTypeColor(row.type)">
                {{ getCostTypeText(row.type) }}
              </el-tag>
            </template>

            <!-- 总成本 -->
            <template #totalCost="{ row }">
              <span class="cost-amount">¥{{ row.totalCost.toFixed(4) }}</span>
            </template>

            <!-- 创建时间 -->
            <template #createdAt="{ row }">
              {{ formatDate(row.createdAt) }}
            </template>
          </DataTable>
        </el-card>
      </el-tab-pane>

      <!-- 预算管理 -->
      <el-tab-pane label="预算管理" name="budget">
        <el-card class="budget-card">
          <template #header>
            <div class="card-header">
              <span>预算配置</span>
              <el-button type="primary" @click="handleCreateBudget">
                <el-icon><Plus /></el-icon>
                创建预算
              </el-button>
            </div>
          </template>

          <el-table :data="budgetList" style="width: 100%">
            <el-table-column prop="name" label="预算名称" />
            <el-table-column prop="type" label="类型" width="120">
              <template #default="{ row }">
                <el-tag :type="getBudgetTypeColor(row.type)">
                  {{ getBudgetTypeText(row.type) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="targetName" label="目标" />
            <el-table-column prop="amount" label="预算金额" width="120">
              <template #default="{ row }">
                ¥{{ row.amount.toFixed(2) }}
              </template>
            </el-table-column>
            <el-table-column prop="usedAmount" label="已使用" width="120">
              <template #default="{ row }">
                ¥{{ row.usedAmount.toFixed(2) }}
              </template>
            </el-table-column>
            <el-table-column prop="remainingAmount" label="剩余" width="120">
              <template #default="{ row }">
                ¥{{ row.remainingAmount.toFixed(2) }}
              </template>
            </el-table-column>
            <el-table-column prop="usageRate" label="使用率" width="120">
              <template #default="{ row }">
                <el-progress 
                  :percentage="row.usageRate" 
                  :status="row.usageRate > 90 ? 'exception' : row.usageRate > 80 ? 'warning' : 'success'"
                />
              </template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="getBudgetStatusType(row.status)">
                  {{ getBudgetStatusText(row.status) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="200">
              <template #default="{ row }">
                <el-button type="primary" link @click="viewBudget(row)">
                  查看
                </el-button>
                <el-button type="primary" link @click="editBudget(row)">
                  编辑
                </el-button>
                <el-button type="danger" link @click="deleteBudget(row)">
                  删除
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-tab-pane>

      <!-- 成本分析 -->
      <el-tab-pane label="成本分析" name="analysis">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-card class="analysis-card">
              <template #header>
                <span>成本归因分析</span>
              </template>
              <div class="analysis-content">
                <div 
                  v-for="item in costAnalysis.costByType" 
                  :key="item.type"
                  class="analysis-item"
                >
                  <div class="analysis-label">{{ getCostTypeText(item.type) }}</div>
                  <div class="analysis-bar">
                    <div 
                      class="analysis-fill" 
                      :style="{ width: item.percentage + '%' }"
                    ></div>
                  </div>
                  <div class="analysis-value">
                    ¥{{ item.cost.toFixed(2) }} ({{ item.percentage.toFixed(1) }}%)
                  </div>
                </div>
              </div>
            </el-card>
          </el-col>
          
          <el-col :span="12">
            <el-card class="analysis-card">
              <template #header>
                <span>成本优化建议</span>
              </template>
              <div class="recommendations">
                <div 
                  v-for="(rec, index) in costAnalysis.recommendations" 
                  :key="index"
                  class="recommendation-item"
                  :class="`priority-${rec.priority}`"
                >
                  <div class="rec-header">
                    <el-tag :type="getPriorityType(rec.priority)" size="small">
                      {{ getPriorityText(rec.priority) }}
                    </el-tag>
                    <span class="rec-savings">可节省 ¥{{ rec.potentialSavings.toFixed(2) }}</span>
                  </div>
                  <div class="rec-title">{{ rec.title }}</div>
                  <div class="rec-description">{{ rec.description }}</div>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <el-row :gutter="20" style="margin-top: 20px;">
          <el-col :span="24">
            <el-card class="comparison-card">
              <template #header>
                <span>成本对比分析</span>
              </template>
              <Chart :option="comparisonChartOption" :height="400" />
            </el-card>
          </el-col>
        </el-row>
      </el-tab-pane>

      <!-- 账单管理 -->
      <el-tab-pane label="账单管理" name="bills">
        <el-card class="bills-card">
          <template #header>
            <div class="card-header">
              <span>账单列表</span>
              <el-button type="primary" @click="generateBill">
                <el-icon><Document /></el-icon>
                生成账单
              </el-button>
            </div>
          </template>

          <el-table :data="billList" style="width: 100%">
            <el-table-column prop="id" label="账单ID" width="120" />
            <el-table-column prop="period" label="账单周期" width="150" />
            <el-table-column prop="totalAmount" label="总金额" width="120">
              <template #default="{ row }">
                ¥{{ row.totalAmount.toFixed(2) }}
              </template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="getBillStatusType(row.status)">
                  {{ getBillStatusText(row.status) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createdAt" label="创建时间" width="160">
              <template #default="{ row }">
                {{ formatDate(row.createdAt) }}
              </template>
            </el-table-column>
            <el-table-column label="操作" width="200">
              <template #default="{ row }">
                <el-button type="primary" link @click="viewBill(row)">
                  查看详情
                </el-button>
                <el-button type="success" link @click="downloadBill(row)">
                  下载PDF
                </el-button>
                <el-button type="warning" link @click="applyInvoice(row)">
                  申请发票
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-tab-pane>
    </el-tabs>

    <!-- 创建预算对话框 -->
    <el-dialog
      v-model="budgetDialogVisible"
      :title="budgetDialogTitle"
      width="600px"
    >
      <el-form ref="budgetFormRef" :model="budgetForm" :rules="budgetRules" label-width="120px">
        <el-form-item label="预算名称" prop="name">
          <el-input v-model="budgetForm.name" />
        </el-form-item>
        
        <el-form-item label="预算类型" prop="type">
          <el-select v-model="budgetForm.type" style="width: 100%">
            <el-option label="项目预算" value="project" />
            <el-option label="用户预算" value="user" />
            <el-option label="全局预算" value="global" />
          </el-select>
        </el-form-item>
        
        <el-form-item label="目标" prop="targetId">
          <el-select v-model="budgetForm.targetId" style="width: 100%">
            <el-option label="全部项目" value="0" />
            <el-option 
              v-for="project in projectOptions" 
              :key="project.id" 
              :label="project.name" 
              :value="project.id" 
            />
          </el-select>
        </el-form-item>
        
        <el-form-item label="预算金额" prop="amount">
          <el-input-number 
            v-model="budgetForm.amount" 
            :min="0" 
            :precision="2"
            style="width: 100%"
          />
        </el-form-item>
        
        <el-form-item label="预算周期" prop="period">
          <el-select v-model="budgetForm.period" style="width: 100%">
            <el-option label="月度" value="monthly" />
            <el-option label="季度" value="quarterly" />
            <el-option label="年度" value="yearly" />
          </el-select>
        </el-form-item>
        
        <el-form-item label="告警阈值" prop="alertThreshold">
          <el-input-number 
            v-model="budgetForm.alertThreshold" 
            :min="0" 
            :max="100" 
            :precision="0"
            style="width: 100%"
          />
          <span class="form-tip">达到此百分比时发送告警</span>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="budgetDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleBudgetSubmit">确定</el-button>
      </template>
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
  getCostSummary,
  getCostTrend,
  getCostDistribution,
  getCostList,
  getBudgetList,
  createBudget,
  updateBudget,
  deleteBudget,
  getCostAnalysis,
  getBillList,
  generateBill,
  downloadBill
} from '@/api/cost'
import { formatDate } from '@/utils'
import type { CostSummary, CostRecord, Budget, BudgetForm, TableColumn } from '@/types'

// 响应式数据
const activeTab = ref('overview')
const trendPeriod = ref('30d')
const distributionDimension = ref('project')
const detailDateRange = ref<[Date, Date] | null>(null)

// 成本概览
const costSummary = ref<CostSummary>({
  totalCost: 0,
  monthlyCost: 0,
  dailyCost: 0,
  costGrowth: 0,
  topProjects: [],
  topUsers: [],
  topModels: []
})

const budgetUsageRate = computed(() => {
  return 75.5 // 模拟数据
})

// 成本明细
const costList = ref<CostRecord[]>([])
const costTotal = ref(0)
const costPage = ref(1)
const costPageSize = ref(10)
const costLoading = ref(false)

// 预算管理
const budgetList = ref<Budget[]>([])
const budgetDialogVisible = ref(false)
const budgetDialogTitle = ref('创建预算')
const budgetForm = reactive<BudgetForm>({
  name: '',
  type: 'project',
  targetId: 0,
  amount: 0,
  period: 'monthly',
  alertThreshold: 80
})

// 成本分析
const costAnalysis = ref({
  costByType: [],
  recommendations: []
})

// 账单管理
const billList = ref<any[]>([])

// 选项数据
const projectOptions = ref<Array<{ id: number; name: string }>>([])

// 图表配置
const trendChartOption = ref({
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: [] },
  yAxis: { type: 'value' },
  series: [{
    name: '成本',
    type: 'line',
    data: [],
    smooth: true,
    areaStyle: {}
  }]
})

const distributionChartOption = ref({
  tooltip: { trigger: 'item' },
  series: [{
    name: '成本分布',
    type: 'pie',
    data: []
  }]
})

const comparisonChartOption = ref({
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: [] },
  yAxis: { type: 'value' },
  series: [{
    name: '当前成本',
    type: 'bar',
    data: []
  }, {
    name: '优化后成本',
    type: 'bar',
    data: []
  }]
})

// 成本明细表格列
const costColumns: TableColumn[] = [
  { prop: 'id', label: 'ID', width: 80 },
  { prop: 'userName', label: '用户', width: 120 },
  { prop: 'projectName', label: '项目', width: 150 },
  { prop: 'modelName', label: '模型', width: 150 },
  { prop: 'type', label: '类型', width: 100 },
  { prop: 'amount', label: '数量', width: 100 },
  { prop: 'price', label: '单价', width: 100 },
  { prop: 'totalCost', label: '总成本', width: 120 },
  { prop: 'createdAt', label: '时间', width: 160 }
]

// 预算表单验证规则
const budgetRules = {
  name: [
    { required: true, message: '请输入预算名称', trigger: 'blur' }
  ],
  type: [
    { required: true, message: '请选择预算类型', trigger: 'change' }
  ],
  amount: [
    { required: true, message: '请输入预算金额', trigger: 'blur' }
  ],
  period: [
    { required: true, message: '请选择预算周期', trigger: 'change' }
  ]
}

// 获取成本概览
const fetchCostSummary = async () => {
  try {
    const response = await getCostSummary({
      startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
      endDate: new Date().toISOString()
    })
    costSummary.value = response
  } catch (error) {
    ElMessage.error('获取成本概览失败')
  }
}

// 获取成本趋势
const fetchCostTrend = async () => {
  try {
    const response = await getCostTrend({
      startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
      endDate: new Date().toISOString(),
      granularity: 'day'
    })
    
    trendChartOption.value.xAxis.data = response.map(item => item.date)
    trendChartOption.value.series[0].data = response.map(item => item.cost)
  } catch (error) {
    ElMessage.error('获取成本趋势失败')
  }
}

// 获取成本分布
const fetchCostDistribution = async () => {
  try {
    const response = await getCostDistribution({
      startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
      endDate: new Date().toISOString(),
      dimension: distributionDimension.value
    })
    
    distributionChartOption.value.series[0].data = response.map(item => ({
      name: item.name,
      value: item.value
    }))
  } catch (error) {
    ElMessage.error('获取成本分布失败')
  }
}

// 获取成本明细
const fetchCostList = async () => {
  costLoading.value = true
  try {
    const response = await getCostList({
      page: costPage.value,
      pageSize: costPageSize.value,
      startDate: detailDateRange.value?.[0]?.toISOString(),
      endDate: detailDateRange.value?.[1]?.toISOString()
    })
    costList.value = response.items
    costTotal.value = response.pagination.total
  } catch (error) {
    ElMessage.error('获取成本明细失败')
  } finally {
    costLoading.value = false
  }
}

// 获取预算列表
const fetchBudgetList = async () => {
  try {
    const response = await getBudgetList()
    budgetList.value = response
  } catch (error) {
    ElMessage.error('获取预算列表失败')
  }
}

// 获取成本分析
const fetchCostAnalysis = async () => {
  try {
    const response = await getCostAnalysis({
      startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
      endDate: new Date().toISOString()
    })
    costAnalysis.value = response
  } catch (error) {
    ElMessage.error('获取成本分析失败')
  }
}

// 获取账单列表
const fetchBillList = async () => {
  try {
    const response = await getBillList({ page: 1, pageSize: 100 })
    billList.value = response.items
  } catch (error) {
    ElMessage.error('获取账单列表失败')
  }
}

// 事件处理
const handleTrendPeriodChange = () => {
  fetchCostTrend()
}

const handleDistributionChange = () => {
  fetchCostDistribution()
}

const handleDetailDateChange = () => {
  costPage.value = 1
  fetchCostList()
}

const handleCostSearch = (keyword: string) => {
  // 实现搜索逻辑
  fetchCostList()
}

const handleCostPageChange = (page: number, size: number) => {
  costPage.value = page
  costPageSize.value = size
  fetchCostList()
}

const handleCreateBudget = () => {
  budgetDialogTitle.value = '创建预算'
  Object.assign(budgetForm, {
    name: '',
    type: 'project',
    targetId: 0,
    amount: 0,
    period: 'monthly',
    alertThreshold: 80
  })
  budgetDialogVisible.value = true
}

const editBudget = (budget: Budget) => {
  budgetDialogTitle.value = '编辑预算'
  Object.assign(budgetForm, {
    name: budget.name,
    type: budget.type,
    targetId: budget.targetId,
    amount: budget.amount,
    period: budget.period,
    alertThreshold: budget.alertThreshold
  })
  budgetDialogVisible.value = true
}

const viewBudget = (budget: Budget) => {
  ElMessage.info('查看预算详情功能开发中')
}

const deleteBudget = async (budget: Budget) => {
  try {
    await ElMessageBox.confirm('确定要删除该预算吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await deleteBudget(budget.id)
    ElMessage.success('预算删除成功')
    fetchBudgetList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

const handleBudgetSubmit = async () => {
  try {
    if (budgetForm.name && budgetForm.amount > 0) {
      await createBudget(budgetForm)
      ElMessage.success('预算创建成功')
      budgetDialogVisible.value = false
      fetchBudgetList()
    }
  } catch (error) {
    ElMessage.error('预算创建失败')
  }
}

const generateBill = async () => {
  try {
    await generateBill({
      startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
      endDate: new Date().toISOString()
    })
    ElMessage.success('账单生成成功')
    fetchBillList()
  } catch (error) {
    ElMessage.error('账单生成失败')
  }
}

const viewBill = (bill: any) => {
  ElMessage.info('查看账单详情功能开发中')
}

const downloadBill = async (bill: any) => {
  try {
    await downloadBill(bill.id)
    ElMessage.success('账单下载已开始')
  } catch (error) {
    ElMessage.error('下载失败')
  }
}

const applyInvoice = (bill: any) => {
  ElMessage.info('申请发票功能开发中')
}

const exportCostDetails = () => {
  ElMessage.info('导出功能开发中')
}

// 工具函数
const getCostTypeColor = (type: string) => {
  const typeMap: Record<string, string> = {
    inference: 'primary',
    training: 'success',
    storage: 'warning',
    compute: 'info'
  }
  return typeMap[type] || 'info'
}

const getCostTypeText = (type: string) => {
  const typeMap: Record<string, string> = {
    inference: '推理',
    training: '训练',
    storage: '存储',
    compute: '计算'
  }
  return typeMap[type] || '未知'
}

const getBudgetTypeColor = (type: string) => {
  const typeMap: Record<string, string> = {
    project: 'primary',
    user: 'success',
    global: 'warning'
  }
  return typeMap[type] || 'info'
}

const getBudgetTypeText = (type: string) => {
  const typeMap: Record<string, string> = {
    project: '项目预算',
    user: '用户预算',
    global: '全局预算'
  }
  return typeMap[type] || '未知'
}

const getBudgetStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    active: 'success',
    exceeded: 'danger',
    expired: 'info'
  }
  return statusMap[status] || 'info'
}

const getBudgetStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    active: '活跃',
    exceeded: '超支',
    expired: '过期'
  }
  return statusMap[status] || '未知'
}

const getBillStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    pending: 'warning',
    paid: 'success',
    overdue: 'danger'
  }
  return statusMap[status] || 'info'
}

const getBillStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    pending: '待支付',
    paid: '已支付',
    overdue: '逾期'
  }
  return statusMap[status] || '未知'
}

const getPriorityType = (priority: string) => {
  const priorityMap: Record<string, string> = {
    high: 'danger',
    medium: 'warning',
    low: 'info'
  }
  return priorityMap[priority] || 'info'
}

const getPriorityText = (priority: string) => {
  const priorityMap: Record<string, string> = {
    high: '高',
    medium: '中',
    low: '低'
  }
  return priorityMap[priority] || '未知'
}

// 初始化
onMounted(() => {
  // 加载选项数据
  projectOptions.value = [
    { id: 1, name: 'AI研究项目' },
    { id: 2, name: '产品开发项目' },
    { id: 3, name: '实验项目' }
  ]

  // 加载数据
  fetchCostSummary()
  fetchCostTrend()
  fetchCostDistribution()
  fetchCostList()
  fetchBudgetList()
  fetchCostAnalysis()
  fetchBillList()
})
</script>

<style lang="scss" scoped>
.costs-page {
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
  
  .overview-cards {
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
    
    .ranking-card {
      .ranking-list {
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
            
            .ranking-value {
              color: #666;
              font-size: 14px;
            }
          }
          
          .ranking-percentage {
            color: #999;
            font-size: 12px;
          }
        }
      }
    }
    
    .details-card {
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
    
    .budget-card {
      .card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
    }
    
    .analysis-card {
      .analysis-content {
        .analysis-item {
          display: flex;
          align-items: center;
          margin-bottom: 16px;
          
          .analysis-label {
            width: 80px;
            font-size: 14px;
            color: #666;
          }
          
          .analysis-bar {
            flex: 1;
            height: 8px;
            background: #f0f0f0;
            border-radius: 4px;
            margin: 0 12px;
            overflow: hidden;
            
            .analysis-fill {
              height: 100%;
              background: linear-gradient(90deg, #409eff, #67c23a);
              transition: width 0.3s ease;
            }
          }
          
          .analysis-value {
            width: 120px;
            text-align: right;
            font-size: 14px;
            color: #333;
          }
        }
      }
      
      .recommendations {
        .recommendation-item {
          padding: 16px;
          border: 1px solid #e4e7ed;
          border-radius: 8px;
          margin-bottom: 12px;
          
          &.priority-high {
            border-left: 4px solid #f56c6c;
          }
          
          &.priority-medium {
            border-left: 4px solid #e6a23c;
          }
          
          &.priority-low {
            border-left: 4px solid #409eff;
          }
          
          .rec-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
            
            .rec-savings {
              color: #67c23a;
              font-weight: 500;
            }
          }
          
          .rec-title {
            font-weight: 500;
            margin-bottom: 4px;
          }
          
          .rec-description {
            color: #666;
            font-size: 14px;
            line-height: 1.4;
          }
        }
      }
    }
    
    .bills-card {
      .card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
    }
  }
  
  .cost-amount {
    color: #f56c6c;
    font-weight: 500;
  }
  
  .form-tip {
    color: #999;
    font-size: 12px;
    margin-left: 8px;
  }
}
</style>
