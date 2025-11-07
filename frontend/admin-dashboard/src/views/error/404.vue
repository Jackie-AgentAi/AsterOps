<template>
  <div class="error-page">
    <div class="error-content">
      <h1>404</h1>
      <h2>页面不存在</h2>
      <p>抱歉，您访问的页面不存在或已被删除。</p>
      <el-button type="primary" @click="goHome">返回首页</el-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()

const goHome = () => {
  router.push('/dashboard')
}
</script>

<style scoped lang="scss">
.error-page {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: #f5f7fa;
}

.error-content {
  text-align: center;
  
  h1 {
    font-size: 120px;
    color: #409eff;
    margin: 0;
    font-weight: bold;
  }
  
  h2 {
    font-size: 32px;
    color: #333;
    margin: 20px 0;
  }
  
  p {
    font-size: 16px;
    color: #666;
    margin-bottom: 30px;
  }
}
</style>
