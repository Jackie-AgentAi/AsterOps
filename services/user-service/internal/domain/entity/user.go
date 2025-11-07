package entity

import (
	"time"
	
	"github.com/golang-jwt/jwt/v5"
)

// 用户实体
type User struct {
	ID        string     `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	Username  string     `json:"username" gorm:"uniqueIndex;not null"`
	Email     string     `json:"email" gorm:"uniqueIndex;not null"`
	Password  string     `json:"-" gorm:"column:password_hash;not null"` // 不返回密码
	FirstName string     `json:"first_name" gorm:"-"`
	LastName  string     `json:"last_name" gorm:"-"`
	Name      string     `json:"name" gorm:"column:name"`
	Avatar    string     `json:"avatar" gorm:"-"`
	IsActive  bool       `json:"is_active" gorm:"-"`
	IsAdmin   bool       `json:"is_admin" gorm:"-"`
	Status    string     `json:"status" gorm:"default:'active'"`
	Phone     string     `json:"phone" gorm:"-"`
	Department string    `json:"department" gorm:"-"`
	Role      string     `json:"role" gorm:"-"`
	TenantID  string     `json:"tenant_id" gorm:"not null;index"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	LastLogin *time.Time `json:"last_login,omitempty" gorm:"column:last_login_at"`
}

