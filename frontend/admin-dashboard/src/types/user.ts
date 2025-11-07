export interface UserInfo {
  id: number
  username: string
  email: string
  avatar?: string
  role: string
  status: 'active' | 'inactive' | 'pending'
  createdAt: string
  lastLoginAt?: string
  department?: string
  phone?: string
}

export interface LoginForm {
  username: string
  password: string
  remember?: boolean
}

export interface UserListParams {
  page: number
  pageSize: number
  search?: string
  role?: string
  status?: string
  sortBy?: string
  sortOrder?: 'asc' | 'desc'
}

export interface UserForm {
  username: string
  email: string
  password?: string
  role: string
  status: 'active' | 'inactive'
  department?: string
  phone?: string
  tenant_id?: string
}

export interface Role {
  id: number
  name: string
  description: string
  permissions: string[]
  createdAt: string
}

export interface Permission {
  id: number
  name: string
  code: string
  module: string
  description: string
}

// 组织相关类型
export interface Organization {
  id: string
  name: string
  description?: string
  parent_id?: string
  tenant_id: string
  status: 'active' | 'inactive'
  settings?: Record<string, any>
  created_at: string
  updated_at: string
  children?: Organization[]
}

// 用户组相关类型
export interface UserGroup {
  id: string
  name: string
  description?: string
  tenant_id: string
  organization_id?: string
  parent_id?: string
  settings?: Record<string, any>
  created_at: string
  updated_at: string
  member_count?: number
}

export interface UserGroupMember {
  id: string
  user_id: string
  group_id: string
  role: string
  joined_at: string
  user?: UserInfo
  user_group?: UserGroup
}

// 配额相关类型
export interface UserQuota {
  id: string
  user_id: string
  resource_type: string
  quota_limit: number
  used_amount: number
  period_type: 'daily' | 'weekly' | 'monthly' | 'yearly'
  created_at: string
  updated_at: string
  user?: UserInfo
}

export interface QuotaUsageStats {
  resource_type: string
  total_quota: number
  used_quota: number
  usage_rate: number
}

// 审计日志相关类型
export interface AuditLog {
  id: string
  user_id?: string
  action: string
  resource_type?: string
  resource_id?: string
  details?: Record<string, any>
  ip_address?: string
  user_agent?: string
  created_at: string
  user?: UserInfo
}

// 安全策略相关类型
export interface SecurityPolicy {
  id: string
  tenant_id: string
  policy_type: 'password_policy' | 'login_policy' | 'quota_policy'
  policy_config: Record<string, any>
  is_active: boolean
  created_at: string
  updated_at: string
}

// 用户统计相关类型
export interface UserStats {
  total_users: number
  active_users: number
  inactive_users: number
  new_users_today: number
  new_users_week: number
  new_users_month: number
  total_groups?: number
}

// 用户偏好设置
export interface UserPreference {
  id: string
  user_id: string
  preference_key: string
  preference_value: Record<string, any>
  created_at: string
  updated_at: string
}

// 批量操作类型
export interface BatchUserOperation {
  user_ids: string[]
  action: 'delete' | 'activate' | 'deactivate' | 'assign_role' | 'remove_role'
  data?: Record<string, any>
}

// 用户搜索参数
export interface UserSearchParams {
  keyword?: string
  role?: string
  status?: string
  tenant_id?: string
  page: number
  page_size: number
}

// 组织树节点
export interface OrganizationTreeNode {
  id: string
  name: string
  description?: string
  status: string
  children?: OrganizationTreeNode[]
}
