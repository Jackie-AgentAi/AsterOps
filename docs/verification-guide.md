# 用户组功能验证指南

> **文档类型**: 验证测试文档  
> **版本**: v1.0  
> **创建日期**: 2025-01-17

## 一、服务启动检查

### 1.1 后端服务启动

#### 检查服务状态
```bash
# 检查user-service是否运行
ps aux | grep user-service

# 检查端口8081是否被占用
netstat -tlnp | grep 8081
# 或使用
lsof -i :8081
```

#### 启动后端服务
```bash
cd services/user-service

# 方式1: 直接运行
go run cmd/server/main.go

# 方式2: 编译后运行
go build -o bin/user-service cmd/server/main.go
./bin/user-service

# 方式3: 使用Makefile（如果存在）
make run
```

#### 验证后端服务
```bash
# 健康检查
curl http://localhost:8081/health

# 检查API根路径
curl http://localhost:8081/api/v1/

# 检查用户组API（需要认证）
curl -X GET http://localhost:8081/api/v1/user-groups/ \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 1.2 前端服务启动

#### 检查服务状态
```bash
# 检查前端服务是否运行
ps aux | grep vite

# 检查端口3000是否被占用
netstat -tlnp | grep 3000
# 或使用
lsof -i :3000
```

#### 启动前端服务
```bash
cd frontend/admin-dashboard

# 安装依赖（如果未安装）
npm install

# 启动开发服务器
npm run dev

# 或使用yarn
yarn dev
```

#### 验证前端服务
```bash
# 访问前端页面
curl http://localhost:3000

# 检查API代理是否正常
curl http://localhost:3000/api/v1/health
```

## 二、数据库初始化检查

### 2.1 检查数据库连接

```bash
# 连接到PostgreSQL数据库
psql -h localhost -U postgres -d llmops

# 检查用户组表是否存在
\dt user_groups

# 检查admin组是否存在
SELECT * FROM user_groups WHERE id = '00000000-0000-0000-0000-000000000002';

# 检查admin用户是否存在
SELECT * FROM users WHERE id = '00000000-0000-0000-0000-000000000001';

# 检查admin用户是否在admin组中
SELECT ugm.*, u.username, ug.name 
FROM user_group_members ugm
JOIN users u ON ugm.user_id = u.id
JOIN user_groups ug ON ugm.group_id = ug.id
WHERE ug.id = '00000000-0000-0000-0000-000000000002';
```

### 2.2 手动初始化Admin数据

如果admin组不存在，可以手动初始化：

```bash
# 方式1: 调用初始化API（需要认证）
curl -X POST http://localhost:8081/api/v1/admin/init \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"

# 方式2: 执行SQL脚本
psql -h localhost -U postgres -d llmops -f services/user-service/scripts/migrations/004_admin_user_group_assignment.sql
```

## 三、功能验证步骤

### 3.1 布局验证

1. **打开用户组页面**
   - 访问: http://localhost:3000/users/user-groups
   - 登录系统（用户名: admin, 密码: admin123）

2. **检查操作栏布局**
   - ✅ 创建按钮和"更多操作"按钮应在左侧同一行
   - ✅ 搜索框应在右侧，宽度为200px（不再占据整行）
   - ✅ 刷新、设置、导出、导入按钮应在搜索框右侧同一行
   - ✅ 所有按钮不应换行显示

3. **检查表格操作列**
   - ✅ "更新"和"更多"按钮应在同一行显示
   - ✅ 按钮之间间距合理

### 3.2 API参数验证

#### 测试分页参数转换
```bash
# 测试offset/limit参数
curl -X GET "http://localhost:8081/api/v1/user-groups/?offset=0&limit=10" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 验证返回数据格式
# 应返回: { "success": true, "data": { "groups": [...], "total": 1, "offset": 0, "limit": 10 } }
```

#### 测试搜索功能
```bash
# 测试搜索参数
curl -X GET "http://localhost:8081/api/v1/user-groups/?offset=0&limit=10&search=管理员" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 验证搜索结果
# 应返回包含"管理员"关键词的用户组
```

### 3.3 Admin组保护验证

#### 测试删除保护（前端）
1. 在用户组列表中，找到"管理员组"
2. 点击"更多"按钮
3. ✅ 应显示"admin组不可删除"（禁用状态）
4. ✅ 不应显示"删除"选项

#### 测试删除保护（后端）
```bash
# 尝试删除admin组（应返回403）
curl -X DELETE "http://localhost:8081/api/v1/user-groups/00000000-0000-0000-0000-000000000002" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 预期响应:
# {
#   "error": "forbidden",
#   "message": "Admin group cannot be deleted"
# }
```

### 3.4 数据加载验证

#### 检查Admin组是否显示
1. 打开用户组列表页面
2. ✅ 应能看到"管理员组"（名称: 管理员组）
3. ✅ 应显示成员数量（至少1个，即admin用户）
4. ✅ 可以点击"查看成员"查看admin用户

#### 检查分页功能
1. 创建多个测试用户组（如果数据不足）
2. ✅ 分页控件应正常工作
3. ✅ 切换页面大小应重新加载数据
4. ✅ 切换页码应正确加载对应页数据

### 3.5 搜索功能验证

1. 在搜索框输入"管理员"
2. ✅ 应只显示包含"管理员"的用户组
3. ✅ 搜索不区分大小写（输入"ADMIN"也应能搜索到）
4. ✅ 清空搜索框应显示所有用户组

## 四、浏览器控制台检查

### 4.1 打开开发者工具
- 按F12打开开发者工具
- 切换到"Console"标签

### 4.2 检查API请求
- 切换到"Network"标签
- 刷新用户组页面
- 查找 `/api/v1/user-groups/` 请求
- ✅ 检查请求参数: `offset=0&limit=10`
- ✅ 检查响应数据: 应包含 `groups` 数组和 `total` 字段

### 4.3 检查错误信息
- ✅ 不应有404错误（API路径正确）
- ✅ 不应有500错误（后端处理正常）
- ✅ 不应有CORS错误（代理配置正确）

## 五、常见问题排查

### 5.1 Admin组不显示

**可能原因1**: 数据库未初始化
```bash
# 解决方案: 执行初始化脚本
psql -h localhost -U postgres -d llmops -f services/user-service/scripts/migrations/004_admin_user_group_assignment.sql
```

**可能原因2**: 后端初始化失败
```bash
# 检查后端日志
tail -f logs/user-service.log

