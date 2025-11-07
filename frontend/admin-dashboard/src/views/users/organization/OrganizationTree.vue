<template>
  <div class="organization-tree">
    <div class="tree-header">
      <h3>组织架构</h3>
      <el-button type="primary" @click="handleAdd">
        <el-icon><Plus /></el-icon>
        新增组织
      </el-button>
    </div>
    
    <div class="tree-content">
      <el-tree
        :data="treeData"
        :props="treeProps"
        :expand-on-click-node="false"
        :default-expand-all="true"
        node-key="id"
        ref="treeRef"
      >
        <template #default="{ node, data }">
          <div class="tree-node">
            <div class="node-content">
              <el-icon class="node-icon">
                <OfficeBuilding v-if="data.type === 'company'" />
                <House v-else-if="data.type === 'department'" />
                <UserFilled v-else-if="data.type === 'team'" />
                <Document v-else />
              </el-icon>
              <span class="node-label">{{ data.name }}</span>
              <el-tag :type="getStatusType(data.status)" size="small">
                {{ getStatusText(data.status) }}
              </el-tag>
            </div>
            <div class="node-actions">
              <el-button type="primary" link @click="handleEdit(data)">
                编辑
              </el-button>
              <el-button type="success" link @click="handleAddChild(data)">
                添加子组织
              </el-button>
              <el-button type="danger" link @click="handleDelete(data)">
                删除
              </el-button>
            </div>
          </div>
        </template>
      </el-tree>
    </div>
    
    <!-- 组织表单对话框 -->
    <OrganizationForm
      v-model="formVisible"
      :organization="selectedOrganization"
      @success="handleFormSuccess"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, OfficeBuilding, House, UserFilled, Document } from '@element-plus/icons-vue'
import { 
  getOrganizationTree, 
  deleteOrganization 
} from '@/api/user'
import OrganizationForm from './OrganizationForm.vue'
import type { Organization } from '@/types'

const treeRef = ref()
const formVisible = ref(false)
const selectedOrganization = ref<Organization | undefined>()
const treeData = ref([])

const treeProps = {
  children: 'children',
  label: 'name'
}

// 获取组织树
const fetchOrganizationTree = async () => {
  try {
    const response = await getOrganizationTree()
    treeData.value = response || []
  } catch (error) {
    ElMessage.error('获取组织树失败')
  }
}

// 新增组织
const handleAdd = () => {
  selectedOrganization.value = undefined
  formVisible.value = true
}

// 编辑组织
const handleEdit = (organization: Organization) => {
  selectedOrganization.value = organization
  formVisible.value = true
}

// 添加子组织
const handleAddChild = (parentOrganization: Organization) => {
  selectedOrganization.value = {
    ...parentOrganization,
    parent_id: parentOrganization.id
  } as Organization
  formVisible.value = true
}

// 删除组织
const handleDelete = (organization: Organization) => {
  ElMessageBox.confirm(
    `确定删除组织 "${organization.name}" 吗？`,
    '提示',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(async () => {
    try {
      await deleteOrganization(organization.id)
      ElMessage.success('删除成功')
      fetchOrganizationTree()
    } catch (error) {
      ElMessage.error('删除失败')
    }
  }).catch(() => {
    ElMessage.info('已取消删除')
  })
}

// 表单成功回调
const handleFormSuccess = () => {
  fetchOrganizationTree()
}

// 获取状态类型
const getStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    active: 'success',
    inactive: 'danger'
  }
  return statusMap[status] || 'info'
}

// 获取状态文本
const getStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    active: '启用',
    inactive: '禁用'
  }
  return statusMap[status] || '未知'
}

// 初始化
onMounted(() => {
  fetchOrganizationTree()
})
</script>

<style lang="scss" scoped>
.organization-tree {
  .tree-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
    
    h3 {
      margin: 0;
      color: #303133;
    }
  }
  
  .tree-content {
    border: 1px solid #e4e7ed;
    border-radius: 4px;
    padding: 16px;
    background: #fff;
    
    .tree-node {
      display: flex;
      justify-content: space-between;
      align-items: center;
      width: 100%;
      
      .node-content {
        display: flex;
        align-items: center;
        flex: 1;
        
        .node-icon {
          margin-right: 8px;
          color: #909399;
        }
        
        .node-label {
          margin-right: 8px;
          font-weight: 500;
        }
      }
      
      .node-actions {
        display: flex;
        gap: 8px;
        opacity: 0;
        transition: opacity 0.3s;
      }
      
      &:hover .node-actions {
        opacity: 1;
      }
    }
  }
}
</style>
