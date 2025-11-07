package router

import (
	"github.com/gin-gonic/gin"
	"github.com/llmops/user-service/internal/app/handler"
)

// 认证路由
func SetupAuthRoutes(r *gin.RouterGroup, authHandler *handler.AuthHandler) {
	auth := r.Group("/auth")
	{
		// 公开路由（不需要认证）
		auth.POST("/login", authHandler.Login)
		auth.POST("/register", authHandler.Register)
		auth.POST("/refresh", authHandler.RefreshToken)

		// 需要认证的路由
		auth.Use(AuthMiddleware()) // 这里需要实现认证中间件
		{
			auth.GET("/profile", authHandler.GetProfile)
			auth.POST("/logout", authHandler.Logout)
		}
	}
}


// 角色路由
func SetupRoleRoutes(r *gin.RouterGroup, roleHandler *handler.RoleHandler) {
	roles := r.Group("/roles")
	{
		// 需要认证的路由
		roles.Use(AuthMiddleware()) // 这里需要实现认证中间件
		{
			roles.GET("/", roleHandler.GetRoles)
			roles.POST("/", roleHandler.CreateRole)
			roles.GET("/:id", roleHandler.GetRole)
			roles.PUT("/:id", roleHandler.UpdateRole)
			roles.DELETE("/:id", roleHandler.DeleteRole)
			roles.POST("/:id/assign", roleHandler.AssignRole)
			roles.DELETE("/:id/unassign", roleHandler.UnassignRole)
		}
	}
}

// 权限路由
func SetupPermissionRoutes(r *gin.RouterGroup, permissionHandler *handler.PermissionHandler) {
	permissions := r.Group("/permissions")
	{
		// 需要认证的路由
		permissions.Use(AuthMiddleware()) // 这里需要实现认证中间件
		{
			permissions.GET("/", permissionHandler.GetPermissions)
			permissions.POST("/", permissionHandler.CreatePermission)
			permissions.GET("/:id", permissionHandler.GetPermission)
			permissions.PUT("/:id", permissionHandler.UpdatePermission)
			permissions.DELETE("/:id", permissionHandler.DeletePermission)
		}
	}
}

// 认证中间件（简化版本）
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 简化的认证中间件
		// 在实际应用中，这里应该验证JWT令牌
		
		// 模拟用户信息
		c.Set("user_id", "550e8400-e29b-41d4-a716-446655440000")
		c.Set("username", "testuser")
		c.Set("email", "test@example.com")
		c.Set("tenant_id", "550e8400-e29b-41d4-a716-446655440000")
		c.Set("roles", []string{"user"})
		
		c.Next()
	}
}

// 管理员中间件
func AdminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 简化的管理员检查
		// 在实际应用中，这里应该检查用户角色
		c.Next()
	}
}

// 租户中间件
func TenantMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 简化的租户检查
		// 在实际应用中，这里应该验证租户权限
		c.Next()
	}
}

