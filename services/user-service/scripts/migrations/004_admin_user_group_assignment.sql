-- 用户组自动分配迁移脚本
-- 创建时间: 2025-01-17
-- 描述: 确保admin用户自动加入admin用户组

-- 插入admin用户（如果不存在）
INSERT INTO users (id, username, email, password_hash, name, status, tenant_id, created_at, updated_at) 
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'admin', 'admin@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrator', 'active', '00000000-0000-0000-0000-000000000001', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 确保admin用户组存在
INSERT INTO user_groups (id, name, description, tenant_id, created_at, updated_at) 
VALUES 
    ('00000000-0000-0000-0000-000000000002', '管理员组', '系统管理员组', '00000000-0000-0000-0000-000000000001', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 将admin用户添加到管理员组（如果不存在）
INSERT INTO user_group_members (id, user_id, group_id, role, joined_at) 
VALUES 
    ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'admin', NOW())
ON CONFLICT (user_id, group_id) DO NOTHING;

-- 为admin用户分配系统管理员角色（如果不存在）
INSERT INTO user_roles (id, user_id, role_id, tenant_id, created_at, updated_at) 
VALUES 
    ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', NOW(), NOW())
ON CONFLICT (user_id, role_id) DO NOTHING;

-- 更新用户组的成员数量统计
UPDATE user_groups 
SET member_count = (
    SELECT COUNT(*) 
    FROM user_group_members 
    WHERE group_id = user_groups.id
)
WHERE id = '00000000-0000-0000-0000-000000000002';

-- 创建触发器函数：当用户被添加到用户组时自动更新成员数量
CREATE OR REPLACE FUNCTION update_user_group_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE user_groups 
        SET member_count = (
            SELECT COUNT(*) 
            FROM user_group_members 
            WHERE group_id = NEW.group_id
        )
        WHERE id = NEW.group_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE user_groups 
        SET member_count = (
            SELECT COUNT(*) 
            FROM user_group_members 
            WHERE group_id = OLD.group_id
        )
        WHERE id = OLD.group_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器：自动更新用户组成员数量
DROP TRIGGER IF EXISTS trigger_update_user_group_member_count ON user_group_members;
CREATE TRIGGER trigger_update_user_group_member_count
    AFTER INSERT OR DELETE ON user_group_members
    FOR EACH ROW EXECUTE FUNCTION update_user_group_member_count();

-- 创建函数：自动将新创建的用户添加到默认用户组
CREATE OR REPLACE FUNCTION auto_assign_user_to_default_group()
RETURNS TRIGGER AS $$
BEGIN
    -- 将新用户添加到默认用户组
    INSERT INTO user_group_members (user_id, group_id, role, joined_at) 
    VALUES (NEW.id, '00000000-0000-0000-0000-000000000001', 'member', NOW())
    ON CONFLICT (user_id, group_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器：新用户自动加入默认用户组
DROP TRIGGER IF EXISTS trigger_auto_assign_user_to_default_group ON users;
CREATE TRIGGER trigger_auto_assign_user_to_default_group
    AFTER INSERT ON users
    FOR EACH ROW EXECUTE FUNCTION auto_assign_user_to_default_group();

-- 创建函数：确保admin用户始终在管理员组中
CREATE OR REPLACE FUNCTION ensure_admin_in_admin_group()
RETURNS TRIGGER AS $$
BEGIN
    -- 如果admin用户被删除，重新创建
    IF OLD.username = 'admin' AND TG_OP = 'DELETE' THEN
        INSERT INTO users (id, username, email, password_hash, name, status, tenant_id, created_at, updated_at) 
        VALUES ('00000000-0000-0000-0000-000000000001', 'admin', 'admin@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrator', 'active', '00000000-0000-0000-0000-000000000001', NOW(), NOW())
        ON CONFLICT (id) DO NOTHING;
        
        -- 确保admin用户在管理员组中
        INSERT INTO user_group_members (user_id, group_id, role, joined_at) 
        VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'admin', NOW())
        ON CONFLICT (user_id, group_id) DO NOTHING;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器：确保admin用户始终存在并在管理员组中
DROP TRIGGER IF EXISTS trigger_ensure_admin_in_admin_group ON users;
CREATE TRIGGER trigger_ensure_admin_in_admin_group
    AFTER DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION ensure_admin_in_admin_group();
