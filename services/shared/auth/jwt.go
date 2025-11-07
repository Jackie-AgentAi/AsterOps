package auth

import (
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// JWT配置
type JWTConfig struct {
	SecretKey     string
	AccessExpiry  time.Duration
	RefreshExpiry time.Duration
	Issuer        string
}

// 默认配置
var DefaultJWTConfig = JWTConfig{
	SecretKey:     "llmops-secret-key-2025",
	AccessExpiry:  15 * time.Minute,
	RefreshExpiry: 7 * 24 * time.Hour,
	Issuer:        "llmops-platform",
}

// 自定义Claims
type Claims struct {
	UserID   string   `json:"user_id"`
	Username string   `json:"username"`
	Email    string   `json:"email"`
	Roles    []string `json:"roles"`
	TenantID string   `json:"tenant_id"`
	jwt.RegisteredClaims
}

// JWT管理器
type JWTManager struct {
	config JWTConfig
}

// 创建JWT管理器
func NewJWTManager(config JWTConfig) *JWTManager {
	return &JWTManager{config: config}
}

// 生成访问令牌
func (j *JWTManager) GenerateAccessToken(userID, username, email, tenantID string, roles []string) (string, error) {
	claims := &Claims{
		UserID:   userID,
		Username: username,
		Email:    email,
		Roles:    roles,
		TenantID: tenantID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(j.config.AccessExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    j.config.Issuer,
			Subject:   userID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(j.config.SecretKey))
}

// 生成刷新令牌
func (j *JWTManager) GenerateRefreshToken(userID string) (string, error) {
	claims := &Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(j.config.RefreshExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    j.config.Issuer,
			Subject:   userID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(j.config.SecretKey))
}

// 验证令牌
func (j *JWTManager) ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(j.config.SecretKey), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

// 刷新访问令牌
func (j *JWTManager) RefreshAccessToken(refreshToken string, username, email string, roles []string) (string, error) {
	claims, err := j.ValidateToken(refreshToken)
	if err != nil {
		return "", err
	}

	// 生成新的访问令牌
	return j.GenerateAccessToken(claims.UserID, username, email, claims.TenantID, roles)
}

// 检查权限
func (c *Claims) HasRole(role string) bool {
	for _, r := range c.Roles {
		if r == role {
			return true
		}
	}
	return false
}

// 检查权限列表
func (c *Claims) HasAnyRole(roles []string) bool {
	for _, role := range roles {
		if c.HasRole(role) {
			return true
		}
	}
	return false
}

// 检查是否为管理员
func (c *Claims) IsAdmin() bool {
	return c.HasRole("admin")
}

// 检查是否为项目所有者
func (c *Claims) IsProjectOwner(projectOwnerID string) bool {
	return c.UserID == projectOwnerID || c.IsAdmin()
}