// 角色实体
type Role struct {
	ID          string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	Name        string    `json:"name" gorm:"uniqueIndex;not null"`
	DisplayName string    `json:"display_name"`
	Description string    `json:"description"`
	TenantID    string    `json:"tenant_id" gorm:"not null;index"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 权限实体
type Permission struct {
	ID          string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	Name        string    `json:"name" gorm:"uniqueIndex;not null"`
	DisplayName string    `json:"display_name"`
	Description string    `json:"description"`
	Resource    string    `json:"resource"` // 资源类型：user, project, model, etc.
	Action      string    `json:"action"`   // 操作类型：create, read, update, delete
	TenantID    string    `json:"tenant_id" gorm:"not null;index"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 用户角色关联
type UserRole struct {
	ID       string `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	UserID   string `json:"user_id" gorm:"not null;index"`
	RoleID   string `json:"role_id" gorm:"not null;index"`
	TenantID string `json:"tenant_id" gorm:"not null;index"`
	User     User   `json:"user" gorm:"foreignKey:UserID"`
	Role     Role   `json:"role" gorm:"foreignKey:RoleID"`
}

// 角色权限关联
type RolePermission struct {
	ID           string     `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	RoleID       string     `json:"role_id" gorm:"not null;index"`
	PermissionID string     `json:"permission_id" gorm:"not null;index"`
	Role         Role       `json:"role" gorm:"foreignKey:RoleID"`
	Permission   Permission `json:"permission" gorm:"foreignKey:PermissionID"`
}

// 登录请求
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// 注册请求
type RegisterRequest struct {
	Username  string `json:"username" binding:"required,min=3,max=20"`
	Email     string `json:"email" binding:"required,email"`
	Password  string `json:"password" binding:"required,min=6"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	TenantID  string `json:"tenant_id" binding:"required"`
}

// 刷新令牌请求
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// 认证响应
type AuthResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	TokenType    string `json:"token_type"`
	ExpiresIn    int64  `json:"expires_in"`
	User         User   `json:"user"`
}

// 租户实体
type Tenant struct {
	ID          string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	Name        string    `json:"name" gorm:"uniqueIndex;not null"`
	DisplayName string    `json:"display_name"`
	Description string    `json:"description"`
	IsActive    bool      `json:"is_active" gorm:"default:true"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 用户会话实体
type UserSession struct {
	ID           string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	UserID       string    `json:"user_id" gorm:"not null;index"`
	SessionToken string    `json:"session_token" gorm:"uniqueIndex;not null"`
	RefreshToken string    `json:"refresh_token" gorm:"uniqueIndex;not null"`
	ExpiresAt    time.Time `json:"expires_at"`
	IsActive     bool      `json:"is_active" gorm:"default:true"`
	IPAddress    string    `json:"ip_address"`
	UserAgent    string    `json:"user_agent"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
	User         User      `json:"user" gorm:"foreignKey:UserID"`
}

// JWT Claims
type Claims struct {
	UserID   string   `json:"user_id"`
	Username string   `json:"username"`
	Email    string   `json:"email"`
	TenantID string   `json:"tenant_id"`
	Roles    []string `json:"roles"`
	jwt.RegisteredClaims
}

// 用户信息响应（不包含敏感信息）
type UserResponse struct {
	ID        string    `json:"id"`
	Username  string    `json:"username"`
	Email     string    `json:"email"`
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
	Avatar    string    `json:"avatar"`
	IsActive  bool      `json:"is_active"`
	IsAdmin   bool      `json:"is_admin"`
	TenantID  string    `json:"tenant_id"`
	Roles     []string  `json:"roles"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	LastLogin *time.Time `json:"last_login,omitempty"`
}

// 组织实体
type Organization struct {
	ID          string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	Name        string    `json:"name" gorm:"not null"`
	Description string    `json:"description"`
	ParentID    *string   `json:"parent_id" gorm:"type:uuid"`
	TenantID    string    `json:"tenant_id" gorm:"not null;index"`
	Settings    string    `json:"settings" gorm:"type:jsonb"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
	DeletedAt   *time.Time `json:"deleted_at,omitempty" gorm:"index"`
}

// 用户组实体
type UserGroup struct {
	ID             string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	Name           string    `json:"name" gorm:"not null"`
	Description    string    `json:"description"`
	TenantID       string    `json:"tenant_id" gorm:"not null;index"`
	OrganizationID *string   `json:"organization_id" gorm:"type:uuid"`
	ParentID       *string   `json:"parent_id" gorm:"type:uuid"`
	Settings       string    `json:"settings" gorm:"type:jsonb"`
	MemberCount    int       `json:"member_count" gorm:"-"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
	DeletedAt      *time.Time `json:"deleted_at,omitempty" gorm:"index"`
}

// 用户组成员实体
type UserGroupMember struct {
	ID        string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	UserID    string    `json:"user_id" gorm:"not null;index"`
	GroupID   string    `json:"group_id" gorm:"not null;index"`
	Role      string    `json:"role" gorm:"default:'member'"`
	JoinedAt  time.Time `json:"joined_at"`
	User      *User     `json:"user" gorm:"foreignKey:UserID"`
	UserGroup *UserGroup `json:"user_group" gorm:"foreignKey:GroupID"`
}

// 用户配额实体
type UserQuota struct {
	ID           string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	UserID       string    `json:"user_id" gorm:"not null;index"`
	ResourceType string    `json:"resource_type" gorm:"not null"`
	QuotaLimit   int64     `json:"quota_limit" gorm:"not null"`
	UsedAmount   int64     `json:"used_amount" gorm:"default:0"`
	PeriodType   string    `json:"period_type" gorm:"default:'monthly'"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
	User         User      `json:"user" gorm:"foreignKey:UserID"`
}

// 审计日志实体
type AuditLog struct {
	ID           string     `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	UserID       *string    `json:"user_id" gorm:"type:uuid"`
	Action       string     `json:"action" gorm:"not null"`
	ResourceType string     `json:"resource_type"`
	ResourceID   string     `json:"resource_id"`
	Details      string     `json:"details" gorm:"type:jsonb"`
	IPAddress    string     `json:"ip_address"`
	UserAgent    string     `json:"user_agent"`
	CreatedAt    time.Time  `json:"created_at"`
	User         *User      `json:"user,omitempty" gorm:"foreignKey:UserID"`
}

// 安全策略实体
type SecurityPolicy struct {
	ID           string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	TenantID     string    `json:"tenant_id" gorm:"not null;index"`
	PolicyType   string    `json:"policy_type" gorm:"not null"`
	PolicyConfig string    `json:"policy_config" gorm:"type:jsonb;not null"`
	IsActive     bool      `json:"is_active" gorm:"default:true"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// 用户偏好设置实体
type UserPreference struct {
	ID              string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	UserID          string    `json:"user_id" gorm:"not null;index"`
	PreferenceKey   string    `json:"preference_key" gorm:"not null"`
	PreferenceValue string    `json:"preference_value" gorm:"type:jsonb"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
	User            User      `json:"user" gorm:"foreignKey:UserID"`
}

// 创建用户请求
type CreateUserRequest struct {
	Username  string `json:"username" binding:"required,min=3,max=20"`
	Email     string `json:"email" binding:"required,email"`
	Password  string `json:"password" binding:"required,min=6"`
	Name      string `json:"name"`
	Phone     string `json:"phone"`
	Department string `json:"department"`
	Role      string `json:"role"`
	Status    string `json:"status"`
	TenantID  string `json:"tenant_id" binding:"required"`
}

// 更新用户请求
type UpdateUserRequest struct {
	Name       string `json:"name"`
	Phone      string `json:"phone"`
	Department string `json:"department"`
	Role       string `json:"role"`
	Status     string `json:"status"`
}

// 批量操作请求
type BatchUserOperationRequest struct {
	UserIDs []string `json:"user_ids" binding:"required"`
	Action  string   `json:"action" binding:"required"`
	Data    string   `json:"data" gorm:"type:jsonb"`
}

// 用户搜索请求
type UserSearchRequest struct {
	Keyword  string `json:"keyword"`
	Role     string `json:"role"`
	Status   string `json:"status"`
	TenantID string `json:"tenant_id"`
	Page     int    `json:"page"`
	PageSize int    `json:"page_size"`
}

// 用户统计响应
type UserStatsResponse struct {
	TotalUsers     int64 `json:"total_users"`
	ActiveUsers    int64 `json:"active_users"`
	InactiveUsers  int64 `json:"inactive_users"`
	NewUsersToday  int64 `json:"new_users_today"`
	NewUsersWeek   int64 `json:"new_users_week"`
	NewUsersMonth  int64 `json:"new_users_month"`
}

// 配额使用统计
type QuotaUsageStats struct {
	ResourceType string  `json:"resource_type"`
	TotalQuota  int64   `json:"total_quota"`
	UsedQuota   int64   `json:"used_quota"`
	UsageRate   float64 `json:"usage_rate"`
}

// 组织树节点
type OrganizationTreeNode struct {
	ID          string                   `json:"id"`
	Name        string                   `json:"name"`
	Description string                   `json:"description"`
	Status      string                   `json:"status"`
	Children    []OrganizationTreeNode   `json:"children,omitempty"`
}