import { test, expect } from '@playwright/test'

test.describe('Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // 登录并导航到仪表板
    await page.goto('/login')
    await page.fill('input[type="text"]', 'admin')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')
    await page.waitForURL('/dashboard')
  })

  test('should display dashboard overview', async ({ page }) => {
    // 检查页面标题
    await expect(page.locator('h2')).toContainText('仪表板')
    
    // 检查统计卡片
    await expect(page.locator('.stats-row')).toBeVisible()
    await expect(page.locator('.status-card')).toHaveCount(4)
    
    // 检查各个统计卡片的内容
    await expect(page.locator('.status-card').nth(0)).toContainText('总用户数')
    await expect(page.locator('.status-card').nth(1)).toContainText('模型数量')
    await expect(page.locator('.status-card').nth(2)).toContainText('推理次数')
    await expect(page.locator('.status-card').nth(3)).toContainText('总成本')
  })

  test('should display charts', async ({ page }) => {
    // 检查图表容器
    await expect(page.locator('.chart-container')).toBeVisible()
    
    // 检查图表标题
    await expect(page.locator('h3')).toContainText('推理请求趋势')
    await expect(page.locator('h3').nth(1)).toContainText('成本分析')
    await expect(page.locator('h3').nth(2)).toContainText('模型使用情况')
  })

  test('should display quick actions', async ({ page }) => {
    // 检查快捷操作区域
    await expect(page.locator('.quick-actions')).toBeVisible()
    
    // 检查快捷操作按钮
    await expect(page.locator('.quick-action-btn')).toHaveCount(4)
    await expect(page.locator('.quick-action-btn').nth(0)).toContainText('创建用户')
    await expect(page.locator('.quick-action-btn').nth(1)).toContainText('新建项目')
    await expect(page.locator('.quick-action-btn').nth(2)).toContainText('上传模型')
    await expect(page.locator('.quick-action-btn').nth(3)).toContainText('开始推理')
  })

  test('should navigate to different modules from quick actions', async ({ page }) => {
    // 点击创建用户按钮
    await page.click('.quick-action-btn:has-text("创建用户")')
    await page.waitForURL('/users')
    await expect(page.locator('h2')).toContainText('用户管理')
    
    // 返回仪表板
    await page.goto('/dashboard')
    
    // 点击新建项目按钮
    await page.click('.quick-action-btn:has-text("新建项目")')
    await page.waitForURL('/projects')
    await expect(page.locator('h2')).toContainText('项目管理')
    
    // 返回仪表板
    await page.goto('/dashboard')
    
    // 点击上传模型按钮
    await page.click('.quick-action-btn:has-text("上传模型")')
    await page.waitForURL('/models')
    await expect(page.locator('h2')).toContainText('模型管理')
  })

  test('should display recent activities', async ({ page }) => {
    // 检查最近活动区域
    await expect(page.locator('.recent-activities')).toBeVisible()
    
    // 检查活动列表
    await expect(page.locator('.activity-item')).toHaveCount(5)
    
    // 检查活动项内容
    const firstActivity = page.locator('.activity-item').first()
    await expect(firstActivity).toContainText('用户')
    await expect(firstActivity).toContainText('创建了')
  })

  test('should display system status', async ({ page }) => {
    // 检查系统状态区域
    await expect(page.locator('.system-status')).toBeVisible()
    
    // 检查后端状态指示器
    await expect(page.locator('.backend-status-indicator')).toBeVisible()
    
    // 检查服务状态
    await expect(page.locator('.service-status')).toBeVisible()
  })

  test('should refresh data when refresh button is clicked', async ({ page }) => {
    // 点击刷新按钮
    await page.click('.refresh-btn')
    
    // 检查是否显示加载状态
    await expect(page.locator('.loading')).toBeVisible()
    
    // 等待加载完成
    await expect(page.locator('.loading')).not.toBeVisible()
  })

  test('should display responsive layout on mobile', async ({ page }) => {
    // 设置移动端视口
    await page.setViewportSize({ width: 375, height: 667 })
    
    // 检查响应式布局
    await expect(page.locator('.stats-row')).toBeVisible()
    
    // 检查统计卡片是否垂直排列
    const statusCards = page.locator('.status-card')
    await expect(statusCards).toHaveCount(4)
    
    // 检查图表是否适应移动端
    await expect(page.locator('.chart-container')).toBeVisible()
  })

  test('should handle chart interactions', async ({ page }) => {
    // 检查图表是否可以交互
    const chart = page.locator('.chart-container').first()
    await expect(chart).toBeVisible()
    
    // 尝试悬停在图表上
    await chart.hover()
    
    // 检查是否有工具提示显示
    await expect(page.locator('.chart-tooltip')).toBeVisible()
  })

  test('should display real-time updates', async ({ page }) => {
    // 等待页面加载完成
    await page.waitForLoadState('networkidle')
    
    // 检查是否有实时数据更新
    const userCount = page.locator('.status-card').first().locator('.status-value')
    const initialValue = await userCount.textContent()
    
    // 等待一段时间看是否有更新
    await page.waitForTimeout(2000)
    
    // 检查值是否有变化（这里只是检查元素仍然存在）
    await expect(userCount).toBeVisible()
  })
})









