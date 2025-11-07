<template>
  <div class="group-detail">
    <div class="detail-header">
      <div class="header-left">
        <el-button type="text" @click="goBack" class="back-button">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
        <div class="title-section">
          <h2>{{ group?.name }}</h2>
          <p>{{ group?.description || '暂无描述' }}</p>
        </div>
      </div>
      <div class="header-right">
        <el-button type="primary" @click="handleEdit">
          <el-icon><Edit /></el-icon>
          编辑
        </el-button>
        <el-button type="danger" @click="handleDelete">
          <el-icon><Delete /></el-icon>
          删除
        </el-button>
      </div>
    </div>

    <el-row :gutter="20">
      <!-- 基本信息 -->
      <el-col :span="12">
        <el-card class="info-card">
          <template #header>
            <div class="card-header">
              <el-icon><InfoFilled /></el-icon>
              <span>基本信息</span>
            </div>
          </template>
          <div class="info-content">
            <div class="info-item">
              <label>用户组名称：</label>
              <span>{{ group?.name }}</span>
            </div>
            <div class="info-item">
              <label>描述：</label>
              <span>{{ group?.description || '暂无描述' }}</span>
            </div>
            <div class="info-item">
              <label>所属组织：</label>
              <span>{{ group?.organization_id || '未设置' }}</span>
            </div>
            <div class="info-item">
              <label>父级用户组：</label>
              <span>{{ group?.parent_id || '无' }}</span>
            </div>
            <div class="info-item">
              <label>创建时间：</label>
              <span>{{ formatDate(group?.created_at) }}</span>
            </div>
            <div class="info-item">
              <label>更新时间：</label>
              <span>{{ formatDate(group?.updated_at) }}</span>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 统计信息 -->
      <el-col :span="12">
        <el-card class="stats-card">
          <template #header>
            <div class="card-header">
              <el-icon><TrendCharts /></el-icon>
              <span>统计信息</span>
            </div>
          </template>
          <div class="stats-content">
            <div class="stat-item">
              <div class="stat-icon members">
                <el-icon><UserFilled /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ memberCount }}</div>
                <div class="stat-label">成员数量</div>
              </div>
            </div>
            <div class="stat-item">
              <div class="stat-icon groups">
                <el-icon><UserFilled /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ subGroupCount }}</div>
                <div class="stat-label">子组数量</div>
              </div>
            </div>
            <div class="stat-item">
              <div class="stat-icon active">
                <el-icon><UserFilled /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ activeMemberCount }}</div>
                <div class="stat-label">活跃成员</div>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 成员列表 -->
    <el-card class="members-card">
      <template #header>
        <div class="card-header">
          <el-icon><UserFilled /></el-icon>
          <span>成员列表</span>
          <el-button type="primary" size="small" @click="handleManageMembers">
            管理成员
          </el-button>
        </div>
      </template>
      <div class="members-preview">
        <div v-if="recentMembers.length === 0" class="empty-state">
          <el-empty description="暂无成员" />
        </div>
        <div v-else class="member-list">
          <div
            v-for="member in recentMembers"
            :key="member.id"
            class="member-item"
          >
            <el-avatar :size="40" :src="member.user?.avatar">
              {{ member.user?.username?.charAt(0) }}
            </el-avatar>
            <div class="member-info">
              <div class="member-name">{{ member.user?.username }}</div>
              <div class="member-role">
                <el-tag :type="getRoleType(member.role)" size="small">
                  {{ getRoleText(member.role) }}
                </el-tag>
              </div>
            </div>
            <div class="member-time">
              {{ formatDate(member.joined_at) }}
            </div>
          </div>
        </div>
        <div v-if="memberCount > 5" class="view-more">
          <el-button type="text" @click="handleManageMembers">
            查看全部 {{ memberCount }} 个成员
            <el-icon><ArrowRight /></el-icon>
          </el-button>
        </div>
      </div>
    </el-card>

    <!-- 子用户组 -->
    <el-card class="subgroups-card" v-if="subGroups.length > 0">
      <template #header>
        <div class="card-header">
          <el-icon><UserFilled /></el-icon>
          <span>子用户组</span>
        </div>
      </template>
      <div class="subgroups-list">
        <div
          v-for="subGroup in subGroups"
          :key="subGroup.id"
          class="subgroup-item"
          @click="handleViewSubGroup(subGroup)"
        >
          <div class="subgroup-info">
            <div class="subgroup-name">{{ subGroup.name }}</div>
            <div class="subgroup-desc">{{ subGroup.description || '暂无描述' }}</div>
          </div>
          <div class="subgroup-stats">
            <el-tag size="small">{{ subGroup.member_count || 0 }} 成员</el-tag>
          </div>
          <el-icon class="subgroup-arrow"><ArrowRight /></el-icon>
        </div>
      </div>
    </el-card>

    <!-- 设置信息 -->
    <el-card class="settings-card" v-if="group?.settings">
      <template #header>
        <div class="card-header">
          <el-icon><Setting /></el-icon>
          <span>设置信息</span>
        </div>
      </template>
      <div class="settings-content">
        <pre>{{ formatSettings(group.settings) }}</pre>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  ArrowLeft, 
  Edit, 
  Delete, 
  InfoFilled, 
  TrendCharts, 
  UserFilled, 
  Setting,
  ArrowRight
} from '@element-plus/icons-vue'
import { 
  getUserGroupById, 
  deleteUserGroup, 
  getGroupMembers,
  getUserGroups
} from '@/api/user'
import { formatDate } from '@/utils'
import type { UserGroup, UserGroupMember } from '@/types'

