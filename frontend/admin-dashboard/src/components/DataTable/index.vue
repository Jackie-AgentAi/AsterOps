<template>
  <div class="data-table">
    <!-- 搜索栏 -->
    <div v-if="showSearch" class="search-bar">
      <el-input
        v-model="searchKeyword"
        placeholder="请输入搜索关键词"
        clearable
        @input="handleSearch"
        class="search-input"
      >
        <template #prefix>
          <el-icon><Search /></el-icon>
        </template>
      </el-input>
      
      <el-button type="primary" @click="handleSearch">
        <el-icon><Search /></el-icon>
        搜索
      </el-button>
      
      <el-button @click="handleReset">
        <el-icon><Refresh /></el-icon>
        重置
      </el-button>
    </div>

    <!-- 操作栏 -->
    <div v-if="showActions" class="action-bar">
      <slot name="actions">
        <el-button 
          v-if="showAdd" 
          type="primary" 
          @click="handleAdd"
        >
          <el-icon><Plus /></el-icon>
          新增
        </el-button>
        
        <el-button 
          v-if="showBatchDelete && selectedRows.length > 0" 
          type="danger" 
          @click="handleBatchDelete"
        >
          <el-icon><Delete /></el-icon>
          批量删除
        </el-button>
        
        <el-button 
          v-if="showExport" 
          @click="handleExport"
        >
          <el-icon><Download /></el-icon>
          导出
        </el-button>
      </slot>
    </div>

    <!-- 表格 -->
    <el-table
      :data="tableData"
      :loading="loading"
      :row-key="rowKey"
      @selection-change="handleSelectionChange"
      @sort-change="handleSortChange"
      class="table"
      v-bind="$attrs"
    >
      <!-- 选择列 -->
      <el-table-column
        v-if="showSelection"
        type="selection"
        width="55"
        fixed="left"
      />
      
      <!-- 序号列 -->
      <el-table-column
        v-if="showIndex"
        type="index"
        label="序号"
        width="80"
        fixed="left"
      />
      
      <!-- 数据列 -->
      <el-table-column
        v-for="column in columns"
        :key="column.prop"
        :prop="column.prop"
        :label="column.label"
        :width="column.width"
        :min-width="column.minWidth"
        :sortable="column.sortable"
        :formatter="column.formatter"
        :show-overflow-tooltip="true"
      >
        <template #default="{ row, column: col, $index }">
          <slot 
            :name="column.prop" 
            :row="row" 
            :column="col" 
            :index="$index"
          >
            <span v-if="column.formatter">
              {{ column.formatter(row, col, row[column.prop]) }}
            </span>
            <span v-else>{{ row[column.prop] }}</span>
          </slot>
        </template>
      </el-table-column>
      
      <!-- 操作列 -->
      <el-table-column
        v-if="showActions"
        label="操作"
        :width="actionWidth"
        fixed="right"
      >
        <template #default="{ row, $index }">
          <slot name="actions" :row="row" :index="$index">
            <el-button
              v-if="showView"
              type="primary"
              link
              @click="handleView(row, $index)"
            >
              查看
            </el-button>
            
            <el-button
              v-if="showEdit"
              type="primary"
              link
              @click="handleEdit(row, $index)"
            >
              编辑
            </el-button>
            
            <el-button
              v-if="showDelete"
              type="danger"
              link
              @click="handleDelete(row, $index)"
            >
              删除
            </el-button>
          </slot>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div v-if="showPagination" class="pagination">
      <el-pagination
        :current-page="currentPage"
        :page-size="pageSize"
        :page-sizes="pageSizes"
        :total="total"
        :layout="paginationLayout"
        @current-change="handleCurrentChange"
        @size-change="handleSizeChange"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import type { TableColumn } from '@/types/common'

interface Props {
  data: any[]
  columns: TableColumn[]
  loading?: boolean
  total?: number
  currentPage?: number
  pageSize?: number
  showSearch?: boolean
  showActions?: boolean
  showSelection?: boolean
  showIndex?: boolean
  showPagination?: boolean
  showAdd?: boolean
  showEdit?: boolean
  showView?: boolean
  showDelete?: boolean
  showBatchDelete?: boolean
  showExport?: boolean
  rowKey?: string
  actionWidth?: number
  pageSizes?: number[]
  paginationLayout?: string
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  total: 0,
  currentPage: 1,
  pageSize: 10,
  showSearch: true,
  showActions: true,
  showSelection: false,
  showIndex: false,
  showPagination: true,
  showAdd: true,
  showEdit: true,
  showView: false,
  showDelete: true,
  showBatchDelete: false,
  showExport: false,
  rowKey: 'id',
  actionWidth: 200,
  pageSizes: () => [10, 20, 50, 100],
  paginationLayout: 'total, sizes, prev, pager, next, jumper'
})

const emit = defineEmits<{
  search: [keyword: string]
  add: []
  edit: [row: any, index: number]
  view: [row: any, index: number]
  delete: [row: any, index: number]
  batchDelete: [rows: any[]]
  export: []
  pageChange: [page: number, pageSize: number]
  sortChange: [sortBy: string, sortOrder: string]
}>()

const searchKeyword = ref('')
const selectedRows = ref<any[]>([])

const tableData = computed(() => props.data)

const handleSearch = () => {
  emit('search', searchKeyword.value)
}

const handleReset = () => {
  searchKeyword.value = ''
  emit('search', '')
}

const handleAdd = () => {
  emit('add')
}

const handleEdit = (row: any, index: number) => {
  emit('edit', row, index)
}

const handleView = (row: any, index: number) => {
  emit('view', row, index)
}

const handleDelete = (row: any, index: number) => {
  emit('delete', row, index)
}

const handleBatchDelete = () => {
  emit('batchDelete', selectedRows.value)
}

const handleExport = () => {
  emit('export')
}

const handleSelectionChange = (selection: any[]) => {
  selectedRows.value = selection
}

const handleSizeChange = (size: number) => {
  emit('pageChange', props.currentPage, size)
}

const handleCurrentChange = (page: number) => {
  emit('pageChange', page, props.pageSize)
}

const handleSortChange = ({ prop, order }: { prop: string; order: string }) => {
  emit('sortChange', prop, order)
}

// 监听搜索关键词变化
watch(searchKeyword, (newVal) => {
  if (newVal === '') {
    handleSearch()
  }
})
</script>

<style lang="scss" scoped>
.data-table {
  .search-bar {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 16px;
    
    .search-input {
      width: 300px;
    }
  }
  
  .action-bar {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 16px;
  }
  
  .table {
    width: 100%;
  }
  
  .pagination {
    display: flex;
    justify-content: flex-end;
    margin-top: 16px;
  }
}
</style>
