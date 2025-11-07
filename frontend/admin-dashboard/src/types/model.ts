export interface Model {
  id: number
  name: string
  version: string
  description: string
  type: 'llm' | 'embedding' | 'classification' | 'generation'
  framework: 'pytorch' | 'tensorflow' | 'onnx' | 'huggingface'
  status: 'draft' | 'ready' | 'deployed' | 'failed'
  size: number
  fileCount: number
  ownerId: number
  ownerName: string
  projectId: number
  projectName: string
  createdAt: string
  updatedAt: string
  tags: string[]
  metrics: ModelMetrics
}

export interface ModelMetrics {
  accuracy?: number
  inferenceTime?: number
  memoryUsage?: number
  gpuUsage?: number
  callCount: number
  successRate: number
  avgLatency: number
}

export interface ModelVersion {
  id: number
  version: string
  description: string
  filePath: string
  fileSize: number
  createdAt: string
  isActive: boolean
  metrics: ModelMetrics
}

export interface ModelForm {
  name: string
  description: string
  type: string
  framework: string
  tags: string[]
  projectId: number
}

export interface ModelListParams {
  page: number
  pageSize: number
  search?: string
  type?: string
  status?: string
  projectId?: number
  ownerId?: number
  sortBy?: string
  sortOrder?: 'asc' | 'desc'
}

export interface DeploymentConfig {
  id: number
  modelId: number
  name: string
  engine: 'vllm' | 'tensorrt' | 'transformers'
  replicas: number
  resources: {
    cpu: string
    memory: string
    gpu: string
  }
  environment: Record<string, string>
  status: 'pending' | 'running' | 'stopped' | 'failed'
  endpoint: string
  createdAt: string
}
