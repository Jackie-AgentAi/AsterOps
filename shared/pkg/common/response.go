package common

import (
	"net/http"
	"github.com/gin-gonic/gin"
)

// 成功响应
func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, SuccessResponse(data))
}

// 创建成功响应
func Created(c *gin.Context, data interface{}) {
	c.JSON(http.StatusCreated, SuccessResponse(data))
}

// 错误响应
func Error(c *gin.Context, code int, message string, err error) {
	c.JSON(code, ErrorResponse(code, message, err))
}

// 验证错误响应
func ValidationError(c *gin.Context, message string, err error) {
	Error(c, http.StatusBadRequest, message, err)
}

// 未找到错误响应
func NotFound(c *gin.Context, message string) {
	Error(c, http.StatusNotFound, message, nil)
}

// 未授权错误响应
func Unauthorized(c *gin.Context, message string) {
	Error(c, http.StatusUnauthorized, message, nil)
}

// 禁止访问错误响应
func Forbidden(c *gin.Context, message string) {
	Error(c, http.StatusForbidden, message, nil)
}

// 内部服务器错误响应
func InternalError(c *gin.Context, message string, err error) {
	Error(c, http.StatusInternalServerError, message, err)
}

// 服务不可用错误响应
func ServiceUnavailable(c *gin.Context, message string) {
	Error(c, http.StatusServiceUnavailable, message, nil)
}

// 请求超时错误响应
func Timeout(c *gin.Context, message string) {
	Error(c, http.StatusRequestTimeout, message, nil)
}

// 限流错误响应
func RateLimit(c *gin.Context, message string) {
	Error(c, http.StatusTooManyRequests, message, nil)
}

// 分页成功响应
func PaginatedSuccess(c *gin.Context, data interface{}, pagination Pagination) {
	c.JSON(http.StatusOK, PaginatedSuccessResponse(data, pagination))
}

// 健康检查响应
func Health(c *gin.Context, service string, version string) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": service,
		"version": version,
	})
}

// 就绪检查响应
func Ready(c *gin.Context, service string) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "ready",
		"service": service,
	})
}



