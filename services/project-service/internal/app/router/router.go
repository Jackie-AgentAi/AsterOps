package router

import (
	"github.com/gin-gonic/gin"
	"github.com/llmops/project-service/internal/app/handler"
	"github.com/llmops/project-service/internal/app/middleware"
	"github.com/llmops/project-service/internal/domain/service"
	"github.com/llmops/project-service/internal/pkg/logger"
)

// SetupRouter 设置路由
func SetupRouter(
	projectService service.ProjectService,
	templateService service.ProjectTemplateService,
	logger logger.Logger,
) *gin.Engine {
	// 设置Gin模式
	gin.SetMode(gin.ReleaseMode)
	
	r := gin.New()
	
	// 添加中间件
	r.Use(middleware.CORS())
	r.Use(middleware.Logging(logger))
	r.Use(middleware.Recovery(logger))
	
	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
			"service": "project-service",
		})
	})
	
	r.GET("/ready", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ready",
			"service": "project-service",
		})
	})
	
	// 创建处理器
	projectHandler := handler.NewProjectHandler(projectService, logger)
	templateHandler := handler.NewProjectTemplateHandler(templateService, logger)
	
	// API路由组
	v1 := r.Group("/api/v1")
	{
		// 项目管理路由
		projects := v1.Group("/projects")
		{
			projects.POST("", projectHandler.CreateProject)
			projects.GET("", projectHandler.ListProjects)
			projects.GET("/search", projectHandler.SearchProjects)
			projects.GET("/:id", projectHandler.GetProject)
			projects.PUT("/:id", projectHandler.UpdateProject)
			projects.DELETE("/:id", projectHandler.DeleteProject)
			
			// 项目成员管理
			projects.POST("/:id/members", projectHandler.AddMember)
			projects.GET("/:id/members", projectHandler.GetMembers)
			projects.PUT("/:id/members/:member_id", projectHandler.UpdateMemberRole)
			projects.DELETE("/:id/members/:member_id", projectHandler.RemoveMember)
			
			// 项目活动日志
			projects.GET("/:id/activities", projectHandler.GetActivities)
		}
		
		// 项目模板路由
		templates := v1.Group("/templates")
		{
			templates.POST("", templateHandler.CreateTemplate)
			templates.GET("", templateHandler.ListTemplates)
			templates.GET("/search", templateHandler.SearchTemplates)
			templates.GET("/public", templateHandler.GetPublicTemplates)
			templates.GET("/category/:category", templateHandler.GetTemplatesByCategory)
			templates.POST("/create-project", templateHandler.CreateProjectFromTemplate)
			templates.GET("/:id", templateHandler.GetTemplate)
			templates.PUT("/:id", templateHandler.UpdateTemplate)
			templates.DELETE("/:id", templateHandler.DeleteTemplate)
		}
	}
	
	return r
}
