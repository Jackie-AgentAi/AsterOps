package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/llmops/project-service/internal/domain/service"
	"github.com/llmops/project-service/internal/pkg/logger"
	"github.com/llmops/project-service/internal/pkg/response"
)

// ProjectHandler 项目处理器
type ProjectHandler struct {
	projectService service.ProjectService
	logger         logger.Logger
}

// NewProjectHandler 创建项目处理器
func NewProjectHandler(projectService service.ProjectService, logger logger.Logger) *ProjectHandler {
	return &ProjectHandler{
		projectService: projectService,
		logger:         logger,
	}
}

// CreateProject 创建项目
// @Summary 创建项目
// @Description 创建新项目
// @Tags 项目管理
// @Accept json
// @Produce json
// @Param request body service.CreateProjectRequest true "创建项目请求"
// @Success 201 {object} response.Response{data=entity.Project}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/projects [post]
func (h *ProjectHandler) CreateProject(c *gin.Context) {
	var req service.CreateProjectRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.Errorf("Invalid request body: %v", err)
		response.Error(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	project, err := h.projectService.CreateProject(c.Request.Context(), &req)
	if err != nil {
		h.logger.Errorf("Failed to create project: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to create project", err.Error())
		return
	}

	response.Success(c, http.StatusCreated, "Project created successfully", project)
}

// GetProject 获取项目详情
// @Summary 获取项目详情
// @Description 根据ID获取项目详情
// @Tags 项目管理
// @Produce json
// @Param id path string true "项目ID"
// @Success 200 {object} response.Response{data=entity.Project}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/projects/{id} [get]
func (h *ProjectHandler) GetProject(c *gin.Context) {
	projectIDStr := c.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid project ID", err.Error())
		return
	}

	project, err := h.projectService.GetProject(c.Request.Context(), projectID)
	if err != nil {
		h.logger.Errorf("Failed to get project: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to get project", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Project retrieved successfully", project)
}

// UpdateProject 更新项目
// @Summary 更新项目
// @Description 更新项目信息
// @Tags 项目管理
// @Accept json
// @Produce json
// @Param id path string true "项目ID"
// @Param request body service.UpdateProjectRequest true "更新项目请求"
// @Success 200 {object} response.Response{data=entity.Project}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/projects/{id} [put]
func (h *ProjectHandler) UpdateProject(c *gin.Context) {
	projectIDStr := c.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid project ID", err.Error())
		return
	}

	var req service.UpdateProjectRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.Errorf("Invalid request body: %v", err)
		response.Error(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	req.ProjectID = projectID
	project, err := h.projectService.UpdateProject(c.Request.Context(), &req)
	if err != nil {
		h.logger.Errorf("Failed to update project: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to update project", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Project updated successfully", project)
}

// DeleteProject 删除项目
// @Summary 删除项目
// @Description 删除项目
// @Tags 项目管理
// @Param id path string true "项目ID"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/projects/{id} [delete]
func (h *ProjectHandler) DeleteProject(c *gin.Context) {
	projectIDStr := c.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid project ID", err.Error())
		return
	}

	err = h.projectService.DeleteProject(c.Request.Context(), projectID)
	if err != nil {
		h.logger.Errorf("Failed to delete project: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to delete project", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Project deleted successfully", nil)
}

// ListProjects 获取项目列表
// @Summary 获取项目列表
// @Description 获取项目列表，支持分页和过滤
// @Tags 项目管理
// @Produce json
// @Param tenant_id query string true "租户ID"
// @Param owner_id query string false "所有者ID"
// @Param user_id query string false "用户ID"
// @Param offset query int false "偏移量" default(0)
// @Param limit query int false "限制数量" default(20)
// @Success 200 {object} response.Response{data=service.ListProjectsResponse}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/projects [get]
func (h *ProjectHandler) ListProjects(c *gin.Context) {
	tenantIDStr := c.Query("tenant_id")
	tenantID, err := uuid.Parse(tenantIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid tenant ID", err.Error())
		return
	}

	req := &service.ListProjectsRequest{
		TenantID: tenantID,
		Offset:   0,
		Limit:    20,
	}

	// 解析可选参数
	if ownerIDStr := c.Query("owner_id"); ownerIDStr != "" {
		ownerID, err := uuid.Parse(ownerIDStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid owner ID", err.Error())
			return
		}
		req.OwnerID = &ownerID
	}

	if userIDStr := c.Query("user_id"); userIDStr != "" {
		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid user ID", err.Error())
			return
		}
		req.UserID = &userID
	}

	if offsetStr := c.Query("offset"); offsetStr != "" {
		offset, err := strconv.Atoi(offsetStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid offset", err.Error())
			return
		}
		req.Offset = offset
	}

	if limitStr := c.Query("limit"); limitStr != "" {
		limit, err := strconv.Atoi(limitStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid limit", err.Error())
			return
		}
		req.Limit = limit
	}

	result, err := h.projectService.ListProjects(c.Request.Context(), req)
	if err != nil {
		h.logger.Errorf("Failed to list projects: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to list projects", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Projects retrieved successfully", result)
}

// SearchProjects 搜索项目
// @Summary 搜索项目
// @Description 根据关键词搜索项目
// @Tags 项目管理
// @Produce json
// @Param tenant_id query string true "租户ID"
// @Param keyword query string true "搜索关键词"
// @Param offset query int false "偏移量" default(0)
// @Param limit query int false "限制数量" default(20)
// @Success 200 {object} response.Response{data=service.ListProjectsResponse}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/projects/search [get]
func (h *ProjectHandler) SearchProjects(c *gin.Context) {
	tenantIDStr := c.Query("tenant_id")
	tenantID, err := uuid.Parse(tenantIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid tenant ID", err.Error())
		return
	}

	keyword := c.Query("keyword")
	if keyword == "" {
		response.Error(c, http.StatusBadRequest, "Keyword is required", "")
		return
	}

	req := &service.SearchProjectsRequest{
		TenantID: tenantID,
		Keyword:  keyword,
		Offset:   0,
		Limit:    20,
	}

	// 解析可选参数
	if offsetStr := c.Query("offset"); offsetStr != "" {
		offset, err := strconv.Atoi(offsetStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid offset", err.Error())
			return
		}
		req.Offset = offset
	}

	if limitStr := c.Query("limit"); limitStr != "" {
		limit, err := strconv.Atoi(limitStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid limit", err.Error())
			return
		}
		req.Limit = limit
	}

	result, err := h.projectService.SearchProjects(c.Request.Context(), req)
	if err != nil {
		h.logger.Errorf("Failed to search projects: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to search projects", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Projects searched successfully", result)
}

// AddMember 添加项目成员
// @Summary 添加项目成员
// @Description 添加用户到项目
// @Tags 项目成员管理
// @Accept json
// @Produce json
// @Param id path string true "项目ID"
// @Param request body service.AddMemberRequest true "添加成员请求"
// @Success 201 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/projects/{id}/members [post]
func (h *ProjectHandler) AddMember(c *gin.Context) {
	projectIDStr := c.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid project ID", err.Error())
		return
	}

	var req service.AddMemberRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.Errorf("Invalid request body: %v", err)
		response.Error(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	req.ProjectID = projectID
	err = h.projectService.AddMember(c.Request.Context(), &req)
	if err != nil {
		h.logger.Errorf("Failed to add member: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to add member", err.Error())
		return
	}

	response.Success(c, http.StatusCreated, "Member added successfully", nil)
}

// RemoveMember 移除项目成员
// @Summary 移除项目成员
// @Description 从项目中移除用户
// @Tags 项目成员管理
// @Param id path string true "项目ID"
// @Param member_id path string true "成员ID"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/projects/{id}/members/{member_id} [delete]
func (h *ProjectHandler) RemoveMember(c *gin.Context) {
	projectIDStr := c.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid project ID", err.Error())
		return
	}

	memberIDStr := c.Param("member_id")
	memberID, err := uuid.Parse(memberIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid member ID", err.Error())
		return
	}

	req := &service.RemoveMemberRequest{
		ProjectID: projectID,
		UserID:    memberID,
	}

	err = h.projectService.RemoveMember(c.Request.Context(), req)
	if err != nil {
		h.logger.Errorf("Failed to remove member: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to remove member", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Member removed successfully", nil)
}

// GetMembers 获取项目成员列表
// @Summary 获取项目成员列表
// @Description 获取项目的所有成员
// @Tags 项目成员管理
// @Produce json
// @Param id path string true "项目ID"
// @Success 200 {object} response.Response{data=[]entity.ProjectMember}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/projects/{id}/members [get]
func (h *ProjectHandler) GetMembers(c *gin.Context) {
	projectIDStr := c.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid project ID", err.Error())
		return
	}

	members, err := h.projectService.GetMembers(c.Request.Context(), projectID)
	if err != nil {
		h.logger.Errorf("Failed to get members: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to get members", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Members retrieved successfully", members)
}

// UpdateMemberRole 更新成员角色
// @Summary 更新成员角色
// @Description 更新项目成员的角色和权限
// @Tags 项目成员管理
// @Accept json
// @Produce json
// @Param id path string true "项目ID"
// @Param member_id path string true "成员ID"
// @Param request body service.UpdateMemberRoleRequest true "更新成员角色请求"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/projects/{id}/members/{member_id} [put]
func (h *ProjectHandler) UpdateMemberRole(c *gin.Context) {
	projectIDStr := c.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid project ID", err.Error())
		return
	}

	memberIDStr := c.Param("member_id")
	memberID, err := uuid.Parse(memberIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid member ID", err.Error())
		return
	}

	var req service.UpdateMemberRoleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.Errorf("Invalid request body: %v", err)
		response.Error(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	req.ProjectID = projectID
	req.UserID = memberID
	err = h.projectService.UpdateMemberRole(c.Request.Context(), &req)
	if err != nil {
		h.logger.Errorf("Failed to update member role: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to update member role", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Member role updated successfully", nil)
}

// GetActivities 获取项目活动日志
// @Summary 获取项目活动日志
// @Description 获取项目的活动日志
// @Tags 项目活动
// @Produce json
// @Param id path string true "项目ID"
// @Param offset query int false "偏移量" default(0)
// @Param limit query int false "限制数量" default(20)
// @Success 200 {object} response.Response{data=[]entity.ProjectActivity}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/projects/{id}/activities [get]
func (h *ProjectHandler) GetActivities(c *gin.Context) {
	projectIDStr := c.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid project ID", err.Error())
		return
	}

	offset := 0
	limit := 20

	if offsetStr := c.Query("offset"); offsetStr != "" {
		offset, err = strconv.Atoi(offsetStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid offset", err.Error())
			return
		}
	}

	if limitStr := c.Query("limit"); limitStr != "" {
		limit, err = strconv.Atoi(limitStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid limit", err.Error())
			return
		}
	}

	activities, total, err := h.projectService.GetActivities(c.Request.Context(), projectID, offset, limit)
	if err != nil {
		h.logger.Errorf("Failed to get activities: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to get activities", err.Error())
		return
	}

	result := map[string]interface{}{
		"activities": activities,
		"total":      total,
		"offset":     offset,
		"limit":      limit,
	}

	response.Success(c, http.StatusOK, "Activities retrieved successfully", result)
}
