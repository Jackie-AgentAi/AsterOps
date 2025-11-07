<template>
  <div class="lazy-image-container" :style="{ width, height }">
    <img
      v-if="loaded"
      :src="src"
      :alt="alt"
      :class="['lazy-image', { 'fade-in': loaded }]"
      @load="handleLoad"
      @error="handleError"
    />
    <div
      v-else
      class="lazy-image-placeholder"
      :class="{ 'loading': loading }"
    >
      <el-icon v-if="loading" class="loading-icon">
        <Loading />
      </el-icon>
      <span v-else class="placeholder-text">{{ placeholder }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { Loading } from '@element-plus/icons-vue'

interface Props {
  src: string
  alt?: string
  width?: string
  height?: string
  placeholder?: string
  threshold?: number
  rootMargin?: string
  lazy?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  alt: '',
  width: '100%',
  height: 'auto',
  placeholder: '加载中...',
  threshold: 0.1,
  rootMargin: '50px',
  lazy: true
})

const emit = defineEmits<{
  load: [event: Event]
  error: [event: Event]
}>()

const loaded = ref(false)
const loading = ref(false)
const error = ref(false)
const observer = ref<IntersectionObserver | null>(null)

const handleLoad = (event: Event) => {
  loaded.value = true
  loading.value = false
  emit('load', event)
}

const handleError = (event: Event) => {
  error.value = true
  loading.value = false
  emit('error', event)
}

const loadImage = () => {
  if (loaded.value || loading.value) return
  
  loading.value = true
  const img = new Image()
  
  img.onload = () => {
    nextTick(() => {
      loaded.value = true
      loading.value = false
    })
  }
  
  img.onerror = () => {
    error.value = true
    loading.value = false
  }
  
  img.src = props.src
}

const setupIntersectionObserver = () => {
  if (!props.lazy) {
    loadImage()
    return
  }

  observer.value = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          loadImage()
          observer.value?.unobserve(entry.target)
        }
      })
    },
    {
      threshold: props.threshold,
      rootMargin: props.rootMargin
    }
  )
}

onMounted(() => {
  setupIntersectionObserver()
  
  if (observer.value) {
    const container = document.querySelector('.lazy-image-container')
    if (container) {
      observer.value.observe(container)
    }
  }
})

onUnmounted(() => {
  if (observer.value) {
    observer.value.disconnect()
  }
})
</script>

<style lang="scss" scoped>
.lazy-image-container {
  position: relative;
  overflow: hidden;
  background-color: #f5f5f5;
  border-radius: 4px;
}

.lazy-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: opacity 0.3s ease;
  
  &.fade-in {
    opacity: 1;
  }
}

.lazy-image-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  background-color: #f5f5f5;
  color: #999;
  font-size: 14px;
  
  &.loading {
    background-color: #f0f0f0;
  }
  
  .loading-icon {
    animation: spin 1s linear infinite;
    font-size: 20px;
    color: #409eff;
  }
  
  .placeholder-text {
    font-size: 12px;
    color: #999;
  }
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

// 响应式图片
@media (max-width: 768px) {
  .lazy-image-container {
    border-radius: 2px;
  }
}
</style>









