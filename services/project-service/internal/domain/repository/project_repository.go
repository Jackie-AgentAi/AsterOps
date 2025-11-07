package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/llmops/project-service/internal/domain/entity"
	"gorm.io/gorm"
)

// ProjectRepository 项目仓储接口
type ProjectRepository interface {
	// 项目基础操作
	Create(ctx context.Context, project *entity.Project) error
	GetByID(ctx context.Context, id uuid.UUID) (*entity.Project, error)
	Update(ctx context.Context, project *entity.Project) error
	Delete(ctx context.Context, id uuid.UUID) error
	
	// 项目查询
	List(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.Project, int64, error)
	Search(ctx context.Context, tenantID uuid.UUID, keyword string, offset, limit int) ([]*entity.Project, int64, error)
	GetByOwner(ctx context.Context, ownerID uuid.UUID, offset, limit int) ([]*entity.Project, int64, error)
	GetByMember(ctx context.Context, userID uuid.UUID, offset, limit int) ([]*entity.Project, int64, error)
	
	// 项目成员操作
	AddMember(ctx context.Context, member *entity.ProjectMember) error
	RemoveMember(ctx context.Context, projectID, userID uuid.UUID) error
	GetMembers(ctx context.Context, projectID uuid.UUID) ([]*entity.ProjectMember, error)
	GetMember(ctx context.Context, projectID, userID uuid.UUID) (*entity.ProjectMember, error)
	UpdateMember(ctx context.Context, member *entity.ProjectMember) error
	
	// 资源配额操作
	SetResourceQuota(ctx context.Context, quota *entity.ProjectResourceQuota) error
	GetResourceQuotas(ctx context.Context, projectID uuid.UUID) ([]*entity.ProjectResourceQuota, error)
	UpdateResourceUsage(ctx context.Context, projectID uuid.UUID, resourceType string, usage int64) error
	
	// 活动日志
	AddActivity(ctx context.Context, activity *entity.ProjectActivity) error
	GetActivities(ctx context.Context, projectID uuid.UUID, offset, limit int) ([]*entity.ProjectActivity, int64, error)
}

// ProjectTemplateRepository 项目模板仓储接口
type ProjectTemplateRepository interface {
	Create(ctx context.Context, template *entity.ProjectTemplate) error
	GetByID(ctx context.Context, id uuid.UUID) (*entity.ProjectTemplate, error)
	Update(ctx context.Context, template *entity.ProjectTemplate) error
	Delete(ctx context.Context, id uuid.UUID) error
	
	List(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.ProjectTemplate, int64, error)
	Search(ctx context.Context, tenantID uuid.UUID, keyword string, offset, limit int) ([]*entity.ProjectTemplate, int64, error)
	GetPublicTemplates(ctx context.Context, offset, limit int) ([]*entity.ProjectTemplate, int64, error)
	GetByCategory(ctx context.Context, category string, offset, limit int) ([]*entity.ProjectTemplate, int64, error)
	IncrementUsage(ctx context.Context, id uuid.UUID) error
}

// projectRepository 项目仓储实现
type projectRepository struct {
	db *gorm.DB
}

// NewProjectRepository 创建项目仓储实例
func NewProjectRepository(db *gorm.DB) ProjectRepository {
	return &projectRepository{db: db}
}

// Create 创建项目
func (r *projectRepository) Create(ctx context.Context, project *entity.Project) error {
	return r.db.WithContext(ctx).Create(project).Error
}

// GetByID 根据ID获取项目
func (r *projectRepository) GetByID(ctx context.Context, id uuid.UUID) (*entity.Project, error) {
	var project entity.Project
	err := r.db.WithContext(ctx).
		Preload("Members").
		Preload("Members.User").
		Preload("Resources").
		Preload("Activities").
		First(&project, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &project, nil
}

// Update 更新项目
func (r *projectRepository) Update(ctx context.Context, project *entity.Project) error {
	return r.db.WithContext(ctx).Save(project).Error
}

// Delete 删除项目
func (r *projectRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&entity.Project{}, "id = ?", id).Error
}

// List 获取项目列表
func (r *projectRepository) List(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.Project, int64, error) {
	var projects []*entity.Project
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.Project{}).Where("tenant_id = ?", tenantID)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Preload("Members").
		Preload("Members.User").
		Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&projects).Error
	
	return projects, total, err
}

