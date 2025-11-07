<template>
  <div class="costs">
    <div class="page-header">
      <h1>成本分析</h1>
      <p>查看您的使用成本和消费统计</p>
    </div>

    <div class="costs-content">
      <div class="stats-row">
        <div class="stat-card">
          <h3>本月总成本</h3>
          <div class="stat-value">¥{{ monthlyCost }}</div>
          <div class="stat-desc">较上月 {{ costTrend }}%</div>
        </div>
        <div class="stat-card">
          <h3>推理成本</h3>
          <div class="stat-value">¥{{ inferenceCost }}</div>
          <div class="stat-desc">占总成本 {{ inferencePercent }}%</div>
        </div>
        <div class="stat-card">
          <h3>存储成本</h3>
          <div class="stat-value">¥{{ storageCost }}</div>
          <div class="stat-desc">占总成本 {{ storagePercent }}%</div>
        </div>
      </div>

      <div class="card">
        <h3>成本趋势</h3>
        <div class="chart-placeholder">
          <p>📊 成本趋势图表</p>
          <p>（此处应显示ECharts图表）</p>
        </div>
      </div>

      <div class="card">
        <h3>详细账单</h3>
        <div class="bill-list">
          <div class="bill-item" v-for="bill in bills" :key="bill.id">
            <div class="bill-info">
              <div class="bill-service">{{ bill.service }}</div>
              <div class="bill-desc">{{ bill.description }}</div>
              <div class="bill-time">{{ bill.time }}</div>
            </div>
            <div class="bill-amount">¥{{ bill.amount }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

const monthlyCost = ref(89.50)
const costTrend = ref(15.8)
const inferenceCost = ref(65.20)
const inferencePercent = ref(73)
const storageCost = ref(24.30)
const storagePercent = ref(27)

const bills = ref([
  {
    id: 1,
    service: '模型推理',
    description: '文本分类模型推理 1000次',
    time: '2024-01-15 14:30',
    amount: 12.50
  },
  {
    id: 2,
    service: '模型存储',
    description: 'ResNet50模型存储 30天',
    time: '2024-01-15 00:00',
    amount: 8.20
  },
  {
    id: 3,
    service: 'API调用',
    description: '推理API调用 500次',
    time: '2024-01-14 16:45',
    amount: 5.80
  }
])

onMounted(() => {
  // TODO: 加载成本数据
})
</script>

<style scoped>
.costs {
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

.stats-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
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
  font-size: 28px;
  font-weight: bold;
  color: #1890ff;
  margin-bottom: 8px;
}

.stat-desc {
  color: #999;
  font-size: 12px;
}

.chart-placeholder {
  height: 300px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  background: #f5f5f5;
  border-radius: 4px;
  color: #999;
}

.bill-list {
  margin-top: 16px;
}

.bill-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 0;
  border-bottom: 1px solid #f0f0f0;
}

.bill-item:last-child {
  border-bottom: none;
}

.bill-service {
  font-weight: 500;
  margin-bottom: 4px;
}

.bill-desc {
  color: #666;
  font-size: 14px;
  margin-bottom: 4px;
}

.bill-time {
  color: #999;
  font-size: 12px;
}

.bill-amount {
  font-weight: bold;
  color: #1890ff;
}
</style>