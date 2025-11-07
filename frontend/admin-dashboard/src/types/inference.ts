export interface InferenceTask {
  id: string
  modelId: number
  modelName: string
  userId: number
  userName: string
  projectId: number
  projectName: string
  status: 'pending' | 'running' | 'completed' | 'failed' | 'cancelled'
  input: string
  output?: string
  parameters: InferenceParameters
  metrics: InferenceMetrics
  createdAt: string
  startedAt?: string
  completedAt?: string
  cost: number
}

export interface InferenceParameters {
  temperature: number
  topP: number
  maxTokens: number
  stopSequences?: string[]
  stream: boolean
}

export interface InferenceMetrics {
  latency: number
  tokensPerSecond: number
  inputTokens: number
  outputTokens: number
  totalTokens: number
  gpuUsage: number
  memoryUsage: number
}

export interface InferenceRequest {
  modelId: number
  input: string
  parameters: Partial<InferenceParameters>
  projectId?: number
}

export interface BatchInferenceTask {
  id: string
  name: string
  modelId: number
  modelName: string
  userId: number
  projectId: number
  status: 'pending' | 'processing' | 'completed' | 'failed'
  totalCount: number
  completedCount: number
  failedCount: number
  progress: number
  inputFile: string
  outputFile?: string
  createdAt: string
  startedAt?: string
  completedAt?: string
  cost: number
}

export interface InferenceListParams {
  page: number
  pageSize: number
  modelId?: number
  userId?: number
  projectId?: number
  status?: string
  startDate?: string
  endDate?: string
  sortBy?: string
  sortOrder?: 'asc' | 'desc'
}
