package service

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/llmops/project-service/internal/domain/entity"
	"github.com/llmops/project-service/internal/domain/repository"
	"github.com/llmops/project-service/internal/pkg/logger"
)

// ProjectService 项目服务接口
type ProjectService interface {
	// 项目基础操作
	CreateProject(ctx context.Context, req *CreateProjectRequest) (*entity.Project, error)
	GetProject(ctx context.Context, projectID uuid.UUID) (*entity.Project, error)
	UpdateProject(ctx context.Context, req *UpdateProjectRequest) (*entity.Project, error)
	DeleteProject(ctx context.Context, projectID uuid.UUID) error
	ListProjects(ctx context.Context, req *ListProjectsRequest) (*ListProjectsResponse, error)
	SearchProjects(ctx context.Context, req *SearchProjectsRequest) (*ListProjectsResponse, error)
	
	// 项目成员管理
	AddMember(ctx context.Context, req *AddMemberRequest) error
	RemoveMember(ctx context.Context, req *RemoveMemberRequest) error
	GetMembers(ctx context.Context, projectID uuid.UUID) ([]*entity.ProjectMember, error)
	UpdateMemberRole(ctx context.Context, req *UpdateMemberRoleRequest) error
	
	// 资源配额管理
	SetResourceQuota(ctx context.Context, req *SetResourceQuotaRequest) error
	GetResourceQuotas(ctx context.Context, projectID uuid.UUID) ([]*entity.ProjectResourceQuota, error)
	CheckResourceQuota(ctx context.Context, projectID uuid.UUID, resourceType string, requested int64) (bool, error)
	
	// 活动日志
	GetActivities(ctx context.Context, projectID uuid.UUID, offset, limit int) ([]*entity.ProjectActivity, int64, error)
	LogActivity(ctx context.Context, req *LogActivityRequest) error
}

// ProjectTemplateService 项目模板服务接口
type ProjectTemplateService interface {
	CreateTemplate(ctx context.Context, req *CreateTemplateRequest) (*entity.ProjectTemplate, error)
	GetTemplate(ctx context.Context, templateID uuid.UUID) (*entity.ProjectTemplate, error)
	UpdateTemplate(ctx context.Context, req *UpdateTemplateRequest) (*entity.ProjectTemplate, error)
	DeleteTemplate(ctx context.Context, templateID uuid.UUID) error
	ListTemplates(ctx context.Context, req *ListTemplatesRequest) (*ListTemplatesResponse, error)
	SearchTemplates(ctx context.Context, req *SearchTemplatesRequest) (*ListTemplatesResponse, error)
	GetPublicTemplates(ctx context.Context, offset, limit int) ([]*entity.ProjectTemplate, int64, error)
	GetTemplatesByCategory(ctx context.Context, category string, offset, limit int) ([]*entity.ProjectTemplate, int64, error)
	CreateProjectFromTemplate(ctx context.Context, req *CreateProjectFromTemplateRequest) (*entity.Project, error)
}

// 请求和响应结构体

// CreateProjectRequest 创建项目请求
type CreateProjectRequest struct {
	Name        string                 `json:"name" validate:"required,min=3,max=255"`
	Description string                 `json:"description"`
	OwnerID     uuid.UUID              `json:"owner_id" validate:"required"`
	TenantID    uuid.UUID              `json:"tenant_id" validate:"required"`
	Settings    map[string]interface{} `json:"settings"`
	Members     []AddMemberRequest     `json:"members"`
}

// UpdateProjectRequest 更新项目请求
type UpdateProjectRequest struct {
	ProjectID   uuid.UUID              `json:"project_id" validate:"required"`
	Name        *string                `json:"name,omitempty"`
	Description *string                `json:"description,omitempty"`
	Status      *string                `json:"status,omitempty"`
	Settings    map[string]interface{} `json:"settings,omitempty"`
}

// ListProjectsRequest 项目列表请求
type ListProjectsRequest struct {
	TenantID uuid.UUID `json:"tenant_id" validate:"required"`
	OwnerID  *uuid.UUID `json:"owner_id,omitempty"`
	UserID   *uuid.UUID `json:"user_id,omitempty"`
	Offset   int        `json:"offset"`
	Limit    int        `json:"limit"`
}

