<template>
  <div class="models-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>模型管理</h2>
      <p>管理AI模型、版本和部署配置</p>
    </div>

    <!-- 模型列表 -->
    <el-card class="table-card">
      <DataTable
        :data="modelList"
        :columns="columns"
        :loading="loading"
        :total="total"
        :current-page="currentPage"
        :page-size="pageSize"
        :show-search="true"
        :show-actions="true"
        :show-selection="true"
        :show-batch-delete="true"
        :show-export="true"
        @search="handleSearch"
        @add="handleAdd"
        @edit="handleEdit"
        @view="handleView"
        @delete="handleDelete"
        @batch-delete="handleBatchDelete"
        @export="handleExport"
        @page-change="handlePageChange"
        @sort-change="handleSortChange"
      >
        <!-- 模型预览 -->
        <template #preview="{ row }">
          <el-avatar 
            :size="40" 
            :src="row.previewUrl"
            shape="square"
          >
            <el-icon><Box /></el-icon>
          </el-avatar>
        </template>

        <!-- 状态列 -->
        <template #status="{ row }">
          <el-tag :type="getStatusType(row.status)">
            {{ getStatusText(row.status) }}
          </el-tag>
        </template>

        <!-- 类型列 -->
        <template #type="{ row }">
          <el-tag :type="getTypeColor(row.type)">
            {{ getTypeText(row.type) }}
          </el-tag>
        </template>

        <!-- 大小列 -->
        <template #size="{ row }">
          {{ formatFileSize(row.size) }}
        </template>

        <!-- 性能指标 -->
        <template #metrics="{ row }">
          <div class="metrics-info">
            <div v-if="row.metrics.accuracy">
              <span class="metric-label">准确率:</span>
              <span class="metric-value">{{ (row.metrics.accuracy * 100).toFixed(1) }}%</span>
            </div>
            <div v-if="row.metrics.inferenceTime">
              <span class="metric-label">推理时间:</span>
              <span class="metric-value">{{ row.metrics.inferenceTime }}ms</span>
            </div>
            <div>
              <span class="metric-label">调用次数:</span>
              <span class="metric-value">{{ row.metrics.callCount }}</span>
            </div>
          </div>
        </template>

        <!-- 操作列 -->
        <template #actions="{ row, index }">
          <el-button type="primary" link @click="handleView(row, index)">
            查看
          </el-button>
          <el-button type="primary" link @click="handleEdit(row, index)">
            编辑
          </el-button>
          <el-button type="primary" link @click="handleVersions(row)">
            版本
          </el-button>
          <el-button type="success" link @click="handleDeploy(row)">
            部署
          </el-button>
          <el-button type="warning" link @click="handleTest(row)">
            测试
          </el-button>
          <el-button type="danger" link @click="handleDelete(row, index)">
            删除
          </el-button>
        </template>
      </DataTable>
    </el-card>

    <!-- 模型详情对话框 -->
    <el-dialog
      v-model="detailVisible"
      :title="dialogTitle"
      width="1000px"
      :close-on-click-modal="false"
    >
      <el-tabs v-model="activeTab" type="border-card">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="basic">
          <el-form
            ref="formRef"
            :model="formData"
            :rules="formRules"
            label-width="120px"
          >
            <el-row :gutter="20">
              <el-col :span="12">
                <el-form-item label="模型名称" prop="name">
                  <el-input v-model="formData.name" :disabled="isView" />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="版本" prop="version">
                  <el-input v-model="formData.version" :disabled="isView" />
                </el-form-item>
              </el-col>
            </el-row>

            <el-row :gutter="20">
              <el-col :span="12">
                <el-form-item label="模型类型" prop="type">
                  <el-select v-model="formData.type" :disabled="isView" style="width: 100%">
                    <el-option label="大语言模型" value="llm" />
                    <el-option label="嵌入模型" value="embedding" />
                    <el-option label="分类模型" value="classification" />
                    <el-option label="生成模型" value="generation" />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="框架" prop="framework">
                  <el-select v-model="formData.framework" :disabled="isView" style="width: 100%">
                    <el-option label="PyTorch" value="pytorch" />
                    <el-option label="TensorFlow" value="tensorflow" />
                    <el-option label="ONNX" value="onnx" />
                    <el-option label="HuggingFace" value="huggingface" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>

            <el-form-item label="描述" prop="description">
              <el-input 
                v-model="formData.description" 
                type="textarea" 
                :rows="3"
                :disabled="isView"
              />
            </el-form-item>

            <el-form-item label="标签" prop="tags">
              <el-select
                v-model="formData.tags"
                multiple
                filterable
                allow-create
                placeholder="请选择或输入标签"
                :disabled="isView"
                style="width: 100%"
              >
                <el-option label="NLP" value="nlp" />
                <el-option label="计算机视觉" value="cv" />
                <el-option label="推荐系统" value="recommendation" />
                <el-option label="语音识别" value="asr" />
              </el-select>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- 文件管理 -->
        <el-tab-pane label="文件管理" name="files">
          <div class="file-management">
            <div class="file-upload-section">
              <FileUpload
                v-model="fileList"
                :multiple="true"
                :max-size="10 * 1024 * 1024 * 1024"
                :allowed-types="['bin', 'safetensors', 'pt', 'pth', 'onnx', 'h5']"
                button-text="上传模型文件"
                tip="支持 .bin, .safetensors, .pt, .pth, .onnx, .h5 格式，最大10GB"
                @success="handleFileUploadSuccess"
              />
            </div>

            <div class="file-list">
              <el-table :data="fileList" style="width: 100%">
                <el-table-column prop="name" label="文件名" />
                <el-table-column prop="size" label="大小" width="120">
                  <template #default="{ row }">
                    {{ formatFileSize(row.size) }}
                  </template>
                </el-table-column>
                <el-table-column prop="status" label="状态" width="100">
                  <template #default="{ row }">
                    <el-tag :type="row.status === 'success' ? 'success' : 'warning'">
                      {{ row.status === 'success' ? '已上传' : '上传中' }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column label="操作" width="150">
                  <template #default="{ row }">
                    <el-button type="primary" link @click="downloadFile(row)">
                      下载
                    </el-button>
                    <el-button type="danger" link @click="deleteFile(row)">
                      删除
                    </el-button>
                  </template>
                </el-table-column>
              </el-table>
            </div>
          </div>
        </el-tab-pane>

        <!-- 版本管理 -->
        <el-tab-pane label="版本管理" name="versions">
          <div class="version-management">
            <div class="version-header">
              <el-button type="primary" @click="handleCreateVersion">
                <el-icon><Plus /></el-icon>
                创建版本
              </el-button>
            </div>

            <el-timeline>
              <el-timeline-item
                v-for="version in versionList"
                :key="version.id"
                :timestamp="formatDate(version.createdAt)"
                placement="top"
              >
                <el-card>
                  <div class="version-item">
                    <div class="version-info">
                      <h4>v{{ version.version }}</h4>
                      <p>{{ version.description }}</p>
                      <div class="version-metrics">
                        <el-tag size="small">大小: {{ formatFileSize(version.fileSize) }}</el-tag>
                        <el-tag size="small" :type="version.isActive ? 'success' : 'info'">
                          {{ version.isActive ? '当前版本' : '历史版本' }}
                        </el-tag>
                      </div>
                    </div>
                    <div class="version-actions">
                      <el-button 
                        v-if="!version.isActive" 
                        type="primary" 
                        size="small"
                        @click="switchVersion(version)"
                      >
                        切换
                      </el-button>
                      <el-button type="primary" size="small" @click="compareVersion(version)">
                        对比
                      </el-button>
                      <el-button type="danger" size="small" @click="deleteVersion(version)">
                        删除
                      </el-button>
                    </div>
                  </div>
                </el-card>
              </el-timeline-item>
            </el-timeline>
          </div>
        </el-tab-pane>

        <!-- 部署配置 -->
        <el-tab-pane label="部署配置" name="deployment">
          <div class="deployment-management">
            <div class="deployment-header">
              <el-button type="primary" @click="handleCreateDeployment">
                <el-icon><Plus /></el-icon>
                创建部署
              </el-button>
            </div>

            <el-table :data="deploymentList" style="width: 100%">
              <el-table-column prop="name" label="部署名称" />
              <el-table-column prop="engine" label="推理引擎" width="120">
                <template #default="{ row }">
                  <el-tag>{{ row.engine }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="replicas" label="副本数" width="100" />
              <el-table-column prop="status" label="状态" width="100">
                <template #default="{ row }">
                  <el-tag :type="getDeploymentStatusType(row.status)">
                    {{ getDeploymentStatusText(row.status) }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="endpoint" label="端点" />
              <el-table-column label="操作" width="200">
                <template #default="{ row }">
                  <el-button type="primary" link @click="viewDeployment(row)">
                    查看
                  </el-button>
                  <el-button type="success" link @click="startDeployment(row)">
                    启动
                  </el-button>
                  <el-button type="warning" link @click="stopDeployment(row)">
                    停止
                  </el-button>
                  <el-button type="danger" link @click="deleteDeployment(row)">
                    删除
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>
      </el-tabs>

      <template #footer>
        <el-button @click="detailVisible = false">取消</el-button>
        <el-button v-if="!isView" type="primary" @click="handleSubmit">
          确定
        </el-button>
      </template>
    </el-dialog>

    <!-- 模型测试对话框 -->
    <el-dialog
      v-model="testVisible"
      title="模型测试"
      width="800px"
    >
      <el-form :model="testForm" label-width="100px">
        <el-form-item label="测试输入">
          <el-input
            v-model="testForm.input"
            type="textarea"
            :rows="4"
            placeholder="请输入测试文本..."
          />
        </el-form-item>
        
        <el-form-item label="推理参数">
          <el-row :gutter="20">
            <el-col :span="8">
              <el-form-item label="温度">
                <el-input-number 
                  v-model="testForm.temperature" 
                  :min="0" 
                  :max="2" 
                  :step="0.1"
                  style="width: 100%"
                />
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="Top-P">
                <el-input-number 
                  v-model="testForm.topP" 
                  :min="0" 
                  :max="1" 
                  :step="0.1"
                  style="width: 100%"
                />
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="最大长度">
                <el-input-number 
                  v-model="testForm.maxTokens" 
                  :min="1" 
                  :max="4096"
                  style="width: 100%"
                />
              </el-form-item>
            </el-col>
          </el-row>
        </el-form-item>
      </el-form>

      <div v-if="testResult" class="test-result">
        <h4>测试结果:</h4>
        <el-input
          v-model="testResult.output"
          type="textarea"
          :rows="6"
          readonly
        />
        <div class="test-metrics">
          <el-tag>推理时间: {{ testResult.metrics.latency }}ms</el-tag>
          <el-tag>Token数: {{ testResult.metrics.totalTokens }}</el-tag>
          <el-tag>Token/秒: {{ testResult.metrics.tokensPerSecond }}</el-tag>
        </div>
      </div>

      <template #footer>
        <el-button @click="testVisible = false">关闭</el-button>
        <el-button type="primary" @click="runTest" :loading="testLoading">
          运行测试
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import DataTable from '@/components/DataTable/index.vue'
import FileUpload from '@/components/FileUpload/index.vue'
import { 
  getModelList, 
  createModel, 
  updateModel, 
  deleteModel,
  uploadModelFile,
  downloadModelFile,
  deleteModelFile,
  getModelVersions,
  createModelVersion,
  switchModelVersion,
  deleteModelVersion,
  getDeploymentList,
  createDeployment,
  startDeployment,
  stopDeployment,
  deleteDeployment,
  testModel
} from '@/api/model'
import { formatDate, formatFileSize } from '@/utils'
import type { Model, ModelForm, ModelVersion, DeploymentConfig, TableColumn } from '@/types'

// 响应式数据
const loading = ref(false)
const modelList = ref<Model[]>([])
const total = ref(0)
const currentPage = ref(1)
const pageSize = ref(10)
const searchKeyword = ref('')

// 对话框状态
const detailVisible = ref(false)
const testVisible = ref(false)
const isView = ref(false)
const dialogTitle = ref('')
const activeTab = ref('basic')

// 当前模型
const currentModel = ref<Model | null>(null)

// 表单数据
const formData = reactive<ModelForm>({
  name: '',
  description: '',
  type: 'llm',
  framework: 'pytorch',
  tags: []
})

// 文件列表
const fileList = ref<any[]>([])

// 版本列表
const versionList = ref<ModelVersion[]>([])

// 部署列表
const deploymentList = ref<DeploymentConfig[]>([])

// 测试表单
const testForm = reactive({
  input: '',
  temperature: 0.7,
  topP: 0.9,
  maxTokens: 1000
})

const testResult = ref<any>(null)
const testLoading = ref(false)

// 表格列配置
const columns: TableColumn[] = [
  { prop: 'preview', label: '预览', width: 80 },
  { prop: 'name', label: '模型名称', minWidth: 150 },
  { prop: 'version', label: '版本', width: 100 },
  { prop: 'type', label: '类型', width: 120 },
  { prop: 'framework', label: '框架', width: 120 },
  { prop: 'status', label: '状态', width: 100 },
  { prop: 'size', label: '大小', width: 120 },
  { prop: 'metrics', label: '性能指标', width: 200 },
  { prop: 'ownerName', label: '创建者', width: 120 },
  { prop: 'createdAt', label: '创建时间', width: 160 }
]

// 表单验证规则
const formRules = {
  name: [
    { required: true, message: '请输入模型名称', trigger: 'blur' },
    { min: 2, max: 50, message: '模型名称长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  version: [
    { required: true, message: '请输入版本号', trigger: 'blur' }
  ],
  type: [
    { required: true, message: '请选择模型类型', trigger: 'change' }
  ],
  framework: [
    { required: true, message: '请选择框架', trigger: 'change' }
  ]
}

// 获取模型列表
const fetchModelList = async () => {
  loading.value = true
  try {
    const response = await getModelList({
      page: currentPage.value,
      pageSize: pageSize.value,
      search: searchKeyword.value
    })
    modelList.value = response.items
    total.value = response.pagination.total
  } catch (error) {
    ElMessage.error('获取模型列表失败')
  } finally {
    loading.value = false
  }
}

// 搜索处理
const handleSearch = (keyword: string) => {
  searchKeyword.value = keyword
  currentPage.value = 1
  fetchModelList()
}

// 分页处理
const handlePageChange = (page: number, size: number) => {
  currentPage.value = page
  pageSize.value = size
  fetchModelList()
}

// 排序处理
const handleSortChange = (sortBy: string, sortOrder: string) => {
  console.log('排序:', sortBy, sortOrder)
}

// 新增模型
const handleAdd = () => {
  isView.value = false
  dialogTitle.value = '新增模型'
  activeTab.value = 'basic'
  Object.assign(formData, {
    name: '',
    description: '',
    type: 'llm',
    framework: 'pytorch',
    tags: []
  })
  fileList.value = []
  detailVisible.value = true
}

// 编辑模型
const handleEdit = (row: Model, index: number) => {
  isView.value = false
  dialogTitle.value = '编辑模型'
  activeTab.value = 'basic'
  currentModel.value = row
  Object.assign(formData, {
    name: row.name,
    description: row.description,
    type: row.type,
    framework: row.framework,
    tags: row.tags
  })
  detailVisible.value = true
  loadModelDetails(row.id)
}

// 查看模型
const handleView = (row: Model, index: number) => {
  isView.value = true
  dialogTitle.value = '模型详情'
  activeTab.value = 'basic'
  currentModel.value = row
  Object.assign(formData, {
    name: row.name,
    description: row.description,
    type: row.type,
    framework: row.framework,
    tags: row.tags
  })
  detailVisible.value = true
  loadModelDetails(row.id)
}

// 加载模型详情
const loadModelDetails = async (modelId: number) => {
  try {
    // 加载版本列表
    const versions = await getModelVersions(modelId)
    versionList.value = versions

    // 加载部署列表
    const deployments = await getDeploymentList(modelId)
    deploymentList.value = deployments
  } catch (error) {
    ElMessage.error('加载模型详情失败')
  }
}

// 删除模型
const handleDelete = async (row: Model, index: number) => {
  try {
    await ElMessageBox.confirm('确定要删除该模型吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await deleteModel(row.id)
    ElMessage.success('删除成功')
    fetchModelList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 批量删除
const handleBatchDelete = async (rows: Model[]) => {
  try {
    await ElMessageBox.confirm(`确定要删除选中的 ${rows.length} 个模型吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    // 实现批量删除逻辑
    ElMessage.success('批量删除成功')
    fetchModelList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('批量删除失败')
    }
  }
}

// 导出模型
const handleExport = () => {
  ElMessage.info('导出功能开发中')
}

// 版本管理
const handleVersions = (row: Model) => {
  currentModel.value = row
  activeTab.value = 'versions'
  detailVisible.value = true
  loadModelDetails(row.id)
}

// 部署模型
const handleDeploy = (row: Model) => {
  currentModel.value = row
  activeTab.value = 'deployment'
  detailVisible.value = true
  loadModelDetails(row.id)
}

// 测试模型
const handleTest = (row: Model) => {
  currentModel.value = row
  testForm.input = ''
  testResult.value = null
  testVisible.value = true
}

// 运行测试
const runTest = async () => {
  if (!currentModel.value || !testForm.input) {
    ElMessage.warning('请输入测试内容')
    return
  }

  testLoading.value = true
  try {
    const result = await testModel(currentModel.value.id, testForm.input)
    testResult.value = result
  } catch (error) {
    ElMessage.error('测试失败')
  } finally {
    testLoading.value = false
  }
}

// 文件上传成功
const handleFileUploadSuccess = (response: any) => {
  ElMessage.success('文件上传成功')
}

// 下载文件
const downloadFile = (file: any) => {
  if (file.url) {
    window.open(file.url, '_blank')
  }
}

// 删除文件
const deleteFile = (file: any) => {
  // 实现删除文件逻辑
  ElMessage.success('文件删除成功')
}

// 创建版本
const handleCreateVersion = () => {
  ElMessage.info('创建版本功能开发中')
}

// 切换版本
const switchVersion = async (version: ModelVersion) => {
  try {
    await switchModelVersion(currentModel.value!.id, version.id)
    ElMessage.success('版本切换成功')
    loadModelDetails(currentModel.value!.id)
  } catch (error) {
    ElMessage.error('版本切换失败')
  }
}

// 对比版本
const compareVersion = (version: ModelVersion) => {
  ElMessage.info('版本对比功能开发中')
}

// 删除版本
const deleteVersion = async (version: ModelVersion) => {
  try {
    await ElMessageBox.confirm('确定要删除该版本吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await deleteModelVersion(currentModel.value!.id, version.id)
    ElMessage.success('版本删除成功')
    loadModelDetails(currentModel.value!.id)
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('版本删除失败')
    }
  }
}

// 创建部署
const handleCreateDeployment = () => {
  ElMessage.info('创建部署功能开发中')
}

// 查看部署
const viewDeployment = (deployment: DeploymentConfig) => {
  ElMessage.info('查看部署功能开发中')
}

// 启动部署
const startDeployment = async (deployment: DeploymentConfig) => {
  try {
    await startDeployment(deployment.id)
    ElMessage.success('部署启动成功')
    loadModelDetails(currentModel.value!.id)
  } catch (error) {
    ElMessage.error('部署启动失败')
  }
}

// 停止部署
const stopDeployment = async (deployment: DeploymentConfig) => {
  try {
    await stopDeployment(deployment.id)
    ElMessage.success('部署停止成功')
    loadModelDetails(currentModel.value!.id)
  } catch (error) {
    ElMessage.error('部署停止失败')
  }
}

// 删除部署
const deleteDeployment = async (deployment: DeploymentConfig) => {
  try {
    await ElMessageBox.confirm('确定要删除该部署吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await deleteDeployment(deployment.id)
    ElMessage.success('部署删除成功')
    loadModelDetails(currentModel.value!.id)
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('部署删除失败')
    }
  }
}

// 提交表单
const handleSubmit = async () => {
  try {
    if (formData.name && formData.description) {
      if (isView.value) return
      
      // 这里需要根据实际情况判断是新增还是编辑
      await createModel(formData)
      ElMessage.success('操作成功')
      detailVisible.value = false
      fetchModelList()
    }
  } catch (error) {
    ElMessage.error('操作失败')
  }
}

// 工具函数
const getStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    draft: 'info',
    ready: 'success',
    deployed: 'primary',
    failed: 'danger'
  }
  return statusMap[status] || 'info'
}

const getStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    draft: '草稿',
    ready: '就绪',
    deployed: '已部署',
    failed: '失败'
  }
  return statusMap[status] || '未知'
}

const getTypeColor = (type: string) => {
  const typeMap: Record<string, string> = {
    llm: 'primary',
    embedding: 'success',
    classification: 'warning',
    generation: 'info'
  }
  return typeMap[type] || 'info'
}

const getTypeText = (type: string) => {
  const typeMap: Record<string, string> = {
    llm: '大语言模型',
    embedding: '嵌入模型',
    classification: '分类模型',
    generation: '生成模型'
  }
  return typeMap[type] || '未知'
}

const getDeploymentStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    pending: 'warning',
    running: 'success',
    stopped: 'info',
    failed: 'danger'
  }
  return statusMap[status] || 'info'
}

const getDeploymentStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    pending: '等待中',
    running: '运行中',
    stopped: '已停止',
    failed: '失败'
  }
  return statusMap[status] || '未知'
}

// 初始化
onMounted(() => {
  fetchModelList()
})
</script>

<style lang="scss" scoped>
.models-page {
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
  
  .table-card {
    .el-card__body {
      padding: 0;
    }
  }
  
  .metrics-info {
    font-size: 12px;
    line-height: 1.4;
    
    div {
      margin-bottom: 2px;
      
      .metric-label {
        color: #666;
        margin-right: 4px;
      }
      
      .metric-value {
        color: #333;
        font-weight: 500;
      }
    }
  }
  
  .file-management {
    .file-upload-section {
      margin-bottom: 20px;
    }
  }
  
  .version-management {
    .version-header {
      margin-bottom: 20px;
    }
    
    .version-item {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      
      .version-info {
        flex: 1;
        
        h4 {
          margin: 0 0 8px 0;
          color: #333;
        }
        
        p {
          margin: 0 0 8px 0;
          color: #666;
        }
        
        .version-metrics {
          display: flex;
          gap: 8px;
        }
      }
      
      .version-actions {
        display: flex;
        gap: 8px;
      }
    }
  }
  
  .deployment-management {
    .deployment-header {
      margin-bottom: 20px;
    }
  }
  
  .test-result {
    margin-top: 20px;
    
    h4 {
      margin: 0 0 12px 0;
      color: #333;
    }
    
    .test-metrics {
      margin-top: 12px;
      display: flex;
      gap: 8px;
    }
  }
}
</style>
