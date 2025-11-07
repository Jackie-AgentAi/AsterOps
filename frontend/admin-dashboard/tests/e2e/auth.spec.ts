import { test, expect } from '@playwright/test'

test.describe('Authentication Flow', () => {
  test.beforeEach(async ({ page }) => {
    // 导航到登录页面
    await page.goto('/login')
  })

  test('should display login form', async ({ page }) => {
    // 检查登录表单元素
    await expect(page.locator('input[type="text"]')).toBeVisible()
    await expect(page.locator('input[type="password"]')).toBeVisible()
    await expect(page.locator('button[type="submit"]')).toBeVisible()
    
    // 检查页面标题
    await expect(page.locator('h1, h2')).toContainText('登录')
  })

  test('should show validation errors for empty form', async ({ page }) => {
    // 点击登录按钮而不填写表单
    await page.click('button[type="submit"]')
    
    // 检查验证错误消息
    await expect(page.locator('.el-form-item__error')).toBeVisible()
  })

  test('should login successfully with valid credentials', async ({ page }) => {
    // 填写登录表单
    await page.fill('input[type="text"]', 'admin')
    await page.fill('input[type="password"]', 'password123')
    
    // 点击登录按钮
    await page.click('button[type="submit"]')
    
    // 等待重定向到仪表板
    await page.waitForURL('/dashboard')
    
    // 检查是否成功登录
    await expect(page.locator('.header-right')).toBeVisible()
    await expect(page.locator('.username')).toContainText('admin')
  })

  test('should show error for invalid credentials', async ({ page }) => {
    // 填写错误的登录信息
    await page.fill('input[type="text"]', 'wronguser')
    await page.fill('input[type="password"]', 'wrongpassword')
    
    // 点击登录按钮
    await page.click('button[type="submit"]')
    
    // 检查错误消息
    await expect(page.locator('.el-message--error')).toBeVisible()
  })

  test('should logout successfully', async ({ page }) => {
    // 先登录
    await page.fill('input[type="text"]', 'admin')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')
    await page.waitForURL('/dashboard')
    
    // 点击用户下拉菜单
    await page.click('.user-info')
    
    // 点击退出登录
    await page.click('text=退出登录')
    
    // 等待重定向到登录页面
    await page.waitForURL('/login')
    
    // 检查是否成功退出
    await expect(page.locator('input[type="text"]')).toBeVisible()
  })

  test('should redirect to login when accessing protected route without auth', async ({ page }) => {
    // 直接访问受保护的路由
    await page.goto('/users')
    
    // 应该重定向到登录页面
    await page.waitForURL('/login')
    await expect(page.locator('input[type="text"]')).toBeVisible()
  })

  test('should remember login state after page refresh', async ({ page }) => {
    // 先登录
    await page.fill('input[type="text"]', 'admin')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')
    await page.waitForURL('/dashboard')
    
    // 刷新页面
    await page.reload()
    
    // 应该仍然在仪表板页面
    await expect(page).toHaveURL('/dashboard')
    await expect(page.locator('.username')).toContainText('admin')
  })
})









