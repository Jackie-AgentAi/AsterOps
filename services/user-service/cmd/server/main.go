package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/llmops/user-service/internal/app/handler"
	admininit "github.com/llmops/user-service/internal/app/init"
	"github.com/llmops/user-service/internal/app/middleware"
	"github.com/llmops/user-service/internal/app/router"
	"github.com/llmops/user-service/internal/domain/repository"
	"github.com/llmops/user-service/internal/domain/service"
	"github.com/llmops/user-service/internal/pkg/config"
	"github.com/llmops/user-service/internal/pkg/database"
	"github.com/llmops/user-service/internal/pkg/logger"
	"github.com/llmops/user-service/internal/pkg/redis"
	"github.com/llmops/user-service/internal/pkg/validator"
)

func main() {
	// 加载配置
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// 初始化日志
	appLogger := logger.NewLogger()

	appLogger.Info("Starting User Service")

	// 初始化数据库
	dbConfig := &database.DatabaseConfig{
		Host:            cfg.Database.Host,
		Port:            cfg.Database.Port,
		User:            cfg.Database.User,
		Password:        cfg.Database.Password,
		DBName:          cfg.Database.DBName,
		SSLMode:         cfg.Database.SSLMode,
		MaxOpenConns:    cfg.Database.MaxOpenConns,
		MaxIdleConns:    cfg.Database.MaxIdleConns,
		ConnMaxLifetime: cfg.Database.ConnMaxLifetime,
		ConnMaxIdleTime: cfg.Database.ConnMaxIdleTime,
		Debug:           cfg.Server.Debug,
	}

	db, err := database.NewDatabase(dbConfig)
	if err != nil {
		appLogger.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	appLogger.Info("Database connected successfully")

	// 初始化Redis
	redisConfig := &redis.RedisConfig{
		Addr:         cfg.Redis.Addr,
		Password:     cfg.Redis.Password,
		DB:           cfg.Redis.DB,
		PoolSize:     10,
		MinIdleConns: 5,
		MaxRetries:   3,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
		PoolTimeout:  4 * time.Second,
		IdleTimeout:  5 * time.Minute,
	}

	redisClient, err := redis.NewClient(redisConfig)
	if err != nil {
		appLogger.Fatalf("Failed to connect to redis: %v", err)
	}
	defer redisClient.Close()

	appLogger.Info("Redis connected successfully")

	// 设置Gin模式
	if !cfg.Server.Debug {
		gin.SetMode(gin.ReleaseMode)
	}

	// 创建Gin引擎
	ginRouter := gin.New()

	// 添加中间件
	ginRouter.Use(gin.Logger())
	ginRouter.Use(gin.Recovery())
	ginRouter.Use(middleware.CORSMiddleware())
	ginRouter.Use(middleware.LoggingMiddleware())

	// 健康检查路由
	healthHandler := func(c *gin.Context) {
		// 检查数据库连接
		if err := db.Ping(); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status": "unhealthy",
				"error":  "database connection failed",
			})
			return
		}

		// 检查Redis连接
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := redisClient.Ping(ctx); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status": "unhealthy",
				"error":  "redis connection failed",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"timestamp": time.Now().UTC(),
			"version":   "1.0.0",
			"service":   "github.com/llmops/user-service",
		})
	}
	
	ginRouter.GET("/health", healthHandler)
	ginRouter.HEAD("/health", healthHandler)

	// 就绪检查路由
	ginRouter.GET("/ready", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "ready",
		})
	})

	// 初始化验证器
	validator := validator.NewValidator()

	// 初始化仓储层
	userRepo := repository.NewUserRepository(db.DB)
	roleRepo := repository.NewRoleRepository(db.DB)
	_ = repository.NewPermissionRepository(db.DB) // 暂时不使用
	_ = repository.NewTenantRepository(db.DB)     // 暂时不使用
	sessionRepo := repository.NewUserSessionRepository(db.DB)
	groupRepo := repository.NewUserGroupRepository(db.DB) // 添加用户组仓储

	// 初始化服务层
	userService := service.NewUserService(userRepo, roleRepo, sessionRepo, groupRepo, appLogger, cfg.JWT.Secret, cfg.JWT.TokenExpiry, cfg.JWT.RefreshExpiry)
	authService := service.NewAuthService(userRepo, sessionRepo, appLogger, cfg.JWT.Secret, cfg.JWT.TokenExpiry, cfg.JWT.RefreshExpiry)
	groupService := service.NewUserGroupService(groupRepo, appLogger) // 添加用户组服务

	// 初始化admin用户和用户组
	adminInitService := admininit.NewAdminInitService(userRepo, groupRepo, groupRepo)
	ctx := context.Background()
	if err := adminInitService.InitializeAdminUser(ctx); err != nil {
		appLogger.Errorf("初始化admin用户和用户组失败: %v", err)
		// 不退出，继续运行，但记录错误
	} else {
		appLogger.Info("Admin用户和用户组初始化成功")
	}

	// 初始化处理器
	userHandler := handler.NewUserHandler(userService)
	authHandler := handler.NewAuthHandler(authService, validator)
	roleHandler := handler.NewRoleHandler(userService)
	permissionHandler := handler.NewPermissionHandler(userService)
	groupHandler := handler.NewUserGroupHandler(groupService) // 添加用户组处理器
	adminHandler := handler.NewAdminHandler(adminInitService) // 添加admin处理器


	// API路由组
	api := ginRouter.Group("/api/v1")
	{
		// 基础信息路由
		api.GET("/", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"message": "User Service API",
				"version": "1.0.0",
			})
		})

		// 设置路由
		router.SetupUserRoutes(api, userHandler, groupHandler, authHandler, adminHandler, middleware.AuthMiddleware())
		
		// 角色路由
		roles := api.Group("/roles")
		{
			roles.Use(middleware.AuthMiddleware())
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
		
		// 权限路由
		permissions := api.Group("/permissions")
		{
			permissions.Use(middleware.AuthMiddleware())
			{
				permissions.GET("/", permissionHandler.GetPermissions)
				permissions.POST("/", permissionHandler.CreatePermission)
				permissions.GET("/:id", permissionHandler.GetPermission)
				permissions.PUT("/:id", permissionHandler.UpdatePermission)
				permissions.DELETE("/:id", permissionHandler.DeletePermission)
			}
		}
	}

	// 创建HTTP服务器
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%d", cfg.Server.Port),
		Handler: ginRouter,
	}

	// 启动服务器
	go func() {
		appLogger.Infof("User Service starting on port %d", cfg.Server.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			appLogger.Fatalf("Failed to start server: %v", err)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	appLogger.Info("Shutting down User Service...")

	// 优雅关闭服务器
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		appLogger.Errorf("Server forced to shutdown: %v", err)
	}

	appLogger.Info("User Service exited")
}



