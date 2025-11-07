<template>
  <div class="user-management">
    <!-- 页面标题 -->
    <div class="page-header">
      <h1>用户管理</h1>
      <p>完整的用户管理解决方案，包括组织架构、用户组、配额管理和审计日志</p>
    </div>
    
    <!-- 功能导航 -->
    <el-card class="nav-card">
      <el-tabs v-model="activeTab" @tab-change="handleTabChange">
        <el-tab-pane label="用户管理" name="users">
          <template #label>
            <span class="tab-label">
              <el-icon><User /></el-icon>
              用户管理
            </span>
          </template>
        </el-tab-pane>
        
        <el-tab-pane label="组织架构" name="organization">
          <template #label>
            <span class="tab-label">
              <el-icon><OfficeBuilding /></el-icon>
              组织架构
            </span>
          </template>
        </el-tab-pane>
        
        <el-tab-pane label="用户组" name="user-groups">
          <template #label>
            <span class="tab-label">
              <el-icon><UserFilled /></el-icon>
              用户组
            </span>
          </template>
        </el-tab-pane>
        
        <el-tab-pane label="配额管理" name="quotas">
          <template #label>
            <span class="tab-label">
              <el-icon><Coin /></el-icon>
              配额管理
            </span>
          </template>
        </el-tab-pane>
        
        <el-tab-pane label="审计日志" name="audit">
          <template #label>
            <span class="tab-label">
              <el-icon><Document /></el-icon>
              审计日志
            </span>
          </template>
        </el-tab-pane>
      </el-tabs>
    </el-card>
    
    <!-- 内容区域 -->
    <div class="content-area">
      <!-- 用户管理 -->
      <div v-if="activeTab === 'users'">
        <UserList />
      </div>
      
      <!-- 组织架构 -->
      <div v-if="activeTab === 'organization'" class="organization-content">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-card>
              <template #header>
                <div class="card-header">
                  <span>组织树</span>
                  <el-button type="primary" size="small" @click="handleAddOrg">
                    <el-icon><Plus /></el-icon>
                    添加组织
                  </el-button>
                </div>
              </template>
              <OrgTree 
                @add="handleAddOrg"
                @edit="handleEditOrg"
                @delete="handleDeleteOrg"
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
      
      <!-- 用户组管理 -->
      <div v-if="activeTab === 'user-groups'">
        <UserGroupList 
          @add="handleAddGroup"
          @edit="handleEditGroup"
          @view="handleViewGroup"
          @delete="handleDeleteGroup"
          @manageMembers="handleManageMembers"
        />
      </div>
      
      <!-- 配额管理 -->
      <div v-if="activeTab === 'quotas'">
        <QuotaList 
          @add="handleAddQuota"
          @edit="handleEditQuota"
          @view="handleViewQuota"
          @delete="handleDeleteQuota"
        />
      </div>
      
      <!-- 审计日志 -->
      <div v-if="activeTab === 'audit'">
        <AuditLog />
      </div>
    </div>
    
    <!-- 组织表单对话框 -->
    <OrgForm 
      v-model="orgFormVisible"
      :organization="selectedOrg"
      :parent-id="selectedParentId"
      @success="handleOrgFormSuccess"
    />
    
    <!-- 用户组表单对话框 -->
    <UserGroupForm 
      v-model="groupFormVisible"
      :user-group="selectedGroup"
      @success="handleGroupFormSuccess"
    />
    
    <!-- 配额表单对话框 -->
    <QuotaForm 
      v-model="quotaFormVisible"
      :quota="selectedQuota"
      @success="handleQuotaFormSuccess"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { ElMessage } from 'element-plus'
import { User, OfficeBuilding, UserFilled, Coin, Document, Plus } from '@element-plus/icons-vue'
import UserList from './index.vue'
import OrgTree from './organization/OrgTree.vue'
import OrgForm from './organization/OrgForm.vue'
import UserGroupList from './user-group/UserGroupList.vue'
import UserGroupForm from './user-group/UserGroupForm.vue'
import QuotaList from './quota/QuotaList.vue'
import QuotaForm from './quota/QuotaForm.vue'
import AuditLog from './audit/AuditLog.vue'
import type { Organization, UserGroup, UserQuota } from '@/types'

// 响应式数据
const activeTab = ref('users')
const orgFormVisible = ref(false)
const groupFormVisible = ref(false)
const quotaFormVisible = ref(false)
const selectedOrg = ref<Organization | undefined>()
const selectedGroup = ref<UserGroup | undefined>()
const selectedQuota = ref<UserQuota | undefined>()
const selectedParentId = ref<string | undefined>()

// 切换标签页
const handleTabChange = (tabName: string) => {
  activeTab.value = tabName
}

// 组织管理事件
const handleAddOrg = (parentId?: string) => {
  selectedOrg.value = undefined
  selectedParentId.value = parentId
  orgFormVisible.value = true
}

const handleEditOrg = (organization: Organization) => {
  selectedOrg.value = organization
  selectedParentId.value = undefined
  orgFormVisible.value = true
}

const handleDeleteOrg = (organization: Organization) => {
  ElMessage.success(`组织"${organization.name}"已删除`)
}

const handleOrgFormSuccess = () => {
  orgFormVisible.value = false
  ElMessage.success('操作成功')
}

// 用户组管理事件
const handleAddGroup = () => {
  selectedGroup.value = undefined
  groupFormVisible.value = true
}

const handleEditGroup = (group: UserGroup) => {
  selectedGroup.value = group
  groupFormVisible.value = true
}

const handleViewGroup = (group: UserGroup) => {
  ElMessage.info(`查看用户组"${group.name}"`)
}

const handleDeleteGroup = (group: UserGroup) => {
  ElMessage.success(`用户组"${group.name}"已删除`)
}

const handleManageMembers = (group: UserGroup) => {
  ElMessage.info(`管理用户组"${group.name}"的成员`)
}

const handleGroupFormSuccess = () => {
  groupFormVisible.value = false
  ElMessage.success('操作成功')
}

// 配额管理事件
const handleAddQuota = () => {
  selectedQuota.value = undefined
  quotaFormVisible.value = true
}

const handleEditQuota = (quota: UserQuota) => {
  selectedQuota.value = quota
  quotaFormVisible.value = true
}

const handleViewQuota = (quota: UserQuota) => {
  ElMessage.info(`查看配额详情`)
}

const handleDeleteQuota = (quota: UserQuota) => {
  ElMessage.success('配额已删除')
}

const handleQuotaFormSuccess = () => {
  quotaFormVisible.value = false
  ElMessage.success('操作成功')
}
</script>

<style lang="scss" scoped>
.user-management {
  .page-header {
    margin-bottom: 24px;
    
    h1 {
      margin: 0 0 8px 0;
      color: #303133;
      font-size: 24px;
      font-weight: 600;
    }
    
    p {
      margin: 0;
      color: #909399;
      font-size: 14px;
    }
  }
  
  .nav-card {
    margin-bottom: 20px;
    
    .tab-label {
      display: flex;
      align-items: center;
      gap: 6px;
    }
  }
  
  .content-area {
    .organization-content {
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
    }
  }
}
</style>
