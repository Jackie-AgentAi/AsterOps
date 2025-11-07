<template>
  <div class="inference">
    <div class="page-header">
      <h1>推理服务</h1>
      <p>使用您的模型进行推理预测</p>
    </div>

    <div class="inference-content">
      <div class="card">
        <h3>选择模型</h3>
        <select v-model="selectedModel" class="model-select">
          <option value="">请选择模型</option>
          <option v-for="model in models" :key="model.id" :value="model.id">
            {{ model.name }} ({{ model.version }})
          </option>
        </select>
      </div>

      <div class="card" v-if="selectedModel">
        <h3>输入数据</h3>
        <textarea 
          v-model="inputData" 
          placeholder="请输入要推理的数据..."
          class="input-textarea"
          rows="6"
        ></textarea>
        <button class="btn btn-primary" @click="runInference" :disabled="loading">
          {{ loading ? '推理中...' : '开始推理' }}
        </button>
      </div>

      <div class="card" v-if="result">
        <h3>推理结果</h3>
        <div class="result-content">
          <pre>{{ result }}</pre>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

const selectedModel = ref('')
const inputData = ref('')
const result = ref('')
const loading = ref(false)

const models = ref([
  { id: 1, name: '文本分类模型', version: 'v1.2.0' },
  { id: 2, name: '图像识别模型', version: 'v2.0.1' }
])

const runInference = async () => {
  if (!selectedModel.value || !inputData.value) return
  
  loading.value = true
  try {
    // TODO: 调用推理API
    await new Promise(resolve => setTimeout(resolve, 2000)) // 模拟API调用
    result.value = JSON.stringify({
      prediction: '正面',
      confidence: 0.95,
      processing_time: '1.2s'
    }, null, 2)
  } catch (error) {
    console.error('推理失败:', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  // TODO: 加载可用模型
})
</script>

<style scoped>
.inference {
  padding: 24px;
}

.page-header {
  margin-bottom: 32px;
}

.page-header h1 {
  font-size: 28px;
  color: #333;
  margin-bottom: 8px;
}

.page-header p {
  color: #666;
  font-size: 16px;
}

.inference-content {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.model-select {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #d9d9d9;
  border-radius: 4px;
  font-size: 14px;
}

.input-textarea {
  width: 100%;
  padding: 12px;
  border: 1px solid #d9d9d9;
  border-radius: 4px;
  font-size: 14px;
  resize: vertical;
  margin-bottom: 16px;
}

.result-content {
  background: #f5f5f5;
  padding: 16px;
  border-radius: 4px;
  border: 1px solid #d9d9d9;
}

.result-content pre {
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
}
</style>