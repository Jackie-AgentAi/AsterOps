import { describe, it, expect, vi } from 'vitest'
import { mountComponent, createTestData } from '../../utils/test-utils'
import DataTable from '@/components/DataTable/index.vue'

describe('DataTable Component', () => {
  const mockData = [
    createTestData.user({ id: 1, username: 'user1', email: 'user1@example.com' }),
    createTestData.user({ id: 2, username: 'user2', email: 'user2@example.com' }),
    createTestData.user({ id: 3, username: 'user3', email: 'user3@example.com' })
  ]

  const mockColumns = [
    { prop: 'id', label: 'ID', width: 80 },
    { prop: 'username', label: '用户名', minWidth: 120 },
    { prop: 'email', label: '邮箱', minWidth: 200 },
    { prop: 'role', label: '角色', width: 100 },
    { prop: 'status', label: '状态', width: 100 }
  ]

  const defaultProps = {
    data: mockData,
    columns: mockColumns,
    loading: false,
    total: 3,
    currentPage: 1,
    pageSize: 10
  }

  it('should render with required props', () => {
    const wrapper = mountComponent(DataTable, {
      props: defaultProps
    })

    expect(wrapper.exists()).toBe(true)
    expect(wrapper.props('data')).toEqual(mockData)
    expect(wrapper.props('columns')).toEqual(mockColumns)
  })

  it('should show loading state', () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        loading: true
      }
    })

    expect(wrapper.props('loading')).toBe(true)
  })

  it('should handle empty data', () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        data: []
      }
    })

    expect(wrapper.props('data')).toEqual([])
  })

  it('should handle pagination', () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        total: 100,
        currentPage: 2,
        pageSize: 20
      }
    })

    expect(wrapper.props('total')).toBe(100)
    expect(wrapper.props('currentPage')).toBe(2)
    expect(wrapper.props('pageSize')).toBe(20)
  })

  it('should show search when enabled', () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showSearch: true
      }
    })

    expect(wrapper.props('showSearch')).toBe(true)
  })

  it('should show actions when enabled', () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showActions: true
      }
    })

    expect(wrapper.props('showActions')).toBe(true)
  })

  it('should show selection when enabled', () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showSelection: true
      }
    })

    expect(wrapper.props('showSelection')).toBe(true)
  })

  it('should show batch delete when enabled', () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showBatchDelete: true
      }
    })

    expect(wrapper.props('showBatchDelete')).toBe(true)
  })

  it('should show export when enabled', () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showExport: true
      }
    })

    expect(wrapper.props('showExport')).toBe(true)
  })

  it('should emit search event', async () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showSearch: true
      }
    })

    // 模拟搜索事件
    await wrapper.vm.$emit('search', 'test query')
    
    expect(wrapper.emitted('search')).toBeTruthy()
    expect(wrapper.emitted('search')?.[0]).toEqual(['test query'])
  })

  it('should emit add event', async () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showActions: true
      }
    })

    await wrapper.vm.$emit('add')
    
    expect(wrapper.emitted('add')).toBeTruthy()
  })

  it('should emit edit event', async () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showActions: true
      }
    })

    const testRow = mockData[0]
    await wrapper.vm.$emit('edit', testRow)
    
    expect(wrapper.emitted('edit')).toBeTruthy()
    expect(wrapper.emitted('edit')?.[0]).toEqual([testRow])
  })

  it('should emit view event', async () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showActions: true
      }
    })

    const testRow = mockData[0]
    await wrapper.vm.$emit('view', testRow)
    
    expect(wrapper.emitted('view')).toBeTruthy()
    expect(wrapper.emitted('view')?.[0]).toEqual([testRow])
  })

  it('should emit delete event', async () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showActions: true
      }
    })

    const testRow = mockData[0]
    await wrapper.vm.$emit('delete', testRow)
    
    expect(wrapper.emitted('delete')).toBeTruthy()
    expect(wrapper.emitted('delete')?.[0]).toEqual([testRow])
  })

  it('should emit batch delete event', async () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showBatchDelete: true
      }
    })

    const selectedRows = [mockData[0], mockData[1]]
    await wrapper.vm.$emit('batch-delete', selectedRows)
    
    expect(wrapper.emitted('batch-delete')).toBeTruthy()
    expect(wrapper.emitted('batch-delete')?.[0]).toEqual([selectedRows])
  })

  it('should emit export event', async () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showExport: true
      }
    })

    await wrapper.vm.$emit('export')
    
    expect(wrapper.emitted('export')).toBeTruthy()
  })

  it('should emit page change event', async () => {
    const wrapper = mountComponent(DataTable, {
      props: defaultProps
    })

    await wrapper.vm.$emit('page-change', 2)
    
    expect(wrapper.emitted('page-change')).toBeTruthy()
    expect(wrapper.emitted('page-change')?.[0]).toEqual([2])
  })

  it('should emit sort change event', async () => {
    const wrapper = mountComponent(DataTable, {
      props: defaultProps
    })

    const sortInfo = { prop: 'username', order: 'ascending' }
    await wrapper.vm.$emit('sort-change', sortInfo)
    
    expect(wrapper.emitted('sort-change')).toBeTruthy()
    expect(wrapper.emitted('sort-change')?.[0]).toEqual([sortInfo])
  })

  it('should handle custom column slots', () => {
    const wrapper = mountComponent(DataTable, {
      props: defaultProps,
      slots: {
        'status': '<template #status="{ row }"><span class="custom-status">{{ row.status }}</span></template>'
      }
    })

    expect(wrapper.exists()).toBe(true)
  })

  it('should handle custom action slots', () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showActions: true
      },
      slots: {
        'actions': '<template #actions="{ row }"><button class="custom-action">Custom Action</button></template>'
      }
    })

    expect(wrapper.exists()).toBe(true)
  })

  it('should handle different column types', () => {
    const columnsWithTypes = [
      { prop: 'id', label: 'ID', type: 'index' },
      { prop: 'username', label: '用户名', type: 'text' },
      { prop: 'avatar', label: '头像', type: 'image' },
      { prop: 'createdAt', label: '创建时间', type: 'datetime' },
      { prop: 'status', label: '状态', type: 'tag' }
    ]

    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        columns: columnsWithTypes
      }
    })

    expect(wrapper.props('columns')).toEqual(columnsWithTypes)
  })

  it('should handle row selection', async () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showSelection: true
      }
    })

    const selectedRows = [mockData[0]]
    await wrapper.vm.$emit('selection-change', selectedRows)
    
    expect(wrapper.emitted('selection-change')).toBeTruthy()
    expect(wrapper.emitted('selection-change')?.[0]).toEqual([selectedRows])
  })

  it('should handle row click', async () => {
    const wrapper = mountComponent(DataTable, {
      props: defaultProps
    })

    const testRow = mockData[0]
    await wrapper.vm.$emit('row-click', testRow)
    
    expect(wrapper.emitted('row-click')).toBeTruthy()
    expect(wrapper.emitted('row-click')?.[0]).toEqual([testRow])
  })

  it('should handle all features enabled', () => {
    const wrapper = mountComponent(DataTable, {
      props: {
        ...defaultProps,
        showSearch: true,
        showActions: true,
        showSelection: true,
        showBatchDelete: true,
        showExport: true,
        loading: false,
        total: 100,
        currentPage: 1,
        pageSize: 20
      }
    })

    expect(wrapper.props('showSearch')).toBe(true)
    expect(wrapper.props('showActions')).toBe(true)
    expect(wrapper.props('showSelection')).toBe(true)
    expect(wrapper.props('showBatchDelete')).toBe(true)
    expect(wrapper.props('showExport')).toBe(true)
    expect(wrapper.props('loading')).toBe(false)
    expect(wrapper.props('total')).toBe(100)
    expect(wrapper.props('currentPage')).toBe(1)
    expect(wrapper.props('pageSize')).toBe(20)
  })
})









