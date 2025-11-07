package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/llmops/user-service/internal/domain/entity"
	"github.com/llmops/user-service/internal/domain/service"
)

// 用户处理器
type UserHandler struct {
	userService *service.UserService
}

// 创建用户处理器
func NewUserHandler(userService *service.UserService) *UserHandler {
	return &UserHandler{
		userService: userService,
	}
}

// 获取用户列表
func (h *UserHandler) GetUsers(c *gin.Context) {
	tenantID, exists := c.Get("tenant_id")
	if !exists {
		// 使用默认租户ID
		tenantID = "00000000-0000-0000-0000-000000000001"
	}
	
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	
	tenantUUID, err := uuid.Parse(tenantID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_tenant_id",
			"message": "Invalid tenant ID",
		})
		return
	}
	users, total, err := h.userService.GetUsers(c.Request.Context(), tenantUUID, offset, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "internal_error",
			"message": "Failed to get users",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"users": users,
			"total": total,
			"offset": offset,
			"limit": limit,
		},
	})
}

// 获取单个用户
func (h *UserHandler) GetUser(c *gin.Context) {
	userID := c.Param("id")
	
	userUUID, _ := uuid.Parse(userID)
	user, err := h.userService.GetUserByID(c.Request.Context(), userUUID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "user_not_found",
			"message": "User not found",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    user,
	})
}

// 创建用户
func (h *UserHandler) CreateUser(c *gin.Context) {
	var req entity.CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": err.Error(),
		})
		return
	}

	// 创建用户实体
	user := &entity.User{
		Username: req.Username,
		Email:    req.Email,
		Password: req.Password, // 这里应该加密
		Name:     req.Name,
		TenantID: req.TenantID,
	}

	err := h.userService.CreateUser(c.Request.Context(), user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "create_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    user,
		"message": "User created successfully",
	})
}

// 更新用户
func (h *UserHandler) UpdateUser(c *gin.Context) {
	userID := c.Param("id")
	userUUID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_user_id",
			"message": "Invalid user ID",
		})
		return
	}

	var req entity.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": err.Error(),
		})
		return
	}

	// 获取现有用户
	user, err := h.userService.GetUserByID(c.Request.Context(), userUUID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "user_not_found",
			"message": "User not found",
		})
		return
	}

	// 更新用户信息
	if req.Name != "" {
		user.Name = req.Name
	}
	if req.Status != "" {
		user.Status = req.Status
	}

	err = h.userService.UpdateUser(c.Request.Context(), user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "update_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    user,
		"message": "User updated successfully",
	})
}

// 删除用户
func (h *UserHandler) DeleteUser(c *gin.Context) {
	userID := c.Param("id")
	
	userUUID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_user_id",
			"message": "Invalid user ID",
		})
		return
	}
	
	// 检查是否为admin用户（ID: 00000000-0000-0000-0000-000000000001）
	adminUserID := uuid.MustParse("00000000-0000-0000-0000-000000000001")
	if userUUID == adminUserID {
		c.JSON(http.StatusForbidden, gin.H{
			"error":   "forbidden",
			"message": "Admin user cannot be deleted",
		})
		return
	}
	
	// 获取用户信息，检查用户名
	user, err := h.userService.GetUserByID(c.Request.Context(), userUUID)
	if err == nil && user != nil {
		if user.Username == "admin" {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "forbidden",
				"message": "Admin user cannot be deleted",
			})
			return
		}
	}
	
	err = h.userService.DeleteUser(c.Request.Context(), userUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "internal_error",
			"message": "Failed to delete user",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "User deleted successfully",
	})
}

// 搜索用户
func (h *UserHandler) SearchUsers(c *gin.Context) {
	tenantID, exists := c.Get("tenant_id")
	if !exists {
		tenantID = "00000000-0000-0000-0000-000000000001"
	}
	
	keyword := c.Query("keyword")
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	
	tenantUUID, err := uuid.Parse(tenantID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_tenant_id",
			"message": "Invalid tenant ID",
		})
		return
	}
	
	users, total, err := h.userService.SearchUsers(c.Request.Context(), tenantUUID, keyword, offset, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "search_failed",
			"message": "Failed to search users",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"users": users,
			"total": total,
			"offset": offset,
			"limit": limit,
		},
	})
}

// 批量操作用户
func (h *UserHandler) BatchUserOperation(c *gin.Context) {
	var req entity.BatchUserOperationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": err.Error(),
		})
		return
	}

	// 根据操作类型执行不同的批量操作
	switch req.Action {
	case "delete":
		err := h.userService.BatchDeleteUsers(c.Request.Context(), req.UserIDs)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "batch_delete_failed",
				"message": err.Error(),
			})
			return
		}
	case "activate":
		err := h.userService.BatchActivateUsers(c.Request.Context(), req.UserIDs)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "batch_activate_failed",
				"message": err.Error(),
			})
			return
		}
	case "deactivate":
		err := h.userService.BatchDeactivateUsers(c.Request.Context(), req.UserIDs)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "batch_deactivate_failed",
				"message": err.Error(),
			})
			return
		}
	default:
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_action",
			"message": "Invalid batch action",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Batch operation completed successfully",
	})
}

// 获取用户统计
func (h *UserHandler) GetUserStats(c *gin.Context) {
	tenantID, exists := c.Get("tenant_id")
	if !exists {
		tenantID = "00000000-0000-0000-0000-000000000001"
	}
	
	tenantUUID, err := uuid.Parse(tenantID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_tenant_id",
			"message": "Invalid tenant ID",
		})
		return
	}
	
	stats, err := h.userService.GetUserStats(c.Request.Context(), tenantUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "stats_failed",
			"message": "Failed to get user statistics",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    stats,
	})
}

// 重置用户密码
func (h *UserHandler) ResetUserPassword(c *gin.Context) {
	userID := c.Param("id")
	userUUID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_user_id",
			"message": "Invalid user ID",
		})
		return
	}

	var req struct {
		NewPassword string `json:"new_password" binding:"required,min=6"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": err.Error(),
		})
		return
	}

	err = h.userService.ResetUserPassword(c.Request.Context(), userUUID, req.NewPassword)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "reset_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Password reset successfully",
	})
}

// 切换用户状态
func (h *UserHandler) ToggleUserStatus(c *gin.Context) {
	userID := c.Param("id")
	userUUID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_user_id",
			"message": "Invalid user ID",
		})
		return
	}

	err = h.userService.ToggleUserStatus(c.Request.Context(), userUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "toggle_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "User status toggled successfully",
	})
}