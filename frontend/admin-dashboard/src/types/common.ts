export interface ApiResponse<T = any> {
  code: number
  message: string
  data: T
  timestamp: string
}

export interface PaginationParams {
  page: number
  pageSize: number
  total?: number
}

export interface PaginationResponse<T = any> {
  items: T[]
  pagination: {
    page: number
    pageSize: number
    total: number
    totalPages: number
  }
}

export interface TableColumn {
  prop: string
  label: string
  width?: number
  minWidth?: number
  sortable?: boolean
  formatter?: (row: any, column: any, cellValue: any) => string
}

export interface SelectOption {
  label: string
  value: string | number
  disabled?: boolean
}

export interface ChartData {
  name: string
  value: number
  color?: string
}

export interface TimeRange {
  start: string
  end: string
  label: string
}

export interface UploadFile {
  name: string
  size: number
  type: string
  status: 'ready' | 'uploading' | 'success' | 'error'
  progress: number
  url?: string
  error?: string
}

export interface NotificationItem {
  id: number
  title: string
  message: string
  type: 'info' | 'success' | 'warning' | 'error'
  read: boolean
  createdAt: string
}
