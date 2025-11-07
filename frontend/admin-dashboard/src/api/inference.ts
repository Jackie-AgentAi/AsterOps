import request from './request'
import type { 
  InferenceTask, 
  InferenceRequest,
  InferenceListParams,
  BatchInferenceTask,
  PaginationResponse
} from '@/types'

// 推理任务相关
export const getInferenceList = (params: InferenceListParams) => {
  return request.get<PaginationResponse<InferenceTask>>('/v3/inference/tasks', { params })
}

export const getInferenceById = (id: string) => {
  return request.get<InferenceTask>(`/v3/inference/tasks/${id}`)
}

export const createInference = (data: InferenceRequest) => {
  return request.post<InferenceTask>('/v3/inference/tasks', data)
}

export const cancelInference = (id: string) => {
  return request.patch(`/v3/inference/tasks/${id}/cancel`)
}

export const deleteInference = (id: string) => {
  return request.delete(`/v3/inference/tasks/${id}`)
}

// 流式推理
export const createStreamInference = (data: InferenceRequest) => {
  return request.post('/inference/stream', data, {
    responseType: 'stream'
  })
}

// 批量推理
export const createBatchInference = (data: {
  name: string
  modelId: number
  inputFile: File
  parameters: any
}) => {
  const formData = new FormData()
  formData.append('name', data.name)
  formData.append('modelId', data.modelId.toString())
  formData.append('inputFile', data.inputFile)
  formData.append('parameters', JSON.stringify(data.parameters))
  
  return request.post<BatchInferenceTask>('/inference/batch', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}

export const getBatchInferenceList = (params: { page: number; pageSize: number }) => {
  return request.get<PaginationResponse<BatchInferenceTask>>('/inference/batch', { params })
}

export const getBatchInferenceById = (id: string) => {
  return request.get<BatchInferenceTask>(`/inference/batch/${id}`)
}

export const cancelBatchInference = (id: string) => {
  return request.patch(`/inference/batch/${id}/cancel`)
}

export const downloadBatchResult = (id: string) => {
  return request.get(`/inference/batch/${id}/download`, {
    responseType: 'blob'
  })
}

// 推理历史
export const getInferenceHistory = (params: InferenceListParams) => {
  return request.get<PaginationResponse<InferenceTask>>('/inference/history', { params })
}

export const exportInferenceHistory = (params: Partial<InferenceListParams>) => {
  return request.get('/inference/history/export', { 
    params,
    responseType: 'blob'
  })
}

// 推理统计
export const getInferenceStats = (params: {
  startDate?: string
  endDate?: string
  modelId?: number
  userId?: number
  projectId?: number
}) => {
  return request.get<{
    totalTasks: number
    successRate: number
    avgLatency: number
    totalCost: number
    dailyStats: Array<{
      date: string
      count: number
      cost: number
    }>
    modelStats: Array<{
      modelId: number
      modelName: string
      count: number
      cost: number
    }>
  }>('/inference/stats', { params })
}

// 推理性能监控
export const getInferenceMetrics = (params: {
  startDate?: string
  endDate?: string
  modelId?: number
}) => {
  return request.get<{
    qps: Array<{ timestamp: string; value: number }>
    latency: Array<{ timestamp: string; p50: number; p90: number; p99: number }>
    successRate: Array<{ timestamp: string; value: number }>
    resourceUsage: Array<{
      timestamp: string
      cpu: number
      memory: number
      gpu: number
    }>
  }>('/inference/metrics', { params })
}
