package middleware

import (
	"api-gateway/internal/config"
	"context"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

// 限流中间件
func RateLimitMiddleware(cfg *config.Config) gin.HandlerFunc {
	// 创建Redis客户端
	rdb := redis.NewClient(&redis.Options{
		Addr: cfg.RedisURL,
	})

	return func(c *gin.Context) {
		// 获取客户端IP
		clientIP := c.ClientIP()
		
		// 获取用户ID（如果已认证）
		userID := c.GetHeader("X-User-ID")
		if userID == "" {
			userID = "anonymous"
		}
		
		// 构建限流键
		key := fmt.Sprintf("rate_limit:%s:%s", clientIP, userID)
		
		// 检查限流
		allowed, err := checkRateLimit(rdb, key, 100, time.Minute)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Rate limit check failed",
			})
			c.Abort()
			return
		}
		
		if !allowed {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "Rate limit exceeded",
				"message": "Too many requests, please try again later",
			})
			c.Abort()
			return
		}
		
		c.Next()
	}
}

// 检查限流
func checkRateLimit(rdb *redis.Client, key string, limit int, window time.Duration) (bool, error) {
	ctx := context.Background()
	
	// 使用Redis的滑动窗口限流
	pipe := rdb.Pipeline()
	
	// 获取当前计数
	countCmd := pipe.Get(ctx, key)
	
	// 设置过期时间
	pipe.Expire(ctx, key, window)
	
	// 执行管道
	_, err := pipe.Exec(ctx)
	if err != nil && err != redis.Nil {
		return false, err
	}
	
	// 获取当前计数
	count, err := countCmd.Int()
	if err != nil && err != redis.Nil {
		return false, err
	}
	
	// 如果超过限制，返回false
	if count >= limit {
		return false, nil
	}
	
	// 增加计数
	_, err = rdb.Incr(ctx, key).Result()
	if err != nil {
		return false, err
	}
	
	return true, nil
}

// 基于用户的限流中间件
func UserRateLimitMiddleware(cfg *config.Config) gin.HandlerFunc {
	rdb := redis.NewClient(&redis.Options{
		Addr: cfg.RedisURL,
	})

	return func(c *gin.Context) {
		// 获取用户ID
		userID := c.GetHeader("X-User-ID")
		if userID == "" {
			c.Next()
			return
		}
		
		// 构建限流键
		key := fmt.Sprintf("user_rate_limit:%s", userID)
		
		// 检查用户限流
		allowed, err := checkRateLimit(rdb, key, 1000, time.Hour)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Rate limit check failed",
			})
			c.Abort()
			return
		}
		
		if !allowed {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "User rate limit exceeded",
				"message": "User rate limit exceeded, please try again later",
			})
			c.Abort()
			return
		}
		
		c.Next()
	}
}

// 基于API的限流中间件
func APIRateLimitMiddleware(cfg *config.Config) gin.HandlerFunc {
	rdb := redis.NewClient(&redis.Options{
		Addr: cfg.RedisURL,
	})

	return func(c *gin.Context) {
		// 获取API路径
		apiPath := c.Request.URL.Path
		
		// 构建限流键
		key := fmt.Sprintf("api_rate_limit:%s", apiPath)
		
		// 根据API设置不同的限流
		limit := getAPILimit(apiPath)
		
		// 检查API限流
		allowed, err := checkRateLimit(rdb, key, limit, time.Minute)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Rate limit check failed",
			})
			c.Abort()
			return
		}
		
		if !allowed {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "API rate limit exceeded",
				"message": "API rate limit exceeded, please try again later",
			})
			c.Abort()
			return
		}
		
		c.Next()
	}
}

// 获取API限流配置
func getAPILimit(apiPath string) int {
	// 根据API路径设置不同的限流
	switch {
	case contains(apiPath, "/api/v1/auth"):
		return 10 // 认证API限制更严格
	case contains(apiPath, "/api/v3/inference"):
		return 50 // 推理API限制中等
	case contains(apiPath, "/api/v5/monitoring"):
		return 200 // 监控API限制较松
	default:
		return 100 // 默认限流
	}
}

// 检查字符串是否包含子字符串
func contains(s, substr string) bool {
	return len(s) >= len(substr) && s[:len(substr)] == substr
}



