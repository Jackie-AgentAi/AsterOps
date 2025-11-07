<template>
  <div class="user-management-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>用户管理</h2>
      <p>管理系统用户、用户组、角色和权限</p>
    </div>
    
    <!-- 用户统计卡片 -->
    <div class="stats-cards" v-if="userStats">
      <el-row :gutter="20">
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon total">
                <el-icon><User /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-title">总用户数</div>
                <div class="stat-value">{{ userStats.total_users || 0 }}</div>
              </div>
            </div>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon active">
                <el-icon><UserFilled /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-title">活跃用户</div>
                <div class="stat-value">{{ userStats.active_users || 0 }}</div>
              </div>
            </div>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon groups">
                <el-icon><UserFilled /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-title">用户组数</div>
                <div class="stat-value">{{ userStats.total_groups || 0 }}</div>
              </div>
            </div>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon week">
                <el-icon><TrendCharts /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-title">本周新增</div>
                <div class="stat-value">{{ userStats.new_users_week || 0 }}</div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- 加载状态 -->
    <div v-else class="loading-state">
      <el-card>
        <div class="loading-content">
          <el-icon class="is-loading"><Loading /></el-icon>
          <span>加载用户统计中...</span>
        </div>
      </el-card>
    </div>

    <!-- 功能菜单卡片 -->
    <div class="menu-cards">
      <el-row :gutter="20">
        <!-- 用户列表子菜单 -->
        <el-col :span="12">
          <el-card class="menu-card" @click="navigateToUserList">
            <div class="menu-content">
              <div class="menu-icon user-list">
                <el-icon><User /></el-icon>
              </div>
              <div class="menu-info">
                <div class="menu-title">用户列表</div>
                <div class="menu-desc">管理用户信息、权限和状态</div>
                <div class="menu-features">
                  <el-tag size="small" type="info">用户管理</el-tag>
                  <el-tag size="small" type="info">用户详情</el-tag>
                  <el-tag size="small" type="info">导入导出</el-tag>
                  <el-tag size="small" type="info">批量操作</el-tag>
                </div>
              </div>
              <div class="menu-arrow">
                <el-icon><ArrowRight /></el-icon>
              </div>
            </div>
          </el-card>
        </el-col>

        <!-- 用户组子菜单 -->
        <el-col :span="12">
          <el-card class="menu-card" @click="navigateToUserGroups">
            <div class="menu-content">
              <div class="menu-icon user-groups">
                <el-icon><UserFilled /></el-icon>
              </div>
              <div class="menu-info">
                <div class="menu-title">用户组</div>
                <div class="menu-desc">管理用户组、组权限和成员</div>
                <div class="menu-features">
                  <el-tag size="small" type="success">组管理</el-tag>
                  <el-tag size="small" type="success">组权限</el-tag>
                  <el-tag size="small" type="success">组成员</el-tag>
                  <el-tag size="small" type="success">组分析</el-tag>
                </div>
              </div>
              <div class="menu-arrow">
                <el-icon><ArrowRight /></el-icon>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- 快速操作 -->
    <div class="quick-actions">
      <el-card>
        <template #header>
          <div class="card-header">
            <span>快速操作</span>
          </div>
        </template>
        <div class="action-buttons">
          <el-button type="primary" @click="navigateToUserList">
            <el-icon><User /></el-icon>
            用户管理
          </el-button>
          <el-button type="success" @click="navigateToUserGroups">
            <el-icon><UserFilled /></el-icon>
            用户组管理
          </el-button>
        </div>
      </el-card>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, UserFilled, TrendCharts, ArrowRight, OfficeBuilding, Lock, Loading } from '@element-plus/icons-vue'
import { getUserStats } from '@/api/user'
import type { UserStats } from '@/types'

// 路由
const router = useRouter()

// 响应式数据
const userStats = ref<UserStats | null>(null)

// 导航功能
const navigateToUserList = () => {
  router.push('/users/user-list')
}

const navigateToUserGroups = () => {
  router.push('/users/user-groups')
}


// 获取用户统计
const fetchUserStats = async () => {
  try {
    const response = await getUserStats()
    console.log('用户统计响应:', response)
    
    // 安全地处理响应数据
    if (response && response.data) {
      userStats.value = response.data
    } else if (response) {
      userStats.value = response
    } else {
      userStats.value = null
    }
  } catch (error) {
    console.error('获取用户统计失败:', error)
    userStats.value = null
  }
}

// 初始化
onMounted(() => {
  fetchUserStats()
})
</script>

<style lang="scss" scoped>
.user-management-page {
  .page-header {
    margin-bottom: 20px;
    
    h2 {
      margin: 0 0 8px 0;
      color: #333;
    }
    
    p {
      margin: 0;
      color: #666;
      font-size: 14px;
    }
  }
  
  .stats-cards {
    margin-bottom: 20px;
    
    .stat-card {
      .stat-content {
        display: flex;
        align-items: center;
        
        .stat-icon {
          width: 48px;
          height: 48px;
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          margin-right: 16px;
          
          &.total {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
          }
          
          &.active {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white;
          }
          
          &.groups {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: white;
          }
          
          &.week {
            background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
            color: white;
          }
        }
        
        .stat-info {
          flex: 1;
          
          .stat-title {
            font-size: 14px;
            color: #909399;
            margin-bottom: 8px;
          }
          
          .stat-value {
            font-size: 24px;
            font-weight: 600;
            color: #303133;
          }
        }
      }
    }
  }
  
  .menu-cards {
    margin-bottom: 20px;
    
    .menu-card {
      cursor: pointer;
      transition: all 0.3s ease;
      border: 1px solid #e4e7ed;
      
      &:hover {
        border-color: #409eff;
        box-shadow: 0 4px 12px rgba(64, 158, 255, 0.15);
        transform: translateY(-2px);
      }
      
      .menu-content {
        display: flex;
        align-items: center;
        padding: 20px;
        
        .menu-icon {
          width: 60px;
          height: 60px;
          border-radius: 12px;
          display: flex;
          align-items: center;
          justify-content: center;
          margin-right: 20px;
          font-size: 24px;
          
          &.user-list {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
          }
          
          &.user-groups {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: white;
          }
        }
        
        .menu-info {
          flex: 1;
          
          .menu-title {
            font-size: 18px;
            font-weight: 600;
            color: #303133;
            margin-bottom: 8px;
          }
          
          .menu-desc {
            font-size: 14px;
            color: #606266;
            margin-bottom: 12px;
          }
          
          .menu-features {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
          }
        }
        
        .menu-arrow {
          color: #c0c4cc;
          font-size: 16px;
        }
      }
    }
  }
  
  .quick-actions {
    .card-header {
      font-weight: 600;
      color: #303133;
    }
    
    .action-buttons {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }
  }
  
  .loading-state {
    margin-bottom: 20px;
    
    .loading-content {
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 40px;
      color: #909399;
      
      .el-icon {
        margin-right: 8px;
        font-size: 16px;
      }
    }
  }
}
</style>