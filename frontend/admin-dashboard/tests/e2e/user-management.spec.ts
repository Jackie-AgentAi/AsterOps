import { test, expect } from '@playwright/test'

test.describe('User Management', () => {
  test.beforeEach(async ({ page }) => {
    // 登录并导航到用户管理页面
    await page.goto('/login')
    await page.fill('input[type="text"]', 'admin')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')
    await page.waitForURL('/dashboard')
    await page.goto('/users')
  })

  test('should display user management page', async ({ page }) => {
    // 检查页面标题
    await expect(page.locator('h2')).toContainText('用户管理')
    await expect(page.locator('p')).toContainText('管理系统用户、角色和权限')
    
    // 检查用户列表表格
    await expect(page.locator('.el-table')).toBeVisible()
    
    // 检查表格列
    await expect(page.locator('th')).toContainText('ID')
    await expect(page.locator('th')).toContainText('用户名')
    await expect(page.locator('th')).toContainText('邮箱')
    await expect(page.locator('th')).toContainText('角色')
    await expect(page.locator('th')).toContainText('状态')
    await expect(page.locator('th')).toContainText('最后登录')
    await expect(page.locator('th')).toContainText('操作')
  })

  test('should display user list with data', async ({ page }) => {
    // 等待表格加载
    await page.waitForSelector('.el-table tbody tr')
    
    // 检查是否有用户数据
    const rows = page.locator('.el-table tbody tr')
    await expect(rows).toHaveCount(3) // 假设有3个用户
    
    // 检查第一行数据
    const firstRow = rows.first()
    await expect(firstRow.locator('td').nth(1)).toContainText('admin')
    await expect(firstRow.locator('td').nth(2)).toContainText('admin@example.com')
  })

  test('should search users', async ({ page }) => {
    // 在搜索框中输入搜索词
    await page.fill('.search-input', 'admin')
    
    // 点击搜索按钮或按回车
    await page.press('.search-input', 'Enter')
    
    // 等待搜索结果
    await page.waitForTimeout(1000)
    
    // 检查搜索结果
    const rows = page.locator('.el-table tbody tr')
    await expect(rows).toHaveCount(1) // 应该只显示admin用户
    await expect(rows.first().locator('td').nth(1)).toContainText('admin')
  })

  test('should create new user', async ({ page }) => {
    // 点击添加用户按钮
    await page.click('.add-btn')
    
    // 等待对话框打开
    await expect(page.locator('.el-dialog')).toBeVisible()
    await expect(page.locator('.el-dialog__title')).toContainText('添加用户')
    
    // 填写用户信息
    await page.fill('input[placeholder*="用户名"]', 'newuser')
    await page.fill('input[placeholder*="邮箱"]', 'newuser@example.com')
    await page.fill('input[placeholder*="密码"]', 'password123')
    
    // 选择角色
    await page.click('.el-select')
    await page.click('.el-option:has-text("用户")')
    
    // 点击确定按钮
    await page.click('.el-dialog .el-button--primary')
    
    // 等待对话框关闭
    await expect(page.locator('.el-dialog')).not.toBeVisible()
    
    // 检查成功消息
    await expect(page.locator('.el-message--success')).toBeVisible()
    
    // 检查新用户是否出现在列表中
    await expect(page.locator('.el-table tbody tr:has-text("newuser")')).toBeVisible()
  })

  test('should edit user', async ({ page }) => {
    // 等待表格加载
    await page.waitForSelector('.el-table tbody tr')
    
    // 点击第一行的编辑按钮
    await page.click('.el-table tbody tr:first-child .edit-btn')
    
    // 等待编辑对话框打开
    await expect(page.locator('.el-dialog')).toBeVisible()
    await expect(page.locator('.el-dialog__title')).toContainText('编辑用户')
    
    // 修改用户名
    await page.fill('input[placeholder*="用户名"]', 'updateduser')
    
    // 点击确定按钮
    await page.click('.el-dialog .el-button--primary')
    
    // 等待对话框关闭
    await expect(page.locator('.el-dialog')).not.toBeVisible()
    
    // 检查成功消息
    await expect(page.locator('.el-message--success')).toBeVisible()
    
    // 检查用户名是否已更新
    await expect(page.locator('.el-table tbody tr:first-child td:nth-child(2)')).toContainText('updateduser')
  })

  test('should delete user', async ({ page }) => {
    // 等待表格加载
    await page.waitForSelector('.el-table tbody tr')
    
    // 点击第一行的删除按钮
    await page.click('.el-table tbody tr:first-child .delete-btn')
    
    // 等待确认对话框
    await expect(page.locator('.el-message-box')).toBeVisible()
    await expect(page.locator('.el-message-box__message')).toContainText('确定要删除')
    
    // 点击确定
    await page.click('.el-message-box .el-button--primary')
    
    // 等待确认对话框关闭
    await expect(page.locator('.el-message-box')).not.toBeVisible()
    
    // 检查成功消息
    await expect(page.locator('.el-message--success')).toBeVisible()
    
    // 检查用户是否从列表中消失
    const rows = page.locator('.el-table tbody tr')
    await expect(rows).toHaveCount(2) // 应该减少一个用户
  })

  test('should handle batch operations', async ({ page }) => {
    // 等待表格加载
    await page.waitForSelector('.el-table tbody tr')
    
    // 选择多个用户
    await page.check('.el-table tbody tr:first-child .el-checkbox')
    await page.check('.el-table tbody tr:nth-child(2) .el-checkbox')
    
    // 点击批量删除按钮
    await page.click('.batch-delete-btn')
    
    // 等待确认对话框
    await expect(page.locator('.el-message-box')).toBeVisible()
    
    // 点击确定
    await page.click('.el-message-box .el-button--primary')
    
    // 检查成功消息
    await expect(page.locator('.el-message--success')).toBeVisible()
  })

  test('should export user data', async ({ page }) => {
    // 点击导出按钮
    await page.click('.export-btn')
    
    // 检查是否开始下载
    const downloadPromise = page.waitForEvent('download')
    await downloadPromise
    
    // 或者检查成功消息
    await expect(page.locator('.el-message--success')).toBeVisible()
  })

  test('should handle pagination', async ({ page }) => {
    // 检查分页组件是否存在
    await expect(page.locator('.el-pagination')).toBeVisible()
    
    // 点击下一页
    await page.click('.el-pagination .btn-next')
    
    // 检查URL是否包含页码参数
    await expect(page).toHaveURL(/page=2/)
    
    // 点击上一页
    await page.click('.el-pagination .btn-prev')
    
    // 检查URL是否回到第一页
    await expect(page).toHaveURL(/page=1/)
  })

  test('should sort table columns', async ({ page }) => {
    // 等待表格加载
    await page.waitForSelector('.el-table tbody tr')
    
    // 点击用户名列头进行排序
    await page.click('th:has-text("用户名")')
    
    // 检查排序指示器
    await expect(page.locator('th:has-text("用户名") .caret-wrapper')).toBeVisible()
    
    // 再次点击进行降序排序
    await page.click('th:has-text("用户名")')
    
    // 检查排序方向是否改变
    await expect(page.locator('th:has-text("用户名") .sort-caret')).toBeVisible()
  })

  test('should handle user status changes', async ({ page }) => {
    // 等待表格加载
    await page.waitForSelector('.el-table tbody tr')
    
    // 点击状态标签
    await page.click('.el-table tbody tr:first-child .el-tag')
    
    // 等待状态选择器
    await expect(page.locator('.el-select-dropdown')).toBeVisible()
    
    // 选择新状态
    await page.click('.el-select-dropdown .el-option:has-text("禁用")')
    
    // 检查状态是否更新
    await expect(page.locator('.el-table tbody tr:first-child .el-tag')).toContainText('禁用')
  })

  test('should display user details', async ({ page }) => {
    // 等待表格加载
    await page.waitForSelector('.el-table tbody tr')
    
    // 点击查看按钮
    await page.click('.el-table tbody tr:first-child .view-btn')
    
    // 等待详情对话框打开
    await expect(page.locator('.el-dialog')).toBeVisible()
    await expect(page.locator('.el-dialog__title')).toContainText('用户详情')
    
    // 检查详情内容
    await expect(page.locator('.user-detail')).toBeVisible()
    await expect(page.locator('.user-detail')).toContainText('用户名')
    await expect(page.locator('.user-detail')).toContainText('邮箱')
    await expect(page.locator('.user-detail')).toContainText('角色')
    await expect(page.locator('.user-detail')).toContainText('状态')
    
    // 关闭对话框
    await page.click('.el-dialog__close')
    await expect(page.locator('.el-dialog')).not.toBeVisible()
  })
})









