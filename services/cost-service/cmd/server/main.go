package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/llmops/cost-service/internal/app/handler"
	"github.com/llmops/cost-service/internal/app/middleware"
	"github.com/llmops/cost-service/internal/app/router"
	"github.com/llmops/cost-service/internal/pkg/config"
	"github.com/llmops/cost-service/internal/pkg/database"
	"github.com/llmops/cost-service/internal/pkg/logger"
	"github.com/llmops/cost-service/internal/pkg/redis"

	"github.com/gin-gonic/gin"
	"github.com/gin-contrib/cors"
	"github.com/gin-contrib/requestid"
	"github.com/sirupsen/logrus"
)

func main() {
	// 加载配置
	cfg := config.Load()

	// 初始化日志
	logger.Init(cfg.LogLevel, cfg.LogFormat)
	log := logger.GetLogger()

	// 初始化数据库
	db, err := database.Init(cfg.DatabaseURL)
	if err != nil {
		log.Fatal("Failed to initialize database:", err)
	}

	// 初始化Redis
	rdb, err := redis.Init(cfg.RedisURL)
	if err != nil {
		log.Fatal("Failed to initialize Redis:", err)
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
			"service": "github.com/llmops/cost-service",
			"version": "1.0.0",
		})
	})

	r.GET("/ready", func(c *gin.Context) {
		// 检查数据库连接
		if err := db.DB().Ping(); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status": "not_ready",
				"reason": "database_connection_failed",
			})
			return
		}

		// 检查Redis连接
		if err := rdb.Ping(context.Background()).Err(); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status": "not_ready",
				"reason": "redis_connection_failed",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"status":  "ready",
			"service": "github.com/llmops/cost-service",
		})
	})

	// 根路径
	r.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Cost Service API",
			"version": "1.0.0",
			"docs":    "/swagger/index.html",
		})
	})

	// 注册路由
	router.SetupRoutes(r, db, rdb, cfg)

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

	log.Info("Cost Service started on port ", cfg.Port)

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("Shutting down Cost Service...")

	// 优雅关闭
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}

	log.Info("Cost Service stopped")
}



