package service

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/llmops/project-service/internal/domain/entity"
	"github.com/llmops/project-service/internal/domain/repository"
	"github.com/llmops/project-service/internal/pkg/logger"
)

// projectTemplateService 项目模板服务实现
type projectTemplateService struct {
	templateRepo repository.ProjectTemplateRepository
	projectRepo  repository.ProjectRepository
	logger       logger.Logger
}

// NewProjectTemplateService 创建项目模板服务实例
func NewProjectTemplateService(
	templateRepo repository.ProjectTemplateRepository,
	projectRepo repository.ProjectRepository,
	logger logger.Logger,
) ProjectTemplateService {
	return &projectTemplateService{
		templateRepo: templateRepo,
		projectRepo:  projectRepo,
		logger:       logger,
	}
}

// CreateTemplate 创建项目模板
func (s *projectTemplateService) CreateTemplate(ctx context.Context, req *CreateTemplateRequest) (*entity.ProjectTemplate, error) {
	template := &entity.ProjectTemplate{
		Name:            req.Name,
		Description:     req.Description,
		Category:        req.Category,
		Tags:            req.Tags,
		IsPublic:        req.IsPublic,
		OwnerID:         req.OwnerID,
		TenantID:        req.TenantID,
		TemplateConfig:  req.TemplateConfig,
		UsageCount:      0,
	}
	
	if err := s.templateRepo.Create(ctx, template); err != nil {
		return nil, fmt.Errorf("failed to create template: %w", err)
	}
	
	s.logger.Infof("Template created successfully: %s (ID: %s)", template.Name, template.ID)
	return template, nil
}

// GetTemplate 获取项目模板
func (s *projectTemplateService) GetTemplate(ctx context.Context, templateID uuid.UUID) (*entity.ProjectTemplate, error) {
	template, err := s.templateRepo.GetByID(ctx, templateID)
	if err != nil {
		return nil, fmt.Errorf("failed to get template: %w", err)
	}
	return template, nil
}

// UpdateTemplate 更新项目模板
func (s *projectTemplateService) UpdateTemplate(ctx context.Context, req *UpdateTemplateRequest) (*entity.ProjectTemplate, error) {
	// 获取模板
	template, err := s.templateRepo.GetByID(ctx, req.TemplateID)
	if err != nil {
		return nil, fmt.Errorf("failed to get template: %w", err)
	}
	
	// 更新字段
	if req.Name != nil {
		template.Name = *req.Name
	}
	if req.Description != nil {
		template.Description = *req.Description
	}
	if req.Category != nil {
		template.Category = *req.Category
	}
	if req.Tags != nil {
		template.Tags = req.Tags
	}
	if req.IsPublic != nil {
		template.IsPublic = *req.IsPublic
	}
	if req.TemplateConfig != nil {
		template.TemplateConfig = req.TemplateConfig
	}
	
	// 保存更新
	if err := s.templateRepo.Update(ctx, template); err != nil {
		return nil, fmt.Errorf("failed to update template: %w", err)
	}
	
	s.logger.Infof("Template updated successfully: %s (ID: %s)", template.Name, template.ID)
	return template, nil
}

// DeleteTemplate 删除项目模板
func (s *projectTemplateService) DeleteTemplate(ctx context.Context, templateID uuid.UUID) error {
	// 获取模板信息用于日志
	template, err := s.templateRepo.GetByID(ctx, templateID)
	if err != nil {
		return fmt.Errorf("failed to get template: %w", err)
	}
	
	// 删除模板
	if err := s.templateRepo.Delete(ctx, templateID); err != nil {
		return fmt.Errorf("failed to delete template: %w", err)
	}
	
	s.logger.Infof("Template deleted successfully: %s (ID: %s)", template.Name, templateID)
	return nil
}

// ListTemplates 获取模板列表
func (s *projectTemplateService) ListTemplates(ctx context.Context, req *ListTemplatesRequest) (*ListTemplatesResponse, error) {
	templates, total, err := s.templateRepo.List(ctx, req.TenantID, req.Offset, req.Limit)
	if err != nil {
		return nil, fmt.Errorf("failed to list templates: %w", err)
	}
	
	return &ListTemplatesResponse{
		Templates: templates,
		Total:     total,
		Offset:    req.Offset,
		Limit:     req.Limit,
	}, nil
}

