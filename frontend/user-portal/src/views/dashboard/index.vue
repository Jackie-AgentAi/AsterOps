<template>
  <div class="dashboard">
    <div class="page-header">
      <h1>仪表板</h1>
      <p>欢迎使用LLMOps平台</p>
    </div>

    <div class="stats-grid">
      <div class="stat-card">
        <h3>我的模型</h3>
        <div class="stat-value">{{ stats.models }}</div>
        <div class="stat-desc">已注册模型数量</div>
      </div>
      
      <div class="stat-card">
        <h3>推理次数</h3>
        <div class="stat-value">{{ stats.inferences }}</div>
        <div class="stat-desc">本月推理次数</div>
      </div>
      
      <div class="stat-card">
        <h3>总成本</h3>
        <div class="stat-value">¥{{ stats.cost }}</div>
        <div class="stat-desc">本月使用成本</div>
      </div>
      
      <div class="stat-card">
        <h3>项目数量</h3>
        <div class="stat-value">{{ stats.projects }}</div>
        <div class="stat-desc">参与项目数量</div>
      </div>
    </div>

    <div class="content-grid">
      <div class="card">
        <h3>最近活动</h3>
        <div class="activity-list">
          <div class="activity-item" v-for="activity in recentActivities" :key="activity.id">
            <div class="activity-icon">{{ activity.icon }}</div>
            <div class="activity-content">
              <div class="activity-title">{{ activity.title }}</div>
              <div class="activity-time">{{ activity.time }}</div>
            </div>
          </div>
        </div>
      </div>
      
      <div class="card">
        <h3>快速操作</h3>
        <div class="quick-actions">
          <button class="btn btn-primary" @click="goToModels">管理模型</button>
          <button class="btn btn-success" @click="goToInference">开始推理</button>
          <button class="btn btn-primary" @click="goToProjects">查看项目</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

// 统计数据
const stats = ref({
  models: 0,
  inferences: 0,
  cost: 0,
  projects: 0
})

// 最近活动
const recentActivities = ref([
  { id: 1, icon: '🤖', title: '模型推理完成', time: '2分钟前' },
  { id: 2, icon: '📊', title: '成本报告生成', time: '1小时前' },
  { id: 3, icon: '👥', title: '加入新项目', time: '3小时前' }
])

// 快速操作
const goToModels = () => router.push('/models')
const goToInference = () => router.push('/inference')
const goToProjects = () => router.push('/projects')

// 加载数据
onMounted(() => {
  // TODO: 从API加载真实数据
  stats.value = {
    models: 5,
    inferences: 1234,
    cost: 89.50,
    projects: 3
  }
})
</script>

<style scoped>
.dashboard {
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

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 32px;
}

.stat-card {
  background: white;
  padding: 24px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  text-align: center;
}

.stat-card h3 {
  color: #666;
  font-size: 14px;
  margin-bottom: 12px;
}

.stat-value {
  font-size: 32px;
  font-weight: bold;
  color: #1890ff;
  margin-bottom: 8px;
}

.stat-desc {
  color: #999;
  font-size: 12px;
}

.content-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.activity-list {
  margin-top: 16px;
}

.activity-item {
  display: flex;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
}

.activity-item:last-child {
  border-bottom: none;
}

.activity-icon {
  font-size: 20px;
  margin-right: 12px;
}

.activity-content {
  flex: 1;
}

.activity-title {
  font-weight: 500;
  margin-bottom: 4px;
}

.activity-time {
  color: #999;
  font-size: 12px;
}

.quick-actions {
  margin-top: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.quick-actions .btn {
  width: 100%;
  text-align: center;
}

@media (max-width: 768px) {
  .content-grid {
    grid-template-columns: 1fr;
  }
  
  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>