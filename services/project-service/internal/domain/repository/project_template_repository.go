package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/llmops/project-service/internal/domain/entity"
	"gorm.io/gorm"
)

// projectTemplateRepository 项目模板仓储实现
type projectTemplateRepository struct {
	db *gorm.DB
}

// NewProjectTemplateRepository 创建项目模板仓储实例
func NewProjectTemplateRepository(db *gorm.DB) ProjectTemplateRepository {
	return &projectTemplateRepository{db: db}
}

// Create 创建项目模板
func (r *projectTemplateRepository) Create(ctx context.Context, template *entity.ProjectTemplate) error {
	return r.db.WithContext(ctx).Create(template).Error
}

// GetByID 根据ID获取项目模板
func (r *projectTemplateRepository) GetByID(ctx context.Context, id uuid.UUID) (*entity.ProjectTemplate, error) {
	var template entity.ProjectTemplate
	err := r.db.WithContext(ctx).First(&template, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &template, nil
}

// Update 更新项目模板
func (r *projectTemplateRepository) Update(ctx context.Context, template *entity.ProjectTemplate) error {
	return r.db.WithContext(ctx).Save(template).Error
}

// Delete 删除项目模板
func (r *projectTemplateRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&entity.ProjectTemplate{}, "id = ?", id).Error
}

// List 获取项目模板列表
func (r *projectTemplateRepository) List(ctx context.Context, tenantID uuid.UUID, offset, limit int) ([]*entity.ProjectTemplate, int64, error) {
	var templates []*entity.ProjectTemplate
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.ProjectTemplate{}).Where("tenant_id = ?", tenantID)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&templates).Error
	
	return templates, total, err
}

// Search 搜索项目模板
func (r *projectTemplateRepository) Search(ctx context.Context, tenantID uuid.UUID, keyword string, offset, limit int) ([]*entity.ProjectTemplate, int64, error) {
	var templates []*entity.ProjectTemplate
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.ProjectTemplate{}).
		Where("tenant_id = ? AND (name ILIKE ? OR description ILIKE ? OR category ILIKE ?)", 
			tenantID, "%"+keyword+"%", "%"+keyword+"%", "%"+keyword+"%")
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&templates).Error
	
	return templates, total, err
}

// GetPublicTemplates 获取公共模板
func (r *projectTemplateRepository) GetPublicTemplates(ctx context.Context, offset, limit int) ([]*entity.ProjectTemplate, int64, error) {
	var templates []*entity.ProjectTemplate
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.ProjectTemplate{}).Where("is_public = ?", true)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Offset(offset).
		Limit(limit).
		Order("usage_count DESC, created_at DESC").
		Find(&templates).Error
	
	return templates, total, err
}

// GetByCategory 根据分类获取模板
func (r *projectTemplateRepository) GetByCategory(ctx context.Context, category string, offset, limit int) ([]*entity.ProjectTemplate, int64, error) {
	var templates []*entity.ProjectTemplate
	var total int64
	
	query := r.db.WithContext(ctx).Model(&entity.ProjectTemplate{}).Where("category = ?", category)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	err := query.Offset(offset).
		Limit(limit).
		Order("usage_count DESC, created_at DESC").
		Find(&templates).Error
	
	return templates, total, err
}

// IncrementUsage 增加使用次数
func (r *projectTemplateRepository) IncrementUsage(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Model(&entity.ProjectTemplate{}).
		Where("id = ?", id).
		Update("usage_count", gorm.Expr("usage_count + 1")).Error
}