// ListProjectsResponse 项目列表响应
type ListProjectsResponse struct {
	Projects []*entity.Project `json:"projects"`
	Total    int64            `json:"total"`
	Offset   int              `json:"offset"`
	Limit    int              `json:"limit"`
}

// SearchProjectsRequest 搜索项目请求
type SearchProjectsRequest struct {
	TenantID uuid.UUID `json:"tenant_id" validate:"required"`
	Keyword  string    `json:"keyword" validate:"required"`
	Offset   int       `json:"offset"`
	Limit    int       `json:"limit"`
}

// AddMemberRequest 添加成员请求
type AddMemberRequest struct {
	ProjectID   uuid.UUID `json:"project_id" validate:"required"`
	UserID      uuid.UUID `json:"user_id" validate:"required"`
	Role        string    `json:"role" validate:"required"`
	Permissions []string  `json:"permissions"`
	InvitedBy   *uuid.UUID `json:"invited_by,omitempty"`
	ExpiresAt   *string   `json:"expires_at,omitempty"`
}

// RemoveMemberRequest 移除成员请求
type RemoveMemberRequest struct {
	ProjectID uuid.UUID `json:"project_id" validate:"required"`
	UserID    uuid.UUID `json:"user_id" validate:"required"`
}

// UpdateMemberRoleRequest 更新成员角色请求
type UpdateMemberRoleRequest struct {
	ProjectID   uuid.UUID `json:"project_id" validate:"required"`
	UserID      uuid.UUID `json:"user_id" validate:"required"`
	Role        string    `json:"role" validate:"required"`
	Permissions []string  `json:"permissions"`
}

// SetResourceQuotaRequest 设置资源配额请求
type SetResourceQuotaRequest struct {
	ProjectID     uuid.UUID `json:"project_id" validate:"required"`
	ResourceType  string    `json:"resource_type" validate:"required"`
	ResourceName  string    `json:"resource_name" validate:"required"`
	Limit         int64     `json:"limit" validate:"required,min=0"`
	Unit          string    `json:"unit"`
}

// LogActivityRequest 记录活动请求
type LogActivityRequest struct {
	ProjectID uuid.UUID `json:"project_id" validate:"required"`
	UserID    uuid.UUID `json:"user_id" validate:"required"`
	Action    string    `json:"action" validate:"required"`
	Resource  string    `json:"resource"`
	Details   string    `json:"details"`
	IPAddress string    `json:"ip_address"`
	UserAgent string    `json:"user_agent"`
}

// CreateTemplateRequest 创建模板请求
type CreateTemplateRequest struct {
	Name           string                 `json:"name" validate:"required,min=3,max=255"`
	Description    string                 `json:"description"`
	Category       string                 `json:"category"`
	Tags           []string               `json:"tags"`
	IsPublic       bool                   `json:"is_public"`
	OwnerID        uuid.UUID              `json:"owner_id" validate:"required"`
	TenantID       uuid.UUID              `json:"tenant_id" validate:"required"`
	TemplateConfig map[string]interface{} `json:"template_config"`
}

// UpdateTemplateRequest 更新模板请求
type UpdateTemplateRequest struct {
	TemplateID     uuid.UUID              `json:"template_id" validate:"required"`
	Name           *string                `json:"name,omitempty"`
	Description    *string                `json:"description,omitempty"`
	Category       *string                `json:"category,omitempty"`
	Tags           []string               `json:"tags,omitempty"`
	IsPublic       *bool                  `json:"is_public,omitempty"`
	TemplateConfig map[string]interface{} `json:"template_config,omitempty"`
}

// ListTemplatesRequest 模板列表请求
type ListTemplatesRequest struct {
	TenantID uuid.UUID `json:"tenant_id" validate:"required"`
	Offset   int       `json:"offset"`
	Limit    int       `json:"limit"`
}

// ListTemplatesResponse 模板列表响应
type ListTemplatesResponse struct {
	Templates []*entity.ProjectTemplate `json:"templates"`
	Total     int64                     `json:"total"`
	Offset    int                       `json:"offset"`
	Limit     int                       `json:"limit"`
}

