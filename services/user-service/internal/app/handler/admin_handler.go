package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	admininit "github.com/llmops/user-service/internal/app/init"
)

// AdminHandler 管理员处理器
type AdminHandler struct {
	adminInitService *admininit.AdminInitService
}

// NewAdminHandler 创建管理员处理器
func NewAdminHandler(adminInitService *admininit.AdminInitService) *AdminHandler {
	return &AdminHandler{
		adminInitService: adminInitService,
	}
}

// EnsureAdminInAdminGroup 确保admin用户在管理员组中
func (h *AdminHandler) EnsureAdminInAdminGroup(c *gin.Context) {
	if err := h.adminInitService.EnsureAdminUserInAdminGroup(c.Request.Context()); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "ensure_admin_failed",
			"message": "确保admin用户在管理员组中失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Admin用户已在管理员组中",
	})
}

// GetAdminGroupInfo 获取管理员组信息
func (h *AdminHandler) GetAdminGroupInfo(c *gin.Context) {
	group, members, err := h.adminInitService.GetAdminUserGroupInfo(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "get_admin_group_failed",
			"message": "获取管理员组信息失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"group":   group,
			"members": members,
		},
	})
}

// InitializeAdmin 初始化admin用户和用户组
func (h *AdminHandler) InitializeAdmin(c *gin.Context) {
	if err := h.adminInitService.InitializeAdminUser(c.Request.Context()); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "init_admin_failed",
			"message": "初始化admin用户和用户组失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Admin用户和用户组初始化成功",
	})
}
