package router

import (
	"api-gateway/internal/config"
	"api-gateway/internal/middleware"
	"api-gateway/internal/gateway"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine, cfg *config.Config) {
	// 创建网关实例
	gatewayInstance := gateway.NewGateway(cfg)
	
	// 添加认证中间件
	r.Use(middleware.AuthMiddleware(cfg))
	
	// 添加限流中间件
	r.Use(middleware.RateLimitMiddleware(cfg))
	
	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "healthy", "service": "api-gateway"})
	})
	
	// API路由组
	api := r.Group("/api")
	{
		// 用户服务路由
		api.Any("/v1/*path", gatewayInstance.ProxyToUserService)
		
		// 模型服务路由
		api.Any("/v2/*path", gatewayInstance.ProxyToModelService)
		
		// 推理服务路由
		api.Any("/v3/*path", gatewayInstance.ProxyToInferenceService)
		
		// 成本服务路由
		api.Any("/v4/*path", gatewayInstance.ProxyToCostService)
		
		// 监控服务路由
		api.Any("/v5/*path", gatewayInstance.ProxyToMonitoringService)
		
		// 项目服务路由
		api.Any("/v6/*path", gatewayInstance.ProxyToProjectService)
	}
}



