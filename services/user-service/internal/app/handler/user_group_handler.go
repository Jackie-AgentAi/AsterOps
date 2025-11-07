package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/llmops/user-service/internal/domain/entity"
	"github.com/llmops/user-service/internal/domain/service"
)

// 用户组处理器
type UserGroupHandler struct {
	groupService *service.UserGroupService
}

// 创建用户组处理器
func NewUserGroupHandler(groupService *service.UserGroupService) *UserGroupHandler {
	return &UserGroupHandler{
		groupService: groupService,
	}
}

// 获取用户组列表
func (h *UserGroupHandler) GetUserGroups(c *gin.Context) {
	tenantID, exists := c.Get("tenant_id")
	if !exists {
		// 使用默认租户ID
		tenantID = "00000000-0000-0000-0000-000000000001"
	}
	
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	searchKeyword := c.Query("keyword")
	
	tenantUUID, err := uuid.Parse(tenantID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_tenant_id",
			"message": "Invalid tenant ID",
		})
		return
	}
	
	groups, total, err := h.groupService.GetUserGroups(c.Request.Context(), tenantUUID, offset, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "internal_error",
			"message": "Failed to get user groups",
		})
		return
	}
	
	// 如果提供了搜索关键词，进行过滤
	if searchKeyword != "" {
		filteredGroups := make([]*entity.UserGroup, 0)
		keyword := searchKeyword
		for _, group := range groups {
			if containsIgnoreCase(group.Name, keyword) || containsIgnoreCase(group.Description, keyword) {
				filteredGroups = append(filteredGroups, group)
			}
		}
		groups = filteredGroups
		total = int64(len(filteredGroups))
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"groups": groups,
			"total":  total,
			"offset": offset,
			"limit":  limit,
		},
	})
}

// containsIgnoreCase 检查字符串是否包含子字符串（不区分大小写）
func containsIgnoreCase(str, substr string) bool {
	if len(substr) == 0 {
		return true
	}
	if len(str) < len(substr) {
		return false
	}
	strLower := toLower(str)
	substrLower := toLower(substr)
	for i := 0; i <= len(strLower)-len(substrLower); i++ {
		if strLower[i:i+len(substrLower)] == substrLower {
			return true
		}
	}
	return false
}

// toLower 将字符串转换为小写
func toLower(s string) string {
	result := make([]byte, len(s))
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c >= 'A' && c <= 'Z' {
			result[i] = c + 32
		} else {
			result[i] = c
		}
	}
	return string(result)
}

// 获取单个用户组
func (h *UserGroupHandler) GetUserGroup(c *gin.Context) {
	groupID := c.Param("id")
	
	groupUUID, err := uuid.Parse(groupID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_group_id",
			"message": "Invalid group ID",
		})
		return
	}
	
	group, err := h.groupService.GetUserGroup(c.Request.Context(), groupUUID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "group_not_found",
			"message": "User group not found",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    group,
	})
}

// 创建用户组
func (h *UserGroupHandler) CreateUserGroup(c *gin.Context) {
	var req struct {
		Name           string `json:"name" binding:"required"`
		Description    string `json:"description"`
		OrganizationID string `json:"organization_id"`
		ParentID       string `json:"parent_id"`
		Settings       string `json:"settings"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": err.Error(),
		})
		return
	}

	tenantID, exists := c.Get("tenant_id")
	if !exists {
		tenantID = "00000000-0000-0000-0000-000000000001"
	}

	// 创建用户组实体
	group := &entity.UserGroup{
		Name:        req.Name,
		Description: req.Description,
		TenantID:    tenantID.(string),
	}

	if req.OrganizationID != "" {
		group.OrganizationID = &req.OrganizationID
	}

	if req.ParentID != "" {
		group.ParentID = &req.ParentID
	}

	if req.Settings != "" {
		group.Settings = req.Settings
	} else {
		group.Settings = "{}"
	}

	err := h.groupService.CreateUserGroup(c.Request.Context(), group)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "create_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    group,
		"message": "User group created successfully",
	})
}

// 更新用户组
func (h *UserGroupHandler) UpdateUserGroup(c *gin.Context) {
	groupID := c.Param("id")
	groupUUID, err := uuid.Parse(groupID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_group_id",
			"message": "Invalid group ID",
		})
		return
	}

	var req struct {
		Name           string `json:"name"`
		Description    string `json:"description"`
		OrganizationID string `json:"organization_id"`
		ParentID       string `json:"parent_id"`
		Settings       string `json:"settings"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": err.Error(),
		})
		return
	}

	// 获取现有用户组
	group, err := h.groupService.GetUserGroup(c.Request.Context(), groupUUID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "group_not_found",
			"message": "User group not found",
		})
		return
	}

	// 更新用户组信息
	if req.Name != "" {
		group.Name = req.Name
	}
	if req.Description != "" {
		group.Description = req.Description
	}
	if req.OrganizationID != "" {
		group.OrganizationID = &req.OrganizationID
	}
	if req.ParentID != "" {
		group.ParentID = &req.ParentID
	}
	if req.Settings != "" {
		group.Settings = req.Settings
	}

	err = h.groupService.UpdateUserGroup(c.Request.Context(), group)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "update_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    group,
		"message": "User group updated successfully",
	})
}

