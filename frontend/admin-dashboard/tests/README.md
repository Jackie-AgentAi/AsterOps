# LLMOps前端测试文档

## 📋 测试概览

本项目采用多层次测试策略，确保代码质量和功能稳定性：

- **单元测试**: 测试单个组件、工具函数和Store
- **集成测试**: 测试API集成、路由和组件交互
- **端到端测试**: 测试完整的用户流程

## 🏗️ 测试架构

```
tests/
├── unit/                    # 单元测试
│   ├── components/         # 组件测试
│   ├── stores/            # Store测试
│   └── utils/             # 工具函数测试
├── integration/            # 集成测试
│   ├── api/               # API集成测试
│   └── router/            # 路由集成测试
├── e2e/                   # 端到端测试
│   ├── auth.spec.ts       # 认证流程测试
│   ├── dashboard.spec.ts  # 仪表板测试
│   └── user-management.spec.ts # 用户管理测试
├── mocks/                 # Mock配置
│   ├── handlers.ts        # API处理器
│   └── server.ts          # Mock服务器
├── utils/                 # 测试工具
│   └── test-utils.ts      # 测试工具函数
└── setup.ts              # 测试设置
```

## 🚀 快速开始

### 安装依赖

```bash
npm install
```

### 运行测试

```bash
# 运行所有测试
npm run test:all

# 运行单元测试
npm run test

# 运行单元测试并生成覆盖率报告
npm run test:coverage

# 运行端到端测试
npm run test:e2e

# 使用UI界面运行测试
npm run test:ui
npm run test:e2e:ui
```

### 使用测试脚本

```bash
# 运行所有测试
./scripts/run-tests.sh all

# 运行单元测试
./scripts/run-tests.sh unit

# 运行单元测试并生成覆盖率报告
./scripts/run-tests.sh unit-coverage

# 运行集成测试
./scripts/run-tests.sh integration

# 运行端到端测试
./scripts/run-tests.sh e2e

# 清理测试文件
./scripts/run-tests.sh clean
```

## 🧪 单元测试

### 测试框架

- **Vitest**: 快速的单元测试框架
- **Vue Test Utils**: Vue组件测试工具
- **Testing Library**: 用户友好的测试工具

### 测试组件

```typescript
import { describe, it, expect } from 'vitest'
import { mountComponent } from '../utils/test-utils'
import StatusCard from '@/components/StatusCard/index.vue'

describe('StatusCard Component', () => {
  it('should render with required props', () => {
    const wrapper = mountComponent(StatusCard, {
      props: {
        title: 'Test Title',
        value: 100,
        icon: 'User',
        status: 'success'
      }
    })

    expect(wrapper.text()).toContain('Test Title')
    expect(wrapper.text()).toContain('100')
  })
})
```

### 测试Store

```typescript
import { describe, it, expect, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useUserStore } from '@/stores/user'

describe('User Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('should login user', () => {
    const userStore = useUserStore()
    const userInfo = { id: 1, username: 'testuser' }
    
    userStore.loginAction(userInfo, 'token', ['read'])
    
    expect(userStore.isLoggedIn).toBe(true)
    expect(userStore.userInfo).toEqual(userInfo)
  })
})
```

### 测试工具函数

```typescript
import { describe, it, expect } from 'vitest'
import { cache } from '@/utils/cache'

describe('Cache Utils', () => {
  it('should store and retrieve values', () => {
    const key = 'test-key'
    const value = { data: 'test-data' }
    
    cache.memory.set(key, value)
    const retrieved = cache.memory.get(key)
    
    expect(retrieved).toEqual(value)
  })
})
```

## 🔗 集成测试

### API集成测试

使用MSW (Mock Service Worker) 模拟API响应：

```typescript
import { setupServer } from 'msw/node'
import { http, HttpResponse } from 'msw'
import { getUserList } from '@/api/user'

const server = setupServer(
  http.get('/api/v1/users', () => {
    return HttpResponse.json({
      code: 200,
      data: { items: [], pagination: { total: 0 } }
    })
  })
)

describe('User API', () => {
  it('should get user list', async () => {
    const result = await getUserList({ page: 1, pageSize: 10 })
    expect(result.items).toEqual([])
  })
})
```

### 路由集成测试

```typescript
import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '@/stores/user'

describe('Router Integration', () => {
  it('should redirect to login for protected routes', async () => {
    const router = createTestRouter()
    const userStore = useUserStore()
    
    userStore.logoutAction()
    await router.push('/dashboard')
    
    expect(router.currentRoute.value.path).toBe('/login')
  })
})
```

## 🎭 端到端测试

### 测试框架

- **Playwright**: 跨浏览器端到端测试
- 支持Chrome、Firefox、Safari和移动端

### 认证流程测试

```typescript
import { test, expect } from '@playwright/test'

test('should login successfully', async ({ page }) => {
  await page.goto('/login')
  await page.fill('input[type="text"]', 'admin')
  await page.fill('input[type="password"]', 'password123')
  await page.click('button[type="submit"]')
  
  await page.waitForURL('/dashboard')
  await expect(page.locator('.username')).toContainText('admin')
})
```

