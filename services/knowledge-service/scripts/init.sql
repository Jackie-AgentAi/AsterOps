-- 知识库管理服务数据库初始化脚本

-- 创建数据库
CREATE DATABASE IF NOT EXISTS knowledge_db;

-- 使用数据库
\c knowledge_db;

-- 启用UUID扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 知识库表
CREATE TABLE IF NOT EXISTS knowledge_bases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    owner_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    is_public BOOLEAN DEFAULT false,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 知识条目表
CREATE TABLE IF NOT EXISTS knowledge_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    content TEXT NOT NULL,
    content_type VARCHAR(50) NOT NULL,
    source VARCHAR(255),
    source_url VARCHAR(500),
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    embedding_vector VECTOR(1536),
    is_indexed BOOLEAN DEFAULT false,
    created_by UUID NOT NULL,
    tenant_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 知识库版本表
CREATE TABLE IF NOT EXISTS knowledge_base_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id) ON DELETE CASCADE,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    change_log TEXT,
    is_current BOOLEAN DEFAULT false,
    created_by UUID NOT NULL,
    tenant_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(knowledge_base_id, version)
);

-- 知识库权限表
CREATE TABLE IF NOT EXISTS knowledge_base_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    permission_type VARCHAR(50) NOT NULL,
    granted_by UUID NOT NULL,
    tenant_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(knowledge_base_id, user_id, permission_type)
);

-- 知识库搜索历史表
CREATE TABLE IF NOT EXISTS knowledge_search_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    query_text TEXT NOT NULL,
    search_type VARCHAR(50) NOT NULL,
    results_count INTEGER DEFAULT 0,
    response_time_ms INTEGER,
    tenant_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 知识库标签表
CREATE TABLE IF NOT EXISTS knowledge_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    color VARCHAR(7),
    category VARCHAR(50),
    usage_count INTEGER DEFAULT 0,
    created_by UUID NOT NULL,
    tenant_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 知识库导入任务表
CREATE TABLE IF NOT EXISTS knowledge_import_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id) ON DELETE CASCADE,
    task_name VARCHAR(255) NOT NULL,
    import_type VARCHAR(50) NOT NULL,
    source_file VARCHAR(500),
    source_url VARCHAR(500),
    status VARCHAR(50) DEFAULT 'pending',
    progress INTEGER DEFAULT 0,
    total_items INTEGER DEFAULT 0,
    processed_items INTEGER DEFAULT 0,
    error_message TEXT,
    config JSONB DEFAULT '{}',
    created_by UUID NOT NULL,
    tenant_id UUID NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 知识库同步表
CREATE TABLE IF NOT EXISTS knowledge_syncs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id) ON DELETE CASCADE,
    target_knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id) ON DELETE CASCADE,
    sync_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    last_sync_at TIMESTAMP WITH TIME ZONE,
    sync_frequency VARCHAR(50),
    config JSONB DEFAULT '{}',
    created_by UUID NOT NULL,
    tenant_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_knowledge_bases_name ON knowledge_bases(name);
