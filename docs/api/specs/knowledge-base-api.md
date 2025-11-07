# 知识库管理API设计

> **模块名称**: knowledge_base  
> **API版本**: v1.0  
> **更新日期**: 2025-10-17

## 一、模块概述

### 1.1 功能描述

知识库管理API提供知识库管理、文档管理、分块管理、检索服务、RAG会话等核心功能，支持大规模知识库的构建、管理和检索。

### 1.2 核心功能

- **知识库管理**: 知识库创建、配置、管理
- **文档管理**: 文档上传、处理、管理
- **分块管理**: 文档分块、向量化、索引
- **检索服务**: 语义检索、相似度搜索
- **RAG会话**: RAG会话管理、上下文维护

## 二、认证授权

### 2.1 认证方式

```http
Authorization: Bearer <jwt_token>
```

### 2.2 权限要求

- **知识库查看**: 需要 `knowledge:read` 权限
- **知识库管理**: 需要 `knowledge:manage` 权限
- **文档管理**: 需要 `knowledge:document:manage` 权限
- **检索服务**: 需要 `knowledge:search:use` 权限

## 三、知识库管理API

### 3.1 获取知识库列表

#### 获取知识库列表
```http
GET /api/v1/knowledge/bases
```

**查询参数**:
- `page`: 页码 (默认: 1)
- `per_page`: 每页数量 (默认: 20, 最大: 100)
- `search`: 搜索关键词
- `status`: 状态过滤 (active, inactive, processing)
- `type`: 类型过滤 (general, domain_specific, qa)
- `created_by`: 创建者过滤
- `sort`: 排序字段 (默认: created_at:desc)

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "bases": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Customer Service Knowledge Base",
        "description": "Comprehensive knowledge base for customer service queries",
        "type": "domain_specific",
        "status": "active",
        "language": "en",
        "document_count": 150,
        "chunk_count": 2500,
        "size": "125.6MB",
        "tags": ["customer-service", "faq", "support"],
        "settings": {
          "chunk_size": 512,
          "chunk_overlap": 50,
          "embedding_model": "text-embedding-ada-002",
          "retrieval_method": "semantic_search",
          "max_results": 10
        },
        "created_by": 1,
        "created_at": "2025-10-17T16:00:00Z",
        "updated_at": "2025-10-17T16:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 25,
      "total_pages": 2,
      "has_next": true,
      "has_prev": false
    }
  }
}
```

### 3.2 创建知识库

#### 创建知识库
```http
POST /api/v1/knowledge/bases
```

**请求体**:
```json
{
  "name": "Technical Documentation Knowledge Base",
  "description": "Technical documentation and API references for developers",
  "type": "general",
  "language": "en",
  "tags": ["technical", "documentation", "api"],
  "settings": {
    "chunk_size": 1024,
    "chunk_overlap": 100,
    "embedding_model": "text-embedding-ada-002",
    "retrieval_method": "hybrid_search",
    "max_results": 15,
    "similarity_threshold": 0.7
  },
  "metadata": {
    "domain": "software_development",
    "audience": "developers",
    "version": "1.0.0"
  }
}
```

**响应**:
```json
{
  "code": 201,
  "message": "Knowledge base created successfully",
  "data": {
    "base": {
      "id": 2,
      "uuid": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Technical Documentation Knowledge Base",
      "description": "Technical documentation and API references for developers",
      "type": "general",
      "status": "active",
      "language": "en",
      "document_count": 0,
      "chunk_count": 0,
      "size": "0MB",
      "tags": ["technical", "documentation", "api"],
      "settings": {
        "chunk_size": 1024,
        "chunk_overlap": 100,
        "embedding_model": "text-embedding-ada-002",
        "retrieval_method": "hybrid_search",
        "max_results": 15,
        "similarity_threshold": 0.7
      },
      "metadata": {
        "domain": "software_development",
        "audience": "developers",
        "version": "1.0.0"
      },
      "created_by": 1,
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 3.3 获取知识库详情

#### 获取知识库详情
```http
GET /api/v1/knowledge/bases/{id}
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "base": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Customer Service Knowledge Base",
      "description": "Comprehensive knowledge base for customer service queries",
      "type": "domain_specific",
      "status": "active",
      "language": "en",
      "document_count": 150,
      "chunk_count": 2500,
      "size": "125.6MB",
      "tags": ["customer-service", "faq", "support"],
      "settings": {
        "chunk_size": 512,
        "chunk_overlap": 50,
        "embedding_model": "text-embedding-ada-002",
        "retrieval_method": "semantic_search",
        "max_results": 10,
        "similarity_threshold": 0.7
      },
      "metadata": {
        "domain": "customer_service",
        "audience": "support_agents",
        "version": "2.1.0"
      },
      "statistics": {
        "total_queries": 15000,
        "successful_queries": 13500,
        "average_response_time": 0.8,
        "user_satisfaction": 4.3
      },
      "created_by": 1,
      "created_at": "2025-10-17T16:00:00Z",
      "updated_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 3.4 更新知识库

#### 更新知识库
```http
PUT /api/v1/knowledge/bases/{id}
```

**请求体**:
```json
{
  "name": "Updated Customer Service Knowledge Base",
  "description": "Enhanced knowledge base with additional customer service resources",
  "tags": ["customer-service", "faq", "support", "enhanced"],
  "settings": {
    "chunk_size": 768,
    "chunk_overlap": 75,
    "embedding_model": "text-embedding-3-large",
    "retrieval_method": "hybrid_search",
    "max_results": 12,
    "similarity_threshold": 0.75
  },
  "metadata": {
    "domain": "customer_service",
    "audience": "support_agents",
    "version": "2.2.0",
    "last_updated": "2025-10-17"
  }
}
```

### 3.5 删除知识库

#### 删除知识库
```http
DELETE /api/v1/knowledge/bases/{id}
```

**请求体**:
```json
{
  "confirm": true,
  "delete_documents": true,
  "reason": "Knowledge base is no longer needed"
}
```

## 四、文档管理API

### 4.1 获取文档列表

#### 获取知识库文档列表
```http
GET /api/v1/knowledge/bases/{id}/documents
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `status`: 状态过滤 (processing, processed, failed)
- `type`: 文档类型过滤
- `search`: 搜索关键词
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "documents": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Customer Service FAQ",
        "type": "pdf",
        "status": "processed",
        "size": "2.5MB",
        "page_count": 25,
        "chunk_count": 50,
        "language": "en",
        "metadata": {
          "title": "Customer Service FAQ",
          "author": "Support Team",
          "created_date": "2025-01-15",
          "category": "faq"
        },
        "uploaded_at": "2025-10-17T16:00:00Z",
        "processed_at": "2025-10-17T16:05:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 150,
      "total_pages": 8,
      "has_next": true,
      "has_prev": false
    }
  }
}
```

### 4.2 上传文档

#### 上传文档
```http
POST /api/v1/knowledge/bases/{id}/documents
```

**请求体** (multipart/form-data):
```
file: [binary file data]
name: API Documentation
type: pdf
metadata: {"title": "API Documentation", "author": "Dev Team", "category": "technical"}
```

**响应**:
```json
{
  "code": 201,
  "message": "Document uploaded successfully",
  "data": {
    "document": {
      "id": 2,
      "uuid": "550e8400-e29b-41d4-a716-446655440001",
      "name": "API Documentation",
      "type": "pdf",
      "status": "processing",
      "size": "5.2MB",
      "page_count": 0,
      "chunk_count": 0,
      "language": "en",
      "metadata": {
        "title": "API Documentation",
        "author": "Dev Team",
        "category": "technical"
      },
      "uploaded_at": "2025-10-17T16:00:00Z",
      "processed_at": null
    }
  }
}
```

### 4.3 获取文档详情

#### 获取文档详情
```http
GET /api/v1/knowledge/bases/{id}/documents/{document_id}
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "document": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Customer Service FAQ",
      "type": "pdf",
      "status": "processed",
      "size": "2.5MB",
      "page_count": 25,
      "chunk_count": 50,
      "language": "en",
      "metadata": {
        "title": "Customer Service FAQ",
        "author": "Support Team",
        "created_date": "2025-01-15",
        "category": "faq"
      },
      "content_preview": "This document contains frequently asked questions about our customer service...",
      "chunks": [
        {
          "id": 1,
          "content": "How can I reset my password?",
          "page_number": 1,
          "chunk_index": 0
        }
      ],
      "uploaded_at": "2025-10-17T16:00:00Z",
      "processed_at": "2025-10-17T16:05:00Z"
    }
  }
}
```

### 4.4 删除文档

#### 删除文档
```http
DELETE /api/v1/knowledge/bases/{id}/documents/{document_id}
```

**请求体**:
```json
{
  "confirm": true,
  "delete_chunks": true,
  "reason": "Document is outdated"
}
```

## 五、分块管理API

### 5.1 获取文档分块

#### 获取文档分块
```http
GET /api/v1/knowledge/bases/{id}/documents/{document_id}/chunks
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `search`: 搜索关键词
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "chunks": [
      {
        "id": 1,
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "content": "How can I reset my password? To reset your password, please visit the login page and click on 'Forgot Password'. You will receive an email with instructions to reset your password.",
        "page_number": 1,
        "chunk_index": 0,
        "start_position": 0,
        "end_position": 150,
        "metadata": {
          "heading": "Password Reset",
          "section": "Account Management",
          "keywords": ["password", "reset", "login"]
        },
        "embedding": {
          "model": "text-embedding-ada-002",
          "dimension": 1536,
          "status": "processed"
        },
        "created_at": "2025-10-17T16:05:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 50,
      "total_pages": 3,
      "has_next": true,
      "has_prev": false
    }
  }
}
```

### 5.2 重新分块文档

#### 重新分块文档
```http
POST /api/v1/knowledge/bases/{id}/documents/{document_id}/rechunk
```

**请求体**:
```json
{
  "chunk_size": 1024,
  "chunk_overlap": 100,
  "strategy": "semantic",
  "preserve_metadata": true
}
```

**响应**:
```json
{
  "code": 200,
  "message": "Document rechunking started successfully",
  "data": {
    "task_id": "rechunk_123456",
    "status": "processing",
    "estimated_completion": "2025-10-17T16:10:00Z"
  }
}
```

### 5.3 更新分块

#### 更新分块
```http
PUT /api/v1/knowledge/bases/{id}/chunks/{chunk_id}
```

**请求体**:
```json
{
  "content": "Updated content for this chunk",
  "metadata": {
    "heading": "Updated Heading",
    "section": "Updated Section",
    "keywords": ["updated", "keywords"]
  }
}
```

## 六、检索服务API

### 6.1 语义检索

#### 语义检索
```http
POST /api/v1/knowledge/bases/{id}/search
```

**请求体**:
```json
{
  "query": "How to reset password",
  "search_type": "semantic",
  "max_results": 10,
  "similarity_threshold": 0.7,
  "filters": {
    "metadata": {
      "category": "faq"
    },
    "date_range": {
      "start": "2025-01-01",
      "end": "2025-12-31"
    }
  },
  "options": {
    "include_metadata": true,
    "include_scores": true,
    "rerank": true
  }
}
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "results": [
      {
        "id": 1,
        "chunk_id": 1,
        "content": "How can I reset my password? To reset your password, please visit the login page and click on 'Forgot Password'. You will receive an email with instructions to reset your password.",
        "score": 0.95,
        "metadata": {
          "document_id": 1,
          "document_name": "Customer Service FAQ",
          "page_number": 1,
          "heading": "Password Reset",
          "section": "Account Management"
        },
        "highlights": [
          {
            "text": "reset your password",
            "start": 45,
            "end": 63
          }
        ]
      }
    ],
    "query": "How to reset password",
    "total_results": 5,
    "search_time": 0.15,
    "search_type": "semantic"
  }
}
```

### 6.2 混合检索

#### 混合检索
```http
POST /api/v1/knowledge/bases/{id}/search/hybrid
```

**请求体**:
```json
{
  "query": "password reset instructions",
  "semantic_weight": 0.7,
  "keyword_weight": 0.3,
  "max_results": 15,
  "similarity_threshold": 0.6,
  "filters": {
    "metadata": {
      "category": "faq"
    }
  }
}
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "results": [
      {
        "id": 1,
        "chunk_id": 1,
        "content": "How can I reset my password? To reset your password, please visit the login page and click on 'Forgot Password'.",
        "semantic_score": 0.95,
        "keyword_score": 0.85,
        "combined_score": 0.92,
        "metadata": {
          "document_id": 1,
          "document_name": "Customer Service FAQ"
        }
      }
    ],
    "query": "password reset instructions",
    "total_results": 8,
    "search_time": 0.25,
    "search_type": "hybrid"
  }
}
```

### 6.3 相似度搜索

#### 相似度搜索
```http
POST /api/v1/knowledge/bases/{id}/search/similar
```

**请求体**:
```json
{
  "chunk_id": 1,
  "max_results": 5,
  "similarity_threshold": 0.8
}
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "results": [
      {
        "id": 2,
        "chunk_id": 2,
        "content": "What if I forgot my password? If you forgot your password, you can reset it by clicking the 'Forgot Password' link on the login page.",
        "similarity_score": 0.92,
        "metadata": {
          "document_id": 1,
          "document_name": "Customer Service FAQ"
        }
      }
    ],
    "reference_chunk_id": 1,
    "total_results": 3,
    "search_time": 0.12
  }
}
```

## 七、RAG会话API

### 7.1 创建RAG会话

#### 创建RAG会话
```http
POST /api/v1/knowledge/bases/{id}/sessions
```

**请求体**:
```json
{
  "name": "Customer Support Session",
  "description": "Session for handling customer support queries",
  "settings": {
    "max_context_length": 4000,
    "temperature": 0.7,
    "max_tokens": 500,
    "retrieval_method": "semantic",
    "max_retrieved_chunks": 5
  },
  "metadata": {
    "user_id": 1,
    "session_type": "support",
    "priority": "normal"
  }
}
```

**响应**:
```json
{
  "code": 201,
  "message": "RAG session created successfully",
  "data": {
    "session": {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Customer Support Session",
      "description": "Session for handling customer support queries",
      "status": "active",
      "settings": {
        "max_context_length": 4000,
        "temperature": 0.7,
        "max_tokens": 500,
        "retrieval_method": "semantic",
        "max_retrieved_chunks": 5
      },
      "metadata": {
        "user_id": 1,
        "session_type": "support",
        "priority": "normal"
      },
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 7.2 发送RAG查询

#### 发送RAG查询
```http
POST /api/v1/knowledge/bases/{id}/sessions/{session_id}/query
```

**请求体**:
```json
{
  "query": "I can't log into my account, what should I do?",
  "context": {
    "user_id": 123,
    "account_type": "premium",
    "previous_issues": ["password_reset"]
  },
  "options": {
    "include_sources": true,
    "include_confidence": true,
    "stream": false
  }
}
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "response": {
      "id": "query_123456",
      "answer": "I understand you're having trouble logging into your account. Here are the steps to resolve this issue:\n\n1. First, try resetting your password by clicking the 'Forgot Password' link on the login page\n2. Check your email for password reset instructions\n3. If you don't receive the email, check your spam folder\n4. If the issue persists, contact our support team directly",
      "confidence": 0.92,
      "sources": [
        {
          "chunk_id": 1,
          "content": "How can I reset my password? To reset your password, please visit the login page and click on 'Forgot Password'.",
          "score": 0.95,
          "metadata": {
            "document_name": "Customer Service FAQ",
            "page_number": 1
          }
        }
      ],
      "context_used": {
        "chunks_retrieved": 3,
        "context_length": 1200,
        "retrieval_time": 0.15
      },
      "generation_time": 1.2,
      "total_time": 1.35,
      "created_at": "2025-10-17T16:00:00Z"
    }
  }
}
```

### 7.3 获取会话历史

#### 获取会话历史
```http
GET /api/v1/knowledge/bases/{id}/sessions/{session_id}/history
```

**查询参数**:
- `page`: 页码
- `per_page`: 每页数量
- `start_time`: 开始时间
- `end_time`: 结束时间
- `sort`: 排序字段

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "history": [
      {
        "id": 1,
        "query": "I can't log into my account, what should I do?",
        "response": "I understand you're having trouble logging into your account. Here are the steps to resolve this issue...",
        "confidence": 0.92,
        "sources_count": 3,
        "created_at": "2025-10-17T16:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 15,
      "total_pages": 1,
      "has_next": false,
      "has_prev": false
    }
  }
}
```

### 7.4 结束RAG会话

#### 结束RAG会话
```http
POST /api/v1/knowledge/bases/{id}/sessions/{session_id}/end
```

**请求体**:
```json
{
  "reason": "Customer issue resolved",
  "feedback": {
    "satisfaction": 5,
    "helpfulness": 5,
    "comments": "Very helpful and clear instructions"
  }
}
```

**响应**:
```json
{
  "code": 200,
  "message": "RAG session ended successfully",
  "data": {
    "session": {
      "id": 1,
      "status": "ended",
      "ended_at": "2025-10-17T16:30:00Z",
      "total_queries": 5,
      "average_confidence": 0.89,
      "feedback": {
        "satisfaction": 5,
        "helpfulness": 5,
        "comments": "Very helpful and clear instructions"
      }
    }
  }
}
```

## 八、错误处理

### 8.1 常见错误码

| 错误码 | 错误类型 | 描述 |
|--------|----------|------|
| 400 | Bad Request | 请求参数错误 |
| 401 | Unauthorized | 未授权访问 |
| 403 | Forbidden | 权限不足 |
| 404 | Not Found | 资源不存在 |
| 409 | Conflict | 资源冲突 |
| 422 | Validation Error | 参数验证失败 |
| 429 | Rate Limited | 请求频率超限 |
| 500 | Internal Error | 服务器内部错误 |

### 8.2 错误响应示例

#### 文档处理失败错误
```json
{
  "code": 422,
  "message": "Document processing failed",
  "error": {
    "type": "processing_error",
    "details": "Failed to process document due to unsupported format",
    "document_id": 1,
    "document_type": "docx",
    "supported_formats": ["pdf", "txt", "md", "html"]
  }
}
```

#### 检索服务不可用错误
```json
{
  "code": 503,
  "message": "Search service unavailable",
  "error": {
    "type": "service_error",
    "details": "Search service is temporarily unavailable",
    "retry_after": 30,
    "knowledge_base_id": 1
  }
}
```

## 九、限流策略

### 9.1 限流规则

- **知识库查询**: 1000 requests/hour
- **文档管理**: 100 requests/hour
- **检索服务**: 500 requests/hour
- **RAG会话**: 200 requests/hour
- **分块管理**: 50 requests/hour

### 9.2 限流响应

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1640995200
```

## 十、安全考虑

### 10.1 数据保护

- **文档加密**: 文档内容加密存储
- **访问控制**: 基于角色的知识库访问控制
- **数据脱敏**: 敏感信息脱敏处理
- **审计追踪**: 完整的知识库操作审计

### 10.2 检索安全

- **查询验证**: 检索查询验证和过滤
- **结果过滤**: 检索结果安全过滤
- **权限检查**: 检索权限实时检查
- **内容审核**: 检索内容安全审核

---

**文档维护**: 本文档应随API设计变化持续更新，保持与系统架构的一致性。

**版本历史**:
- v1.0 (2025-10-17): 初始版本，知识库管理API设计

