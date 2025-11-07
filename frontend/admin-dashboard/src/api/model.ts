import request from './request'
import type { 
  Model, 
  ModelListParams, 
  ModelForm, 
  ModelVersion,
  DeploymentConfig,
  PaginationResponse
} from '@/types'

// 模型管理相关
export const getModelList = (params: ModelListParams) => {
  return request.get<PaginationResponse<Model>>('/v2/models', { params })
}

export const getModelById = (id: number) => {
  return request.get<Model>(`/v2/models/${id}`)
}

export const createModel = (data: ModelForm) => {
  return request.post<Model>('/v2/models', data)
}

export const updateModel = (id: number, data: Partial<ModelForm>) => {
  return request.put<Model>(`/v2/models/${id}`, data)
}

export const deleteModel = (id: number) => {
  return request.delete(`/v2/models/${id}`)
}

// 模型文件管理
export const uploadModelFile = (modelId: number, file: File, onProgress?: (progress: number) => void) => {
  const formData = new FormData()
  formData.append('file', file)
  
  return request.post(`/v2/models/${modelId}/upload`, formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    },
    onUploadProgress: (progressEvent) => {
      if (onProgress && progressEvent.total) {
        const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total)
        onProgress(progress)
      }
    }
  })
}

export const downloadModelFile = (modelId: number, filePath: string) => {
  return request.get(`/models/${modelId}/download`, {
    params: { filePath },
    responseType: 'blob'
  })
}

export const deleteModelFile = (modelId: number, filePath: string) => {
  return request.delete(`/models/${modelId}/files`, { data: { filePath } })
}

// 模型版本管理
export const getModelVersions = (modelId: number) => {
  return request.get<ModelVersion[]>(`/models/${modelId}/versions`)
}

export const createModelVersion = (modelId: number, data: { version: string; description: string }) => {
  return request.post<ModelVersion>(`/models/${modelId}/versions`, data)
}

export const switchModelVersion = (modelId: number, versionId: number) => {
  return request.patch(`/models/${modelId}/versions/${versionId}/switch`)
}

export const deleteModelVersion = (modelId: number, versionId: number) => {
  return request.delete(`/models/${modelId}/versions/${versionId}`)
}

// 模型部署
export const getDeploymentList = (modelId?: number) => {
  return request.get<DeploymentConfig[]>(`/deployments${modelId ? `?modelId=${modelId}` : ''}`)
}

export const createDeployment = (data: {
  modelId: number
  name: string
  engine: string
  replicas: number
  resources: any
  environment: Record<string, string>
}) => {
  return request.post<DeploymentConfig>('/deployments', data)
}

export const updateDeployment = (id: number, data: Partial<DeploymentConfig>) => {
  return request.put<DeploymentConfig>(`/deployments/${id}`, data)
}

export const deleteDeployment = (id: number) => {
  return request.delete(`/deployments/${id}`)
}

export const startDeployment = (id: number) => {
  return request.patch(`/deployments/${id}/start`)
}

export const stopDeployment = (id: number) => {
  return request.patch(`/deployments/${id}/stop`)
}

export const getDeploymentStatus = (id: number) => {
  return request.get<{
    status: string
    replicas: number
    readyReplicas: number
    endpoint: string
    metrics: any
  }>(`/deployments/${id}/status`)
}

// 模型验证
export const validateModel = (modelId: number) => {
  return request.post<{
    valid: boolean
    errors: string[]
    warnings: string[]
  }>(`/models/${modelId}/validate`)
}

// 模型测试
export const testModel = (modelId: number, input: string) => {
  return request.post<{
    output: string
    metrics: any
  }>(`/models/${modelId}/test`, { input })
}
