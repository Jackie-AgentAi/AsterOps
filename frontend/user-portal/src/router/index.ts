import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    redirect: '/dashboard'
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: () => import('../views/dashboard/index.vue'),
    meta: { title: '仪表板' }
  },
  {
    path: '/profile',
    name: 'Profile',
    component: () => import('../views/profile/index.vue'),
    meta: { title: '个人中心' }
  },
  {
    path: '/models',
    name: 'Models',
    component: () => import('../views/models/index.vue'),
    meta: { title: '我的模型' }
  },
  {
    path: '/inference',
    name: 'Inference',
    component: () => import('../views/inference/index.vue'),
    meta: { title: '推理服务' }
  },
  {
    path: '/costs',
    name: 'Costs',
    component: () => import('../views/costs/index.vue'),
    meta: { title: '成本分析' }
  },
  {
    path: '/projects',
    name: 'Projects',
    component: () => import('../views/projects/index.vue'),
    meta: { title: '项目协作' }
  },
  {
    path: '/help',
    name: 'Help',
    component: () => import('../views/help/index.vue'),
    meta: { title: '帮助中心' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router