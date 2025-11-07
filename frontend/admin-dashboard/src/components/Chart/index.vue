<template>
  <div class="chart-container" :style="{ height: height + 'px' }">
    <div v-if="loading" class="chart-loading">
      <el-icon class="is-loading"><Loading /></el-icon>
      <span>加载中...</span>
    </div>
    <div v-else ref="chartRef" class="chart"></div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch, nextTick } from 'vue'
import * as echarts from 'echarts'
import type { EChartsOption } from 'echarts'

interface Props {
  option: EChartsOption
  height?: number
  loading?: boolean
  autoResize?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  height: 400,
  loading: false,
  autoResize: true
})

const emit = defineEmits<{
  click: [params: any]
  hover: [params: any]
  selectchanged: [params: any]
}>()

const chartRef = ref<HTMLDivElement>()
let chartInstance: echarts.ECharts | null = null

const initChart = () => {
  if (!chartRef.value) return
  
  chartInstance = echarts.init(chartRef.value)
  
  // 绑定事件
  chartInstance.on('click', (params) => {
    emit('click', params)
  })
  
  chartInstance.on('hover', (params) => {
    emit('hover', params)
  })
  
  chartInstance.on('selectchanged', (params) => {
    emit('selectchanged', params)
  })
  
  // 设置配置
  chartInstance.setOption(props.option, true)
}

const updateChart = () => {
  if (!chartInstance) return
  chartInstance.setOption(props.option, true)
}

const resizeChart = () => {
  if (!chartInstance) return
  chartInstance.resize()
}

const disposeChart = () => {
  if (chartInstance) {
    chartInstance.dispose()
    chartInstance = null
  }
}

// 监听配置变化
watch(() => props.option, updateChart, { deep: true })

// 监听loading状态
watch(() => props.loading, (loading) => {
  if (!loading && chartInstance) {
    nextTick(() => {
      updateChart()
    })
  }
})

onMounted(() => {
  nextTick(() => {
    initChart()
    
    if (props.autoResize) {
      window.addEventListener('resize', resizeChart)
    }
  })
})

onUnmounted(() => {
  if (props.autoResize) {
    window.removeEventListener('resize', resizeChart)
  }
  disposeChart()
})

// 暴露方法
defineExpose({
  chartInstance,
  resize: resizeChart,
  update: updateChart,
  dispose: disposeChart
})
</script>

<style lang="scss" scoped>
.chart-container {
  position: relative;
  width: 100%;
  
  .chart-loading {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100%;
    color: #999;
    
    .el-icon {
      font-size: 24px;
      margin-bottom: 8px;
    }
  }
  
  .chart {
    width: 100%;
    height: 100%;
  }
}
</style>
