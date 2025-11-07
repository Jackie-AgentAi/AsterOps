package service

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/llmops/user-service/internal/domain/entity"
	"github.com/llmops/user-service/internal/domain/repository"
)

// 用户服务
type UserService struct {
	userRepo       repository.UserRepository
	roleRepo       repository.RoleRepository
	sessionRepo    repository.UserSessionRepository
	groupRepo      repository.UserGroupRepository
	logger         Logger
	jwtSecret      string
	tokenExpiry    time.Duration
	refreshExpiry  time.Duration
}

// Logger 日志接口
type Logger interface {
	Info(args ...interface{})
	Infof(format string, args ...interface{})
	Error(args ...interface{})
	Errorf(format string, args ...interface{})
	Fatal(args ...interface{})
	Fatalf(format string, args ...interface{})
}

// 创建用户服务
func NewUserService(
	userRepo repository.UserRepository,
	roleRepo repository.RoleRepository,
	sessionRepo repository.UserSessionRepository,
	groupRepo repository.UserGroupRepository,
	logger Logger,
	jwtSecret string,
	tokenExpiry time.Duration,
	refreshExpiry time.Duration,
) *UserService {
	return &UserService{
		userRepo:      userRepo,
		roleRepo:      roleRepo,
		sessionRepo:   sessionRepo,
		groupRepo:     groupRepo,
		logger:        logger,
		jwtSecret:     jwtSecret,
		tokenExpiry:   tokenExpiry,
		refreshExpiry: refreshExpiry,
	}
}

// 创建用户
func (s *UserService) CreateUser(ctx context.Context, user *entity.User) error {
	// 检查用户名是否已存在
	existingUser, _ := s.userRepo.GetByUsername(ctx, user.Username)
	if existingUser != nil {
		return errors.New("username already exists")
	}

	// 检查邮箱是否已存在
	existingUser, _ = s.userRepo.GetByEmail(ctx, user.Email)
	if existingUser != nil {
		return errors.New("email already exists")
	}

	// 设置创建时间
	user.CreatedAt = time.Now()
	user.UpdatedAt = time.Now()

	return s.userRepo.Create(ctx, user)
}

// 根据ID获取用户
func (s *UserService) GetUserByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
	return s.userRepo.GetByID(ctx, id)
}

// 根据用户名获取用户
func (s *UserService) GetUserByUsername(ctx context.Context, username string) (*entity.User, error) {
	return s.userRepo.GetByUsername(ctx, username)
}

// 根据邮箱获取用户
func (s *UserService) GetUserByEmail(ctx context.Context, email string) (*entity.User, error) {
	return s.userRepo.GetByEmail(ctx, email)
}

// 更新用户
func (s *UserService) UpdateUser(ctx context.Context, user *entity.User) error {
	user.UpdatedAt = time.Now()
	return s.userRepo.Update(ctx, user)
}

// 删除用户
func (s *UserService) DeleteUser(ctx context.Context, id uuid.UUID) error {
	return s.userRepo.Delete(ctx, id)
}

// 获取用户列表
func (s *UserService) GetUsers(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.User, int64, error) {
	return s.userRepo.List(ctx, tenantID, offset, limit)
}

// 获取用户角色
func (s *UserService) GetUserRoles(ctx context.Context, userID uuid.UUID) ([]string, error) {
	userRoles, err := s.userRepo.GetUserRoles(ctx, userID)
	if err != nil {
		return nil, err
	}

	roles := make([]string, 0, len(userRoles))
	for _, role := range userRoles {
		roles = append(roles, role.Name)
	}

	return roles, nil
}

// 分配角色给用户
func (s *UserService) AssignRole(ctx context.Context, userID, roleID, tenantID uuid.UUID) error {
	// 检查用户是否存在
	_, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return errors.New("user not found")
	}

	// 检查角色是否存在
	_, err = s.roleRepo.GetByID(ctx, roleID)
	if err != nil {
		return errors.New("role not found")
	}

	// 检查是否已经分配
	existing, _ := s.userRepo.CheckUserRole(ctx, userID, roleID)
	if existing {
		return errors.New("role already assigned")
	}

	// 分配角色
	return s.userRepo.AssignRole(ctx, userID, roleID, tenantID)
}

