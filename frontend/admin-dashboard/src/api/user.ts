import request from './request'
import type { 
  LoginForm, 
  UserInfo, 
  UserListParams, 
  UserForm, 
  PaginationResponse,
  Role,
  Permission,
  Organization,
  UserGroup,
  UserQuota,
  AuditLog,
  SecurityPolicy,
  UserStats,
  QuotaUsageStats
} from '@/types'

/**
 * 用户API服务类
 */
export class UserApiService {
  private basePath = '/v1/users'

  // 用户认证相关
  async login(data: LoginForm) {
    return request.post<{
      token: string
      user: UserInfo
      permissions: string[]
    }>('/v1/auth/login', data)
  }

  async logout() {
    return request.post('/v1/auth/logout')
  }

  async getUserInfo() {
    return request.get<UserInfo>('/v1/auth/profile')
  }

  // 用户管理相关
  async getUsers(params: UserListParams) {
    return request.get<PaginationResponse<UserInfo>>('/v1/users', { params })
  }

  async getUserById(id: string) {
    return request.get<UserInfo>(`/v1/users/${id}`)
  }

  async createUser(data: UserForm) {
    return request.post<UserInfo>('/v1/users', data)
  }

  async updateUser(id: string, data: Partial<UserForm>) {
    return request.put<UserInfo>(`/v1/users/${id}`, data)
  }

  async deleteUser(id: string) {
    return request.delete(`/v1/users/${id}`)
  }

  // 角色权限相关
  async getRoles() {
    return request.get<Role[]>('/v1/roles')
  }

  async getPermissions() {
    return request.get<Permission[]>('/v1/permissions')
  }

  // 用户管理相关（新版本API）
  async getUserList(params: UserListParams) {
    return request.get<PaginationResponse<UserInfo>>('/v1/users/', { params })
  }

  async getUserByIdV2(id: number) {
    return request.get<UserInfo>(`/users/${id}`)
  }

  async createUserV2(data: UserForm) {
    return request.post<UserInfo>('/v1/users/', data)
  }

  async updateUserV2(id: number, data: Partial<UserForm>) {
    return request.put<UserInfo>(`/users/${id}`, data)
  }

  async deleteUserV2(id: number) {
    return request.delete(`/users/${id}`)
  }

  async batchDeleteUsers(ids: number[]) {
    return request.delete('/v1/users/batch', { data: { ids } })
  }

  async updateUserStatus(id: number, status: string) {
    return request.patch(`/users/${id}/status`, { status })
  }

  async resetUserPassword(id: number, password: string) {
    return request.patch(`/users/${id}/password`, { password })
  }

  // 角色权限相关
  async getRoleList() {
    return request.get<Role[]>('/roles')
  }

  async getPermissionList() {
    return request.get<Permission[]>('/permissions')
  }

  async assignUserRole(userId: number, roleId: number) {
    return request.post(`/users/${userId}/roles`, { roleId })
  }

  async removeUserRole(userId: number, roleId: number) {
    return request.delete(`/users/${userId}/roles/${roleId}`)
  }

  // 用户导入导出
  async exportUsers(params: Partial<UserListParams>) {
    return request.get('/v1/users/export', { 
      params,
      responseType: 'blob'
    })
  }

