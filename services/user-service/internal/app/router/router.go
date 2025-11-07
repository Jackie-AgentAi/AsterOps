package router

import (
	"github.com/gin-gonic/gin"
	"github.com/llmops/user-service/internal/app/handler"
)

// SetupUserRoutes 设置用户相关路由
func SetupUserRoutes(r *gin.RouterGroup, userHandler *handler.UserHandler, groupHandler *handler.UserGroupHandler, authHandler *handler.AuthHandler, adminHandler *handler.AdminHandler, authMiddleware gin.HandlerFunc) {
	// 认证路由
	auth := r.Group("/auth")
	{
		// 公开路由（不需要认证）
		auth.POST("/login", authHandler.Login)
		auth.POST("/register", authHandler.Register)
		auth.POST("/refresh", authHandler.RefreshToken)

		// 需要认证的路由
		auth.Use(authMiddleware)
		{
			auth.GET("/profile", authHandler.GetProfile)
			auth.POST("/logout", authHandler.Logout)
		}
	}

	// 用户路由
	users := r.Group("/users")
	{
		// 需要认证的路由
		users.Use(authMiddleware)
		{
			// 基础CRUD操作
			users.GET("/", userHandler.GetUsers)
			users.POST("/", userHandler.CreateUser)
			users.GET("/:id", userHandler.GetUser)
			users.PUT("/:id", userHandler.UpdateUser)
			users.DELETE("/:id", userHandler.DeleteUser)
			
			// 搜索和统计
			users.GET("/search", userHandler.SearchUsers)
			users.GET("/stats", userHandler.GetUserStats)
			
			// 批量操作
			users.POST("/batch", userHandler.BatchUserOperation)
			
			// 用户管理操作
			users.POST("/:id/reset-password", userHandler.ResetUserPassword)
			users.POST("/:id/toggle-status", userHandler.ToggleUserStatus)
		}
	}

	// 用户组路由
	groups := r.Group("/user-groups")
	{
		// 需要认证的路由
		groups.Use(authMiddleware)
		{
			// 基础CRUD操作
			groups.GET("/", groupHandler.GetUserGroups)
			groups.POST("/", groupHandler.CreateUserGroup)
			groups.GET("/:id", groupHandler.GetUserGroup)
			groups.PUT("/:id", groupHandler.UpdateUserGroup)
			groups.DELETE("/:id", groupHandler.DeleteUserGroup)
			
			// 成员管理
			groups.GET("/:id/members", groupHandler.GetGroupMembers)
			groups.POST("/:id/members", groupHandler.AddGroupMember)
			groups.DELETE("/:id/members/:user_id", groupHandler.RemoveGroupMember)
			
			// 用户所属组
			groups.GET("/user/:user_id", groupHandler.GetUserGroupsByUser)
		}
	}

	// Admin管理路由
	admin := r.Group("/admin")
	{
		// 需要认证的路由
		admin.Use(authMiddleware)
		{
			admin.POST("/ensure", adminHandler.EnsureAdminInAdminGroup)
			admin.GET("/group-info", adminHandler.GetAdminGroupInfo)
			admin.POST("/init", adminHandler.InitializeAdmin)
		}
	}
}