// Search 搜索项目
func (r *projectRepository) Search(ctx context.Context, tenantID uuid.UUID, keyword string, offset, limit int) ([]*entity.Project, int64, error) {
	var projects []*entity.Project
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.Project{}).
		Where("tenant_id = ? AND (name ILIKE ? OR description ILIKE ?)", 
			tenantID, "%"+keyword+"%", "%"+keyword+"%")
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Preload("Members").
		Preload("Members.User").
		Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&projects).Error
	
	return projects, total, err
}

// GetByOwner 获取用户拥有的项目
func (r *projectRepository) GetByOwner(ctx context.Context, ownerID uuid.UUID, offset, limit int) ([]*entity.Project, int64, error) {
	var projects []*entity.Project
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.Project{}).Where("owner_id = ?", ownerID)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Preload("Members").
		Preload("Members.User").
		Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&projects).Error
	
	return projects, total, err
}

// GetByMember 获取用户参与的项目
func (r *projectRepository) GetByMember(ctx context.Context, userID uuid.UUID, offset, limit int) ([]*entity.Project, int64, error) {
	var projects []*entity.Project
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.Project{}).
		Joins("JOIN project_members ON projects.id = project_members.project_id").
		Where("project_members.user_id = ?", userID)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Preload("Members").
		Preload("Members.User").
		Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&projects).Error
	
	return projects, total, err
}

// AddMember 添加项目成员
func (r *projectRepository) AddMember(ctx context.Context, member *entity.ProjectMember) error {
	return r.db.WithContext(ctx).Create(member).Error
}

// RemoveMember 移除项目成员
func (r *projectRepository) RemoveMember(ctx context.Context, projectID, userID uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&entity.ProjectMember{}, 
		"project_id = ? AND user_id = ?", projectID, userID).Error
}

// GetMembers 获取项目成员
func (r *projectRepository) GetMembers(ctx context.Context, projectID uuid.UUID) ([]*entity.ProjectMember, error) {
	var members []*entity.ProjectMember
	err := r.db.WithContext(ctx).
		Preload("User").
		Where("project_id = ?", projectID).
		Find(&members).Error
	return members, err
}

// GetMember 获取项目成员
func (r *projectRepository) GetMember(ctx context.Context, projectID, userID uuid.UUID) (*entity.ProjectMember, error) {
	var member entity.ProjectMember
	err := r.db.WithContext(ctx).
		Preload("User").
		Where("project_id = ? AND user_id = ?", projectID, userID).
		First(&member).Error
	if err != nil {
		return nil, err
	}
	return &member, nil
}

// UpdateMember 更新项目成员
func (r *projectRepository) UpdateMember(ctx context.Context, member *entity.ProjectMember) error {
	return r.db.WithContext(ctx).Save(member).Error
}

// SetResourceQuota 设置资源配额
func (r *projectRepository) SetResourceQuota(ctx context.Context, quota *entity.ProjectResourceQuota) error {
	return r.db.WithContext(ctx).Save(quota).Error
}

// GetResourceQuotas 获取资源配额
func (r *projectRepository) GetResourceQuotas(ctx context.Context, projectID uuid.UUID) ([]*entity.ProjectResourceQuota, error) {
	var quotas []*entity.ProjectResourceQuota
	err := r.db.WithContext(ctx).
		Where("project_id = ?", projectID).
		Find(&quotas).Error
	return quotas, err
}

// UpdateResourceUsage 更新资源使用量
func (r *projectRepository) UpdateResourceUsage(ctx context.Context, projectID uuid.UUID, resourceType string, usage int64) error {
	return r.db.WithContext(ctx).Model(&entity.Project{}).
		Where("id = ?", projectID).
		Update(resourceType, usage).Error
}

// AddActivity 添加活动日志
func (r *projectRepository) AddActivity(ctx context.Context, activity *entity.ProjectActivity) error {
	return r.db.WithContext(ctx).Create(activity).Error
}

// GetActivities 获取活动日志
func (r *projectRepository) GetActivities(ctx context.Context, projectID uuid.UUID, offset, limit int) ([]*entity.ProjectActivity, int64, error) {
	var activities []*entity.ProjectActivity
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.ProjectActivity{}).Where("project_id = ?", projectID)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Preload("User").
		Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&activities).Error
	
	return activities, total, err
}