// SearchTemplatesRequest 搜索模板请求
type SearchTemplatesRequest struct {
	TenantID uuid.UUID `json:"tenant_id" validate:"required"`
	Keyword  string    `json:"keyword" validate:"required"`
	Offset   int       `json:"offset"`
	Limit    int       `json:"limit"`
}

// CreateProjectFromTemplateRequest 从模板创建项目请求
type CreateProjectFromTemplateRequest struct {
	TemplateID  uuid.UUID              `json:"template_id" validate:"required"`
	Name        string                 `json:"name" validate:"required,min=3,max=255"`
	Description string                 `json:"description"`
	OwnerID     uuid.UUID              `json:"owner_id" validate:"required"`
	TenantID    uuid.UUID              `json:"tenant_id" validate:"required"`
	Settings    map[string]interface{} `json:"settings"`
}

// projectService 项目服务实现
type projectService struct {
	projectRepo       repository.ProjectRepository
	templateRepo      repository.ProjectTemplateRepository
	logger            logger.Logger
}

// NewProjectService 创建项目服务实例
func NewProjectService(
	projectRepo repository.ProjectRepository,
	templateRepo repository.ProjectTemplateRepository,
	logger logger.Logger,
) ProjectService {
	return &projectService{
		projectRepo:  projectRepo,
		templateRepo: templateRepo,
		logger:       logger,
	}
}

// CreateProject 创建项目
func (s *projectService) CreateProject(ctx context.Context, req *CreateProjectRequest) (*entity.Project, error) {
	// 创建项目
	project := &entity.Project{
		Name:        req.Name,
		Description: req.Description,
		OwnerID:     req.OwnerID,
		TenantID:    req.TenantID,
		Status:      "active",
		Settings:    req.Settings,
	}
	
	if err := s.projectRepo.Create(ctx, project); err != nil {
		return nil, fmt.Errorf("failed to create project: %w", err)
	}
	
	// 添加项目成员
	for _, memberReq := range req.Members {
		member := &entity.ProjectMember{
			ProjectID:   project.ID,
			UserID:      memberReq.UserID,
			Role:        memberReq.Role,
			Permissions: memberReq.Permissions,
			Status:      "active",
		}
		
		if err := s.projectRepo.AddMember(ctx, member); err != nil {
			s.logger.Warnf("Failed to add member %s to project %s: %v", memberReq.UserID, project.ID, err)
		}
	}
	
	// 记录活动日志
	activity := &entity.ProjectActivity{
		ProjectID: project.ID,
		UserID:    req.OwnerID,
		Action:    "project_created",
		Resource:  "project",
		Details:   fmt.Sprintf("Project '%s' created", project.Name),
	}
	s.projectRepo.AddActivity(ctx, activity)
	
	s.logger.Infof("Project created successfully: %s (ID: %s)", project.Name, project.ID)
	return project, nil
}

// GetProject 获取项目
func (s *projectService) GetProject(ctx context.Context, projectID uuid.UUID) (*entity.Project, error) {
	project, err := s.projectRepo.GetByID(ctx, projectID)
	if err != nil {
		return nil, fmt.Errorf("failed to get project: %w", err)
	}
	return project, nil
}

// UpdateProject 更新项目
func (s *projectService) UpdateProject(ctx context.Context, req *UpdateProjectRequest) (*entity.Project, error) {
	// 获取项目
	project, err := s.projectRepo.GetByID(ctx, req.ProjectID)
	if err != nil {
		return nil, fmt.Errorf("failed to get project: %w", err)
	}
	
	// 更新字段
	if req.Name != nil {
		project.Name = *req.Name
	}
	if req.Description != nil {
		project.Description = *req.Description
	}
	if req.Status != nil {
		project.Status = *req.Status
	}
	if req.Settings != nil {
		project.Settings = req.Settings
	}
	
	// 保存更新
	if err := s.projectRepo.Update(ctx, project); err != nil {
		return nil, fmt.Errorf("failed to update project: %w", err)
	}
	
	// 记录活动日志
	activity := &entity.ProjectActivity{
		ProjectID: project.ID,
		UserID:    project.OwnerID,
		Action:    "project_updated",
		Resource:  "project",
		Details:   fmt.Sprintf("Project '%s' updated", project.Name),
	}
	s.projectRepo.AddActivity(ctx, activity)
	
	s.logger.Infof("Project updated successfully: %s (ID: %s)", project.Name, project.ID)
	return project, nil
}

