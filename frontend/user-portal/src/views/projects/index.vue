<template>
  <div class="projects">
    <div class="page-header">
      <h1>项目协作</h1>
      <p>参与和管理您的项目</p>
    </div>

    <div class="projects-content">
      <div class="card">
        <div class="card-header">
          <h3>我的项目</h3>
          <button class="btn btn-primary" @click="joinProject">加入项目</button>
        </div>
        
        <div class="project-list">
          <div class="project-item" v-for="project in projects" :key="project.id">
            <div class="project-info">
              <h4>{{ project.name }}</h4>
              <p>{{ project.description }}</p>
              <div class="project-meta">
                <span class="project-role">角色: {{ project.role }}</span>
                <span class="project-status" :class="project.status">{{ project.statusText }}</span>
              </div>
            </div>
            <div class="project-actions">
              <button class="btn btn-primary" @click="viewProject(project)">进入</button>
              <button class="btn" @click="leaveProject(project)">退出</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

const projects = ref([
  {
    id: 1,
    name: '智能客服项目',
    description: '基于大语言模型的智能客服系统',
    role: '开发者',
    status: 'active',
    statusText: '进行中'
  },
  {
    id: 2,
    name: '图像识别研究',
    description: '医疗影像AI识别技术研究',
    role: '研究员',
    status: 'active',
    statusText: '进行中'
  },
  {
    id: 3,
    name: '文本分析工具',
    description: '企业文档智能分析平台',
    role: '测试员',
    status: 'completed',
    statusText: '已完成'
  }
])

const joinProject = () => {
  // TODO: 加入项目
  console.log('加入项目')
}

const viewProject = (project: any) => {
  // TODO: 查看项目详情
  console.log('查看项目', project)
}

const leaveProject = (project: any) => {
  // TODO: 退出项目
  console.log('退出项目', project)
}

onMounted(() => {
  // TODO: 加载项目列表
})
</script>

<style scoped>
.projects {
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

.project-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.project-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  background: white;
}

.project-info h4 {
  margin-bottom: 8px;
  color: #333;
}

.project-info p {
  color: #666;
  margin-bottom: 12px;
}

.project-meta {
  display: flex;
  gap: 16px;
  font-size: 12px;
}

.project-role {
  color: #999;
}

.project-status {
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 12px;
}

.project-status.active {
  background: #f6ffed;
  color: #52c41a;
}

.project-status.completed {
  background: #f0f0f0;
  color: #999;
}

.project-actions {
  display: flex;
  gap: 8px;
}

.project-actions .btn {
  padding: 6px 12px;
  font-size: 12px;
}
</style>