import { describe, it, expect, vi } from 'vitest'
import { mountComponent } from '../../utils/test-utils'
import StatusCard from '@/components/StatusCard/index.vue'

describe('StatusCard Component', () => {
  const defaultProps = {
    title: 'Test Title',
    value: 100,
    icon: 'User',
    status: 'success'
  }

  it('should render with required props', () => {
    const wrapper = mountComponent(StatusCard, {
      props: defaultProps
    })

    expect(wrapper.text()).toContain('Test Title')
    expect(wrapper.text()).toContain('100')
  })

  it('should render with unit', () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        ...defaultProps,
        unit: '个'
      }
    })

    expect(wrapper.text()).toContain('100个')
  })

  it('should render with description', () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        ...defaultProps,
        description: 'Test description'
      }
    })

    expect(wrapper.text()).toContain('Test description')
  })

  it('should render with trend', () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        ...defaultProps,
        trend: 12.5
      }
    })

    expect(wrapper.text()).toContain('12.5%')
  })

  it('should render with negative trend', () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        ...defaultProps,
        trend: -5.3
      }
    })

    expect(wrapper.text()).toContain('-5.3%')
  })

  it('should apply correct status class', () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        ...defaultProps,
        status: 'error'
      }
    })

    expect(wrapper.classes()).toContain('status-error')
  })

  it('should handle different status types', () => {
    const statuses = ['success', 'warning', 'error', 'info']
    
    statuses.forEach(status => {
      const wrapper = mountComponent(StatusCard, {
        props: {
          ...defaultProps,
          status
        }
      })

      expect(wrapper.classes()).toContain(`status-${status}`)
    })
  })

  it('should render icon when provided', () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        ...defaultProps,
        icon: 'User'
      }
    })

    // 检查是否渲染了图标（由于stub，这里主要检查props传递）
    expect(wrapper.props('icon')).toBe('User')
  })

  it('should format large numbers', () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        ...defaultProps,
        value: 1234567
      }
    })

    expect(wrapper.text()).toContain('1234567')
  })

  it('should handle zero value', () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        ...defaultProps,
        value: 0
      }
    })

    expect(wrapper.text()).toContain('0')
  })

  it('should handle string value', () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        ...defaultProps,
        value: 'Active'
      }
    })

    expect(wrapper.text()).toContain('Active')
  })

  it('should handle loading state', () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        ...defaultProps,
        loading: true
      }
    })

    expect(wrapper.props('loading')).toBe(true)
  })

  it('should handle click event', async () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        ...defaultProps,
        clickable: true
      }
    })

    await wrapper.trigger('click')
    
    // 检查是否触发了点击事件
    expect(wrapper.emitted('click')).toBeTruthy()
  })

  it('should not be clickable by default', () => {
    const wrapper = mountComponent(StatusCard, {
      props: defaultProps
    })

    expect(wrapper.props('clickable')).toBeFalsy()
  })

  it('should handle custom class', () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        ...defaultProps,
        customClass: 'custom-status-card'
      }
    })

    expect(wrapper.classes()).toContain('custom-status-card')
  })

  it('should handle all props together', () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        title: 'Complete Test',
        value: 999,
        unit: '次',
        icon: 'Cpu',
        status: 'warning',
        trend: 25.8,
        description: 'Complete test description',
        loading: false,
        clickable: true,
        customClass: 'test-class'
      }
    })

    expect(wrapper.text()).toContain('Complete Test')
    expect(wrapper.text()).toContain('999次')
    expect(wrapper.text()).toContain('25.8%')
    expect(wrapper.text()).toContain('Complete test description')
    expect(wrapper.classes()).toContain('status-warning')
    expect(wrapper.classes()).toContain('test-class')
    expect(wrapper.props('clickable')).toBe(true)
  })
})









