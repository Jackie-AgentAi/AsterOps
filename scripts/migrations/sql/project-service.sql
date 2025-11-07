-- 项目管理服务数据库表结构
-- 生产环境初始化脚本

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 项目表
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id UUID NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    visibility VARCHAR(50) DEFAULT 'private',
    tags JSONB DEFAULT '[]',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, name)
);

-- 项目成员表
CREATE TABLE IF NOT EXISTS project_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'member',
    permissions JSONB DEFAULT '[]',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    invited_by UUID,
    UNIQUE(project_id, user_id)
);

-- 项目配额表
CREATE TABLE IF NOT EXISTS project_quotas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    resource_type VARCHAR(50) NOT NULL,
    limit_value DECIMAL(15,2) NOT NULL,
    used_value DECIMAL(15,2) DEFAULT 0,
    unit VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, resource_type)
);

-- 项目活动日志表
CREATE TABLE IF NOT EXISTS project_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id VARCHAR(255),
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 项目模板表
CREATE TABLE IF NOT EXISTS project_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    template_config JSONB NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 项目资源使用记录表
CREATE TABLE IF NOT EXISTS project_resource_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    resource_type VARCHAR(50) NOT NULL,
    usage_value DECIMAL(15,2) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_projects_tenant_id ON projects(tenant_id);
CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects(created_at);

CREATE INDEX IF NOT EXISTS idx_project_members_project_id ON project_members(project_id);
CREATE INDEX IF NOT EXISTS idx_project_members_user_id ON project_members(user_id);
CREATE INDEX IF NOT EXISTS idx_project_members_role ON project_members(role);

CREATE INDEX IF NOT EXISTS idx_project_quotas_project_id ON project_quotas(project_id);
CREATE INDEX IF NOT EXISTS idx_project_quotas_resource_type ON project_quotas(resource_type);

CREATE INDEX IF NOT EXISTS idx_project_activities_project_id ON project_activities(project_id);
CREATE INDEX IF NOT EXISTS idx_project_activities_user_id ON project_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_project_activities_action ON project_activities(action);
CREATE INDEX IF NOT EXISTS idx_project_activities_created_at ON project_activities(created_at);

CREATE INDEX IF NOT EXISTS idx_project_templates_tenant_id ON project_templates(tenant_id);
CREATE INDEX IF NOT EXISTS idx_project_templates_is_public ON project_templates(is_public);

CREATE INDEX IF NOT EXISTS idx_project_resource_usage_project_id ON project_resource_usage(project_id);
CREATE INDEX IF NOT EXISTS idx_project_resource_usage_resource_type ON project_resource_usage(resource_type);
CREATE INDEX IF NOT EXISTS idx_project_resource_usage_recorded_at ON project_resource_usage(recorded_at);

-- 创建触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 创建更新时间触发器
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_project_quotas_updated_at BEFORE UPDATE ON project_quotas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_project_templates_updated_at BEFORE UPDATE ON project_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入默认数据
INSERT INTO project_templates (id, tenant_id, name, description, template_config, is_public, created_by) VALUES 
    ('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440000', '基础项目模板', '包含基本配置的项目模板', 
     '{"quotas": {"cpu": 2, "memory": 4, "gpu": 0}, "settings": {"auto_approve": false, "notifications": true}}', 
     TRUE, '550e8400-e29b-41d4-a716-446655440000'),
    ('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440000', 'AI项目模板', '专为AI项目设计的模板', 
     '{"quotas": {"cpu": 4, "memory": 8, "gpu": 1}, "settings": {"auto_approve": true, "notifications": true}}', 
     TRUE, '550e8400-e29b-41d4-a716-446655440000')
ON CONFLICT (id) DO NOTHING;
