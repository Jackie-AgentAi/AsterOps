import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'
import { visualizer } from 'rollup-plugin-visualizer'
import { compression } from 'vite-plugin-compression2'
import legacy from '@vitejs/plugin-legacy'

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd())
  const isProduction = mode === 'production'

  return {
    plugins: [
      vue({
        template: {
          compilerOptions: {
            // 优化模板编译
            hoistStatic: true,
            cacheHandlers: true
          }
        }
      }),
      // 传统浏览器支持
      legacy({
        targets: ['defaults', 'not IE 11'],
        additionalLegacyPolyfills: ['regenerator-runtime/runtime'],
        renderLegacyChunks: true,
        polyfills: [
          'es.symbol',
          'es.array.filter',
          'es.promise',
          'es.promise.finally',
          'es/map',
          'es/set',
          'es.array.for-each',
          'es.object.define-properties',
          'es.object.get-own-property-descriptor',
          'es.object.get-own-property-descriptors',
          'es.object.keys',
          'es.object.to-string',
          'web.dom-collections.for-each',
          'esnext.global-this',
          'esnext.string.match-all'
        ]
      }),
      // Gzip压缩
      compression({
        algorithm: 'gzip',
        exclude: [/\.(br)$ /, /\.(gz)$/]
      }),
      // Brotli压缩
      compression({
        algorithm: 'brotliCompress',
        exclude: [/\.(br)$ /, /\.(gz)$/]
      }),
      // 打包分析
      isProduction && visualizer({
        filename: 'dist/stats.html',
        open: true,
        gzipSize: true,
        brotliSize: true
      })
    ],
    resolve: {
      alias: {
        '@': resolve(__dirname, 'src')
      }
    },
    server: {
      host: '0.0.0.0',
      port: 3000,
      open: true,
      cors: true,
      fs: {
        strict: false,
        allow: ['..']
      },
      proxy: {
        '/api': {
          target: 'http://172.16.10.3:8081',
          changeOrigin: true,
          secure: false
        },
        '/health': {
          target: 'http://172.16.10.3:8081',
          changeOrigin: true,
          secure: false
        },
        '/ws': {
          target: env.VITE_WS_URL || 'ws://172.16.10.3:8081',
          ws: true,
          changeOrigin: true
        }
      }
    },
    build: {
      outDir: 'dist',
      assetsDir: 'static',
      emptyOutDir: true,
      // 启用CSS代码分割
      cssCodeSplit: true,
      // 启用源码映射
      sourcemap: !isProduction,
      // 压缩配置
      minify: 'terser',
      terserOptions: {
        compress: {
          // 生产环境移除console
          drop_console: isProduction,
          drop_debugger: isProduction,
          // 移除未使用的代码
          pure_funcs: isProduction ? ['console.log', 'console.info'] : []
        },
        mangle: {
          // 混淆变量名
          safari10: true
        }
      },
      // 分包策略
      rollupOptions: {
        output: {
          // 手动分包
          manualChunks: {
            // Vue相关
            vue: ['vue', 'vue-router', 'pinia'],
            // Element Plus
            'element-plus': ['element-plus', '@element-plus/icons-vue'],
            // 图表库
            charts: ['echarts', 'vue-echarts'],
            // 工具库
            utils: ['axios', 'dayjs', 'lodash-es', 'js-cookie', 'mitt'],
            // 第三方库
            vendor: ['nprogress']
          },
          // 资源文件命名
          chunkFileNames: 'static/js/[name]-[hash].js',
          entryFileNames: 'static/js/[name]-[hash].js',
          assetFileNames: (assetInfo) => {
            const info = assetInfo.name.split('.')
            const ext = info[info.length - 1]
            if (/\.(mp4|webm|ogg|mp3|wav|flac|aac)(\?.*)?$/i.test(assetInfo.name)) {
              return `static/media/[name]-[hash].${ext}`
            }
            if (/\.(png|jpe?g|gif|svg)(\?.*)?$/i.test(assetInfo.name)) {
              return `static/images/[name]-[hash].${ext}`
            }
            if (/\.(woff2?|eot|ttf|otf)(\?.*)?$/i.test(assetInfo.name)) {
              return `static/fonts/[name]-[hash].${ext}`
            }
            return `static/[ext]/[name]-[hash].${ext}`
          }
        }
      },
      // 构建大小警告阈值
      chunkSizeWarningLimit: 1000
    },
    // 依赖预构建优化
    optimizeDeps: {
      include: [
        'vue',
        'vue-router',
        'pinia',
        'element-plus',
        '@element-plus/icons-vue',
        'axios',
        'dayjs',
        'lodash-es',
        'js-cookie',
        'mitt',
        'nprogress'
      ],
      exclude: ['@vueuse/core']
    },
    // CSS预处理器配置
    css: {
      preprocessorOptions: {
        scss: {
          additionalData: `@import "@/styles/variables.scss";`
        }
      }
    },
    define: {
      __VUE_OPTIONS_API__: true,
      __VUE_PROD_DEVTOOLS__: false
    }
  }
})