# 手动调用初始化API
curl -X POST http://localhost:8081/api/v1/admin/init \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**可能原因3**: 租户ID不匹配
```bash
# 检查数据库中的租户ID
SELECT id, name FROM user_groups;

# 确保租户ID为: 00000000-0000-0000-0000-000000000001
```

### 5.2 布局问题

**问题**: 按钮仍然换行显示
- 检查浏览器缓存，强制刷新（Ctrl+Shift+R）
- 检查CSS是否正确加载
- 检查浏览器窗口宽度是否足够

**问题**: 搜索框仍然很大
- 检查CSS样式是否正确应用
- 检查是否有其他CSS覆盖了样式

### 5.3 API请求失败

**问题**: 404错误
- 检查后端服务是否运行
- 检查API路径是否正确（`/api/v1/user-groups/`）
- 检查代理配置是否正确

**问题**: 401错误（未授权）
- 检查是否已登录
- 检查Token是否有效
- 重新登录获取新Token

**问题**: 500错误（服务器错误）
- 检查后端日志
- 检查数据库连接
- 检查数据库表结构是否正确

## 六、完整测试流程

### 6.1 准备阶段
1. ✅ 启动PostgreSQL数据库
2. ✅ 启动后端服务（user-service）
3. ✅ 启动前端服务（admin-dashboard）
4. ✅ 确保数据库已初始化

### 6.2 功能测试
1. ✅ 登录系统（admin/admin123）
2. ✅ 访问用户组页面
3. ✅ 验证布局（按钮在一行显示）
4. ✅ 验证Admin组显示
5. ✅ 验证Admin组删除保护
6. ✅ 验证搜索功能
7. ✅ 验证分页功能
8. ✅ 验证创建用户组功能
9. ✅ 验证编辑用户组功能
10. ✅ 验证删除用户组功能（非admin组）

### 6.3 回归测试
1. ✅ 验证用户列表功能正常
2. ✅ 验证其他页面功能正常
3. ✅ 验证API接口响应正常

## 七、验证检查清单

- [ ] 后端服务正常运行（端口8081）
- [ ] 前端服务正常运行（端口3000）
- [ ] 数据库连接正常
- [ ] Admin组数据存在
- [ ] Admin用户数据存在
- [ ] Admin用户在Admin组中
- [ ] 用户组列表页面布局正确
- [ ] 搜索框宽度正确（200px）
- [ ] 所有按钮在一行显示
- [ ] API参数转换正确（page→offset）
- [ ] 搜索功能正常
- [ ] 分页功能正常
- [ ] Admin组删除保护生效
- [ ] Admin用户删除保护生效
- [ ] 浏览器控制台无错误

## 八、快速验证命令

```bash
# 一键检查服务状态
echo "=== 检查后端服务 ===" && \
curl -s http://localhost:8081/health && \
echo -e "\n=== 检查前端服务 ===" && \
curl -s http://localhost:3000 | head -n 5 && \
echo -e "\n=== 检查数据库连接 ===" && \
psql -h localhost -U postgres -d llmops -c "SELECT COUNT(*) FROM user_groups;" && \
echo -e "\n=== 检查Admin组 ===" && \
psql -h localhost -U postgres -d llmops -c "SELECT name, member_count FROM user_groups WHERE id = '00000000-0000-0000-0000-000000000002';"
```

## 九、联系支持

如果遇到问题，请提供以下信息：
1. 后端服务日志
2. 前端浏览器控制台错误
3. 数据库查询结果
4. API请求和响应详情

