package middleware

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// AuthMiddleware JWT认证中间件
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		// 检查Bearer token格式
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token format"})
			c.Abort()
			return
		}

		// 简化的token验证（实际应该使用真正的JWT）
		if strings.HasPrefix(tokenString, "access_token_") {
			// 从token中提取用户信息
			// token格式: access_token_00000000-0000-0000-0000-000000000001_admin
			parts := strings.Split(tokenString, "_")
			// 打印调试信息
			fmt.Println("Token parts:", parts)
			if len(parts) >= 4 {
				userID := parts[2]
				username := parts[3]
				fmt.Printf("Parsed UserID: %s, Username: %s\n", userID, username)
				c.Set("user_id", userID)
				c.Set("username", username)
				// 设置默认的tenant_id
				c.Set("tenant_id", "00000000-0000-0000-0000-000000000001")
			} else {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token format"})
				c.Abort()
				return
			}
		} else {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			c.Abort()
			return
		}

		c.Next()
	}
}

// CORSMiddleware 跨域中间件
func CORSMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}

// LoggingMiddleware 日志中间件
func LoggingMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 简单的日志记录
		c.Next()
	}
}

