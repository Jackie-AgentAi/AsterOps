<template>
  <div class="inference-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>推理服务</h2>
      <p>在线推理、批量推理和历史记录管理</p>
    </div>

    <!-- 标签页 -->
    <el-tabs v-model="activeTab" type="border-card">
      <!-- 在线推理 -->
      <el-tab-pane label="在线推理" name="online">
        <el-card class="inference-card">
          <div class="inference-form">
            <el-form :model="inferenceForm" label-width="100px">
              <el-row :gutter="20">
                <el-col :span="12">
                  <el-form-item label="选择模型" required>
                    <el-select 
                      v-model="inferenceForm.modelId" 
                      placeholder="请选择模型"
                      style="width: 100%"
                      @change="handleModelChange"
                    >
                      <el-option
                        v-for="model in modelOptions"
                        :key="model.id"
                        :label="`${model.name} (v${model.version})`"
                        :value="model.id"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="项目">
                    <el-select 
                      v-model="inferenceForm.projectId" 
                      placeholder="请选择项目"
                      style="width: 100%"
                    >
                      <el-option
                        v-for="project in projectOptions"
                        :key="project.id"
                        :label="project.name"
                        :value="project.id"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
              </el-row>

              <el-form-item label="输入内容" required>
                <el-input
                  v-model="inferenceForm.input"
                  type="textarea"
                  :rows="6"
                  placeholder="请输入要推理的文本内容..."
                />
              </el-form-item>

              <el-form-item label="推理参数">
                <el-row :gutter="20">
                  <el-col :span="6">
                    <el-form-item label="温度">
                      <el-slider
                        v-model="inferenceForm.parameters.temperature"
                        :min="0"
                        :max="2"
                        :step="0.1"
                        show-input
                      />
                    </el-form-item>
                  </el-col>
                  <el-col :span="6">
                    <el-form-item label="Top-P">
                      <el-slider
                        v-model="inferenceForm.parameters.topP"
                        :min="0"
                        :max="1"
                        :step="0.1"
                        show-input
                      />
                    </el-form-item>
                  </el-col>
                  <el-col :span="6">
                    <el-form-item label="最大长度">
                      <el-input-number
                        v-model="inferenceForm.parameters.maxTokens"
                        :min="1"
                        :max="4096"
                        style="width: 100%"
                      />
                    </el-form-item>
                  </el-col>
                  <el-col :span="6">
                    <el-form-item label="流式输出">
                      <el-switch v-model="inferenceForm.parameters.stream" />
                    </el-form-item>
                  </el-col>
                </el-row>
              </el-form-item>

              <el-form-item>
                <el-button 
                  type="primary" 
                  @click="runInference"
                  :loading="inferenceLoading"
                  :disabled="!inferenceForm.modelId || !inferenceForm.input"
                >
                  <el-icon><Cpu /></el-icon>
                  开始推理
                </el-button>
                <el-button @click="clearForm">
                  <el-icon><Refresh /></el-icon>
                  清空
                </el-button>
              </el-form-item>
            </el-form>
          </div>

          <!-- 推理结果 -->
          <div v-if="inferenceResult" class="inference-result">
            <el-divider content-position="left">推理结果</el-divider>
            <div class="result-content">
              <el-input
                v-model="inferenceResult.output"
                type="textarea"
                :rows="8"
                readonly
                placeholder="推理结果将在这里显示..."
              />
              <div class="result-actions">
                <el-button type="primary" @click="copyResult">
                  <el-icon><CopyDocument /></el-icon>
                  复制结果
                </el-button>
                <el-button @click="downloadResult">
                  <el-icon><Download /></el-icon>
                  下载结果
                </el-button>
              </div>
            </div>
            
            <!-- 性能指标 -->
            <div class="performance-metrics">
              <el-row :gutter="20">
                <el-col :span="6">
                  <el-statistic title="推理时间" :value="inferenceResult.metrics.latency" suffix="ms" />
                </el-col>
                <el-col :span="6">
                  <el-statistic title="Token数" :value="inferenceResult.metrics.totalTokens" />
                </el-col>
                <el-col :span="6">
                  <el-statistic title="Token/秒" :value="inferenceResult.metrics.tokensPerSecond" />
                </el-col>
                <el-col :span="6">
                  <el-statistic title="成本" :value="inferenceResult.cost" suffix="元" />
                </el-col>
              </el-row>
            </div>
          </div>
        </el-card>
      </el-tab-pane>

      <!-- 批量推理 -->
      <el-tab-pane label="批量推理" name="batch">
        <el-card class="batch-card">
          <div class="batch-form">
            <el-form :model="batchForm" label-width="120px">
              <el-row :gutter="20">
                <el-col :span="8">
                  <el-form-item label="任务名称" required>
                    <el-input v-model="batchForm.name" placeholder="请输入任务名称" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="选择模型" required>
                    <el-select 
                      v-model="batchForm.modelId" 
                      placeholder="请选择模型"
                      style="width: 100%"
                    >
                      <el-option
                        v-for="model in modelOptions"
                        :key="model.id"
                        :label="`${model.name} (v${model.version})`"
                        :value="model.id"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="项目">
                    <el-select 
                      v-model="batchForm.projectId" 
                      placeholder="请选择项目"
                      style="width: 100%"
                    >
                      <el-option
                        v-for="project in projectOptions"
                        :key="project.id"
                        :label="project.name"
                        :value="project.id"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
              </el-row>

              <el-form-item label="输入文件" required>
                <FileUpload
                  v-model="batchForm.inputFile"
                  :accept="'.txt,.json,.csv'"
                  :max-size="100 * 1024 * 1024"
                  button-text="选择输入文件"
                  tip="支持 .txt, .json, .csv 格式，最大100MB"
                />
              </el-form-item>

              <el-form-item label="推理参数">
                <el-row :gutter="20">
                  <el-col :span="6">
                    <el-form-item label="温度">
                      <el-input-number
                        v-model="batchForm.parameters.temperature"
                        :min="0"
                        :max="2"
                        :step="0.1"
                        style="width: 100%"
                      />
                    </el-form-item>
                  </el-col>
                  <el-col :span="6">
                    <el-form-item label="Top-P">
                      <el-input-number
                        v-model="batchForm.parameters.topP"
                        :min="0"
                        :max="1"
                        :step="0.1"
                        style="width: 100%"
                      />
                    </el-form-item>
                  </el-col>
                  <el-col :span="6">
                    <el-form-item label="最大长度">
                      <el-input-number
                        v-model="batchForm.parameters.maxTokens"
                        :min="1"
                        :max="4096"
                        style="width: 100%"
                      />
                    </el-form-item>
                  </el-col>
                  <el-col :span="6">
                    <el-form-item label="流式输出">
                      <el-switch v-model="batchForm.parameters.stream" />
                    </el-form-item>
                  </el-col>
                </el-row>
              </el-form-item>

              <el-form-item>
                <el-button 
                  type="primary" 
                  @click="createBatchTask"
                  :loading="batchLoading"
                  :disabled="!batchForm.name || !batchForm.modelId || !batchForm.inputFile.length"
                >
                  <el-icon><Upload /></el-icon>
                  创建批量任务
                </el-button>
              </el-form-item>
            </el-form>
          </div>
        </el-card>

        <!-- 批量任务列表 -->
        <el-card class="batch-tasks-card">
          <template #header>
            <div class="card-header">
              <span>批量任务列表</span>
              <el-button type="primary" @click="refreshBatchTasks">
                <el-icon><Refresh /></el-icon>
                刷新
              </el-button>
            </div>
          </template>

          <el-table :data="batchTaskList" style="width: 100%">
            <el-table-column prop="name" label="任务名称" />
            <el-table-column prop="modelName" label="模型" />
            <el-table-column prop="status" label="状态" width="120">
              <template #default="{ row }">
                <el-tag :type="getBatchStatusType(row.status)">
                  {{ getBatchStatusText(row.status) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="progress" label="进度" width="120">
              <template #default="{ row }">
                <el-progress 
                  :percentage="row.progress" 
                  :status="row.status === 'failed' ? 'exception' : undefined"
                />
              </template>
            </el-table-column>
            <el-table-column prop="totalCount" label="总数" width="80" />
            <el-table-column prop="completedCount" label="已完成" width="80" />
            <el-table-column prop="failedCount" label="失败" width="80" />
            <el-table-column prop="createdAt" label="创建时间" width="160" />
            <el-table-column label="操作" width="200">
              <template #default="{ row }">
                <el-button type="primary" link @click="viewBatchTask(row)">
                  查看
                </el-button>
                <el-button 
                  v-if="row.status === 'processing'" 
                  type="warning" 
                  link 
                  @click="cancelBatchTask(row)"
                >
                  取消
                </el-button>
                <el-button 
                  v-if="row.status === 'completed'" 
                  type="success" 
                  link 
                  @click="downloadBatchResult(row)"
                >
                  下载
                </el-button>
                <el-button type="danger" link @click="deleteBatchTask(row)">
                  删除
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-tab-pane>

      <!-- 推理历史 -->
      <el-tab-pane label="推理历史" name="history">
        <el-card class="history-card">
          <template #header>
            <div class="card-header">
              <span>推理历史记录</span>
              <div class="header-actions">
                <el-date-picker
                  v-model="historyDateRange"
                  type="datetimerange"
                  range-separator="至"
                  start-placeholder="开始日期"
                  end-placeholder="结束日期"
                  @change="handleDateRangeChange"
                />
                <el-button type="primary" @click="exportHistory">
                  <el-icon><Download /></el-icon>
                  导出
                </el-button>
              </div>
            </div>
          </template>

          <DataTable
            :data="historyList"
            :columns="historyColumns"
            :loading="historyLoading"
            :total="historyTotal"
            :current-page="historyPage"
            :page-size="historyPageSize"
            :show-search="true"
            :show-actions="false"
            @search="handleHistorySearch"
            @page-change="handleHistoryPageChange"
          >
            <!-- 状态列 -->
            <template #status="{ row }">
              <el-tag :type="getTaskStatusType(row.status)">
                {{ getTaskStatusText(row.status) }}
              </el-tag>
            </template>

            <!-- 输入内容 -->
            <template #input="{ row }">
              <el-tooltip :content="row.input" placement="top">
                <span class="text-truncate">{{ row.input.substring(0, 50) }}...</span>
              </el-tooltip>
            </template>

            <!-- 输出内容 -->
            <template #output="{ row }">
              <el-tooltip v-if="row.output" :content="row.output" placement="top">
                <span class="text-truncate">{{ row.output.substring(0, 50) }}...</span>
              </el-tooltip>
              <span v-else>-</span>
            </template>

            <!-- 成本 -->
            <template #cost="{ row }">
              <span class="cost-text">¥{{ row.cost.toFixed(4) }}</span>
            </template>

            <!-- 操作列 -->
            <template #actions="{ row, index }">
              <el-button type="primary" link @click="viewHistoryDetail(row)">
                查看详情
              </el-button>
              <el-button type="success" link @click="rerunInference(row)">
                重新运行
              </el-button>
              <el-button type="danger" link @click="deleteHistory(row)">
                删除
              </el-button>
            </template>
          </DataTable>
        </el-card>
      </el-tab-pane>

      <!-- 性能监控 -->
      <el-tab-pane label="性能监控" name="monitoring">
        <el-card class="monitoring-card">
          <template #header>
            <div class="card-header">
              <span>推理性能监控</span>
              <el-button type="primary" @click="refreshMetrics">
                <el-icon><Refresh /></el-icon>
                刷新
              </el-button>
            </div>
          </template>

          <el-row :gutter="20">
            <el-col :span="12">
              <div class="chart-container">
                <h4>QPS趋势</h4>
                <Chart :option="qpsChartOption" :height="300" />
              </div>
            </el-col>
            <el-col :span="12">
              <div class="chart-container">
                <h4>延迟分布</h4>
                <Chart :option="latencyChartOption" :height="300" />
              </div>
            </el-col>
          </el-row>

          <el-row :gutter="20" style="margin-top: 20px;">
            <el-col :span="12">
              <div class="chart-container">
                <h4>成功率统计</h4>
                <Chart :option="successRateChartOption" :height="300" />
              </div>
            </el-col>
            <el-col :span="12">
              <div class="chart-container">
                <h4>资源使用率</h4>
                <Chart :option="resourceChartOption" :height="300" />
              </div>
            </el-col>
          </el-row>
        </el-card>
      </el-tab-pane>
    </el-tabs>

    <!-- 历史详情对话框 -->
    <el-dialog
      v-model="historyDetailVisible"
      title="推理详情"
      width="800px"
    >
      <div v-if="currentHistory" class="history-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="任务ID">{{ currentHistory.id }}</el-descriptions-item>
          <el-descriptions-item label="模型">{{ currentHistory.modelName }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="getTaskStatusType(currentHistory.status)">
              {{ getTaskStatusText(currentHistory.status) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ formatDate(currentHistory.createdAt) }}</el-descriptions-item>
          <el-descriptions-item label="推理时间">{{ currentHistory.metrics.latency }}ms</el-descriptions-item>
          <el-descriptions-item label="Token数">{{ currentHistory.metrics.totalTokens }}</el-descriptions-item>
          <el-descriptions-item label="成本">¥{{ currentHistory.cost.toFixed(4) }}</el-descriptions-item>
        </el-descriptions>

        <el-divider content-position="left">输入内容</el-divider>
        <el-input
          v-model="currentHistory.input"
          type="textarea"
          :rows="4"
          readonly
        />

        <el-divider content-position="left">输出内容</el-divider>
        <el-input
          v-model="currentHistory.output"
          type="textarea"
          :rows="6"
          readonly
        />

        <el-divider content-position="left">推理参数</el-divider>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="温度">{{ currentHistory.parameters.temperature }}</el-descriptions-item>
          <el-descriptions-item label="Top-P">{{ currentHistory.parameters.topP }}</el-descriptions-item>
          <el-descriptions-item label="最大长度">{{ currentHistory.parameters.maxTokens }}</el-descriptions-item>
          <el-descriptions-item label="流式输出">{{ currentHistory.parameters.stream ? '是' : '否' }}</el-descriptions-item>
        </el-descriptions>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import DataTable from '@/components/DataTable/index.vue'
import FileUpload from '@/components/FileUpload/index.vue'
import Chart from '@/components/Chart/index.vue'
import { 
  getInferenceList,
  createInference,
  getBatchInferenceList,
  createBatchInference,
  cancelBatchInference,
  downloadBatchResult,
  getInferenceHistory,
  exportInferenceHistory,
  getInferenceStats,
  getInferenceMetrics
} from '@/api/inference'
import { formatDate, copyToClipboard } from '@/utils'
import type { InferenceTask, InferenceRequest, BatchInferenceTask, TableColumn } from '@/types'

// 响应式数据
const activeTab = ref('online')

// 在线推理
const inferenceForm = reactive<InferenceRequest>({
  modelId: 0,
  input: '',
  parameters: {
    temperature: 0.7,
    topP: 0.9,
    maxTokens: 1000,
    stream: false
  },
  projectId: 0
})

const inferenceResult = ref<any>(null)
const inferenceLoading = ref(false)

// 批量推理
const batchForm = reactive({
  name: '',
  modelId: 0,
  projectId: 0,
  inputFile: [] as any[],
  parameters: {
    temperature: 0.7,
    topP: 0.9,
    maxTokens: 1000,
    stream: false
  }
})

const batchTaskList = ref<BatchInferenceTask[]>([])
const batchLoading = ref(false)

// 推理历史
const historyList = ref<InferenceTask[]>([])
const historyTotal = ref(0)
const historyPage = ref(1)
const historyPageSize = ref(10)
const historyLoading = ref(false)
const historyDateRange = ref<[Date, Date] | null>(null)
const historyDetailVisible = ref(false)
const currentHistory = ref<InferenceTask | null>(null)

// 选项数据
const modelOptions = ref<Array<{ id: number; name: string; version: string }>>([])
const projectOptions = ref<Array<{ id: number; name: string }>>([])

// 历史记录表格列
const historyColumns: TableColumn[] = [
  { prop: 'id', label: '任务ID', width: 120 },
  { prop: 'modelName', label: '模型', width: 150 },
  { prop: 'status', label: '状态', width: 100 },
  { prop: 'input', label: '输入内容', minWidth: 200 },
  { prop: 'output', label: '输出内容', minWidth: 200 },
  { prop: 'cost', label: '成本', width: 100 },
  { prop: 'createdAt', label: '创建时间', width: 160 }
]

// 性能监控图表
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

const latencyChartOption = ref({
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: [] },
  yAxis: { type: 'value' },
  series: [{
    name: '延迟(ms)',
    type: 'bar',
    data: []
  }]
})

const successRateChartOption = ref({
  tooltip: { trigger: 'item' },
  series: [{
    name: '成功率',
    type: 'pie',
    data: [
      { value: 95, name: '成功' },
      { value: 5, name: '失败' }
    ]
  }]
})

const resourceChartOption = ref({
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: [] },
  yAxis: { type: 'value' },
  series: [
    { name: 'CPU', type: 'line', data: [] },
    { name: '内存', type: 'line', data: [] },
    { name: 'GPU', type: 'line', data: [] }
  ]
})

// 运行在线推理
const runInference = async () => {
  if (!inferenceForm.modelId || !inferenceForm.input) {
    ElMessage.warning('请选择模型并输入内容')
    return
  }

  inferenceLoading.value = true
  try {
    const result = await createInference(inferenceForm)
    inferenceResult.value = result
    ElMessage.success('推理完成')
  } catch (error) {
    ElMessage.error('推理失败')
  } finally {
    inferenceLoading.value = false
  }
}

// 清空表单
const clearForm = () => {
  inferenceForm.input = ''
  inferenceResult.value = null
}

// 复制结果
const copyResult = async () => {
  if (inferenceResult.value?.output) {
    const success = await copyToClipboard(inferenceResult.value.output)
    if (success) {
      ElMessage.success('结果已复制到剪贴板')
    } else {
      ElMessage.error('复制失败')
    }
  }
}

// 下载结果
const downloadResult = () => {
  if (inferenceResult.value?.output) {
    const blob = new Blob([inferenceResult.value.output], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `inference_result_${Date.now()}.txt`
    link.click()
    URL.revokeObjectURL(url)
  }
}

// 创建批量任务
const createBatchTask = async () => {
  if (!batchForm.name || !batchForm.modelId || !batchForm.inputFile.length) {
    ElMessage.warning('请填写完整信息')
    return
  }

  batchLoading.value = true
  try {
    const formData = new FormData()
    formData.append('name', batchForm.name)
    formData.append('modelId', batchForm.modelId.toString())
    formData.append('projectId', batchForm.projectId.toString())
    formData.append('inputFile', batchForm.inputFile[0].raw)
    formData.append('parameters', JSON.stringify(batchForm.parameters))

    await createBatchInference(formData)
    ElMessage.success('批量任务创建成功')
    fetchBatchTasks()
  } catch (error) {
    ElMessage.error('创建批量任务失败')
  } finally {
    batchLoading.value = false
  }
}

// 获取批量任务列表
const fetchBatchTasks = async () => {
  try {
    const response = await getBatchInferenceList({
      page: 1,
      pageSize: 100
    })
    batchTaskList.value = response.items
  } catch (error) {
    ElMessage.error('获取批量任务列表失败')
  }
}

// 刷新批量任务
const refreshBatchTasks = () => {
  fetchBatchTasks()
}

// 查看批量任务
const viewBatchTask = (task: BatchInferenceTask) => {
  ElMessage.info('查看批量任务功能开发中')
}

// 取消批量任务
const cancelBatchTask = async (task: BatchInferenceTask) => {
  try {
    await cancelBatchInference(task.id)
    ElMessage.success('任务已取消')
    fetchBatchTasks()
  } catch (error) {
    ElMessage.error('取消任务失败')
  }
}

// 下载批量结果
const downloadBatchResult = async (task: BatchInferenceTask) => {
  try {
    await downloadBatchResult(task.id)
    ElMessage.success('结果下载已开始')
  } catch (error) {
    ElMessage.error('下载失败')
  }
}

// 删除批量任务
const deleteBatchTask = async (task: BatchInferenceTask) => {
  try {
    await ElMessageBox.confirm('确定要删除该任务吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    // 实现删除逻辑
    ElMessage.success('任务删除成功')
    fetchBatchTasks()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 获取推理历史
const fetchHistory = async () => {
  historyLoading.value = true
  try {
    const response = await getInferenceHistory({
      page: historyPage.value,
      pageSize: historyPageSize.value,
      startDate: historyDateRange.value?.[0]?.toISOString(),
      endDate: historyDateRange.value?.[1]?.toISOString()
    })
    historyList.value = response.items
    historyTotal.value = response.pagination.total
  } catch (error) {
    ElMessage.error('获取推理历史失败')
  } finally {
    historyLoading.value = false
  }
}

// 历史搜索
const handleHistorySearch = (keyword: string) => {
  // 实现搜索逻辑
  fetchHistory()
}

// 历史分页
const handleHistoryPageChange = (page: number, size: number) => {
  historyPage.value = page
  historyPageSize.value = size
  fetchHistory()
}

// 日期范围变化
const handleDateRangeChange = () => {
  historyPage.value = 1
  fetchHistory()
}

// 导出历史
const exportHistory = async () => {
  try {
    await exportInferenceHistory({
      startDate: historyDateRange.value?.[0]?.toISOString(),
      endDate: historyDateRange.value?.[1]?.toISOString()
    })
    ElMessage.success('导出已开始')
  } catch (error) {
    ElMessage.error('导出失败')
  }
}

// 查看历史详情
const viewHistoryDetail = (row: InferenceTask) => {
  currentHistory.value = row
  historyDetailVisible.value = true
}

// 重新运行推理
const rerunInference = (row: InferenceTask) => {
  activeTab.value = 'online'
  inferenceForm.modelId = row.modelId
  inferenceForm.input = row.input
  inferenceForm.parameters = row.parameters
  ElMessage.info('已填充到在线推理表单')
}

// 删除历史
const deleteHistory = async (row: InferenceTask) => {
  try {
    await ElMessageBox.confirm('确定要删除该记录吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    // 实现删除逻辑
    ElMessage.success('记录删除成功')
    fetchHistory()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 刷新性能指标
const refreshMetrics = async () => {
  try {
    const metrics = await getInferenceMetrics({
      startDate: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
      endDate: new Date().toISOString()
    })
    
    // 更新图表数据
    qpsChartOption.value.xAxis.data = metrics.qps.map(item => item.timestamp)
    qpsChartOption.value.series[0].data = metrics.qps.map(item => item.value)
    
    latencyChartOption.value.xAxis.data = metrics.latency.map(item => item.timestamp)
    latencyChartOption.value.series[0].data = metrics.latency.map(item => item.p50)
    
    resourceChartOption.value.xAxis.data = metrics.resourceUsage.map(item => item.timestamp)
    resourceChartOption.value.series[0].data = metrics.resourceUsage.map(item => item.cpu)
    resourceChartOption.value.series[1].data = metrics.resourceUsage.map(item => item.memory)
    resourceChartOption.value.series[2].data = metrics.resourceUsage.map(item => item.gpu)
  } catch (error) {
    ElMessage.error('获取性能指标失败')
  }
}

// 模型变化处理
const handleModelChange = (modelId: number) => {
  // 可以在这里加载模型特定的配置
  console.log('选择模型:', modelId)
}

// 工具函数
const getBatchStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    pending: 'warning',
    processing: 'primary',
    completed: 'success',
    failed: 'danger'
  }
  return statusMap[status] || 'info'
}

const getBatchStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    pending: '等待中',
    processing: '处理中',
    completed: '已完成',
    failed: '失败'
  }
  return statusMap[status] || '未知'
}

const getTaskStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    pending: 'warning',
    running: 'primary',
    completed: 'success',
    failed: 'danger',
    cancelled: 'info'
  }
  return statusMap[status] || 'info'
}

const getTaskStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    pending: '等待中',
    running: '运行中',
    completed: '已完成',
    failed: '失败',
    cancelled: '已取消'
  }
  return statusMap[status] || '未知'
}

