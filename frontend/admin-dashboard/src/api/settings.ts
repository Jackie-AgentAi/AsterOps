/**
 * 系统设置API
 */
import request from './request'

// 基本设置接口
export interface BasicSettings {
  siteName: string
  siteDescription: string
  siteUrl: string
  adminEmail: string
  timezone: string
  language: string
  maintenanceMode: boolean
}

// 安全设置接口
export interface SecuritySettings {
  passwordMinLength: number
  passwordRequireSpecialChars: boolean
  sessionTimeout: number
  maxLoginAttempts: number
  enableTwoFactor: boolean
  enableIpWhitelist: boolean
  allowedIps: string[]
}

// 集成设置接口
export interface IntegrationSettings {
  emailSmtpHost: string
  emailSmtpPort: number
  emailSmtpUser: string
  emailSmtpPassword: string
  emailFromAddress: string
  webhookUrl: string
  webhookSecret: string
  enableNotifications: boolean
}

// API密钥接口
export interface ApiKey {
  id: string
  name: string
  key: string
  permissions: string[]
  createdAt: string
  lastUsed: string
  expiresAt: string
  isActive: boolean
}

// 创建API密钥请求
export interface CreateApiKeyRequest {
  name: string
  permissions: string[]
  expiresAt?: string
}

// 更新API密钥请求
export interface UpdateApiKeyRequest {
  name?: string
  permissions?: string[]
  isActive?: boolean
}

/**
 * 获取基本设置
 */
export function getBasicSettings(): Promise<BasicSettings> {
  return request.get('/api/v1/settings/basic')
}

/**
 * 更新基本设置
 */
export function updateBasicSettings(settings: Partial<BasicSettings>): Promise<void> {
  return request.put('/api/v1/settings/basic', settings)
}

/**
 * 获取安全设置
 */
export function getSecuritySettings(): Promise<SecuritySettings> {
  return request.get('/api/v1/settings/security')
}

/**
 * 更新安全设置
 */
export function updateSecuritySettings(settings: Partial<SecuritySettings>): Promise<void> {
  return request.put('/api/v1/settings/security', settings)
}

/**
 * 获取集成设置
 */
export function getIntegrationSettings(): Promise<IntegrationSettings> {
  return request.get('/api/v1/settings/integration')
}

/**
 * 更新集成设置
 */
export function updateIntegrationSettings(settings: Partial<IntegrationSettings>): Promise<void> {
  return request.put('/api/v1/settings/integration', settings)
}

/**
 * 获取API密钥列表
 */
export function getApiKeyList(): Promise<ApiKey[]> {
  return request.get('/api/v1/settings/api-keys')
}

/**
 * 创建API密钥
 */
export function createApiKey(data: CreateApiKeyRequest): Promise<ApiKey> {
  return request.post('/api/v1/settings/api-keys', data)
}

/**
 * 更新API密钥
 */
export function updateApiKey(id: string, data: UpdateApiKeyRequest): Promise<void> {
  return request.put(`/api/v1/settings/api-keys/${id}`, data)
}

/**
 * 删除API密钥
 */
export function deleteApiKey(id: string): Promise<void> {
  return request.delete(`/api/v1/settings/api-keys/${id}`)
}

/**
 * 创建系统备份
 */
export function createBackup(): Promise<{ backupId: string; message: string }> {
  return request.post('/api/v1/settings/backup')
}

/**
 * 运行系统清理
 */
export function runCleanup(): Promise<{ message: string; cleanedItems: number }> {
  return request.post('/api/v1/settings/cleanup')
}

/**
 * 运行系统诊断
 */
export function runSystemDiagnosis(): Promise<{
  status: 'healthy' | 'warning' | 'error'
  checks: Array<{
    name: string
    status: 'pass' | 'fail' | 'warning'
    message: string
    details?: any
  }>
}> {
  return request.post('/api/v1/settings/diagnosis')
}