package repository

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/llmops/user-service/internal/domain/entity"
	"gorm.io/gorm"
)

// UserRepository 用户仓储接口
type UserRepository interface {
	// 用户基础操作
	Create(ctx context.Context, user *entity.User) error
	GetByID(ctx context.Context, id uuid.UUID) (*entity.User, error)
	GetByUsername(ctx context.Context, username string) (*entity.User, error)
	GetByEmail(ctx context.Context, email string) (*entity.User, error)
	Update(ctx context.Context, user *entity.User) error
	Delete(ctx context.Context, id uuid.UUID) error
	
	// 用户查询
	List(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.User, int64, error)
	Search(ctx context.Context, tenantID uuid.UUID, keyword string, offset, limit int) ([]*entity.User, int64, error)
	
	// 用户角色操作
	AssignRole(ctx context.Context, userID, roleID, tenantID uuid.UUID) error
	RemoveRole(ctx context.Context, userID, roleID uuid.UUID) error
	GetUserRoles(ctx context.Context, userID uuid.UUID) ([]*entity.Role, error)
	CheckUserRole(ctx context.Context, userID, roleID uuid.UUID) (bool, error)
	
	// 权限检查
	CheckUserPermission(ctx context.Context, userID uuid.UUID, permission string) (bool, error)
	GetUserPermissions(ctx context.Context, userID uuid.UUID) ([]string, error)
}

// RoleRepository 角色仓储接口
type RoleRepository interface {
	Create(ctx context.Context, role *entity.Role) error
	GetByID(ctx context.Context, id uuid.UUID) (*entity.Role, error)
	GetByName(ctx context.Context, name string, tenantID uuid.UUID) (*entity.Role, error)
	Update(ctx context.Context, role *entity.Role) error
	Delete(ctx context.Context, id uuid.UUID) error
	
	List(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.Role, int64, error)
	Search(ctx context.Context, tenantID uuid.UUID, keyword string, offset, limit int) ([]*entity.Role, int64, error)
}

// PermissionRepository 权限仓储接口
type PermissionRepository interface {
	Create(ctx context.Context, permission *entity.Permission) error
	GetByID(ctx context.Context, id uuid.UUID) (*entity.Permission, error)
	GetByName(ctx context.Context, name string, tenantID uuid.UUID) (*entity.Permission, error)
	Update(ctx context.Context, permission *entity.Permission) error
	Delete(ctx context.Context, id uuid.UUID) error
	
	List(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.Permission, int64, error)
	GetByResource(ctx context.Context, resource string, tenantID uuid.UUID) ([]*entity.Permission, error)
}

// TenantRepository 租户仓储接口
type TenantRepository interface {
	Create(ctx context.Context, tenant *entity.Tenant) error
	GetByID(ctx context.Context, id uuid.UUID) (*entity.Tenant, error)
	GetByDomain(ctx context.Context, domain string) (*entity.Tenant, error)
	Update(ctx context.Context, tenant *entity.Tenant) error
	Delete(ctx context.Context, id uuid.UUID) error
	
	List(ctx context.Context, offset, limit int) ([]*entity.Tenant, int64, error)
}

// UserSessionRepository 用户会话仓储接口
type UserSessionRepository interface {
	Create(ctx context.Context, session *entity.UserSession) error
	GetByToken(ctx context.Context, token string) (*entity.UserSession, error)
	GetByUserID(ctx context.Context, userID uuid.UUID) ([]*entity.UserSession, error)
	Update(ctx context.Context, session *entity.UserSession) error
	Delete(ctx context.Context, id uuid.UUID) error
	DeleteByUserID(ctx context.Context, userID uuid.UUID) error
	DeleteExpired(ctx context.Context) error
}

// userRepository 用户仓储实现
type userRepository struct {
	db *gorm.DB
}

// NewUserRepository 创建用户仓储实例
func NewUserRepository(db *gorm.DB) UserRepository {
	return &userRepository{db: db}
}

// Create 创建用户
func (r *userRepository) Create(ctx context.Context, user *entity.User) error {
	return r.db.WithContext(ctx).Create(user).Error
}

