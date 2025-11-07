package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/llmops/project-service/internal/pkg/logger"
)

// Logging 日志中间件
func Logging(logger logger.Logger) gin.HandlerFunc {
	return gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		logger.Infof("[%s] %s %s %d %s %s %s",
			param.TimeStamp.Format(time.RFC3339),
			param.Method,
			param.Path,
			param.StatusCode,
			param.Latency,
			param.ClientIP,
			param.ErrorMessage,
		)
		return ""
	})
}
