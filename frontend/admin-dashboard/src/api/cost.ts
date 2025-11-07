import request from './request'
import type { 
  CostRecord, 
  CostSummary,
  Budget,
  BudgetForm,
  CostListParams
} from '@/types'

// 成本记录相关
export const getCostList = (params: CostListParams) => {
  return request.get<{
    items: CostRecord[]
    pagination: {
      page: number
      pageSize: number
      total: number
      totalPages: number
    }
  }>('/v4/costs', { params })
}

export const getCostById = (id: number) => {
  return request.get<CostRecord>(`/v4/costs/${id}`)
}

export const deleteCost = (id: number) => {
  return request.delete(`/v4/costs/${id}`)
}

// 成本概览
export const getCostSummary = (params: {
  startDate?: string
  endDate?: string
  projectId?: number
  userId?: number
}) => {
  return request.get<CostSummary>('/costs/summary', { params })
}

export const getCostTrend = (params: {
  startDate: string
  endDate: string
  granularity: 'day' | 'week' | 'month'
  projectId?: number
  userId?: number
}) => {
  return request.get<Array<{
    date: string
    cost: number
    inference: number
    training: number
    storage: number
    compute: number
  }>>('/costs/trend', { params })
}

export const getCostDistribution = (params: {
  startDate: string
  endDate: string
  dimension: 'project' | 'user' | 'model' | 'type'
}) => {
  return request.get<Array<{
    name: string
    value: number
    percentage: number
  }>>('/costs/distribution', { params })
}

// 预算管理
export const getBudgetList = () => {
  return request.get<Budget[]>('/budgets')
}

export const getBudgetById = (id: number) => {
  return request.get<Budget>(`/budgets/${id}`)
}

export const createBudget = (data: BudgetForm) => {
  return request.post<Budget>('/budgets', data)
}

export const updateBudget = (id: number, data: Partial<BudgetForm>) => {
  return request.put<Budget>(`/budgets/${id}`, data)
}

export const deleteBudget = (id: number) => {
  return request.delete(`/budgets/${id}`)
}

export const getBudgetUsage = (id: number) => {
  return request.get<{
    used: number
    remaining: number
    percentage: number
    dailyUsage: Array<{
      date: string
      cost: number
    }>
  }>(`/budgets/${id}/usage`)
}

// 成本分析
export const getCostAnalysis = (params: {
  startDate: string
  endDate: string
  projectId?: number
  userId?: number
}) => {
  return request.get<{
    totalCost: number
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
    costByType: Array<{
      type: string
      cost: number
      percentage: number
    }>
  }>('/costs/analysis', { params })
}

export const getCostOptimization = (params: {
  startDate: string
  endDate: string
  projectId?: number
}) => {
  return request.get<{
    recommendations: Array<{
      type: string
      title: string
      description: string
      potentialSavings: number
      priority: 'high' | 'medium' | 'low'
    }>
    costComparison: Array<{
      model: string
      currentCost: number
      optimizedCost: number
      savings: number
    }>
  }>('/costs/optimization', { params })
}

// 账单管理
export const generateBill = (params: {
  startDate: string
  endDate: string
  projectId?: number
  userId?: number
}) => {
  return request.post<{
    billId: string
    totalAmount: number
    items: Array<{
      description: string
      amount: number
      quantity: number
      unitPrice: number
    }>
  }>('/bills/generate', params)
}

export const getBillList = (params: { page: number; pageSize: number }) => {
  return request.get<{
    items: Array<{
      id: string
      period: string
      totalAmount: number
      status: string
      createdAt: string
    }>
    pagination: {
      page: number
      pageSize: number
      total: number
      totalPages: number
    }
  }>('/bills', { params })
}

export const downloadBill = (billId: string) => {
  return request.get(`/bills/${billId}/download`, {
    responseType: 'blob'
  })
}
