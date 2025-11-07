-- 用户权限服务数据库初始化脚本

-- 创建数据库（如果不存在）
SELECT 'CREATE DATABASE user_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'user_db')\gexec

-- 使用数据库
\c user_db;

-- 启用UUID扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    status VARCHAR(50) DEFAULT 'active',
    tenant_id UUID NOT NULL,
    last_login_at TIMESTAMP WITH TIME ZONE,
    mfa_enabled BOOLEAN DEFAULT false,
    mfa_secret VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 角色表
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    tenant_id UUID NOT NULL,
    is_system BOOLEAN DEFAULT false,
    permissions TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 用户角色关联表
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, role_id)
);

-- 权限表
CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(100) NOT NULL,
    tenant_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 租户表
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'active',
    domain VARCHAR(255),
    settings JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 用户会话表
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 角色权限关联表
CREATE TABLE IF NOT EXISTS role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(role_id, permission_id)
);

-- 组织表
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    parent_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    tenant_id UUID NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    settings JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_tenant_id ON users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

CREATE INDEX IF NOT EXISTS idx_roles_name ON roles(name);
CREATE INDEX IF NOT EXISTS idx_roles_tenant_id ON roles(tenant_id);
CREATE INDEX IF NOT EXISTS idx_roles_is_system ON roles(is_system);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles(role_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_tenant_id ON user_roles(tenant_id);

CREATE INDEX IF NOT EXISTS idx_permissions_name ON permissions(name);
CREATE INDEX IF NOT EXISTS idx_permissions_resource ON permissions(resource);
CREATE INDEX IF NOT EXISTS idx_permissions_tenant_id ON permissions(tenant_id);

CREATE INDEX IF NOT EXISTS idx_tenants_name ON tenants(name);
CREATE INDEX IF NOT EXISTS idx_tenants_domain ON tenants(domain);
CREATE INDEX IF NOT EXISTS idx_tenants_status ON tenants(status);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires_at ON user_sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_is_active ON user_sessions(is_active);

CREATE INDEX IF NOT EXISTS idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission_id ON role_permissions(permission_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_tenant_id ON role_permissions(tenant_id);

CREATE INDEX IF NOT EXISTS idx_organizations_name ON organizations(name);
CREATE INDEX IF NOT EXISTS idx_organizations_parent_id ON organizations(parent_id);
CREATE INDEX IF NOT EXISTS idx_organizations_tenant_id ON organizations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_organizations_status ON organizations(status);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有表添加更新时间触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_roles_updated_at BEFORE UPDATE ON user_roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_permissions_updated_at BEFORE UPDATE ON permissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_sessions_updated_at BEFORE UPDATE ON user_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_role_permissions_updated_at BEFORE UPDATE ON role_permissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入默认租户
INSERT INTO tenants (id, name, description, status, domain) VALUES 
('00000000-0000-0000-0000-000000000001', 'Default Tenant', 'Default system tenant', 'active', 'localhost')
ON CONFLICT (id) DO NOTHING;

-- 插入默认角色
INSERT INTO roles (id, name, description, tenant_id, is_system, permissions) VALUES 
('00000000-0000-0000-0000-000000000001', 'system_admin', 'System Administrator', '00000000-0000-0000-0000-000000000001', true, ARRAY['*']),
('00000000-0000-0000-0000-000000000002', 'tenant_admin', 'Tenant Administrator', '00000000-0000-0000-0000-000000000001', false, ARRAY['user:manage', 'role:manage', 'permission:manage']),
('00000000-0000-0000-0000-000000000003', 'user', 'Regular User', '00000000-0000-0000-0000-000000000001', false, ARRAY['user:read', 'profile:manage'])
ON CONFLICT (id) DO NOTHING;

-- 插入默认权限
INSERT INTO permissions (id, name, description, resource, action, tenant_id) VALUES 
('00000000-0000-0000-0000-000000000001', 'user:create', 'Create users', 'user', 'create', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000002', 'user:read', 'Read users', 'user', 'read', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000003', 'user:update', 'Update users', 'user', 'update', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000004', 'user:delete', 'Delete users', 'user', 'delete', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000005', 'role:manage', 'Manage roles', 'role', 'manage', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000006', 'permission:manage', 'Manage permissions', 'permission', 'manage', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000007', 'profile:manage', 'Manage own profile', 'profile', 'manage', '00000000-0000-0000-0000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- 插入角色权限关联
INSERT INTO role_permissions (id, role_id, permission_id, tenant_id) VALUES 
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- 插入默认组织
INSERT INTO organizations (id, name, description, tenant_id, status, settings) VALUES 
('00000000-0000-0000-0000-000000000001', 'Default Organization', 'Default system organization', '00000000-0000-0000-0000-000000000001', 'active', '{}')
ON CONFLICT (id) DO NOTHING;

-- 用户组表
CREATE TABLE IF NOT EXISTS user_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    tenant_id UUID NOT NULL,
    organization_id UUID REFERENCES organizations(id),
    parent_id UUID REFERENCES user_groups(id),
    settings JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 用户组用户关联表
CREATE TABLE IF NOT EXISTS user_group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    group_id UUID NOT NULL REFERENCES user_groups(id) ON DELETE CASCADE,
    role VARCHAR(100) DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, group_id)
);

-- 资源配额表
CREATE TABLE IF NOT EXISTS user_quotas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    resource_type VARCHAR(100) NOT NULL,
    quota_limit BIGINT NOT NULL,
    used_amount BIGINT DEFAULT 0,
    period_type VARCHAR(50) DEFAULT 'monthly',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 审计日志表
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id VARCHAR(100),
    details JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 安全策略表
CREATE TABLE IF NOT EXISTS security_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    policy_type VARCHAR(100) NOT NULL,
    policy_config JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 用户偏好设置表
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    preference_key VARCHAR(100) NOT NULL,
    preference_value JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, preference_key)
);