// 移除用户角色
func (s *UserService) RemoveRole(ctx context.Context, userID, roleID uuid.UUID) error {
	return s.userRepo.RemoveRole(ctx, userID, roleID)
}

// 分配默认角色
func (s *UserService) AssignDefaultRole(ctx context.Context, userID, tenantID uuid.UUID) error {
	// 获取默认用户角色
	role, err := s.roleRepo.GetByName(ctx, "user", tenantID)
	if err != nil {
		return err
	}
	
	return s.AssignRole(ctx, userID, uuid.MustParse(role.ID), tenantID)
}

// 搜索用户
func (s *UserService) SearchUsers(ctx context.Context, tenantID uuid.UUID, keyword string, offset, limit int) ([]*entity.User, int64, error) {
	return s.userRepo.Search(ctx, tenantID, keyword, offset, limit)
}

// 批量删除用户
func (s *UserService) BatchDeleteUsers(ctx context.Context, userIDs []string) error {
	for _, userIDStr := range userIDs {
		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			continue
		}
		err = s.userRepo.Delete(ctx, userID)
		if err != nil {
			s.logger.Errorf("Failed to delete user %s: %v", userIDStr, err)
		}
	}
	return nil
}

// 批量激活用户
func (s *UserService) BatchActivateUsers(ctx context.Context, userIDs []string) error {
	for _, userIDStr := range userIDs {
		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			continue
		}
		user, err := s.userRepo.GetByID(ctx, userID)
		if err != nil {
			continue
		}
		user.Status = "active"
		err = s.userRepo.Update(ctx, user)
		if err != nil {
			s.logger.Errorf("Failed to activate user %s: %v", userIDStr, err)
		}
	}
	return nil
}

// 批量禁用用户
func (s *UserService) BatchDeactivateUsers(ctx context.Context, userIDs []string) error {
	for _, userIDStr := range userIDs {
		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			continue
		}
		user, err := s.userRepo.GetByID(ctx, userID)
		if err != nil {
			continue
		}
		user.Status = "inactive"
		err = s.userRepo.Update(ctx, user)
		if err != nil {
			s.logger.Errorf("Failed to deactivate user %s: %v", userIDStr, err)
		}
	}
	return nil
}

// 获取用户统计
func (s *UserService) GetUserStats(ctx context.Context, tenantID uuid.UUID) (*entity.UserStatsResponse, error) {
	// 获取总用户数
	_, totalUsers, err := s.userRepo.List(ctx, tenantID, 0, 1)
	if err != nil {
		return nil, err
	}
	
	// 获取活跃用户数（简化处理，实际应该查询is_active=true的用户）
	activeUsers := totalUsers
	
	// 获取用户组数量
	if s.groupRepo != nil {
		_, _, err := s.groupRepo.List(ctx, tenantID, 0, 1)
		if err != nil {
			s.logger.Error("Failed to get user group count:", err)
		}
	}
	
	// 计算本周新增用户数（简化处理）
	newUsersWeek := int64(0)
	
	// 这里应该实现更详细的统计逻辑
	// 为了简化，返回基础统计
	stats := &entity.UserStatsResponse{
		TotalUsers:    totalUsers,
		ActiveUsers:   activeUsers,
		InactiveUsers: totalUsers - activeUsers,
		NewUsersToday: 0,
		NewUsersWeek:  newUsersWeek,
		NewUsersMonth: 0,
	}
	
	return stats, nil
}

// 重置用户密码
func (s *UserService) ResetUserPassword(ctx context.Context, userID uuid.UUID, newPassword string) error {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return err
	}
	
	// 这里应该加密密码
	user.Password = newPassword
	user.UpdatedAt = time.Now()
	
	return s.userRepo.Update(ctx, user)
}

// 切换用户状态
func (s *UserService) ToggleUserStatus(ctx context.Context, userID uuid.UUID) error {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return err
	}
	
	if user.Status == "active" {
		user.Status = "inactive"
	} else {
		user.Status = "active"
	}
	user.UpdatedAt = time.Now()
	
	return s.userRepo.Update(ctx, user)
}

// 检查用户权限
func (s *UserService) HasPermission(ctx context.Context, userID uuid.UUID, resource, action string) (bool, error) {
	// 使用仓储层的权限检查方法
	return s.userRepo.CheckUserPermission(ctx, userID, resource+"."+action)
}