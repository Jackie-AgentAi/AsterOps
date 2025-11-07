package middleware

import (
	"net"
	"net/http/httputil"
	"os"
	"runtime/debug"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/llmops/project-service/internal/pkg/logger"
	"github.com/llmops/project-service/internal/pkg/response"
)

// Recovery 恢复中间件
func Recovery(logger logger.Logger) gin.HandlerFunc {
	return gin.CustomRecovery(func(c *gin.Context, recovered interface{}) {
		if err, ok := recovered.(string); ok {
			if strings.Contains(err, "broken pipe") {
				// 客户端断开连接，不需要记录错误
				c.Abort()
				return
			}
		}

		// 检查是否是网络错误
		if ne, ok := recovered.(*net.OpError); ok {
			if se, ok := ne.Err.(*os.SyscallError); ok {
				if strings.Contains(strings.ToLower(se.Error()), "broken pipe") ||
					strings.Contains(strings.ToLower(se.Error()), "connection reset by peer") {
					c.Abort()
					return
				}
			}
		}

		// 记录错误日志
		httpRequest, _ := httputil.DumpRequest(c.Request, false)
		logger.Errorf("[Recovery] panic recovered:\n%s\n%s\n%s",
			string(httpRequest),
			recovered,
			string(debug.Stack()),
		)

		// 返回错误响应
		response.InternalServerError(c, "Internal server error", "An unexpected error occurred")
	})
}
