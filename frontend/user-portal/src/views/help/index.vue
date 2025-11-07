<template>
  <div class="help">
    <div class="page-header">
      <h1>帮助中心</h1>
      <p>获取使用指南和技术支持</p>
    </div>

    <div class="help-content">
      <div class="help-sections">
        <div class="card">
          <h3>📚 使用指南</h3>
          <div class="guide-list">
            <div class="guide-item" v-for="guide in guides" :key="guide.id">
              <h4>{{ guide.title }}</h4>
              <p>{{ guide.description }}</p>
            </div>
          </div>
        </div>

        <div class="card">
          <h3>❓ 常见问题</h3>
          <div class="faq-list">
            <div class="faq-item" v-for="faq in faqs" :key="faq.id">
              <div class="faq-question" @click="toggleFaq(faq.id)">
                {{ faq.question }}
                <span class="faq-icon">{{ expandedFaqs.includes(faq.id) ? '−' : '+' }}</span>
              </div>
              <div class="faq-answer" v-if="expandedFaqs.includes(faq.id)">
                {{ faq.answer }}
              </div>
            </div>
          </div>
        </div>

        <div class="card">
          <h3>📞 联系我们</h3>
          <div class="contact-info">
            <p>📧 邮箱: support@llmops.com</p>
            <p>💬 在线客服: 工作日 9:00-18:00</p>
            <p>📱 技术支持: 400-123-4567</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

const expandedFaqs = ref<number[]>([])

const guides = ref([
  {
    id: 1,
    title: '快速开始',
    description: '了解如何快速上手LLMOps平台'
  },
  {
    id: 2,
    title: '模型管理',
    description: '学习如何上传和管理您的AI模型'
  },
  {
    id: 3,
    title: '推理服务',
    description: '掌握模型推理的使用方法'
  },
  {
    id: 4,
    title: '成本控制',
    description: '了解如何控制和管理使用成本'
  }
])

const faqs = ref([
  {
    id: 1,
    question: '如何上传模型？',
    answer: '在"我的模型"页面点击"上传模型"按钮，选择模型文件并填写相关信息即可。'
  },
  {
    id: 2,
    question: '推理服务如何计费？',
    answer: '推理服务按照实际调用次数和计算资源使用量计费，具体价格请查看定价页面。'
  },
  {
    id: 3,
    question: '如何加入项目？',
    answer: '在"项目协作"页面点击"加入项目"按钮，输入项目邀请码即可加入。'
  },
  {
    id: 4,
    question: '如何联系技术支持？',
    answer: '您可以通过邮箱、在线客服或电话联系我们，我们会在工作时间内及时回复。'
  }
])

const toggleFaq = (id: number) => {
  const index = expandedFaqs.value.indexOf(id)
  if (index > -1) {
    expandedFaqs.value.splice(index, 1)
  } else {
    expandedFaqs.value.push(id)
  }
}

onMounted(() => {
  // TODO: 加载帮助内容
})
</script>

<style scoped>
.help {
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

.help-sections {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}

.guide-list {
  margin-top: 16px;
}

.guide-item {
  padding: 16px 0;
  border-bottom: 1px solid #f0f0f0;
}

.guide-item:last-child {
  border-bottom: none;
}

.guide-item h4 {
  margin-bottom: 8px;
  color: #333;
}

.guide-item p {
  color: #666;
  font-size: 14px;
}

.faq-list {
  margin-top: 16px;
}

.faq-item {
  border-bottom: 1px solid #f0f0f0;
}

.faq-item:last-child {
  border-bottom: none;
}

.faq-question {
  padding: 16px 0;
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: 500;
}

.faq-question:hover {
  color: #1890ff;
}

.faq-icon {
  font-size: 18px;
  color: #1890ff;
}

.faq-answer {
  padding: 0 0 16px 0;
  color: #666;
  line-height: 1.6;
}

.contact-info {
  margin-top: 16px;
}

.contact-info p {
  margin-bottom: 12px;
  color: #666;
}

@media (max-width: 768px) {
  .help-sections {
    grid-template-columns: 1fr;
  }
}
</style>