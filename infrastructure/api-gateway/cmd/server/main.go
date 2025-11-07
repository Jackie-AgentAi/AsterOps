package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"api-gateway/internal/gateway"
	"api-gateway/internal/middleware"
	"api-gateway/internal/router"
	"api-gateway/internal/config"

	"github.com/gin-gonic/gin"
	"github.com/gin-contrib/cors"
	"github.com/gin-contrib/requestid"
	"github.com/sirupsen/logrus"
)

func main() {
	// 加载配置
	cfg := config.Load()

	// 初始化日志
	logger := logrus.New()
	logger.SetLevel(logrus.InfoLevel)
	if cfg.Debug {
		logger.SetLevel(logrus.DebugLevel)
	}

	// 设置Gin模式
	if cfg.Debug {
		gin.SetMode(gin.DebugMode)
	} else {
		gin.SetMode(gin.ReleaseMode)
	}

	// 创建Gin引擎
	r := gin.New()

	// 添加中间件
	r.Use(gin.Logger())
	r.Use(gin.Recovery())
	r.Use(requestid.New())
	r.Use(middleware.LoggingMiddleware())
	r.Use(middleware.CORSMiddleware())
	r.Use(middleware.MetricsMiddleware())

	// 健康检查端点
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "api-gateway",
			"version": "1.0.0",
		})
	})

	r.GET("/ready", func(c *gin.Context) {
		// 检查服务发现连接
		// 检查Redis连接
		c.JSON(http.StatusOK, gin.H{
			"status":  "ready",
			"service": "api-gateway",
		})
	})

	// 根路径
	r.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "API Gateway",
			"version": "1.0.0",
			"docs":    "/swagger/index.html",
		})
	})

	// 注册路由
	router.SetupRoutes(r, cfg)

	// 启动服务器
	srv := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: r,
	}

	// 优雅关闭
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal("Failed to start server:", err)
		}
	}()

	logger.Info("API Gateway started on port ", cfg.Port)

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down API Gateway...")

	// 优雅关闭
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}

	logger.Info("API Gateway stopped")
}



