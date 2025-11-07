package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/llmops/project-service/internal/app/router"
	"github.com/llmops/project-service/internal/domain/repository"
	"github.com/llmops/project-service/internal/domain/service"
	"github.com/llmops/project-service/internal/pkg/config"
	"github.com/llmops/project-service/internal/pkg/database"
	"github.com/llmops/project-service/internal/pkg/logger"
)

func main() {
	// 加载配置
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// 创建日志器
	logger := logger.NewLoggerWithLevel(cfg.Log.Level)
	logger.Infof("Starting project service on port %s", cfg.Server.Port)

	// 连接数据库
	db, err := database.NewDB(&cfg.Database)
	if err != nil {
		logger.Fatalf("Failed to connect to database: %v", err)
	}

	// 自动迁移数据库表
	if err := database.AutoMigrate(db); err != nil {
		logger.Fatalf("Failed to migrate database: %v", err)
	}

	// 创建仓储层
	projectRepo := repository.NewProjectRepository(db)
	templateRepo := repository.NewProjectTemplateRepository(db)

	// 创建服务层
	projectService := service.NewProjectService(projectRepo, templateRepo, logger)
	templateService := service.NewProjectTemplateService(templateRepo, projectRepo, logger)

	// 设置路由
	r := router.SetupRouter(projectService, templateService, logger)

	// 创建HTTP服务器
	srv := &http.Server{
		Addr:         ":" + cfg.Server.Port,
		Handler:      r,
		ReadTimeout:  cfg.Server.ReadTimeout,
		WriteTimeout: cfg.Server.WriteTimeout,
		IdleTimeout:  cfg.Server.IdleTimeout,
	}

	// 启动服务器
	go func() {
		logger.Infof("Server starting on port %s", cfg.Server.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("Failed to start server: %v", err)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("Shutting down server...")

	// 优雅关闭服务器
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Errorf("Server forced to shutdown: %v", err)
	}

	logger.Info("Server exited")
}