const props = defineProps<{
  groupId: string
}>()

const emit = defineEmits<{
  edit: [group: UserGroup]
  delete: [group: UserGroup]
  manageMembers: [group: UserGroup]
}>()

const router = useRouter()

// 响应式数据
const group = ref<UserGroup | null>(null)
const memberList = ref<UserGroupMember[]>([])
const subGroups = ref<UserGroup[]>([])
const loading = ref(false)

// 计算属性
const memberCount = computed(() => memberList.value.length)
const activeMemberCount = computed(() => 
  memberList.value.filter(member => member.user?.is_active).length
)
const subGroupCount = computed(() => subGroups.value.length)
const recentMembers = computed(() => memberList.value.slice(0, 5))

// 获取用户组详情
const fetchGroupDetail = async () => {
  loading.value = true
  try {
    const response = await getUserGroupById(props.groupId)
    group.value = response.data
  } catch (error) {
    ElMessage.error('获取用户组详情失败')
  } finally {
    loading.value = false
  }
}

// 获取成员列表
const fetchMemberList = async () => {
  try {
    const response = await getGroupMembers(props.groupId)
    memberList.value = response.data || []
  } catch (error) {
    console.error('获取成员列表失败:', error)
  }
}

// 获取子用户组
const fetchSubGroups = async () => {
  try {
    const response = await getUserGroups({ page: 1, pageSize: 100 })
    subGroups.value = (response.data?.items || []).filter(
      g => g.parent_id === props.groupId
    )
  } catch (error) {
    console.error('获取子用户组失败:', error)
  }
}

// 返回上一页
const goBack = () => {
  router.go(-1)
}

// 编辑用户组
const handleEdit = () => {
  if (group.value) {
    emit('edit', group.value)
  }
}