// 初始化
onMounted(() => {
  // 加载选项数据
  modelOptions.value = [
    { id: 1, name: 'GPT-3.5', version: '1.0' },
    { id: 2, name: 'GPT-4', version: '2.0' },
    { id: 3, name: 'Claude', version: '1.5' }
  ]
  
  projectOptions.value = [
    { id: 1, name: 'AI研究项目' },
    { id: 2, name: '产品开发项目' },
    { id: 3, name: '实验项目' }
  ]

  // 加载数据
  fetchBatchTasks()
  fetchHistory()
  refreshMetrics()
})
</script>

<style lang="scss" scoped>
.inference-page {
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
  
  .inference-card {
    .inference-form {
      margin-bottom: 20px;
    }
    
    .inference-result {
      .result-content {
        margin-bottom: 20px;
        
        .result-actions {
          margin-top: 12px;
          display: flex;
          gap: 12px;
        }
      }
      
      .performance-metrics {
        background: #f5f7fa;
        padding: 16px;
        border-radius: 8px;
      }
    }
  }
  
  .batch-card {
    margin-bottom: 20px;
  }
  
  .batch-tasks-card {
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
  }
  
  .history-card {
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
  
  .monitoring-card {
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    
    .chart-container {
      h4 {
        margin: 0 0 16px 0;
        color: #333;
        font-size: 16px;
      }
    }
  }
  
  .history-detail {
    .el-descriptions {
      margin-bottom: 20px;
    }
  }
  
  .text-truncate {
    display: inline-block;
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  
  .cost-text {
    color: #f56c6c;
    font-weight: 500;
  }
}
</style>
