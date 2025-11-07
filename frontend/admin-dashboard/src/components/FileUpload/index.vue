<template>
  <div class="file-upload">
    <el-upload
      ref="uploadRef"
      :action="uploadUrl"
      :headers="uploadHeaders"
      :data="uploadData"
      :file-list="fileList"
      :before-upload="beforeUpload"
      :on-progress="onProgress"
      :on-success="onSuccess"
      :on-error="onError"
      :on-remove="onRemove"
      :on-change="onChange"
      :accept="accept"
      :multiple="multiple"
      :disabled="disabled"
      :limit="limit"
      :on-exceed="onExceed"
      :show-file-list="showFileList"
      :drag="drag"
      class="upload-demo"
    >
      <template v-if="drag">
        <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
        <div class="el-upload__text">
          将文件拖到此处，或<em>点击上传</em>
        </div>
      </template>
      
      <template v-else>
        <el-button type="primary" :disabled="disabled">
          <el-icon><Upload /></el-icon>
          {{ buttonText }}
        </el-button>
      </template>
      
      <template #tip>
        <div class="el-upload__tip">
          {{ tip }}
        </div>
      </template>
    </el-upload>
    
    <!-- 上传进度 -->
    <div v-if="showProgress && uploadProgress > 0" class="upload-progress">
      <el-progress 
        :percentage="uploadProgress" 
        :status="uploadStatus"
        :stroke-width="6"
      />
    </div>
    
    <!-- 文件列表 -->
    <div v-if="showFileList && fileList.length > 0" class="file-list">
      <div 
        v-for="(file, index) in fileList" 
        :key="index"
        class="file-item"
      >
        <div class="file-info">
          <el-icon class="file-icon">
            <Document v-if="!isImageFile(file.name)" />
            <Picture v-else />
          </el-icon>
          <span class="file-name">{{ file.name }}</span>
          <span class="file-size">{{ formatFileSize(file.size) }}</span>
        </div>
        
        <div class="file-actions">
          <el-button 
            v-if="file.status === 'success'" 
            type="primary" 
            link
            @click="previewFile(file)"
          >
            预览
          </el-button>
          
          <el-button 
            v-if="file.status === 'success'" 
            type="primary" 
            link
            @click="downloadFile(file)"
          >
            下载
          </el-button>
          
          <el-button 
            type="danger" 
            link
            @click="removeFile(index)"
          >
            删除
          </el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { UploadFilled, Upload, Document, Picture } from '@element-plus/icons-vue'
import { formatFileSize, isImageFile } from '@/utils'
import type { UploadFile, UploadProps, UploadUserFile } from 'element-plus'

interface Props {
  modelValue?: UploadUserFile[]
  uploadUrl?: string
  headers?: Record<string, string>
  data?: Record<string, any>
  accept?: string
  multiple?: boolean
  disabled?: boolean
  limit?: number
  showFileList?: boolean
  showProgress?: boolean
  drag?: boolean
  buttonText?: string
  tip?: string
  maxSize?: number
  allowedTypes?: string[]
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: () => [],
  uploadUrl: '/api/upload',
  headers: () => ({}),
  data: () => ({}),
  accept: '*',
  multiple: false,
  disabled: false,
  limit: 1,
  showFileList: true,
  showProgress: true,
  drag: false,
  buttonText: '选择文件',
  tip: '支持单个文件上传',
  maxSize: 10 * 1024 * 1024, // 10MB
  allowedTypes: () => []
})

const emit = defineEmits<{
  'update:modelValue': [files: UploadUserFile[]]
  success: [response: any, file: UploadFile]
  error: [error: Error, file: UploadFile]
  progress: [event: any, file: UploadFile]
  change: [file: UploadFile, fileList: UploadFile[]]
  remove: [file: UploadFile, fileList: UploadFile[]]
  exceed: [files: File[], fileList: UploadFile[]]
}>()

const uploadRef = ref()
const fileList = ref<UploadUserFile[]>(props.modelValue || [])
const uploadProgress = ref(0)
const uploadStatus = ref<'success' | 'exception' | undefined>()

const uploadHeaders = computed(() => {
  const token = localStorage.getItem('token')
  return {
    ...props.headers,
    ...(token ? { Authorization: `Bearer ${token}` } : {})
  }
})

const uploadData = computed(() => props.data)

const beforeUpload = (file: File) => {
  // 检查文件大小
  if (file.size > props.maxSize) {
    ElMessage.error(`文件大小不能超过 ${formatFileSize(props.maxSize)}`)
    return false
  }
  
  // 检查文件类型
  if (props.allowedTypes.length > 0) {
    const fileType = file.type
    const fileName = file.name
    const fileExtension = fileName.split('.').pop()?.toLowerCase()
    
    const isAllowed = props.allowedTypes.some(type => 
      type === fileType || type === fileExtension
    )
    
    if (!isAllowed) {
      ElMessage.error(`不支持的文件类型: ${fileType}`)
      return false
    }
  }
  
  return true
}

const onProgress = (event: any, file: UploadFile) => {
  uploadProgress.value = Math.round((event.loaded / event.total) * 100)
  uploadStatus.value = undefined
  emit('progress', event, file)
}

const onSuccess = (response: any, file: UploadFile) => {
  uploadProgress.value = 100
  uploadStatus.value = 'success'
  emit('success', response, file)
  ElMessage.success('上传成功')
}

const onError = (error: Error, file: UploadFile) => {
  uploadProgress.value = 0
  uploadStatus.value = 'exception'
  emit('error', error, file)
  ElMessage.error('上传失败')
}

const onChange = (file: UploadFile, fileList: UploadFile[]) => {
  emit('change', file, fileList)
  emit('update:modelValue', fileList)
}

const onRemove = (file: UploadFile, fileList: UploadFile[]) => {
  emit('remove', file, fileList)
  emit('update:modelValue', fileList)
}

const onExceed = (files: File[], fileList: UploadFile[]) => {
  emit('exceed', files, fileList)
  ElMessage.warning(`最多只能上传 ${props.limit} 个文件`)
}

const removeFile = (index: number) => {
  fileList.value.splice(index, 1)
  emit('update:modelValue', fileList.value)
}

const previewFile = (file: UploadUserFile) => {
  if (file.url) {
    window.open(file.url, '_blank')
  }
}

const downloadFile = (file: UploadUserFile) => {
  if (file.url) {
    const link = document.createElement('a')
    link.href = file.url
    link.download = file.name
    link.click()
  }
}

// 清空文件列表
const clearFiles = () => {
  fileList.value = []
  emit('update:modelValue', [])
}

// 提交文件
const submitUpload = () => {
  uploadRef.value?.submit()
}

// 暴露方法
defineExpose({
  clearFiles,
  submitUpload
})
</script>

<style lang="scss" scoped>
.file-upload {
  .upload-progress {
    margin-top: 12px;
  }
  
  .file-list {
    margin-top: 16px;
    
    .file-item {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 8px 12px;
      border: 1px solid #e4e7ed;
      border-radius: 4px;
      margin-bottom: 8px;
      
      .file-info {
        display: flex;
        align-items: center;
        flex: 1;
        
        .file-icon {
          margin-right: 8px;
          color: #409eff;
        }
        
        .file-name {
          margin-right: 8px;
          max-width: 200px;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        
        .file-size {
          color: #999;
          font-size: 12px;
        }
      }
      
      .file-actions {
        display: flex;
        gap: 8px;
      }
    }
  }
}
</style>
