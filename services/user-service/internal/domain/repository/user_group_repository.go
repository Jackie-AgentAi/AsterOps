package repository

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/llmops/user-service/internal/domain/entity"
	"gorm.io/gorm"
)

// UserGroupRepository 用户组仓储接口
type UserGroupRepository interface {
	// 用户组基础操作
	Create(ctx context.Context, group *entity.UserGroup) error
	GetByID(ctx context.Context, id uuid.UUID) (*entity.UserGroup, error)
	GetByName(ctx context.Context, name string, tenantID uuid.UUID) (*entity.UserGroup, error)
	Update(ctx context.Context, group *entity.UserGroup) error
	Delete(ctx context.Context, id uuid.UUID) error
	
	// 用户组查询
	List(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.UserGroup, int64, error)
	GetChildren(ctx context.Context, parentID uuid.UUID) ([]*entity.UserGroup, error)
	
	// 用户组成员管理
	AddMember(ctx context.Context, userID, groupID uuid.UUID, role string) error
	RemoveMember(ctx context.Context, userID, groupID uuid.UUID) error
	GetMembers(ctx context.Context, groupID uuid.UUID) ([]*entity.UserGroupMember, error)
	GetUserGroups(ctx context.Context, userID uuid.UUID) ([]*entity.UserGroup, error)
	CheckUserInGroup(ctx context.Context, userID, groupID uuid.UUID) (bool, error)
}

// userGroupRepository 用户组仓储实现
type userGroupRepository struct {
	db *gorm.DB
}

// NewUserGroupRepository 创建用户组仓储实例
func NewUserGroupRepository(db *gorm.DB) UserGroupRepository {
	return &userGroupRepository{db: db}
}

// Create 创建用户组
func (r *userGroupRepository) Create(ctx context.Context, group *entity.UserGroup) error {
	return r.db.WithContext(ctx).Create(group).Error
}

// GetByID 根据ID获取用户组
func (r *userGroupRepository) GetByID(ctx context.Context, id uuid.UUID) (*entity.UserGroup, error) {
	var group entity.UserGroup
	err := r.db.WithContext(ctx).First(&group, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &group, nil
}

// GetByName 根据名称获取用户组
func (r *userGroupRepository) GetByName(ctx context.Context, name string, tenantID uuid.UUID) (*entity.UserGroup, error) {
	var group entity.UserGroup
	err := r.db.WithContext(ctx).First(&group, "name = ? AND tenant_id = ?", name, tenantID).Error
	if err != nil {
		return nil, err
	}
	return &group, nil
}

// Update 更新用户组
func (r *userGroupRepository) Update(ctx context.Context, group *entity.UserGroup) error {
	return r.db.WithContext(ctx).Save(group).Error
}

// Delete 删除用户组
func (r *userGroupRepository) Delete(ctx context.Context, id uuid.UUID) error {
	// 先删除所有成员关系
	if err := r.db.WithContext(ctx).Delete(&entity.UserGroupMember{}, "group_id = ?", id).Error; err != nil {
		return err
	}
	// 再删除用户组
	return r.db.WithContext(ctx).Delete(&entity.UserGroup{}, "id = ?", id).Error
}

// List 获取用户组列表
func (r *userGroupRepository) List(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.UserGroup, int64, error) {
	var groups []*entity.UserGroup
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.UserGroup{}).Where("tenant_id = ?", tenantID)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&groups).Error
	
	return groups, total, err
}

// GetChildren 获取子用户组
func (r *userGroupRepository) GetChildren(ctx context.Context, parentID uuid.UUID) ([]*entity.UserGroup, error) {
	var groups []*entity.UserGroup
	err := r.db.WithContext(ctx).
		Where("parent_id = ?", parentID).
		Order("created_at ASC").
		Find(&groups).Error
	return groups, err
}

// AddMember 添加用户组成员
func (r *userGroupRepository) AddMember(ctx context.Context, userID, groupID uuid.UUID, role string) error {
	// 检查用户是否已经在组中
	exists, err := r.CheckUserInGroup(ctx, userID, groupID)
	if err != nil {
		return err
	}
	if exists {
		return gorm.ErrDuplicatedKey
	}
	
	member := &entity.UserGroupMember{
		UserID:   userID.String(),
		GroupID:  groupID.String(),
		Role:     role,
		JoinedAt: time.Now(),
	}
	
	return r.db.WithContext(ctx).Create(member).Error
}

// RemoveMember 移除用户组成员
func (r *userGroupRepository) RemoveMember(ctx context.Context, userID, groupID uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&entity.UserGroupMember{}, 
		"user_id = ? AND group_id = ?", userID, groupID).Error
}

// GetMembers 获取用户组成员
func (r *userGroupRepository) GetMembers(ctx context.Context, groupID uuid.UUID) ([]*entity.UserGroupMember, error) {
	var members []*entity.UserGroupMember
	err := r.db.WithContext(ctx).
		Preload("User").
		Where("group_id = ?", groupID).
		Order("joined_at ASC").
		Find(&members).Error
	return members, err
}

// GetUserGroups 获取用户所属的用户组
func (r *userGroupRepository) GetUserGroups(ctx context.Context, userID uuid.UUID) ([]*entity.UserGroup, error) {
	var groups []*entity.UserGroup
	err := r.db.WithContext(ctx).
		Joins("JOIN user_group_members ON user_groups.id = user_group_members.group_id").
		Where("user_group_members.user_id = ?", userID).
		Order("user_groups.created_at ASC").
		Find(&groups).Error
	return groups, err
}

// CheckUserInGroup 检查用户是否在组中
func (r *userGroupRepository) CheckUserInGroup(ctx context.Context, userID, groupID uuid.UUID) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&entity.UserGroupMember{}).
		Where("user_id = ? AND group_id = ?", userID, groupID).
		Count(&count).Error
	return count > 0, err
}