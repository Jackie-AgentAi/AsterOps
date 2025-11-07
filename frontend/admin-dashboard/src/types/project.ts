export interface Project {
  id: number
  name: string
  description: string
  status: 'active' | 'inactive' | 'archived'
  ownerId: number
  ownerName: string
  memberCount: number
  modelCount: number
  createdAt: string
  updatedAt: string
  tags: string[]
  quota: ProjectQuota
}

export interface ProjectQuota {
  cpu: number
  memory: number
  gpu: number
  storage: number
  usedCpu: number
  usedMemory: number
  usedGpu: number
  usedStorage: number
}

export interface ProjectMember {
  id: number
  userId: number
  username: string
  email: string
  role: 'owner' | 'admin' | 'developer' | 'viewer'
  joinedAt: string
  permissions: string[]
}

export interface ProjectForm {
  name: string
  description: string
  tags: string[]
  quota: Partial<ProjectQuota>
}

export interface ProjectListParams {
  page: number
  pageSize: number
  search?: string
  status?: string
  ownerId?: number
  sortBy?: string
  sortOrder?: 'asc' | 'desc'
}