### 用户管理测试

```typescript
test('should create new user', async ({ page }) => {
  await page.goto('/users')
  await page.click('.add-btn')
  
  await page.fill('input[placeholder*="用户名"]', 'newuser')
  await page.fill('input[placeholder*="邮箱"]', 'newuser@example.com')
  await page.click('.el-dialog .el-button--primary')
  
  await expect(page.locator('.el-message--success')).toBeVisible()
})
```

## 📊 测试覆盖率

### 覆盖率目标

- **语句覆盖率**: ≥ 80%
- **分支覆盖率**: ≥ 80%
- **函数覆盖率**: ≥ 80%
- **行覆盖率**: ≥ 80%

### 查看覆盖率报告

```bash
# 生成覆盖率报告
npm run test:coverage

# 打开覆盖率报告
open coverage/index.html
```

## 🛠️ 测试工具

### 测试工具函数

```typescript
// 组件挂载工具
export const mountComponent = (component, options = {}) => {
  const { pinia, router } = createTestApp()
  return mount(component, {
    global: { plugins: [pinia, router] },
    ...options
  })
}

// 测试数据工厂
export const createTestData = {
  user: (overrides = {}) => ({
    id: 1,
    username: 'testuser',
    email: 'test@example.com',
    role: 'admin',
    ...overrides
  })
}

// 用户交互模拟
export const userEvent = {
  click: (element) => element.click(),
  type: (element, text) => {
    element.value = text
    element.dispatchEvent(new Event('input', { bubbles: true }))
  }
}
```

### Mock配置

```typescript
// API Mock
export const handlers = [
  http.get('/api/v1/users', () => {
    return HttpResponse.json({
      code: 200,
      data: { items: [], pagination: { total: 0 } }
    })
  })
]

// 组件Mock
vi.mock('element-plus', () => ({
  ElMessage: {
    success: vi.fn(),
    error: vi.fn()
  }
}))
```

## 🚀 CI/CD集成

### GitHub Actions

测试在每次推送和PR时自动运行：

```yaml
name: Frontend Tests
on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm run test:coverage
```

### 测试报告

- 单元测试覆盖率报告上传到Codecov
- 端到端测试结果保存为Artifacts
- 测试摘要显示在PR中

## 📝 测试最佳实践

### 1. 测试命名

```typescript
// ✅ 好的命名
describe('UserStore', () => {
  it('should login user with valid credentials', () => {
    // 测试实现
  })
})

// ❌ 不好的命名
describe('UserStore', () => {
  it('test login', () => {
    // 测试实现
  })
})
```

### 2. 测试结构

```typescript
describe('Component', () => {
  // Arrange - 准备测试数据
  const props = { title: 'Test' }
  
  it('should do something', () => {
    // Act - 执行操作
    const wrapper = mountComponent(Component, { props })
    
    // Assert - 验证结果
    expect(wrapper.text()).toContain('Test')
  })
})
```

### 3. 测试隔离

```typescript
describe('Test Suite', () => {
  beforeEach(() => {
    // 每个测试前清理状态
    vi.clearAllMocks()
    cache.clearAll()
  })
  
  afterEach(() => {
    // 每个测试后清理
    cleanup()
  })
})
```

### 4. 异步测试

```typescript
it('should handle async operations', async () => {
  const promise = asyncFunction()
  
  await expect(promise).resolves.toBe('expected result')
})

it('should handle async errors', async () => {
  const promise = failingAsyncFunction()
  
  await expect(promise).rejects.toThrow('Expected error')
})
```

## 🐛 调试测试

### 调试单元测试

```bash
# 使用VS Code调试
# 在.vscode/launch.json中配置：
{
  "type": "node",
  "request": "launch",
  "name": "Debug Tests",
  "program": "${workspaceFolder}/node_modules/vitest/vitest.mjs",
  "args": ["run", "--reporter=verbose"],
  "console": "integratedTerminal"
}
```

### 调试端到端测试

```bash
# 使用Playwright UI调试
npm run test:e2e:ui

# 使用浏览器调试
npx playwright test --debug
```

### 测试日志

```typescript
// 在测试中添加日志
it('should do something', () => {
  console.log('Starting test...')
  
  // 测试代码
  
  console.log('Test completed')
})
```

## 📚 参考资料

- [Vitest文档](https://vitest.dev/)
- [Vue Test Utils文档](https://test-utils.vuejs.org/)
- [Playwright文档](https://playwright.dev/)
- [Testing Library文档](https://testing-library.com/)
- [MSW文档](https://mswjs.io/)

## 🤝 贡献指南

1. 为新功能编写测试
2. 确保测试覆盖率达标
3. 遵循测试命名规范
4. 添加必要的Mock
5. 更新测试文档

## 📞 支持

如有测试相关问题，请：

1. 查看本文档
2. 检查测试日志
3. 联系开发团队
4. 提交Issue