// 删除用户组
const handleDelete = async () => {
  if (!group.value) return

  try {
    await ElMessageBox.confirm(
      `确定要删除用户组"${group.value.name}"吗？删除后不可恢复。`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await deleteUserGroup(props.groupId)
    ElMessage.success('删除成功')
    emit('delete', group.value)
    goBack()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 管理成员
const handleManageMembers = () => {
  if (group.value) {
    emit('manageMembers', group.value)
  }
}

// 查看子用户组
const handleViewSubGroup = (subGroup: UserGroup) => {
  router.push(`/users/user-groups/${subGroup.id}`)
}

// 工具函数
const getRoleType = (role: string) => {
  const roleMap: Record<string, string> = {
    admin: 'danger',
    leader: 'warning',
    member: 'info'
  }
  return roleMap[role] || 'info'
}

const getRoleText = (role: string) => {
  const roleMap: Record<string, string> = {
    admin: '管理员',
    leader: '组长',
    member: '成员'
  }
  return roleMap[role] || '未知'
}

const formatSettings = (settings: string) => {
  try {
    return JSON.stringify(JSON.parse(settings), null, 2)
  } catch {
    return settings
  }
}

// 初始化
onMounted(() => {
  fetchGroupDetail()
  fetchMemberList()
  fetchSubGroups()
})
</script>

<style lang="scss" scoped>
.group-detail {
  .detail-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 20px;
    
    .header-left {
      display: flex;
      align-items: center;
      gap: 16px;
      
      .back-button {
        color: #409eff;
        font-size: 14px;
        
        &:hover {
          color: #66b1ff;
        }
      }
      
      .title-section {
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
    }
    
    .header-right {
      display: flex;
      gap: 12px;
    }
  }
  
  .info-card, .stats-card, .members-card, .subgroups-card, .settings-card {
    margin-bottom: 20px;
    
    .card-header {
      display: flex;
      align-items: center;
      gap: 8px;
      font-weight: 600;
      color: #303133;
    }
  }
  
  .info-content {
    .info-item {
      display: flex;
      margin-bottom: 12px;
      
      label {
        width: 100px;
        color: #909399;
        font-size: 14px;
      }
      
      span {
        color: #303133;
        font-size: 14px;
      }
    }
  }
  
  .stats-content {
    .stat-item {
      display: flex;
      align-items: center;
      margin-bottom: 20px;
      
      .stat-icon {
        width: 48px;
        height: 48px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-right: 16px;
        font-size: 20px;
        
        &.members {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
        }
        
        &.groups {
          background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
          color: white;
        }
        
        &.active {
          background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
          color: white;
        }
      }
      
      .stat-info {
        .stat-value {
          font-size: 24px;
          font-weight: 600;
          color: #303133;
          margin-bottom: 4px;
        }
        
        .stat-label {
          font-size: 14px;
          color: #909399;
        }
      }
    }
  }
  
  .members-preview {
    .empty-state {
      text-align: center;
      padding: 40px 0;
    }
    
    .member-list {
      .member-item {
        display: flex;
        align-items: center;
        padding: 12px 0;
        border-bottom: 1px solid #f0f0f0;
        
        &:last-child {
          border-bottom: none;
        }
        
        .member-info {
          flex: 1;
          margin-left: 12px;
          
          .member-name {
            font-weight: 500;
            color: #303133;
            margin-bottom: 4px;
          }
          
          .member-role {
            margin-bottom: 0;
          }
        }
        
        .member-time {
          font-size: 12px;
          color: #909399;
        }
      }
    }
    
    .view-more {
      text-align: center;
      padding-top: 16px;
      border-top: 1px solid #f0f0f0;
      margin-top: 16px;
    }
  }
  
  .subgroups-list {
    .subgroup-item {
      display: flex;
      align-items: center;
      padding: 16px;
      border: 1px solid #e4e7ed;
      border-radius: 8px;
      margin-bottom: 12px;
      cursor: pointer;
      transition: all 0.3s ease;
      
      &:hover {
        border-color: #409eff;
        box-shadow: 0 2px 8px rgba(64, 158, 255, 0.15);
      }
      
      &:last-child {
        margin-bottom: 0;
      }
      
      .subgroup-info {
        flex: 1;
        
        .subgroup-name {
          font-weight: 500;
          color: #303133;
          margin-bottom: 4px;
        }
        
        .subgroup-desc {
          font-size: 14px;
          color: #909399;
        }
      }
      
      .subgroup-stats {
        margin-right: 12px;
      }
      
      .subgroup-arrow {
        color: #c0c4cc;
      }
    }
  }
  
  .settings-content {
    pre {
      background: #f5f7fa;
      padding: 16px;
      border-radius: 8px;
      font-size: 12px;
      color: #606266;
      overflow-x: auto;
      margin: 0;
    }
  }
}
</style>