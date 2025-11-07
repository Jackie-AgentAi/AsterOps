import request from './request'
import type { 
  Project, 
  ProjectListParams, 
  ProjectForm, 
  ProjectMember,
  ProjectQuota,
  PaginationResponse
} from '@/types'

// 项目管理相关
export const getProjectList = (params: ProjectListParams) => {
  return request.get<PaginationResponse<Project>>('/v6/projects', { params })
}

export const getProjectById = (id: number) => {
  return request.get<Project>(`/v6/projects/${id}`)
}

export const createProject = (data: ProjectForm) => {
  return request.post<Project>('/v6/projects', data)
}

export const updateProject = (id: number, data: Partial<ProjectForm>) => {
  return request.put<Project>(`/v6/projects/${id}`, data)
}

export const deleteProject = (id: number) => {
  return request.delete(`/v6/projects/${id}`)
}

export const archiveProject = (id: number) => {
  return request.patch(`/v6/projects/${id}/archive`)
}

export const restoreProject = (id: number) => {
  return request.patch(`/v6/projects/${id}/restore`)
}

// 项目成员管理
export const getProjectMembers = (projectId: number) => {
  return request.get<ProjectMember[]>(`/v6/projects/${projectId}/members`)
}

export const addProjectMember = (projectId: number, userId: number, role: string) => {
  return request.post(`/v6/projects/${projectId}/members`, { userId, role })
}

export const updateProjectMember = (projectId: number, userId: number, role: string) => {
  return request.put(`/v6/projects/${projectId}/members/${userId}`, { role })
}

export const removeProjectMember = (projectId: number, userId: number) => {
  return request.delete(`/v6/projects/${projectId}/members/${userId}`)
}

export const inviteProjectMember = (projectId: number, email: string, role: string) => {
  return request.post(`/v6/projects/${projectId}/invite`, { email, role })
}

// 项目配额管理
export const getProjectQuota = (projectId: number) => {
  return request.get<ProjectQuota>(`/v6/projects/${projectId}/quota`)
}

export const updateProjectQuota = (projectId: number, quota: Partial<ProjectQuota>) => {
  return request.put(`/v6/projects/${projectId}/quota`, quota)
}

// 项目统计
export const getProjectStats = (projectId: number) => {
  return request.get<{
    memberCount: number
    modelCount: number
    inferenceCount: number
    totalCost: number
    lastActivity: string
  }>(`/v6/projects/${projectId}/stats`)
}

// 项目活动日志
export const getProjectActivities = (projectId: number, params: { page: number; pageSize: number }) => {
  return request.get<PaginationResponse<{
    id: number
    action: string
    description: string
    userId: number
    userName: string
    createdAt: string
  }>>(`/v6/projects/${projectId}/activities`, { params })
}