  async importUsers(file: File) {
    const formData = new FormData()
    formData.append('file', file)
    return request.post('/v1/users/import', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
  }
}

// 创建服务实例
export const userApiService = new UserApiService()

// 用户认证相关
export const login = (data: LoginForm) => {
  return request.post<{
    token: string
    user: UserInfo
    permissions: string[]
  }>('/v1/auth/login', data)
}

export const logout = () => {
  return request.post('/v1/auth/logout')
}

// 更新用户资料
export const updateUserProfile = (data: any) => {
  return request.put('/v1/users/profile', data)
}

// 修改密码
export const changePassword = (data: { currentPassword: string; newPassword: string }) => {
  return request.post('/v1/users/change-password', data)
}

export const getUserInfo = () => {
  return request.get<UserInfo>('/v1/users/me')
}

// 用户管理相关
export const getUsers = (params: UserListParams) => {
  return request.get<PaginationResponse<UserInfo>>('/v1/users', { params })
}

export const getUserById = (id: string) => {
  return request.get<UserInfo>(`/v1/users/${id}`)
}

export const createUser = (data: UserForm) => {
  return request.post<UserInfo>('/v1/users/', data)
}

export const updateUser = (id: string, data: Partial<UserForm>) => {
  return request.put<UserInfo>(`/v1/users/${id}`, data)
}

export const deleteUser = (id: string) => {
  return request.delete(`/v1/users/${id}`)
}

// 角色权限相关
export const getRoles = () => {
  return request.get<Role[]>('/v1/roles')
}

export const getPermissions = () => {
  return request.get<Permission[]>('/v1/permissions')
}

// 用户管理相关（新版本API）
export const getUserList = (params: UserListParams) => {
  return request.get<PaginationResponse<UserInfo>>('/v1/users/', { params })
}

export const getUserByIdV2 = (id: number) => {
  return request.get<UserInfo>(`/users/${id}`)
}

// 用户搜索
export const searchUsers = (params: { keyword: string; page: number; pageSize: number }) => {
  return request.get<PaginationResponse<UserInfo>>('/v1/users/search', { params })
}

// 批量操作用户
export const batchUserOperation = (data: { user_ids: string[]; action: string; data?: any }) => {
  return request.post('/v1/users/batch', data)
}

// 获取用户统计
export const getUserStats = () => {
  return request.get<UserStats>('/v1/users/stats')
}

// 重置用户密码
export const resetUserPassword = (id: string, password: string) => {
  return request.post(`/users/${id}/reset-password`, { new_password: password })
}

// 切换用户状态
export const toggleUserStatus = (id: string) => {
  return request.post(`/users/${id}/toggle-status`)
}

// 组织管理API
export const getOrganizations = (params?: { page: number; pageSize: number }) => {
  return request.get<PaginationResponse<Organization>>('/organizations', { params })
}

export const getOrganizationById = (id: string) => {
  return request.get<Organization>(`/organizations/${id}`)
}

export const createOrganization = (data: Partial<Organization>) => {
  return request.post<Organization>('/organizations', data)
}

export const updateOrganization = (id: string, data: Partial<Organization>) => {
  return request.put<Organization>(`/organizations/${id}`, data)
}

export const deleteOrganization = (id: string) => {
  return request.delete(`/organizations/${id}`)
}

export const getOrganizationTree = () => {
  return request.get<Organization[]>('/organizations/tree')
}

// 用户组管理API
export const getUserGroups = (params?: { offset?: number; limit?: number; page?: number; pageSize?: number; search?: string }) => {
  // 如果传递了page和pageSize，转换为offset和limit
  const queryParams: any = { ...params }
  if (params?.page && params?.pageSize) {
    queryParams.offset = (params.page - 1) * params.pageSize
    queryParams.limit = params.pageSize
    delete queryParams.page
    delete queryParams.pageSize
  }
  return request.get<PaginationResponse<UserGroup>>('/v1/user-groups/', { params: queryParams })
}

export const getUserGroupById = (id: string) => {
  return request.get<UserGroup>(`/v1/user-groups/${id}`)
}

export const createUserGroup = (data: Partial<UserGroup>) => {
  return request.post<UserGroup>('/v1/user-groups/', data)
}

export const updateUserGroup = (id: string, data: Partial<UserGroup>) => {
  return request.put<UserGroup>(`/v1/user-groups/${id}`, data)
}

export const deleteUserGroup = (id: string) => {
  return request.delete(`/v1/user-groups/${id}`)
}

export const addUserToGroup = (groupId: string, userId: string, role: string = 'member') => {
  return request.post(`/v1/user-groups/${groupId}/members`, { user_id: userId, role })
}

export const removeUserFromGroup = (groupId: string, userId: string) => {
  return request.delete(`/v1/user-groups/${groupId}/members/${userId}`)
}

export const getGroupMembers = (groupId: string) => {
  return request.get(`/v1/user-groups/${groupId}/members`)
}

export const getUserGroupsByUser = (userId: string) => {
  return request.get<UserGroup[]>(`/v1/user-groups/user/${userId}`)
}

// 配额管理API
export const getUserQuotas = (userId: string) => {
  return request.get<UserQuota[]>(`/users/${userId}/quotas`)
}

export const createUserQuota = (data: Partial<UserQuota>) => {
  return request.post<UserQuota>('/user-quotas', data)
}

export const updateUserQuota = (id: string, data: Partial<UserQuota>) => {
  return request.put<UserQuota>(`/user-quotas/${id}`, data)
}

export const deleteUserQuota = (id: string) => {
  return request.delete(`/user-quotas/${id}`)
}

export const getQuotaUsageStats = () => {
  return request.get<QuotaUsageStats[]>('/quotas/usage-stats')
}

// 审计日志API
export const getAuditLogs = (params?: { page: number; pageSize: number; user_id?: string; action?: string }) => {
  return request.get<PaginationResponse<AuditLog>>('/audit-logs', { params })
}

export const getAuditLogById = (id: string) => {
  return request.get<AuditLog>(`/audit-logs/${id}`)
}

export const getUserAuditLogs = (userId: string, params?: { page: number; pageSize: number }) => {
  return request.get<PaginationResponse<AuditLog>>(`/users/${userId}/audit-logs`, { params })
}

// 安全策略API
export const getSecurityPolicies = () => {
  return request.get<SecurityPolicy[]>('/security-policies')
}

export const getSecurityPolicyById = (id: string) => {
  return request.get<SecurityPolicy>(`/security-policies/${id}`)
}

export const createSecurityPolicy = (data: Partial<SecurityPolicy>) => {
  return request.post<SecurityPolicy>('/security-policies', data)
}

export const updateSecurityPolicy = (id: string, data: Partial<SecurityPolicy>) => {
  return request.put<SecurityPolicy>(`/security-policies/${id}`, data)
}

export const deleteSecurityPolicy = (id: string) => {
  return request.delete(`/security-policies/${id}`)
}

export const createUserV2 = (data: UserForm) => {
  return request.post<UserInfo>('/v1/users/', data)
}

export const updateUserV2 = (id: number, data: Partial<UserForm>) => {
  return request.put<UserInfo>(`/users/${id}`, data)
}

export const deleteUserV2 = (id: number) => {
  return request.delete(`/users/${id}`)
}

export const batchDeleteUsers = (ids: number[]) => {
  return request.delete('/v1/users/batch', { data: { ids } })
}

export const updateUserStatus = (id: number, status: string) => {
  return request.patch(`/users/${id}/status`, { status })
}

// 这个函数已经在UserApiService类中定义了，这里删除重复定义

// 角色权限相关
export const getRoleList = () => {
  return request.get<Role[]>('/roles')
}

export const getPermissionList = () => {
  return request.get<Permission[]>('/permissions')
}

export const assignUserRole = (userId: number, roleId: number) => {
  return request.post(`/users/${userId}/roles`, { roleId })
}

export const removeUserRole = (userId: number, roleId: number) => {
  return request.delete(`/users/${userId}/roles/${roleId}`)
}

// 用户导入导出
export const exportUsers = (params: Partial<UserListParams>) => {
  return request.get('/v1/users/export', { 
    params,
    responseType: 'blob'
  })
}

export const importUsers = (file: File) => {
  const formData = new FormData()
  formData.append('file', file)
  return request.post('/v1/users/import', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}
