package auth

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// 认证中间件
func AuthMiddleware(jwtManager *JWTManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取Authorization头
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "unauthorized",
				"message": "Authorization header is required",
			})
			c.Abort()
			return
		}

		// 检查Bearer格式
		tokenParts := strings.Split(authHeader, " ")
		if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "unauthorized",
				"message": "Invalid authorization header format",
			})
			c.Abort()
			return
		}

		// 验证令牌
		claims, err := jwtManager.ValidateToken(tokenParts[1])
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "unauthorized",
				"message": "Invalid or expired token",
			})
			c.Abort()
			return
		}

		// 将用户信息存储到上下文中
		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("email", claims.Email)
		c.Set("roles", claims.Roles)
		c.Set("tenant_id", claims.TenantID)
		c.Set("claims", claims)

		c.Next()
	}
}

// 角色权限中间件
func RoleMiddleware(requiredRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := c.Get("claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "unauthorized",
				"message": "User claims not found",
			})
			c.Abort()
			return
		}

		userClaims, ok := claims.(*Claims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "unauthorized",
				"message": "Invalid user claims",
			})
			c.Abort()
			return
		}

		// 检查是否有必需的角色
		if !userClaims.HasAnyRole(requiredRoles) {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "forbidden",
				"message": "Insufficient permissions",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// 管理员权限中间件
func AdminMiddleware() gin.HandlerFunc {
	return RoleMiddleware("admin")
}

// 租户权限中间件
func TenantMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := c.Get("claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "unauthorized",
				"message": "User claims not found",
			})
			c.Abort()
			return
		}

		userClaims, ok := claims.(*Claims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "unauthorized",
				"message": "Invalid user claims",
			})
			c.Abort()
			return
		}

		// 获取请求中的租户ID
		tenantID := c.Query("tenant_id")
		if tenantID == "" {
			tenantID = c.Param("tenant_id")
		}

		// 检查租户权限
		if tenantID != "" && userClaims.TenantID != tenantID && !userClaims.IsAdmin() {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "forbidden",
				"message": "Access denied to this tenant",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// 可选认证中间件（不强制要求认证）
func OptionalAuthMiddleware(jwtManager *JWTManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.Next()
			return
		}

		tokenParts := strings.Split(authHeader, " ")
		if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
			c.Next()
			return
		}

		claims, err := jwtManager.ValidateToken(tokenParts[1])
		if err != nil {
			c.Next()
			return
		}

		// 将用户信息存储到上下文中
		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("email", claims.Email)
		c.Set("roles", claims.Roles)
		c.Set("tenant_id", claims.TenantID)
		c.Set("claims", claims)

		c.Next()
	}
}

// 获取当前用户信息
func GetCurrentUser(c *gin.Context) (*Claims, bool) {
	claims, exists := c.Get("claims")
	if !exists {
		return nil, false
	}

	userClaims, ok := claims.(*Claims)
	return userClaims, ok
}

// 获取当前用户ID
func GetCurrentUserID(c *gin.Context) (string, bool) {
	userID, exists := c.Get("user_id")
	if !exists {
		return "", false
	}

	id, ok := userID.(string)
	return id, ok
}

// 获取当前租户ID
func GetCurrentTenantID(c *gin.Context) (string, bool) {
	tenantID, exists := c.Get("tenant_id")
	if !exists {
		return "", false
	}

	id, ok := tenantID.(string)
	return id, ok
}

