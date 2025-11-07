<template>
  <div class="profile">
    <div class="page-header">
      <h1>个人中心</h1>
      <p>管理您的个人信息和账户设置</p>
    </div>

    <div class="profile-content">
      <div class="card">
        <h3>基本信息</h3>
        <div class="form-group">
          <label>用户名</label>
          <input type="text" v-model="userInfo.username" readonly />
        </div>
        <div class="form-group">
          <label>邮箱</label>
          <input type="email" v-model="userInfo.email" />
        </div>
        <div class="form-group">
          <label>姓名</label>
          <input type="text" v-model="userInfo.name" />
        </div>
        <button class="btn btn-primary" @click="saveProfile">保存修改</button>
      </div>

      <div class="card">
        <h3>安全设置</h3>
        <div class="form-group">
          <label>当前密码</label>
          <input type="password" v-model="passwordForm.current" />
        </div>
        <div class="form-group">
          <label>新密码</label>
          <input type="password" v-model="passwordForm.new" />
        </div>
        <div class="form-group">
          <label>确认新密码</label>
          <input type="password" v-model="passwordForm.confirm" />
        </div>
        <button class="btn btn-primary" @click="changePassword">修改密码</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

const userInfo = ref({
  username: '',
  email: '',
  name: ''
})

const passwordForm = ref({
  current: '',
  new: '',
  confirm: ''
})

const saveProfile = () => {
  // TODO: 保存用户信息
  console.log('保存用户信息', userInfo.value)
}

const changePassword = () => {
  // TODO: 修改密码
  console.log('修改密码', passwordForm.value)
}

onMounted(() => {
  // TODO: 加载用户信息
  userInfo.value = {
    username: 'user123',
    email: 'user@example.com',
    name: '张三'
  }
})
</script>

<style scoped>
.profile {
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

.profile-content {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 500;
  color: #333;
}

.form-group input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #d9d9d9;
  border-radius: 4px;
  font-size: 14px;
}

.form-group input:focus {
  outline: none;
  border-color: #1890ff;
  box-shadow: 0 0 0 2px rgba(24, 144, 255, 0.2);
}

@media (max-width: 768px) {
  .profile-content {
    grid-template-columns: 1fr;
  }
}
</style>