// SearchTemplates 搜索模板
func (s *projectTemplateService) SearchTemplates(ctx context.Context, req *SearchTemplatesRequest) (*ListTemplatesResponse, error) {
	templates, total, err := s.templateRepo.Search(ctx, req.TenantID, req.Keyword, req.Offset, req.Limit)
	if err != nil {
		return nil, fmt.Errorf("failed to search templates: %w", err)
	}
	
	return &ListTemplatesResponse{
		Templates: templates,
		Total:     total,
		Offset:    req.Offset,
		Limit:     req.Limit,
	}, nil
}

// GetPublicTemplates 获取公共模板
func (s *projectTemplateService) GetPublicTemplates(ctx context.Context, offset, limit int) ([]*entity.ProjectTemplate, int64, error) {
	templates, total, err := s.templateRepo.GetPublicTemplates(ctx, offset, limit)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get public templates: %w", err)
	}
	return templates, total, nil
}

// GetTemplatesByCategory 根据分类获取模板
func (s *projectTemplateService) GetTemplatesByCategory(ctx context.Context, category string, offset, limit int) ([]*entity.ProjectTemplate, int64, error) {
	templates, total, err := s.templateRepo.GetByCategory(ctx, category, offset, limit)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get templates by category: %w", err)
	}
	return templates, total, nil
}

// CreateProjectFromTemplate 从模板创建项目
func (s *projectTemplateService) CreateProjectFromTemplate(ctx context.Context, req *CreateProjectFromTemplateRequest) (*entity.Project, error) {
	// 获取模板
	template, err := s.templateRepo.GetByID(ctx, req.TemplateID)
	if err != nil {
		return nil, fmt.Errorf("failed to get template: %w", err)
	}
	
	// 检查模板是否公开或用户是否有权限
	if !template.IsPublic && template.TenantID != req.TenantID {
		return nil, fmt.Errorf("template not accessible")
	}
	
	// 创建项目
	project := &entity.Project{
		Name:        req.Name,
		Description: req.Description,
		OwnerID:     req.OwnerID,
		TenantID:    req.TenantID,
		Status:      "active",
		Settings:    req.Settings,
	}
	
	// 应用模板配置
	if template.TemplateConfig != nil {
		if config, ok := template.TemplateConfig["settings"]; ok {
			if settings, ok := config.(map[string]interface{}); ok {
				project.Settings = settings
			}
		}
		
		if config, ok := template.TemplateConfig["quotas"]; ok {
			if quotas, ok := config.(map[string]interface{}); ok {
				// 设置资源配额
				for resourceType, limit := range quotas {
					if limitValue, ok := limit.(float64); ok {
						quota := &entity.ProjectResourceQuota{
							ProjectID:    project.ID,
							ResourceType: resourceType,
							ResourceName: resourceType,
							Limit:        int64(limitValue),
							Unit:         "units",
						}
						s.projectRepo.SetResourceQuota(ctx, quota)
					}
				}
			}
		}
	}
	
	if err := s.projectRepo.Create(ctx, project); err != nil {
		return nil, fmt.Errorf("failed to create project from template: %w", err)
	}
	
	// 增加模板使用次数
	if err := s.templateRepo.IncrementUsage(ctx, template.ID); err != nil {
		s.logger.Warnf("Failed to increment template usage: %v", err)
	}
	
	// 记录活动日志
	activity := &entity.ProjectActivity{
		ProjectID: project.ID,
		UserID:    req.OwnerID,
		Action:    "project_created_from_template",
		Resource:  "project",
		Details:   fmt.Sprintf("Project '%s' created from template '%s'", project.Name, template.Name),
	}
	s.projectRepo.AddActivity(ctx, activity)
	
	s.logger.Infof("Project created from template: %s (Template: %s)", project.Name, template.Name)
	return project, nil
}



