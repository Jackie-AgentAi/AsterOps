package service

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/llmops/user-service/internal/domain/entity"
)


// 用户组服务
type UserGroupService struct {
	groupRepo UserGroupRepository
	logger    interface {
		Info(args ...interface{})
		Infof(format string, args ...interface{})
		Error(args ...interface{})
		Errorf(format string, args ...interface{})
		Fatal(args ...interface{})
		Fatalf(format string, args ...interface{})
	}
}

// 用户组仓储接口
type UserGroupRepository interface {
	Create(ctx context.Context, group *entity.UserGroup) error
	GetByID(ctx context.Context, id uuid.UUID) (*entity.UserGroup, error)
	GetByName(ctx context.Context, name string, tenantID uuid.UUID) (*entity.UserGroup, error)
	Update(ctx context.Context, group *entity.UserGroup) error
	Delete(ctx context.Context, id uuid.UUID) error
	List(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.UserGroup, int64, error)
	GetChildren(ctx context.Context, parentID uuid.UUID) ([]*entity.UserGroup, error)
	
	// 用户组成员管理
	AddMember(ctx context.Context, userID, groupID uuid.UUID, role string) error
	RemoveMember(ctx context.Context, userID, groupID uuid.UUID) error
	GetMembers(ctx context.Context, groupID uuid.UUID) ([]*entity.UserGroupMember, error)
	GetUserGroups(ctx context.Context, userID uuid.UUID) ([]*entity.UserGroup, error)
}

// 创建用户组服务
func NewUserGroupService(groupRepo UserGroupRepository, logger interface {
	Info(args ...interface{})
	Infof(format string, args ...interface{})
	Error(args ...interface{})
	Errorf(format string, args ...interface{})
	Fatal(args ...interface{})
	Fatalf(format string, args ...interface{})
}) *UserGroupService {
	return &UserGroupService{
		groupRepo: groupRepo,
		logger:    logger,
	}
}

// 创建用户组
func (s *UserGroupService) CreateUserGroup(ctx context.Context, group *entity.UserGroup) error {
	// 检查用户组名是否已存在
	tenantID, _ := uuid.Parse(group.TenantID)
	existing, _ := s.groupRepo.GetByName(ctx, group.Name, tenantID)
	if existing != nil {
		return errors.New("user group name already exists")
	}

	group.CreatedAt = time.Now()
	group.UpdatedAt = time.Now()

	return s.groupRepo.Create(ctx, group)
}

// 获取用户组
func (s *UserGroupService) GetUserGroup(ctx context.Context, id uuid.UUID) (*entity.UserGroup, error) {
	return s.groupRepo.GetByID(ctx, id)
}

// 更新用户组
func (s *UserGroupService) UpdateUserGroup(ctx context.Context, group *entity.UserGroup) error {
	group.UpdatedAt = time.Now()
	return s.groupRepo.Update(ctx, group)
}

// 删除用户组
func (s *UserGroupService) DeleteUserGroup(ctx context.Context, id uuid.UUID) error {
	return s.groupRepo.Delete(ctx, id)
}

// 获取用户组列表
func (s *UserGroupService) GetUserGroups(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.UserGroup, int64, error) {
	groups, total, err := s.groupRepo.List(ctx, tenantID, offset, limit)
	if err != nil {
		return nil, 0, err
	}
	
	// 为每个用户组添加成员数量
	for _, group := range groups {
		members, err := s.groupRepo.GetMembers(ctx, uuid.MustParse(group.ID))
		if err == nil {
			group.MemberCount = len(members)
		}
	}
	
	return groups, total, nil
}

// 获取用户组统计
func (s *UserGroupService) GetUserGroupStats(ctx context.Context, tenantID uuid.UUID) (int64, error) {
	_, total, err := s.groupRepo.List(ctx, tenantID, 0, 1)
	if err != nil {
		return 0, err
	}
	return total, nil
}

// 获取子用户组
func (s *UserGroupService) GetChildUserGroups(ctx context.Context, parentID uuid.UUID) ([]*entity.UserGroup, error) {
	return s.groupRepo.GetChildren(ctx, parentID)
}

// 添加用户组成员
func (s *UserGroupService) AddMember(ctx context.Context, userID, groupID uuid.UUID, role string) error {
	return s.groupRepo.AddMember(ctx, userID, groupID, role)
}

// 移除用户组成员
func (s *UserGroupService) RemoveMember(ctx context.Context, userID, groupID uuid.UUID) error {
	return s.groupRepo.RemoveMember(ctx, userID, groupID)
}

// 获取用户组成员
func (s *UserGroupService) GetMembers(ctx context.Context, groupID uuid.UUID) ([]*entity.UserGroupMember, error) {
	return s.groupRepo.GetMembers(ctx, groupID)
}

// 获取用户所属的用户组
func (s *UserGroupService) GetUserGroupsByUser(ctx context.Context, userID uuid.UUID) ([]*entity.UserGroup, error) {
	return s.groupRepo.GetUserGroups(ctx, userID)
}