// GetByID 根据ID获取用户
func (r *userRepository) GetByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
	var user entity.User
	err := r.db.WithContext(ctx).First(&user, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// GetByUsername 根据用户名获取用户
func (r *userRepository) GetByUsername(ctx context.Context, username string) (*entity.User, error) {
	var user entity.User
	err := r.db.WithContext(ctx).First(&user, "username = ?", username).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// GetByEmail 根据邮箱获取用户
func (r *userRepository) GetByEmail(ctx context.Context, email string) (*entity.User, error) {
	var user entity.User
	err := r.db.WithContext(ctx).Preload("Roles").Preload("Roles.Role").First(&user, "email = ?", email).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// Update 更新用户
func (r *userRepository) Update(ctx context.Context, user *entity.User) error {
	return r.db.WithContext(ctx).Save(user).Error
}

// Delete 删除用户
func (r *userRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&entity.User{}, "id = ?", id).Error
}

// List 获取用户列表
func (r *userRepository) List(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.User, int64, error) {
	var users []*entity.User
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.User{}).Where("tenant_id = ?", tenantID)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&users).Error
	
	return users, total, err
}

// Search 搜索用户
func (r *userRepository) Search(ctx context.Context, tenantID uuid.UUID, keyword string, offset, limit int) ([]*entity.User, int64, error) {
	var users []*entity.User
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.User{}).
		Where("tenant_id = ? AND (username ILIKE ? OR email ILIKE ? OR name ILIKE ?)", 
			tenantID, "%"+keyword+"%", "%"+keyword+"%", "%"+keyword+"%")
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Preload("Roles").Preload("Roles.Role").
		Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&users).Error
	
	return users, total, err
}

// AssignRole 分配角色
func (r *userRepository) AssignRole(ctx context.Context, userID, roleID, tenantID uuid.UUID) error {
	userRole := &entity.UserRole{
		UserID:   userID.String(),
		RoleID:   roleID.String(),
		TenantID: tenantID.String(),
	}
	return r.db.WithContext(ctx).Create(userRole).Error
}

// RemoveRole 移除角色
func (r *userRepository) RemoveRole(ctx context.Context, userID, roleID uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&entity.UserRole{}, 
		"user_id = ? AND role_id = ?", userID, roleID).Error
}

// UserRoleRepository 用户角色仓储接口
type UserRoleRepository interface {
	AssignRole(ctx context.Context, userID, roleID, tenantID uuid.UUID) error
	RemoveRole(ctx context.Context, userID, roleID uuid.UUID) error
	GetUserRoles(ctx context.Context, userID uuid.UUID) ([]*entity.Role, error)
	CheckUserRole(ctx context.Context, userID, roleID uuid.UUID) (bool, error)
}

// RolePermissionRepository 角色权限仓储接口
type RolePermissionRepository interface {
	AssignPermission(ctx context.Context, roleID, permissionID uuid.UUID) error
	RemovePermission(ctx context.Context, roleID, permissionID uuid.UUID) error
	GetRolePermissions(ctx context.Context, roleID uuid.UUID) ([]*entity.Permission, error)
	CheckRolePermission(ctx context.Context, roleID, permissionID uuid.UUID) (bool, error)
}

// GetUserRoles 获取用户角色
func (r *userRepository) GetUserRoles(ctx context.Context, userID uuid.UUID) ([]*entity.Role, error) {
	var roles []*entity.Role
	err := r.db.WithContext(ctx).
		Joins("JOIN user_roles ON roles.id = user_roles.role_id").
		Where("user_roles.user_id = ?", userID).
		Find(&roles).Error
	return roles, err
}

// CheckUserRole 检查用户角色
func (r *userRepository) CheckUserRole(ctx context.Context, userID, roleID uuid.UUID) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&entity.UserRole{}).
		Where("user_id = ? AND role_id = ?", userID, roleID).
		Count(&count).Error
	return count > 0, err
}

