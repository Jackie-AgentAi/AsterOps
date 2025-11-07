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

// ProjectTemplateHandler 项目模板处理器
type ProjectTemplateHandler struct {
	templateService service.ProjectTemplateService
	logger          logger.Logger
}

// NewProjectTemplateHandler 创建项目模板处理器
func NewProjectTemplateHandler(templateService service.ProjectTemplateService, logger logger.Logger) *ProjectTemplateHandler {
	return &ProjectTemplateHandler{
		templateService: templateService,
		logger:          logger,
	}
}

// CreateTemplate 创建项目模板
// @Summary 创建项目模板
// @Description 创建新项目模板
// @Tags 项目模板管理
// @Accept json
// @Produce json
// @Param request body service.CreateTemplateRequest true "创建模板请求"
// @Success 201 {object} response.Response{data=entity.ProjectTemplate}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/templates [post]
func (h *ProjectTemplateHandler) CreateTemplate(c *gin.Context) {
	var req service.CreateTemplateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.Errorf("Invalid request body: %v", err)
		response.Error(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	template, err := h.templateService.CreateTemplate(c.Request.Context(), &req)
	if err != nil {
		h.logger.Errorf("Failed to create template: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to create template", err.Error())
		return
	}

	response.Success(c, http.StatusCreated, "Template created successfully", template)
}

// GetTemplate 获取项目模板详情
// @Summary 获取项目模板详情
// @Description 根据ID获取项目模板详情
// @Tags 项目模板管理
// @Produce json
// @Param id path string true "模板ID"
// @Success 200 {object} response.Response{data=entity.ProjectTemplate}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/templates/{id} [get]
func (h *ProjectTemplateHandler) GetTemplate(c *gin.Context) {
	templateIDStr := c.Param("id")
	templateID, err := uuid.Parse(templateIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid template ID", err.Error())
		return
	}

	template, err := h.templateService.GetTemplate(c.Request.Context(), templateID)
	if err != nil {
		h.logger.Errorf("Failed to get template: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to get template", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Template retrieved successfully", template)
}

// UpdateTemplate 更新项目模板
// @Summary 更新项目模板
// @Description 更新项目模板信息
// @Tags 项目模板管理
// @Accept json
// @Produce json
// @Param id path string true "模板ID"
// @Param request body service.UpdateTemplateRequest true "更新模板请求"
// @Success 200 {object} response.Response{data=entity.ProjectTemplate}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/templates/{id} [put]
func (h *ProjectTemplateHandler) UpdateTemplate(c *gin.Context) {
	templateIDStr := c.Param("id")
	templateID, err := uuid.Parse(templateIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid template ID", err.Error())
		return
	}

	var req service.UpdateTemplateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.Errorf("Invalid request body: %v", err)
		response.Error(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	req.TemplateID = templateID
	template, err := h.templateService.UpdateTemplate(c.Request.Context(), &req)
	if err != nil {
		h.logger.Errorf("Failed to update template: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to update template", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Template updated successfully", template)
}

// DeleteTemplate 删除项目模板
// @Summary 删除项目模板
// @Description 删除项目模板
// @Tags 项目模板管理
// @Param id path string true "模板ID"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/templates/{id} [delete]
func (h *ProjectTemplateHandler) DeleteTemplate(c *gin.Context) {
	templateIDStr := c.Param("id")
	templateID, err := uuid.Parse(templateIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid template ID", err.Error())
		return
	}

	err = h.templateService.DeleteTemplate(c.Request.Context(), templateID)
	if err != nil {
		h.logger.Errorf("Failed to delete template: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to delete template", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Template deleted successfully", nil)
}

// ListTemplates 获取项目模板列表
// @Summary 获取项目模板列表
// @Description 获取项目模板列表，支持分页
// @Tags 项目模板管理
// @Produce json
// @Param tenant_id query string true "租户ID"
// @Param offset query int false "偏移量" default(0)
// @Param limit query int false "限制数量" default(20)
// @Success 200 {object} response.Response{data=service.ListTemplatesResponse}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/templates [get]
func (h *ProjectTemplateHandler) ListTemplates(c *gin.Context) {
	tenantIDStr := c.Query("tenant_id")
	tenantID, err := uuid.Parse(tenantIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid tenant ID", err.Error())
		return
	}

	req := &service.ListTemplatesRequest{
		TenantID: tenantID,
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

	result, err := h.templateService.ListTemplates(c.Request.Context(), req)
	if err != nil {
		h.logger.Errorf("Failed to list templates: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to list templates", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Templates retrieved successfully", result)
}

// SearchTemplates 搜索项目模板
// @Summary 搜索项目模板
// @Description 根据关键词搜索项目模板
// @Tags 项目模板管理
// @Produce json
// @Param tenant_id query string true "租户ID"
// @Param keyword query string true "搜索关键词"
// @Param offset query int false "偏移量" default(0)
// @Param limit query int false "限制数量" default(20)
// @Success 200 {object} response.Response{data=service.ListTemplatesResponse}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/templates/search [get]
func (h *ProjectTemplateHandler) SearchTemplates(c *gin.Context) {
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

	req := &service.SearchTemplatesRequest{
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

	result, err := h.templateService.SearchTemplates(c.Request.Context(), req)
	if err != nil {
		h.logger.Errorf("Failed to search templates: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to search templates", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Templates searched successfully", result)
}

// GetPublicTemplates 获取公共模板
// @Summary 获取公共模板
// @Description 获取所有公共项目模板
// @Tags 项目模板管理
// @Produce json
// @Param offset query int false "偏移量" default(0)
// @Param limit query int false "限制数量" default(20)
// @Success 200 {object} response.Response{data=[]entity.ProjectTemplate}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/templates/public [get]
func (h *ProjectTemplateHandler) GetPublicTemplates(c *gin.Context) {
	offset := 0
	limit := 20

	if offsetStr := c.Query("offset"); offsetStr != "" {
		var err error
		offset, err = strconv.Atoi(offsetStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid offset", err.Error())
			return
		}
	}

	if limitStr := c.Query("limit"); limitStr != "" {
		var err error
		limit, err = strconv.Atoi(limitStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid limit", err.Error())
			return
		}
	}

	templates, total, err := h.templateService.GetPublicTemplates(c.Request.Context(), offset, limit)
	if err != nil {
		h.logger.Errorf("Failed to get public templates: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to get public templates", err.Error())
		return
	}

	result := map[string]interface{}{
		"templates": templates,
		"total":     total,
		"offset":    offset,
		"limit":     limit,
	}

	response.Success(c, http.StatusOK, "Public templates retrieved successfully", result)
}

// GetTemplatesByCategory 根据分类获取模板
// @Summary 根据分类获取模板
// @Description 根据分类获取项目模板
// @Tags 项目模板管理
// @Produce json
// @Param category path string true "分类名称"
// @Param offset query int false "偏移量" default(0)
// @Param limit query int false "限制数量" default(20)
// @Success 200 {object} response.Response{data=[]entity.ProjectTemplate}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/templates/category/{category} [get]
func (h *ProjectTemplateHandler) GetTemplatesByCategory(c *gin.Context) {
	category := c.Param("category")
	if category == "" {
		response.Error(c, http.StatusBadRequest, "Category is required", "")
		return
	}

	offset := 0
	limit := 20

	if offsetStr := c.Query("offset"); offsetStr != "" {
		var err error
		offset, err = strconv.Atoi(offsetStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid offset", err.Error())
			return
		}
	}

	if limitStr := c.Query("limit"); limitStr != "" {
		var err error
		limit, err = strconv.Atoi(limitStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid limit", err.Error())
			return
		}
	}

	templates, total, err := h.templateService.GetTemplatesByCategory(c.Request.Context(), category, offset, limit)
	if err != nil {
		h.logger.Errorf("Failed to get templates by category: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to get templates by category", err.Error())
		return
	}

	result := map[string]interface{}{
		"templates": templates,
		"total":     total,
		"offset":    offset,
		"limit":     limit,
		"category":  category,
	}

	response.Success(c, http.StatusOK, "Templates by category retrieved successfully", result)
}

// CreateProjectFromTemplate 从模板创建项目
// @Summary 从模板创建项目
// @Description 使用项目模板创建新项目
// @Tags 项目模板管理
// @Accept json
// @Produce json
// @Param request body service.CreateProjectFromTemplateRequest true "从模板创建项目请求"
// @Success 201 {object} response.Response{data=entity.Project}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/templates/create-project [post]
func (h *ProjectTemplateHandler) CreateProjectFromTemplate(c *gin.Context) {
	var req service.CreateProjectFromTemplateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.Errorf("Invalid request body: %v", err)
		response.Error(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	project, err := h.templateService.CreateProjectFromTemplate(c.Request.Context(), &req)
	if err != nil {
		h.logger.Errorf("Failed to create project from template: %v", err)
		response.Error(c, http.StatusInternalServerError, "Failed to create project from template", err.Error())
		return
	}

	response.Success(c, http.StatusCreated, "Project created from template successfully", project)
}
