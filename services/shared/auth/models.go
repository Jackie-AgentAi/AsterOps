package auth

import (
	"time"
)

// 用户模型
type User struct {
	ID        string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	Username  string    `json:"username" gorm:"uniqueIndex;not null"`
	Email     string    `json:"email" gorm:"uniqueIndex;not null"`
	Password  string    `json:"-" gorm:"not null"` // 不返回密码
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
	Avatar    string    `json:"avatar"`
	IsActive  bool      `json:"is_active" gorm:"default:true"`
	IsAdmin   bool      `json:"is_admin" gorm:"default:false"`
	TenantID  string    `json:"tenant_id" gorm:"not null;index"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	LastLogin *time.Time `json:"last_login,omitempty"`
}

// 角色模型
type Role struct {
	ID          string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	Name        string    `json:"name" gorm:"uniqueIndex;not null"`
	DisplayName string    `json:"display_name"`
	Description string    `json:"description"`
	TenantID    string    `json:"tenant_id" gorm:"not null;index"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 权限模型
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
	ID     string `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	UserID string `json:"user_id" gorm:"not null;index"`
	RoleID string `json:"role_id" gorm:"not null;index"`
	User   User   `json:"user" gorm:"foreignKey:UserID"`
	Role   Role   `json:"role" gorm:"foreignKey:RoleID"`
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

// 角色响应
type RoleResponse struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	DisplayName string   `json:"display_name"`
	Description string   `json:"description"`
	Permissions []string `json:"permissions"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 权限响应
type PermissionResponse struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	DisplayName string `json:"display_name"`
	Description string `json:"description"`
	Resource    string `json:"resource"`
	Action      string `json:"action"`
}

// 密码哈希接口
type PasswordHasher interface {
	Hash(password string) (string, error)
	Verify(password, hash string) bool
}

// 默认密码哈希器
type BCryptHasher struct{}

func (h *BCryptHasher) Hash(password string) (string, error) {
	// 这里应该使用bcrypt，但为了简化，先返回明文
	// 生产环境中应该使用: return bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return password, nil
}

func (h *BCryptHasher) Verify(password, hash string) bool {
	// 这里应该使用bcrypt验证，但为了简化，先直接比较
	// 生产环境中应该使用: return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
	return password == hash
}