CREATE INDEX IF NOT EXISTS idx_knowledge_bases_type ON knowledge_bases(type);
CREATE INDEX IF NOT EXISTS idx_knowledge_bases_status ON knowledge_bases(status);
CREATE INDEX IF NOT EXISTS idx_knowledge_bases_owner_id ON knowledge_bases(owner_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_bases_tenant_id ON knowledge_bases(tenant_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_bases_is_public ON knowledge_bases(is_public);

CREATE INDEX IF NOT EXISTS idx_knowledge_items_knowledge_base_id ON knowledge_items(knowledge_base_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_items_title ON knowledge_items(title);
CREATE INDEX IF NOT EXISTS idx_knowledge_items_content_type ON knowledge_items(content_type);
CREATE INDEX IF NOT EXISTS idx_knowledge_items_source ON knowledge_items(source);
CREATE INDEX IF NOT EXISTS idx_knowledge_items_is_indexed ON knowledge_items(is_indexed);
CREATE INDEX IF NOT EXISTS idx_knowledge_items_created_by ON knowledge_items(created_by);
CREATE INDEX IF NOT EXISTS idx_knowledge_items_tenant_id ON knowledge_items(tenant_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_items_created_at ON knowledge_items(created_at);

CREATE INDEX IF NOT EXISTS idx_knowledge_base_versions_knowledge_base_id ON knowledge_base_versions(knowledge_base_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_base_versions_version ON knowledge_base_versions(version);
CREATE INDEX IF NOT EXISTS idx_knowledge_base_versions_is_current ON knowledge_base_versions(is_current);

CREATE INDEX IF NOT EXISTS idx_knowledge_base_permissions_knowledge_base_id ON knowledge_base_permissions(knowledge_base_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_base_permissions_user_id ON knowledge_base_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_base_permissions_permission_type ON knowledge_base_permissions(permission_type);

CREATE INDEX IF NOT EXISTS idx_knowledge_search_history_knowledge_base_id ON knowledge_search_history(knowledge_base_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_search_history_user_id ON knowledge_search_history(user_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_search_history_created_at ON knowledge_search_history(created_at);

CREATE INDEX IF NOT EXISTS idx_knowledge_tags_name ON knowledge_tags(name);
CREATE INDEX IF NOT EXISTS idx_knowledge_tags_category ON knowledge_tags(category);
CREATE INDEX IF NOT EXISTS idx_knowledge_tags_usage_count ON knowledge_tags(usage_count);

CREATE INDEX IF NOT EXISTS idx_knowledge_import_tasks_knowledge_base_id ON knowledge_import_tasks(knowledge_base_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_import_tasks_import_type ON knowledge_import_tasks(import_type);
CREATE INDEX IF NOT EXISTS idx_knowledge_import_tasks_status ON knowledge_import_tasks(status);
CREATE INDEX IF NOT EXISTS idx_knowledge_import_tasks_created_by ON knowledge_import_tasks(created_by);

CREATE INDEX IF NOT EXISTS idx_knowledge_syncs_source_knowledge_base_id ON knowledge_syncs(source_knowledge_base_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_syncs_target_knowledge_base_id ON knowledge_syncs(target_knowledge_base_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_syncs_sync_type ON knowledge_syncs(sync_type);
CREATE INDEX IF NOT EXISTS idx_knowledge_syncs_status ON knowledge_syncs(status);

-- 创建复合索引
CREATE INDEX IF NOT EXISTS idx_knowledge_bases_tenant_status ON knowledge_bases(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_knowledge_bases_tenant_type ON knowledge_bases(tenant_id, type);
CREATE INDEX IF NOT EXISTS idx_knowledge_bases_tenant_public ON knowledge_bases(tenant_id, is_public);

CREATE INDEX IF NOT EXISTS idx_knowledge_items_kb_created ON knowledge_items(knowledge_base_id, created_at);
CREATE INDEX IF NOT EXISTS idx_knowledge_items_kb_type ON knowledge_items(knowledge_base_id, content_type);
CREATE INDEX IF NOT EXISTS idx_knowledge_items_kb_indexed ON knowledge_items(knowledge_base_id, is_indexed);

CREATE INDEX IF NOT EXISTS idx_knowledge_base_permissions_kb_user ON knowledge_base_permissions(knowledge_base_id, user_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_base_permissions_kb_type ON knowledge_base_permissions(knowledge_base_id, permission_type);

CREATE INDEX IF NOT EXISTS idx_knowledge_search_history_kb_user ON knowledge_search_history(knowledge_base_id, user_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_search_history_kb_created ON knowledge_search_history(knowledge_base_id, created_at);

CREATE INDEX IF NOT EXISTS idx_knowledge_import_tasks_kb_status ON knowledge_import_tasks(knowledge_base_id, status);
CREATE INDEX IF NOT EXISTS idx_knowledge_import_tasks_kb_type ON knowledge_import_tasks(knowledge_base_id, import_type);

-- 创建全文搜索索引
CREATE INDEX IF NOT EXISTS idx_knowledge_items_content_fts ON knowledge_items USING gin(to_tsvector('english', title || ' ' || content));
CREATE INDEX IF NOT EXISTS idx_knowledge_items_title_fts ON knowledge_items USING gin(to_tsvector('english', title));

-- 创建向量相似度搜索索引（需要pgvector扩展）
-- CREATE INDEX IF NOT EXISTS idx_knowledge_items_embedding_cosine ON knowledge_items USING ivfflat (embedding_vector vector_cosine_ops) WITH (lists = 100);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有表添加更新时间触发器
CREATE TRIGGER update_knowledge_bases_updated_at BEFORE UPDATE ON knowledge_bases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_items_updated_at BEFORE UPDATE ON knowledge_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_base_permissions_updated_at BEFORE UPDATE ON knowledge_base_permissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_tags_updated_at BEFORE UPDATE ON knowledge_tags
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_import_tasks_updated_at BEFORE UPDATE ON knowledge_import_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_syncs_updated_at BEFORE UPDATE ON knowledge_syncs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入示例数据
INSERT INTO knowledge_bases (id, name, description, type, status, owner_id, tenant_id, is_public, settings) VALUES 
('00000000-0000-0000-0000-000000000001', 'AI Research Knowledge Base', 'Knowledge base for AI research papers and documentation', 'research', 'active', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true, '{"search_enabled": true, "auto_indexing": true}'),
('00000000-0000-0000-0000-000000000002', 'Product Documentation', 'Internal product documentation and user guides', 'documentation', 'active', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', false, '{"search_enabled": true, "auto_indexing": false}'),
('00000000-0000-0000-0000-000000000003', 'Technical Support KB', 'Technical support knowledge base', 'support', 'active', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true, '{"search_enabled": true, "auto_indexing": true}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO knowledge_items (id, knowledge_base_id, title, content, content_type, source, tags, created_by, tenant_id, is_indexed) VALUES 
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Introduction to Large Language Models', 'Large Language Models (LLMs) are artificial intelligence systems that have been trained on vast amounts of text data to understand and generate human-like text. They are based on transformer architectures and have revolutionized natural language processing.', 'article', 'Research Paper', ARRAY['llm', 'ai', 'nlp', 'transformer'], '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true),
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Fine-tuning Techniques for LLMs', 'Fine-tuning is the process of adapting a pre-trained language model to a specific task or domain. This involves training the model on task-specific data while keeping the pre-trained weights as a starting point.', 'article', 'Research Paper', ARRAY['fine-tuning', 'llm', 'training'], '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', 'API Documentation', 'This document provides comprehensive information about our API endpoints, authentication methods, and usage examples.', 'documentation', 'Internal', ARRAY['api', 'documentation', 'guide'], '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true),
('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000003', 'Common Installation Issues', 'This article covers the most common installation issues users encounter and their solutions.', 'faq', 'Support', ARRAY['installation', 'troubleshooting', 'support'], '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO knowledge_tags (id, name, description, color, category, usage_count, created_by, tenant_id) VALUES 
('00000000-0000-0000-0000-000000000001', 'llm', 'Large Language Models', '#FF6B6B', 'ai', 2, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000002', 'ai', 'Artificial Intelligence', '#4ECDC4', 'ai', 2, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000003', 'nlp', 'Natural Language Processing', '#45B7D1', 'ai', 1, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000004', 'api', 'API Documentation', '#96CEB4', 'technical', 1, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000005', 'support', 'Support Related', '#FFEAA7', 'support', 1, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001')
ON CONFLICT (id) DO NOTHING;

INSERT INTO knowledge_base_versions (id, knowledge_base_id, version, description, is_current, created_by, tenant_id) VALUES 
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '1.0.0', 'Initial version', true, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', '1.0.0', 'Initial version', true, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', '1.0.0', 'Initial version', true, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001')
ON CONFLICT (id) DO NOTHING;