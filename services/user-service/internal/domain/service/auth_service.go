package service

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/llmops/user-service/internal/domain/entity"
	"github.com/llmops/user-service/internal/domain/repository"
)

// JWT管理器服务
type JWTManager struct {
	secretKey     string
	accessExpiry  time.Duration
	refreshExpiry time.Duration
	issuer        string
}

// 创建JWT管理器
func NewJWTManager(secretKey string) *JWTManager {
	return &JWTManager{
		secretKey:     secretKey,
		accessExpiry:  15 * time.Minute,
		refreshExpiry: 7 * 24 * time.Hour,
		issuer:        "llmops-platform",
	}
}

// 生成访问令牌
func (j *JWTManager) GenerateAccessToken(userID, username, email, tenantID string, roles []string) (string, error) {
	// 简化的JWT实现，实际应该使用jwt-go库
	// 这里返回一个模拟的令牌
	token := "access_token_" + userID + "_" + username
	return token, nil
}

// 生成刷新令牌
func (j *JWTManager) GenerateRefreshToken(userID string) (string, error) {
	// 简化的JWT实现，实际应该使用jwt-go库
	// 这里返回一个模拟的令牌
	token := "refresh_token_" + userID
	return token, nil
}

// 验证令牌
func (j *JWTManager) ValidateToken(tokenString string) (*entity.Claims, error) {
	// 简化的JWT验证，实际应该使用jwt-go库
	// 这里返回模拟的Claims
	claims := &entity.Claims{
		UserID:   "550e8400-e29b-41d4-a716-446655440000",
		Username: "testuser",
		Email:    "test@example.com",
		Roles:    []string{"user"},
		TenantID: "550e8400-e29b-41d4-a716-446655440000",
	}
	return claims, nil
}

// 密码哈希器
type PasswordHasher struct{}

// 创建密码哈希器
func NewPasswordHasher() *PasswordHasher {
	return &PasswordHasher{}
}

// 哈希密码
func (h *PasswordHasher) Hash(password string) (string, error) {
	// 简化的密码哈希，实际应该使用bcrypt
	// 这里直接返回原密码（仅用于演示）
	return password, nil
}

// 验证密码
func (h *PasswordHasher) Verify(password, hash string) bool {
	// 简化的密码验证，实际应该使用bcrypt
	// 这里直接比较密码（仅用于演示）
	return password == hash
}

// 认证服务
type AuthService struct {
	userRepo       repository.UserRepository
	sessionRepo    repository.UserSessionRepository
	logger         Logger
	jwtSecret      string
	tokenExpiry    time.Duration
	refreshExpiry  time.Duration
}

// 创建认证服务
func NewAuthService(
	userRepo repository.UserRepository,
	sessionRepo repository.UserSessionRepository,
	logger Logger,
	jwtSecret string,
	tokenExpiry time.Duration,
	refreshExpiry time.Duration,
) *AuthService {
	return &AuthService{
		userRepo:      userRepo,
		sessionRepo:   sessionRepo,
		logger:        logger,
		jwtSecret:     jwtSecret,
		tokenExpiry:   tokenExpiry,
		refreshExpiry: refreshExpiry,
	}
}

// 验证用户凭据
func (s *AuthService) ValidateCredentials(ctx context.Context, username, password string) (*entity.User, error) {
	user, err := s.userRepo.GetByUsername(ctx, username)
	if err != nil {
		s.logger.Errorf("Failed to get user by username %s: %v", username, err)
		return nil, err
	}

	// 简化的密码验证（实际应该使用bcrypt）
	if password != user.Password {
		s.logger.Errorf("Password mismatch for user %s", username)
		return nil, errors.New("invalid credentials")
	}

	return user, nil
}

// 生成认证响应
func (s *AuthService) GenerateAuthResponse(ctx context.Context, user *entity.User) (*entity.AuthResponse, error) {
	// 生成访问令牌
	accessToken, err := s.GenerateAccessToken(user.ID, user.Username, user.Email, user.TenantID, []string{"user"})
	if err != nil {
		return nil, err
	}

	// 生成刷新令牌
	refreshToken, err := s.GenerateRefreshToken(user.ID)
	if err != nil {
		return nil, err
	}

	response := &entity.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    int64(s.tokenExpiry.Seconds()),
		User:         *user,
	}

	return response, nil
}

// 生成访问令牌
func (s *AuthService) GenerateAccessToken(userID, username, email, tenantID string, roles []string) (string, error) {
	// 简化的JWT实现
	token := "access_token_" + userID + "_" + username
	return token, nil
}

// 生成刷新令牌
func (s *AuthService) GenerateRefreshToken(userID string) (string, error) {
	// 简化的JWT实现
	token := "refresh_token_" + userID
	return token, nil
}

// 登录
func (s *AuthService) Login(ctx context.Context, req *entity.LoginRequest) (*entity.AuthResponse, error) {
	user, err := s.ValidateCredentials(ctx, req.Username, req.Password)
	if err != nil {
		return nil, err
	}

	return s.GenerateAuthResponse(ctx, user)
}

// 注册
func (s *AuthService) Register(ctx context.Context, req *entity.RegisterRequest) (*entity.AuthResponse, error) {
	// 检查用户名是否已存在
	existingUser, _ := s.userRepo.GetByUsername(ctx, req.Username)
	if existingUser != nil {
		return nil, errors.New("username already exists")
	}

	// 检查邮箱是否已存在
	existingUser, _ = s.userRepo.GetByEmail(ctx, req.Email)
	if existingUser != nil {
		return nil, errors.New("email already exists")
	}

	// 创建用户
	user := &entity.User{
		ID:        uuid.New().String(),
		Username:  req.Username,
		Email:     req.Email,
		Password:  req.Password, // 实际应该哈希密码
		FirstName: req.FirstName,
		LastName:  req.LastName,
		TenantID:  req.TenantID,
		IsActive:  true,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	err := s.userRepo.Create(ctx, user)
	if err != nil {
		return nil, err
	}

	return s.GenerateAuthResponse(ctx, user)
}

// 刷新令牌
func (s *AuthService) RefreshToken(ctx context.Context, req *entity.RefreshTokenRequest) (*entity.AuthResponse, error) {
	// 简化的刷新令牌实现
	// 实际应该验证刷新令牌并生成新的访问令牌
	return &entity.AuthResponse{
		AccessToken:  "new_access_token",
		RefreshToken: "new_refresh_token",
		TokenType:    "Bearer",
		ExpiresIn:    int64(s.tokenExpiry.Seconds()),
	}, nil
}

// 获取用户信息
func (s *AuthService) GetProfile(ctx context.Context, userID string) (*entity.User, error) {
	userUUID, err := uuid.Parse(userID)
	if err != nil {
		return nil, err
	}
	return s.userRepo.GetByID(ctx, userUUID)
}

// 登出
func (s *AuthService) Logout(ctx context.Context, userID string) error {
	// 简化的登出实现
	// 实际应该使令牌失效
	return nil
}