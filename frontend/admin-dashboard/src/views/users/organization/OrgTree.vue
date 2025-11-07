<template>
  <div class="org-tree">
    <div class="tree-header">
      <h3>组织架构</h3>
      <el-button type="primary" @click="handleAddRoot">
        <el-icon><Plus /></el-icon>
        添加根组织
      </el-button>
    </div>
    
    <el-tree
      ref="treeRef"
      :data="treeData"
      :props="treeProps"
      node-key="id"
      :expand-on-click-node="false"
      :default-expand-all="false"
      class="organization-tree"
    >
      <template #default="{ node, data }">
        <div class="tree-node">
          <div class="node-content">
            <el-icon class="node-icon">
              <OfficeBuilding />
            </el-icon>
            <span class="node-label">{{ data.name }}</span>
            <el-tag v-if="data.status === 'active'" type="success" size="small">活跃</el-tag>
            <el-tag v-else type="danger" size="small">禁用</el-tag>
          </div>
          <div class="node-actions">
            <el-button type="primary" link size="small" @click="handleAddChild(data)">
              添加子组织
            </el-button>
            <el-button type="primary" link size="small" @click="handleEdit(data)">
              编辑
            </el-button>
            <el-button type="danger" link size="small" @click="handleDelete(data)">
              删除
            </el-button>
          </div>
        </div>
      </template>
    </el-tree>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, OfficeBuilding } from '@element-plus/icons-vue'
import { getOrganizationTree, deleteOrganization } from '@/api/user'
import type { Organization, OrganizationTreeNode } from '@/types'

const emit = defineEmits<{
  add: [parentId?: string]
  edit: [organization: Organization]
  delete: [organization: Organization]
}>()

const treeRef = ref()
const treeData = ref<OrganizationTreeNode[]>([])
const loading = ref(false)

const treeProps = {
  children: 'children',
  label: 'name'
}

// 获取组织树数据
const fetchTreeData = async () => {
  loading.value = true
  try {
    const response = await getOrganizationTree()
    treeData.value = response
  } catch (error) {
    ElMessage.error('获取组织树失败')
  } finally {
    loading.value = false
  }
}

// 添加根组织
const handleAddRoot = () => {
  emit('add')
}

// 添加子组织
const handleAddChild = (parent: Organization) => {
  emit('add', parent.id)
}

// 编辑组织
const handleEdit = (organization: Organization) => {
  emit('edit', organization)
}

// 删除组织
const handleDelete = async (organization: Organization) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除组织"${organization.name}"吗？删除后不可恢复。`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await deleteOrganization(organization.id)
    ElMessage.success('删除成功')
    await fetchTreeData()
    emit('delete', organization)
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 展开所有节点
const expandAll = () => {
  const nodes = treeRef.value?.store?.nodesMap
  if (nodes) {
    Object.values(nodes).forEach((node: any) => {
      node.expanded = true
    })
  }
}

// 折叠所有节点
const collapseAll = () => {
  const nodes = treeRef.value?.store?.nodesMap
  if (nodes) {
    Object.values(nodes).forEach((node: any) => {
      node.expanded = false
    })
  }
}

onMounted(() => {
  fetchTreeData()
})

defineExpose({
  fetchTreeData,
  expandAll,
  collapseAll
})
</script>

<style lang="scss" scoped>
.org-tree {
  .tree-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
    padding-bottom: 12px;
    border-bottom: 1px solid #e4e7ed;
    
    h3 {
      margin: 0;
      color: #303133;
    }
  }
  
  .organization-tree {
    .tree-node {
      display: flex;
      align-items: center;
      justify-content: space-between;
      width: 100%;
      padding: 4px 0;
      
      .node-content {
        display: flex;
        align-items: center;
        flex: 1;
        
        .node-icon {
          margin-right: 8px;
          color: #409eff;
        }
        
        .node-label {
          margin-right: 8px;
          font-weight: 500;
        }
      }
      
      .node-actions {
        opacity: 0;
        transition: opacity 0.2s;
        
        .el-button {
          margin-left: 4px;
        }
      }
      
      &:hover .node-actions {
        opacity: 1;
      }
    }
  }
}
</style>
