import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { useUserStore } from '@/stores/user'

// 懒加载组件函数，支持预加载
const lazyLoad = (view: string, preload = false) => {
  const importFn = () => import(/* webpackChunkName: "[request]" */ `@/views/${view}/index.vue`)
  
  if (preload) {
    // 预加载关键页面
    setTimeout(() => importFn(), 100)
  }
  
  return importFn
}

// 预加载关键组件
const preloadCriticalComponents = () => {
  // 预加载仪表板和用户管理页面
  lazyLoad('dashboard', true)
  lazyLoad('users', true)
}

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import(/* webpackChunkName: "login" */ '@/views/login/index.vue'),
    meta: { 
      requiresAuth: false,
      title: '登录'
    }
  },
  {
    path: '/',
    component: () => import(/* webpackChunkName: "layout" */ '@/layout/index.vue'),
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: lazyLoad('dashboard'),
        meta: { 
          title: '仪表板', 
          icon: 'Odometer',
          preload: true // 标记为需要预加载
        }
      },
      {
        path: 'users',
        name: 'Users',
        redirect: '/users/user-list',
        meta: { 
          title: '用户管理', 
          icon: 'User',
          preload: true // 标记为需要预加载
        },
        children: [
          {
            path: 'user-list',
            name: 'UserList',
            component: () => import('@/views/users/user-list/index.vue'),
            meta: { 
              title: '用户列表', 
              icon: 'User'
            }
          },
          {
            path: 'user-groups',
            name: 'UserGroups',
            component: () => import('@/views/users/user-group/UserGroupList.vue'),
            meta: { 
              title: '用户组管理', 
              icon: 'UserFilled'
            }
          },
          {
            path: 'user-groups/:id',
            name: 'UserGroupDetail',
            component: () => import('@/views/users/user-group/UserGroupDetail.vue'),
            meta: { 
              title: '用户组详情', 
              icon: 'UserFilled'
            }
          }
        ]
      },
      {
        path: 'projects',
        name: 'Projects',
        component: lazyLoad('projects'),
        meta: { 
          title: '项目管理', 
          icon: 'Folder'
        }
      },
      {
        path: 'models',
        name: 'Models',
        component: lazyLoad('models'),
        meta: { 
          title: '模型管理', 
          icon: 'Box'
        }
      },
      {
        path: 'inference',
        name: 'Inference',
        component: lazyLoad('inference'),
        meta: { 
          title: '推理服务', 
          icon: 'Cpu'
        }
      },
      {
        path: 'costs',
        name: 'Costs',
        component: lazyLoad('costs'),
        meta: { 
          title: '成本管理', 
          icon: 'Money'
        }
      },
      {
        path: 'monitoring',
        name: 'Monitoring',
        component: lazyLoad('monitoring'),
        meta: { title: '监控告警', icon: 'Monitor' }
      },
      {
        path: 'profile',
        name: 'Profile',
        component: () => import('@/views/profile/index.vue'),
        meta: { 
          title: '个人资料', 
          icon: 'User',
          requiresAuth: true
        }
      },
      {
        path: 'settings',
        name: 'Settings',
        component: () => import('@/views/settings/index.vue'),
        meta: { 
          title: '账户设置', 
          icon: 'Setting',
          requiresAuth: true
        }
      }
    ]
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/error/404.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫
router.beforeEach((to, from, next) => {
  const userStore = useUserStore()
  
  if (to.meta.requiresAuth !== false && !userStore.isLoggedIn) {
    next('/login')
  } else if (to.path === '/login' && userStore.isLoggedIn) {
    next('/')
  } else {
    next()
  }
})

export default router