// 删除用户组
func (h *UserGroupHandler) DeleteUserGroup(c *gin.Context) {
	groupID := c.Param("id")
	
	groupUUID, err := uuid.Parse(groupID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_group_id",
			"message": "Invalid group ID",
		})
		return
	}
	
	// 检查是否为admin组（ID: 00000000-0000-0000-0000-000000000002）
	adminGroupID := uuid.MustParse("00000000-0000-0000-0000-000000000002")
	if groupUUID == adminGroupID {
		c.JSON(http.StatusForbidden, gin.H{
			"error":   "forbidden",
			"message": "Admin group cannot be deleted",
		})
		return
	}
	
	// 获取用户组信息，检查名称
	group, err := h.groupService.GetUserGroup(c.Request.Context(), groupUUID)
	if err == nil && group != nil {
		if group.Name == "管理员组" || group.Name == "admin" {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "forbidden",
				"message": "Admin group cannot be deleted",
			})
			return
		}
	}
	
	err = h.groupService.DeleteUserGroup(c.Request.Context(), groupUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "internal_error",
			"message": "Failed to delete user group",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "User group deleted successfully",
	})
}

// 获取用户组成员
func (h *UserGroupHandler) GetGroupMembers(c *gin.Context) {
	groupID := c.Param("id")
	
	groupUUID, err := uuid.Parse(groupID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_group_id",
			"message": "Invalid group ID",
		})
		return
	}
	
	members, err := h.groupService.GetMembers(c.Request.Context(), groupUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "internal_error",
			"message": "Failed to get group members",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    members,
	})
}

// 添加用户组成员
func (h *UserGroupHandler) AddGroupMember(c *gin.Context) {
	groupID := c.Param("id")
	groupUUID, err := uuid.Parse(groupID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_group_id",
			"message": "Invalid group ID",
		})
		return
	}

	var req struct {
		UserID string `json:"user_id" binding:"required"`
		Role   string `json:"role"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": err.Error(),
		})
		return
	}

	userUUID, err := uuid.Parse(req.UserID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_user_id",
			"message": "Invalid user ID",
		})
		return
	}

	role := req.Role
	if role == "" {
		role = "member"
	}

	err = h.groupService.AddMember(c.Request.Context(), userUUID, groupUUID, role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "add_member_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Member added successfully",
	})
}

// 移除用户组成员
func (h *UserGroupHandler) RemoveGroupMember(c *gin.Context) {
	groupID := c.Param("id")
	userID := c.Param("user_id")
	
	groupUUID, err := uuid.Parse(groupID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_group_id",
			"message": "Invalid group ID",
		})
		return
	}
	
	userUUID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_user_id",
			"message": "Invalid user ID",
		})
		return
	}
	
	err = h.groupService.RemoveMember(c.Request.Context(), userUUID, groupUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "remove_member_failed",
			"message": err.Error(),
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Member removed successfully",
	})
}

// 获取用户所属的用户组
func (h *UserGroupHandler) GetUserGroupsByUser(c *gin.Context) {
	userID := c.Param("user_id")
	
	userUUID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_user_id",
			"message": "Invalid user ID",
		})
		return
	}
	
	groups, err := h.groupService.GetUserGroupsByUser(c.Request.Context(), userUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "internal_error",
			"message": "Failed to get user groups",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    groups,
	})
}
