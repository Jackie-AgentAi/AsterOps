# LLMOps平台数据库设计

> 企业级LLM能力运营平台完整数据库设计方案

## 📚 文档导航

### 数据库设计文档
- [数据库总体设计](./design/database-overall-design.md) - **⭐️ 核心设计文档**
  - 设计原则与规范
  - 技术选型与架构
  - 数据分层策略
  - 性能优化方案

### 数据模型设计
- [用户权限模块](./schema/user-permission-schema.md) - 用户、角色、权限管理
- [项目管理模块](./schema/project-management-schema.md) - 项目、成员、配置管理
- [模型管理模块](./schema/model-management-schema.md) - 模型、版本、部署管理
- [推理服务模块](./schema/inference-service-schema.md) - 推理请求、结果、配置
- [成本管理模块](./schema/cost-management-schema.md) - 成本记录、预算、计费
- [监控日志模块](./schema/monitoring-logging-schema.md) - 监控指标、告警、审计
- [评测管理模块](./schema/evaluation-management-schema.md) - 评测任务、结果、数据集
- [知识库模块](./schema/knowledge-base-schema.md) - 知识库、文档、向量索引

### 数据迁移
- [迁移脚本](./migrations/) - 数据库版本升级脚本
- [数据初始化](./migrations/init/) - 初始数据和基础配置

## 🎯 快速开始

### 1. 了解总体设计
**推荐首先阅读**: [数据库总体设计](./design/database-overall-design.md)

### 2. 查看具体模块
根据开发需要，查看相应模块的数据模型设计

### 3. 执行数据库初始化
```bash
# 创建数据库
psql -c "CREATE DATABASE llmops_platform;"

# 执行初始化脚本
psql -d llmops_platform -f migrations/init/01_create_tables.sql
psql -d llmops_platform -f migrations/init/02_insert_initial_data.sql
```

## 📊 数据库概览

### 技术栈
- **主数据库**: PostgreSQL 15+
- **缓存数据库**: Redis 7.x
- **文档数据库**: MongoDB 6.x
- **向量数据库**: Milvus 2.3+
- **时序数据库**: InfluxDB 2.x

### 核心特性
- **多租户支持**: 数据隔离与共享
- **高可用设计**: 主从复制 + 读写分离
- **性能优化**: 索引优化 + 分区策略
- **数据安全**: 加密存储 + 审计日志
- **扩展性**: 水平分片 + 垂直拆分

### 数据分层
- **热数据**: Redis (实时访问)
- **温数据**: PostgreSQL (业务数据)
- **冷数据**: MongoDB (历史数据)
- **向量数据**: Milvus (语义检索)

## 🏗️ 数据架构亮点

### 多租户架构
- 租户级数据隔离
- 共享资源池管理
- 细粒度权限控制

### 性能优化
- 读写分离
- 分库分表
- 缓存策略
- 索引优化

### 数据安全
- 传输加密 (TLS)
- 存储加密 (AES-256)
- 访问审计
- 数据脱敏

## 📝 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v1.0 | 2025-10-17 | 初始版本，完整数据库设计 |

---

**注意**: 数据库设计应随业务需求变化持续演进，保持与系统架构的一致性。