-- 创建新增表的索引
CREATE INDEX IF NOT EXISTS idx_user_groups_tenant_id ON user_groups(tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_groups_organization_id ON user_groups(organization_id);
CREATE INDEX IF NOT EXISTS idx_user_groups_parent_id ON user_groups(parent_id);

CREATE INDEX IF NOT EXISTS idx_user_group_members_user_id ON user_group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_user_group_members_group_id ON user_group_members(group_id);

CREATE INDEX IF NOT EXISTS idx_user_quotas_user_id ON user_quotas(user_id);
CREATE INDEX IF NOT EXISTS idx_user_quotas_resource_type ON user_quotas(resource_type);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource_type ON audit_logs(resource_type);

CREATE INDEX IF NOT EXISTS idx_security_policies_tenant_id ON security_policies(tenant_id);
CREATE INDEX IF NOT EXISTS idx_security_policies_policy_type ON security_policies(policy_type);
CREATE INDEX IF NOT EXISTS idx_security_policies_is_active ON security_policies(is_active);

CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_key ON user_preferences(preference_key);

-- 为新增表添加更新时间触发器
CREATE TRIGGER update_user_groups_updated_at BEFORE UPDATE ON user_groups
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_quotas_updated_at BEFORE UPDATE ON user_quotas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_security_policies_updated_at BEFORE UPDATE ON security_policies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入默认用户组
INSERT INTO user_groups (id, name, description, tenant_id, organization_id) VALUES 
('00000000-0000-0000-0000-000000000001', 'Default Group', 'Default system group', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- 插入默认安全策略
INSERT INTO security_policies (id, tenant_id, policy_type, policy_config) VALUES 
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'password_policy', '{"min_length": 8, "require_uppercase": true, "require_lowercase": true, "require_numbers": true, "require_symbols": false, "max_age_days": 90}'),
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'login_policy', '{"max_failed_attempts": 5, "lockout_duration_minutes": 30, "session_timeout_minutes": 480, "require_mfa": false}'),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'quota_policy', '{"default_gpu_quota": 100, "default_storage_quota": 1000, "default_api_quota": 10000}')
ON CONFLICT (id) DO NOTHING;