// CheckUserPermission 检查用户权限
func (r *userRepository) CheckUserPermission(ctx context.Context, userID uuid.UUID, permission string) (bool, error) {
	// 获取用户的所有角色权限
	var permissions []string
	err := r.db.WithContext(ctx).
		Table("roles").
		Select("permissions").
		Joins("JOIN user_roles ON roles.id = user_roles.role_id").
		Where("user_roles.user_id = ?", userID).
		Pluck("permissions", &permissions).Error
	
	if err != nil {
		return false, err
	}
	
	// 检查是否有对应权限
	for _, perms := range permissions {
		if perms == "*" || perms == permission {
			return true, nil
		}
	}
	
	return false, nil
}

// GetUserPermissions 获取用户权限
func (r *userRepository) GetUserPermissions(ctx context.Context, userID uuid.UUID) ([]string, error) {
	var permissions []string
	err := r.db.WithContext(ctx).
		Table("roles").
		Select("permissions").
		Joins("JOIN user_roles ON roles.id = user_roles.role_id").
		Where("user_roles.user_id = ?", userID).
		Pluck("permissions", &permissions).Error
	
	return permissions, err
}

// roleRepository 角色仓储实现
type roleRepository struct {
	db *gorm.DB
}

// NewRoleRepository 创建角色仓储实例
func NewRoleRepository(db *gorm.DB) RoleRepository {
	return &roleRepository{db: db}
}

// Create 创建角色
func (r *roleRepository) Create(ctx context.Context, role *entity.Role) error {
	return r.db.WithContext(ctx).Create(role).Error
}

// GetByID 根据ID获取角色
func (r *roleRepository) GetByID(ctx context.Context, id uuid.UUID) (*entity.Role, error) {
	var role entity.Role
	err := r.db.WithContext(ctx).First(&role, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &role, nil
}

// GetByName 根据名称获取角色
func (r *roleRepository) GetByName(ctx context.Context, name string, tenantID uuid.UUID) (*entity.Role, error) {
	var role entity.Role
	err := r.db.WithContext(ctx).First(&role, "name = ? AND tenant_id = ?", name, tenantID).Error
	if err != nil {
		return nil, err
	}
	return &role, nil
}

// Update 更新角色
func (r *roleRepository) Update(ctx context.Context, role *entity.Role) error {
	return r.db.WithContext(ctx).Save(role).Error
}

// Delete 删除角色
func (r *roleRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&entity.Role{}, "id = ?", id).Error
}

// List 获取角色列表
func (r *roleRepository) List(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.Role, int64, error) {
	var roles []*entity.Role
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.Role{}).Where("tenant_id = ?", tenantID)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&roles).Error
	
	return roles, total, err
}

// Search 搜索角色
func (r *roleRepository) Search(ctx context.Context, tenantID uuid.UUID, keyword string, offset, limit int) ([]*entity.Role, int64, error) {
	var roles []*entity.Role
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.Role{}).
		Where("tenant_id = ? AND (name ILIKE ? OR display_name ILIKE ? OR description ILIKE ?)", 
			tenantID, "%"+keyword+"%", "%"+keyword+"%", "%"+keyword+"%")
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&roles).Error
	
	return roles, total, err
}

// permissionRepository 权限仓储实现
type permissionRepository struct {
	db *gorm.DB
}

// NewPermissionRepository 创建权限仓储实例
func NewPermissionRepository(db *gorm.DB) PermissionRepository {
	return &permissionRepository{db: db}
}

// Create 创建权限
func (r *permissionRepository) Create(ctx context.Context, permission *entity.Permission) error {
	return r.db.WithContext(ctx).Create(permission).Error
}

// GetByID 根据ID获取权限
func (r *permissionRepository) GetByID(ctx context.Context, id uuid.UUID) (*entity.Permission, error) {
	var permission entity.Permission
	err := r.db.WithContext(ctx).First(&permission, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &permission, nil
}

// GetByName 根据名称获取权限
func (r *permissionRepository) GetByName(ctx context.Context, name string, tenantID uuid.UUID) (*entity.Permission, error) {
	var permission entity.Permission
	err := r.db.WithContext(ctx).First(&permission, "name = ? AND tenant_id = ?", name, tenantID).Error
	if err != nil {
		return nil, err
	}
	return &permission, nil
}

// Update 更新权限
func (r *permissionRepository) Update(ctx context.Context, permission *entity.Permission) error {
	return r.db.WithContext(ctx).Save(permission).Error
}

// Delete 删除权限
func (r *permissionRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&entity.Permission{}, "id = ?", id).Error
}

