<template>
  <div class="virtual-list" :style="{ height: containerHeight + 'px' }" @scroll="handleScroll">
    <div class="virtual-list-spacer" :style="{ height: totalHeight + 'px' }">
      <div
        class="virtual-list-items"
        :style="{ transform: `translateY(${offsetY}px)` }"
      >
        <div
          v-for="item in visibleItems"
          :key="getItemKey(item)"
          class="virtual-list-item"
          :style="{ height: itemHeight + 'px' }"
        >
          <slot :item="item" :index="getItemIndex(item)">
            {{ item }}
          </slot>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'

interface Props {
  items: any[]
  itemHeight: number
  containerHeight: number
  overscan?: number
  itemKey?: string | ((item: any) => string | number)
}

const props = withDefaults(defineProps<Props>(), {
  overscan: 5,
  itemKey: 'id'
})

const scrollTop = ref(0)
const containerRef = ref<HTMLElement>()

// 计算可见范围
const visibleRange = computed(() => {
  const start = Math.floor(scrollTop.value / props.itemHeight)
  const end = Math.min(
    start + Math.ceil(props.containerHeight / props.itemHeight) + props.overscan,
    props.items.length
  )
  
  return {
    start: Math.max(0, start - props.overscan),
    end
  }
})

// 可见项目
const visibleItems = computed(() => {
  return props.items.slice(visibleRange.value.start, visibleRange.value.end)
})

// 总高度
const totalHeight = computed(() => {
  return props.items.length * props.itemHeight
})

// 偏移量
const offsetY = computed(() => {
  return visibleRange.value.start * props.itemHeight
})

// 获取项目键
const getItemKey = (item: any) => {
  if (typeof props.itemKey === 'function') {
    return props.itemKey(item)
  }
  return item[props.itemKey]
}

// 获取项目索引
const getItemIndex = (item: any) => {
  return props.items.findIndex(i => getItemKey(i) === getItemKey(item))
}

// 滚动处理
const handleScroll = (event: Event) => {
  const target = event.target as HTMLElement
  scrollTop.value = target.scrollTop
}

// 滚动到指定项目
const scrollToItem = (index: number) => {
  if (containerRef.value) {
    const scrollTop = index * props.itemHeight
    containerRef.value.scrollTop = scrollTop
  }
}

// 滚动到顶部
const scrollToTop = () => {
  scrollToItem(0)
}

// 滚动到底部
const scrollToBottom = () => {
  scrollToItem(props.items.length - 1)
}

// 获取可见项目范围
const getVisibleRange = () => {
  return visibleRange.value
}

// 暴露方法
defineExpose({
  scrollToItem,
  scrollToTop,
  scrollToBottom,
  getVisibleRange
})

// 监听项目变化，重置滚动位置
watch(() => props.items, () => {
  scrollTop.value = 0
  if (containerRef.value) {
    containerRef.value.scrollTop = 0
  }
})
</script>

<style lang="scss" scoped>
.virtual-list {
  overflow-y: auto;
  overflow-x: hidden;
  position: relative;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  
  &::-webkit-scrollbar {
    width: 6px;
  }
  
  &::-webkit-scrollbar-track {
    background: #f1f1f1;
    border-radius: 3px;
  }
  
  &::-webkit-scrollbar-thumb {
    background: #c1c1c1;
    border-radius: 3px;
    
    &:hover {
      background: #a8a8a8;
    }
  }
}

.virtual-list-spacer {
  position: relative;
}

.virtual-list-items {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
}

.virtual-list-item {
  display: flex;
  align-items: center;
  padding: 0 16px;
  border-bottom: 1px solid #f0f0f0;
  transition: background-color 0.2s ease;
  
  &:hover {
    background-color: #f5f7fa;
  }
  
  &:last-child {
    border-bottom: none;
  }
}

// 加载状态
.virtual-list-item.loading {
  display: flex;
  align-items: center;
  justify-content: center;
  color: #999;
  font-size: 14px;
}

// 空状态
.virtual-list-item.empty {
  display: flex;
  align-items: center;
  justify-content: center;
  color: #999;
  font-size: 14px;
  background-color: #fafafa;
}

// 响应式设计
@media (max-width: 768px) {
  .virtual-list-item {
    padding: 0 12px;
  }
}
</style>
