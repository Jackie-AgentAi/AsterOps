import dayjs from 'dayjs'
import relativeTime from 'dayjs/plugin/relativeTime'
import 'dayjs/locale/zh-cn'

dayjs.extend(relativeTime)
dayjs.locale('zh-cn')

// 日期格式化
export const formatDate = (date: string | Date, format = 'YYYY-MM-DD HH:mm:ss') => {
  return dayjs(date).format(format)
}

export const formatRelativeTime = (date: string | Date) => {
  return dayjs(date).fromNow()
}

// 文件大小格式化
export const formatFileSize = (bytes: number) => {
  if (bytes === 0) return '0 B'
  
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

// 数字格式化
export const formatNumber = (num: number, decimals = 2) => {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(decimals) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(decimals) + 'K'
  }
  return num.toString()
}

// 百分比格式化
export const formatPercentage = (value: number, decimals = 1) => {
  return (value * 100).toFixed(decimals) + '%'
}

// 货币格式化
export const formatCurrency = (amount: number, currency = 'CNY') => {
  return new Intl.NumberFormat('zh-CN', {
    style: 'currency',
    currency: currency
  }).format(amount)
}

// 防抖函数
export const debounce = <T extends (...args: any[]) => any>(
  func: T,
  wait: number
): ((...args: Parameters<T>) => void) => {
  let timeout: NodeJS.Timeout | null = null
  
  return (...args: Parameters<T>) => {
    if (timeout) clearTimeout(timeout)
    timeout = setTimeout(() => func(...args), wait)
  }
}

// 节流函数
export const throttle = <T extends (...args: any[]) => any>(
  func: T,
  wait: number
): ((...args: Parameters<T>) => void) => {
  let timeout: NodeJS.Timeout | null = null
  let previous = 0
  
  return (...args: Parameters<T>) => {
    const now = Date.now()
    if (now - previous > wait) {
      func(...args)
      previous = now
    } else if (!timeout) {
      timeout = setTimeout(() => {
        func(...args)
        previous = Date.now()
        timeout = null
      }, wait - (now - previous))
    }
  }
}

// 深拷贝
export const deepClone = <T>(obj: T): T => {
  if (obj === null || typeof obj !== 'object') return obj
  if (obj instanceof Date) return new Date(obj.getTime()) as any
  if (obj instanceof Array) return obj.map(item => deepClone(item)) as any
  if (typeof obj === 'object') {
    const clonedObj = {} as any
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        clonedObj[key] = deepClone(obj[key])
      }
    }
    return clonedObj
  }
  return obj
}

// 生成随机ID
export const generateId = (prefix = 'id') => {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
}

// 验证邮箱
export const isValidEmail = (email: string) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

// 验证手机号
export const isValidPhone = (phone: string) => {
  const phoneRegex = /^1[3-9]\d{9}$/
  return phoneRegex.test(phone)
}

// 验证URL
export const isValidUrl = (url: string) => {
  try {
    new URL(url)
    return true
  } catch {
    return false
  }
}

// 获取文件扩展名
export const getFileExtension = (filename: string) => {
  return filename.split('.').pop()?.toLowerCase() || ''
}

// 检查文件类型
export const isImageFile = (filename: string) => {
  const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
  return imageExtensions.includes(getFileExtension(filename))
}

export const isVideoFile = (filename: string) => {
  const videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm']
  return videoExtensions.includes(getFileExtension(filename))
}

export const isDocumentFile = (filename: string) => {
  const documentExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt']
  return documentExtensions.includes(getFileExtension(filename))
}

// 下载文件
export const downloadFile = (blob: Blob, filename: string) => {
  const url = window.URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  window.URL.revokeObjectURL(url)
}

// 复制到剪贴板
export const copyToClipboard = async (text: string) => {
  try {
    await navigator.clipboard.writeText(text)
    return true
  } catch (err) {
    // 降级方案
    const textArea = document.createElement('textarea')
    textArea.value = text
    document.body.appendChild(textArea)
    textArea.select()
    try {
      document.execCommand('copy')
      return true
    } catch (err) {
      return false
    } finally {
      document.body.removeChild(textArea)
    }
  }
}

// 获取查询参数
export const getQueryParams = () => {
  const params = new URLSearchParams(window.location.search)
  const result: Record<string, string> = {}
  for (const [key, value] of params.entries()) {
    result[key] = value
  }
  return result
}

// 设置查询参数
export const setQueryParams = (params: Record<string, string | number | boolean>) => {
  const url = new URL(window.location.href)
  Object.entries(params).forEach(([key, value]) => {
    url.searchParams.set(key, String(value))
  })
  window.history.replaceState({}, '', url.toString())
}

// 移除查询参数
export const removeQueryParams = (keys: string[]) => {
  const url = new URL(window.location.href)
  keys.forEach(key => {
    url.searchParams.delete(key)
  })
  window.history.replaceState({}, '', url.toString())
}