// DeleteProject 删除项目
func (s *projectService) DeleteProject(ctx context.Context, projectID uuid.UUID) error {
	// 获取项目信息用于日志
	project, err := s.projectRepo.GetByID(ctx, projectID)
	if err != nil {
		return fmt.Errorf("failed to get project: %w", err)
	}
	
	// 删除项目
	if err := s.projectRepo.Delete(ctx, projectID); err != nil {
		return fmt.Errorf("failed to delete project: %w", err)
	}
	
	s.logger.Infof("Project deleted successfully: %s (ID: %s)", project.Name, projectID)
	return nil
}

// ListProjects 获取项目列表
func (s *projectService) ListProjects(ctx context.Context, req *ListProjectsRequest) (*ListProjectsResponse, error) {
	var projects []*entity.Project
	var total int64
	var err error
	
	if req.OwnerID != nil {
		projects, total, err = s.projectRepo.GetByOwner(ctx, *req.OwnerID, req.Offset, req.Limit)
	} else if req.UserID != nil {
		projects, total, err = s.projectRepo.GetByMember(ctx, *req.UserID, req.Offset, req.Limit)
	} else {
		projects, total, err = s.projectRepo.List(ctx, req.TenantID, req.Offset, req.Limit)
	}
	
	if err != nil {
		return nil, fmt.Errorf("failed to list projects: %w", err)
	}
	
	return &ListProjectsResponse{
		Projects: projects,
		Total:    total,
		Offset:   req.Offset,
		Limit:    req.Limit,
	}, nil
}

// SearchProjects 搜索项目
func (s *projectService) SearchProjects(ctx context.Context, req *SearchProjectsRequest) (*ListProjectsResponse, error) {
	projects, total, err := s.projectRepo.Search(ctx, req.TenantID, req.Keyword, req.Offset, req.Limit)
	if err != nil {
		return nil, fmt.Errorf("failed to search projects: %w", err)
	}
	
	return &ListProjectsResponse{
		Projects: projects,
		Total:    total,
		Offset:   req.Offset,
		Limit:    req.Limit,
	}, nil
}

// AddMember 添加项目成员
func (s *projectService) AddMember(ctx context.Context, req *AddMemberRequest) error {
	member := &entity.ProjectMember{
		ProjectID:   req.ProjectID,
		UserID:      req.UserID,
		Role:        req.Role,
		Permissions: req.Permissions,
		Status:      "active",
		InvitedBy:   req.InvitedBy,
	}
	
	if err := s.projectRepo.AddMember(ctx, member); err != nil {
		return fmt.Errorf("failed to add member: %w", err)
	}
	
	// 记录活动日志
	activity := &entity.ProjectActivity{
		ProjectID: req.ProjectID,
		UserID:    req.UserID,
		Action:    "member_added",
		Resource:  "member",
		Details:   fmt.Sprintf("User %s added as %s", req.UserID, req.Role),
	}
	s.projectRepo.AddActivity(ctx, activity)
	
	s.logger.Infof("Member added to project: %s -> %s", req.UserID, req.ProjectID)
	return nil
}

// RemoveMember 移除项目成员
func (s *projectService) RemoveMember(ctx context.Context, req *RemoveMemberRequest) error {
	if err := s.projectRepo.RemoveMember(ctx, req.ProjectID, req.UserID); err != nil {
		return fmt.Errorf("failed to remove member: %w", err)
	}
	
	// 记录活动日志
	activity := &entity.ProjectActivity{
		ProjectID: req.ProjectID,
		UserID:    req.UserID,
		Action:    "member_removed",
		Resource:  "member",
		Details:   fmt.Sprintf("User %s removed from project", req.UserID),
	}
	s.projectRepo.AddActivity(ctx, activity)
	
	s.logger.Infof("Member removed from project: %s -> %s", req.UserID, req.ProjectID)
	return nil
}

