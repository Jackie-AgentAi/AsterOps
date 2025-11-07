# API认证示例

> **文档类型**: API使用示例  
> **更新时间**: 2025-10-17

## 一、认证方式概述

LLMOps平台支持多种认证方式，包括JWT Token认证、API Key认证和OAuth 2.0认证。

## 二、JWT Token认证

### 2.1 用户登录获取Token

#### 请求示例
```bash
curl -X POST https://api.llmops.com/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "SecurePass123!",
    "remember_me": true,
    "device_info": {
      "device_type": "web",
      "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      "ip_address": "192.168.1.1"
    }
  }'
```

#### 响应示例
```json
{
  "code": 200,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "username": "john_doe",
      "email": "john@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "status": "active"
    },
    "tokens": {
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
      "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
      "expires_in": 3600,
      "token_type": "Bearer"
    },
    "permissions": [
      "user:read",
      "project:read",
      "model:read",
      "inference:use"
    ],
    "roles": [
      "developer",
      "project_member"
    ]
  }
}
```

### 2.2 使用Token进行API调用

#### 请求示例
```bash
curl -X GET https://api.llmops.com/v1/users/me \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c" \
  -H "Content-Type: application/json"
```

### 2.3 Token刷新

#### 请求示例
```bash
curl -X POST https://api.llmops.com/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
  }'
```

## 三、API Key认证

### 3.1 创建API Key

#### 请求示例
```bash
curl -X POST https://api.llmops.com/v1/api-keys \
  -H "Authorization: Bearer <jwt_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production API Key",
    "description": "API key for production environment",
    "permissions": [
      "inference:use",
      "model:read"
    ],
    "expires_at": "2025-12-31T23:59:59Z"
  }'
```

#### 响应示例
```json
{
  "code": 201,
  "message": "API key created successfully",
  "data": {
    "api_key": {
      "id": 1,
      "name": "Production API Key",
      "key": "ak_1234567890abcdef",
      "secret": "sk_abcdef1234567890",
      "permissions": [
        "inference:use",
        "model:read"
      ],
      "expires_at": "2025-12-31T23:59:59Z",
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 3.2 使用API Key进行API调用

#### 请求示例
```bash
curl -X GET https://api.llmops.com/v1/models \
  -H "X-API-Key: ak_1234567890abcdef" \
  -H "Content-Type: application/json"
```

## 四、OAuth 2.0认证

### 4.1 获取授权码

#### 请求示例
```bash
curl -X GET "https://api.llmops.com/v1/oauth/authorize?client_id=your_client_id&redirect_uri=https://your-app.com/callback&response_type=code&scope=read write&state=random_state_string"
```

### 4.2 交换访问令牌

#### 请求示例
```bash
curl -X POST https://api.llmops.com/v1/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code&client_id=your_client_id&client_secret=your_client_secret&code=authorization_code&redirect_uri=https://your-app.com/callback"
```

#### 响应示例
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
  "scope": "read write"
}
```

## 五、多因素认证

### 5.1 启用多因素认证

#### 请求示例
```bash
curl -X POST https://api.llmops.com/v1/users/me/mfa/enable \
  -H "Authorization: Bearer <jwt_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "method": "totp",
    "password": "SecurePass123!"
  }'
```

#### 响应示例
```json
{
  "code": 200,
  "message": "MFA enabled successfully",
  "data": {
    "secret": "JBSWY3DPEHPK3PXP",
    "qr_code": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
    "backup_codes": [
      "12345678",
      "87654321",
      "11223344",
      "44332211"
    ]
  }
}
```

### 5.2 使用多因素认证登录

#### 请求示例
```bash
curl -X POST https://api.llmops.com/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "SecurePass123!",
    "mfa_code": "123456"
  }'
```

## 六、错误处理示例

### 6.1 认证失败

#### 响应示例
```json
{
  "code": 401,
  "message": "Authentication failed",
  "error": {
    "type": "authentication_error",
    "details": "Invalid credentials",
    "field": "password"
  }
}
```

### 6.2 Token过期

#### 响应示例
```json
{
  "code": 401,
  "message": "Token expired",
  "error": {
    "type": "token_expired",
    "details": "The access token has expired",
    "expired_at": "2025-10-17T15:00:00Z"
  }
}
```

### 6.3 权限不足

#### 响应示例
```json
{
  "code": 403,
  "message": "Insufficient permissions",
  "error": {
    "type": "authorization_error",
    "details": "You don't have permission to perform this action",
    "required_permission": "model:manage",
    "user_permissions": ["model:read"]
  }
}
```

## 七、最佳实践

### 7.1 Token管理

- **安全存储**: 将Token存储在安全的地方，避免硬编码
- **定期刷新**: 定期刷新Token，避免过期
- **及时撤销**: 发现Token泄露时及时撤销
- **最小权限**: 只申请必要的权限

### 7.2 API Key管理

- **命名规范**: 使用有意义的API Key名称
- **权限最小化**: 只授予必要的权限
- **定期轮换**: 定期轮换API Key
- **监控使用**: 监控API Key的使用情况

### 7.3 错误处理

- **重试机制**: 实现适当的重试机制
- **错误日志**: 记录详细的错误日志
- **用户友好**: 提供用户友好的错误信息
- **降级处理**: 实现降级处理机制

## 八、SDK示例

### 8.1 Python SDK

```python
from llmops_sdk import LLMOpsClient

# 使用JWT Token认证
client = LLMOpsClient(
    base_url="https://api.llmops.com/v1",
    access_token="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
)

# 使用API Key认证
client = LLMOpsClient(
    base_url="https://api.llmops.com/v1",
    api_key="ak_1234567890abcdef"
)

# 获取用户信息
user = client.users.get_me()
print(f"Welcome, {user['first_name']} {user['last_name']}!")

# 发送推理请求
response = client.inference.chat(
    model="gpt-4-chatbot",
    messages=[
        {"role": "user", "content": "Hello, how are you?"}
    ]
)
print(response['choices'][0]['message']['content'])
```

### 8.2 JavaScript SDK

```javascript
const { LLMOpsClient } = require('llmops-sdk');

// 使用JWT Token认证
const client = new LLMOpsClient({
  baseUrl: 'https://api.llmops.com/v1',
  accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
});

// 使用API Key认证
const client = new LLMOpsClient({
  baseUrl: 'https://api.llmops.com/v1',
  apiKey: 'ak_1234567890abcdef'
});

// 获取用户信息
const user = await client.users.getMe();
console.log(`Welcome, ${user.first_name} ${user.last_name}!`);

// 发送推理请求
const response = await client.inference.chat({
  model: 'gpt-4-chatbot',
  messages: [
    { role: 'user', content: 'Hello, how are you?' }
  ]
});
console.log(response.choices[0].message.content);
```

---

**文档维护**: 本文档应随API设计变化持续更新，保持与系统架构的一致性。

**版本历史**:
- v1.0 (2025-10-17): 初始版本，API认证示例