// List 获取权限列表
func (r *permissionRepository) List(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.Permission, int64, error) {
	var permissions []*entity.Permission
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.Permission{}).Where("tenant_id = ?", tenantID)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&permissions).Error
	
	return permissions, total, err
}

// GetByResource 根据资源获取权限
func (r *permissionRepository) GetByResource(ctx context.Context, resource string, tenantID uuid.UUID) ([]*entity.Permission, error) {
	var permissions []*entity.Permission
	err := r.db.WithContext(ctx).
		Where("resource = ? AND tenant_id = ?", resource, tenantID).
		Find(&permissions).Error
	return permissions, err
}

// tenantRepository 租户仓储实现
type tenantRepository struct {
	db *gorm.DB
}

// NewTenantRepository 创建租户仓储实例
func NewTenantRepository(db *gorm.DB) TenantRepository {
	return &tenantRepository{db: db}
}

// Create 创建租户
func (r *tenantRepository) Create(ctx context.Context, tenant *entity.Tenant) error {
	return r.db.WithContext(ctx).Create(tenant).Error
}

// GetByID 根据ID获取租户
func (r *tenantRepository) GetByID(ctx context.Context, id uuid.UUID) (*entity.Tenant, error) {
	var tenant entity.Tenant
	err := r.db.WithContext(ctx).First(&tenant, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &tenant, nil
}

// GetByDomain 根据域名获取租户
func (r *tenantRepository) GetByDomain(ctx context.Context, domain string) (*entity.Tenant, error) {
	var tenant entity.Tenant
	err := r.db.WithContext(ctx).First(&tenant, "domain = ?", domain).Error
	if err != nil {
		return nil, err
	}
	return &tenant, nil
}

// Update 更新租户
func (r *tenantRepository) Update(ctx context.Context, tenant *entity.Tenant) error {
	return r.db.WithContext(ctx).Save(tenant).Error
}

// Delete 删除租户
func (r *tenantRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&entity.Tenant{}, "id = ?", id).Error
}

// List 获取租户列表
func (r *tenantRepository) List(ctx context.Context, offset, limit int) ([]*entity.Tenant, int64, error) {
	var tenants []*entity.Tenant
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.Tenant{})
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&tenants).Error
	
	return tenants, total, err
}

// userSessionRepository 用户会话仓储实现
type userSessionRepository struct {
	db *gorm.DB
}

// NewUserSessionRepository 创建用户会话仓储实例
func NewUserSessionRepository(db *gorm.DB) UserSessionRepository {
	return &userSessionRepository{db: db}
}

// Create 创建用户会话
func (r *userSessionRepository) Create(ctx context.Context, session *entity.UserSession) error {
	return r.db.WithContext(ctx).Create(session).Error
}

// GetByToken 根据令牌获取用户会话
func (r *userSessionRepository) GetByToken(ctx context.Context, token string) (*entity.UserSession, error) {
	var session entity.UserSession
	err := r.db.WithContext(ctx).First(&session, "session_token = ?", token).Error
	if err != nil {
		return nil, err
	}
	return &session, nil
}

// GetByUserID 根据用户ID获取用户会话
func (r *userSessionRepository) GetByUserID(ctx context.Context, userID uuid.UUID) ([]*entity.UserSession, error) {
	var sessions []*entity.UserSession
	err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Find(&sessions).Error
	return sessions, err
}

// Update 更新用户会话
func (r *userSessionRepository) Update(ctx context.Context, session *entity.UserSession) error {
	return r.db.WithContext(ctx).Save(session).Error
}

// Delete 删除用户会话
func (r *userSessionRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&entity.UserSession{}, "id = ?", id).Error
}

// DeleteByUserID 根据用户ID删除用户会话
func (r *userSessionRepository) DeleteByUserID(ctx context.Context, userID uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&entity.UserSession{}, "user_id = ?", userID).Error
}

// DeleteExpired 删除过期会话
func (r *userSessionRepository) DeleteExpired(ctx context.Context) error {
	return r.db.WithContext(ctx).Delete(&entity.UserSession{}, "expires_at < ?", time.Now()).Error
}



