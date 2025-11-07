-- 用户组相关表结构
-- 创建时间: 2025-01-17
-- 描述: 添加用户组管理相关表

-- 用户组表
CREATE TABLE IF NOT EXISTS user_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    tenant_id UUID NOT NULL,
    organization_id UUID,
    parent_id UUID REFERENCES user_groups(id),
    settings JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 用户组成员关联表
CREATE TABLE IF NOT EXISTS user_group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    group_id UUID NOT NULL REFERENCES user_groups(id),
    role VARCHAR(100) DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, group_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_user_groups_tenant_id ON user_groups(tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_groups_parent_id ON user_groups(parent_id);
CREATE INDEX IF NOT EXISTS idx_user_groups_organization_id ON user_groups(organization_id);
CREATE INDEX IF NOT EXISTS idx_user_groups_deleted_at ON user_groups(deleted_at);

CREATE INDEX IF NOT EXISTS idx_user_group_members_user_id ON user_group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_user_group_members_group_id ON user_group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_user_group_members_role ON user_group_members(role);

-- 添加约束
ALTER TABLE user_groups ADD CONSTRAINT fk_user_groups_tenant_id 
    FOREIGN KEY (tenant_id) REFERENCES tenants(id);

-- 插入默认数据
INSERT INTO user_groups (id, name, description, tenant_id, created_at, updated_at) 
VALUES 
    ('00000000-0000-0000-0000-000000000001', '默认用户组', '系统默认用户组', '00000000-0000-0000-0000-000000000001', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000002', '管理员组', '系统管理员组', '00000000-0000-0000-0000-000000000001', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000003', '开发者组', '开发人员组', '00000000-0000-0000-0000-000000000001', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;