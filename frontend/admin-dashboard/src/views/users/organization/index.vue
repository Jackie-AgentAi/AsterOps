<template>
  <div class="organization-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <div class="header-left">
        <el-button type="text" @click="goBack" class="back-button">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
        <div class="title-section">
          <h2>组织管理</h2>
          <p>管理组织架构和部门结构</p>
        </div>
      </div>
      <div class="header-right">
        <el-button type="primary" @click="handleAdd">
          <el-icon><Plus /></el-icon>
          添加组织
        </el-button>
      </div>
    </div>

    <!-- 组织架构内容 -->
    <el-row :gutter="20">
      <el-col :span="8">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>组织树</span>
              <el-button type="primary" size="small" @click="handleAdd">
                <el-icon><Plus /></el-icon>
                添加组织
              </el-button>
            </div>
          </template>
          <OrgTree 
            @add="handleAdd"
            @edit="handleEdit"
            @delete="handleDelete"
          />
        </el-card>
      </el-col>
      <el-col :span="16">
        <el-card>
          <template #header>
            <span>组织详情</span>
          </template>
          <div class="org-detail">
            <el-empty description="请选择一个组织查看详情" />
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft, Plus } from '@element-plus/icons-vue'
import OrgTree from './OrgTree.vue'

const router = useRouter()

// 返回上一页
const goBack = () => {
  router.back()
}

// 添加组织
const handleAdd = () => {
  ElMessage.info('添加组织功能待实现')
}

// 编辑组织
const handleEdit = (org: any) => {
  ElMessage.info('编辑组织功能待实现')
}

// 删除组织
const handleDelete = (org: any) => {
  ElMessage.info('删除组织功能待实现')
}
</script>

<style scoped>
.organization-page {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.back-button {
  color: #606266;
}

.title-section h2 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}

.title-section p {
  margin: 4px 0 0 0;
  color: #909399;
  font-size: 14px;
}

.header-right {
  display: flex;
  gap: 12px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.org-detail {
  min-height: 400px;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
