export interface CostRecord {
  id: number
  userId: number
  userName: string
  projectId: number
  projectName: string
  modelId: number
  modelName: string
  type: 'inference' | 'training' | 'storage' | 'compute'
  amount: number
  unit: string
  price: number
  totalCost: number
  currency: string
  createdAt: string
  description?: string
}

export interface CostSummary {
  totalCost: number
  monthlyCost: number
  dailyCost: number
  costGrowth: number
  topProjects: Array<{
    projectId: number
    projectName: string
    cost: number
    percentage: number
  }>
  topUsers: Array<{
    userId: number
    userName: string
    cost: number
    percentage: number
  }>
  topModels: Array<{
    modelId: number
    modelName: string
    cost: number
    percentage: number
  }>
}

export interface Budget {
  id: number
  name: string
  type: 'project' | 'user' | 'global'
  targetId: number
  targetName: string
  amount: number
  usedAmount: number
  remainingAmount: number
  period: 'monthly' | 'quarterly' | 'yearly'
  status: 'active' | 'exceeded' | 'expired'
  alertThreshold: number
  createdAt: string
  updatedAt: string
}

export interface CostListParams {
  page: number
  pageSize: number
  userId?: number
  projectId?: number
  modelId?: number
  type?: string
  startDate?: string
  endDate?: string
  sortBy?: string
  sortOrder?: 'asc' | 'desc'
}

export interface BudgetForm {
  name: string
  type: 'project' | 'user' | 'global'
  targetId: number
  amount: number
  period: 'monthly' | 'quarterly' | 'yearly'
  alertThreshold: number
}
