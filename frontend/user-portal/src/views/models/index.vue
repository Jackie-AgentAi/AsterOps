<template>
  <div class="models">
    <div class="page-header">
      <h1>我的模型</h1>
      <p>管理您的AI模型和版本</p>
    </div>

    <div class="card">
      <div class="card-header">
        <h3>模型列表</h3>
        <button class="btn btn-primary" @click="uploadModel">上传模型</button>
      </div>
      
      <div class="model-list">
        <div class="model-item" v-for="model in models" :key="model.id">
          <div class="model-info">
            <h4>{{ model.name }}</h4>
            <p>{{ model.description }}</p>
            <div class="model-meta">
              <span class="model-version">版本: {{ model.version }}</span>
              <span class="model-status" :class="model.status">{{ model.statusText }}</span>
            </div>
          </div>
          <div class="model-actions">
            <button class="btn btn-primary" @click="viewModel(model)">查看</button>
            <button class="btn btn-success" @click="deployModel(model)">部署</button>
            <button class="btn" @click="deleteModel(model)">删除</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

const models = ref([
  {
    id: 1,
    name: '文本分类模型',
    description: '用于新闻分类的BERT模型',
    version: 'v1.2.0',
    status: 'active',
    statusText: '已部署'
  },
  {
    id: 2,
    name: '图像识别模型',
    description: 'ResNet50图像分类模型',
    version: 'v2.0.1',
    status: 'inactive',
    statusText: '未部署'
  }
])

const uploadModel = () => {
  // TODO: 上传模型
  console.log('上传模型')
}

const viewModel = (model: any) => {
  // TODO: 查看模型详情
  console.log('查看模型', model)
}

const deployModel = (model: any) => {
  // TODO: 部署模型
  console.log('部署模型', model)
}

const deleteModel = (model: any) => {
  // TODO: 删除模型
  console.log('删除模型', model)
}

onMounted(() => {
  // TODO: 加载模型列表
})
</script>

<style scoped>
.models {
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

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.model-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.model-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  background: white;
}

.model-info h4 {
  margin-bottom: 8px;
  color: #333;
}

.model-info p {
  color: #666;
  margin-bottom: 12px;
}

.model-meta {
  display: flex;
  gap: 16px;
  font-size: 12px;
}

.model-version {
  color: #999;
}

.model-status {
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 12px;
}

.model-status.active {
  background: #f6ffed;
  color: #52c41a;
}

.model-status.inactive {
  background: #fff2e8;
  color: #fa8c16;
}

.model-actions {
  display: flex;
  gap: 8px;
}

.model-actions .btn {
  padding: 6px 12px;
  font-size: 12px;
}
</style>