// GetMembers 获取项目成员
func (s *projectService) GetMembers(ctx context.Context, projectID uuid.UUID) ([]*entity.ProjectMember, error) {
	members, err := s.projectRepo.GetMembers(ctx, projectID)
	if err != nil {
		return nil, fmt.Errorf("failed to get members: %w", err)
	}
	return members, nil
}

// UpdateMemberRole 更新成员角色
func (s *projectService) UpdateMemberRole(ctx context.Context, req *UpdateMemberRoleRequest) error {
	member, err := s.projectRepo.GetMember(ctx, req.ProjectID, req.UserID)
	if err != nil {
		return fmt.Errorf("failed to get member: %w", err)
	}
	
	member.Role = req.Role
	member.Permissions = req.Permissions
	
	if err := s.projectRepo.UpdateMember(ctx, member); err != nil {
		return fmt.Errorf("failed to update member: %w", err)
	}
	
	// 记录活动日志
	activity := &entity.ProjectActivity{
		ProjectID: req.ProjectID,
		UserID:    req.UserID,
		Action:    "member_role_updated",
		Resource:  "member",
		Details:   fmt.Sprintf("User %s role updated to %s", req.UserID, req.Role),
	}
	s.projectRepo.AddActivity(ctx, activity)
	
	s.logger.Infof("Member role updated: %s -> %s (%s)", req.UserID, req.ProjectID, req.Role)
	return nil
}

// SetResourceQuota 设置资源配额
func (s *projectService) SetResourceQuota(ctx context.Context, req *SetResourceQuotaRequest) error {
	quota := &entity.ProjectResourceQuota{
		ProjectID:     req.ProjectID,
		ResourceType:  req.ResourceType,
		ResourceName:  req.ResourceName,
		Limit:         req.Limit,
		Unit:          req.Unit,
	}
	
	if err := s.projectRepo.SetResourceQuota(ctx, quota); err != nil {
		return fmt.Errorf("failed to set resource quota: %w", err)
	}
	
	s.logger.Infof("Resource quota set: %s -> %s (%s: %d %s)", req.ProjectID, req.ResourceType, req.ResourceName, req.Limit, req.Unit)
	return nil
}

// GetResourceQuotas 获取资源配额
func (s *projectService) GetResourceQuotas(ctx context.Context, projectID uuid.UUID) ([]*entity.ProjectResourceQuota, error) {
	quotas, err := s.projectRepo.GetResourceQuotas(ctx, projectID)
	if err != nil {
		return nil, fmt.Errorf("failed to get resource quotas: %w", err)
	}
	return quotas, nil
}

// CheckResourceQuota 检查资源配额
func (s *projectService) CheckResourceQuota(ctx context.Context, projectID uuid.UUID, resourceType string, requested int64) (bool, error) {
	quotas, err := s.projectRepo.GetResourceQuotas(ctx, projectID)
	if err != nil {
		return false, fmt.Errorf("failed to get resource quotas: %w", err)
	}
	
	for _, quota := range quotas {
		if quota.ResourceType == resourceType {
			return quota.Used+requested <= quota.Limit, nil
		}
	}
	
	// 如果没有设置配额，默认允许
	return true, nil
}

// GetActivities 获取活动日志
func (s *projectService) GetActivities(ctx context.Context, projectID uuid.UUID, offset, limit int) ([]*entity.ProjectActivity, int64, error) {
	activities, total, err := s.projectRepo.GetActivities(ctx, projectID, offset, limit)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get activities: %w", err)
	}
	return activities, total, nil
}

// LogActivity 记录活动日志
func (s *projectService) LogActivity(ctx context.Context, req *LogActivityRequest) error {
	activity := &entity.ProjectActivity{
		ProjectID: req.ProjectID,
		UserID:    req.UserID,
		Action:    req.Action,
		Resource:  req.Resource,
		Details:   req.Details,
		IPAddress: req.IPAddress,
		UserAgent: req.UserAgent,
	}
	
	if err := s.projectRepo.AddActivity(ctx, activity); err != nil {
		return fmt.Errorf("failed to log activity: %w", err)
	}
	
	return nil
}



