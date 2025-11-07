package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	// 设置Gin模式
	gin.SetMode(gin.ReleaseMode)

	// 创建Gin引擎
	r := gin.New()
	r.Use(gin.Logger())
	r.Use(gin.Recovery())

	// 健康检查路由
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "cost-service",
			"version": "1.0.0",
		})
	})

	// 就绪检查路由
	r.GET("/ready", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "ready",
		})
	})

	// 根路径
	r.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Cost Service API",
			"version": "1.0.0",
		})
	})

	// API路由组
	api := r.Group("/api/v1")
	{
		// 成本记录路由
		api.POST("/costs", func(c *gin.Context) {
			c.JSON(201, gin.H{
				"success": true,
				"data": gin.H{
					"id":          "cost-123",
					"project_id":  "project-456",
					"cost_type":   "inference",
					"amount":      10.50,
					"currency":   "USD",
					"description": "Model inference cost",
					"created_at":  "2024-01-01T00:00:00Z",
				},
			})
		})

		api.GET("/costs/:id", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"success": true,
				"data": gin.H{
					"id":          c.Param("id"),
					"project_id":  "project-456",
					"cost_type":  "inference",
					"amount":      10.50,
					"currency":   "USD",
					"description": "Model inference cost",
					"created_at":  "2024-01-01T00:00:00Z",
				},
			})
		})

		api.GET("/costs", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"success": true,
				"data": gin.H{
					"costs": []gin.H{
						{
							"id":          "cost-123",
							"project_id":  "project-456",
							"cost_type":   "inference",
							"amount":      10.50,
							"currency":   "USD",
							"description": "Model inference cost",
							"created_at":  "2024-01-01T00:00:00Z",
						},
						{
							"id":          "cost-124",
							"project_id":  "project-456",
							"cost_type":   "training",
							"amount":      25.00,
							"currency":   "USD",
							"description": "Model training cost",
							"created_at":  "2024-01-01T01:00:00Z",
						},
					},
					"total": 2,
				},
			})
		})

		api.PUT("/costs/:id", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"success": true,
				"data": gin.H{
					"id":          c.Param("id"),
					"project_id":  "project-456",
					"cost_type":   "inference",
					"amount":      15.50,
					"currency":   "USD",
					"description": "Updated model inference cost",
					"updated_at":  "2024-01-01T02:00:00Z",
				},
			})
		})

		api.DELETE("/costs/:id", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"success": true,
				"message": "Cost record deleted successfully",
			})
		})

		// 成本分析路由
		api.GET("/costs/summary", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"success": true,
				"data": gin.H{
					"total_cost":   1000.0,
					"cost_by_type": gin.H{
						"inference": 500.0,
						"training":  300.0,
						"storage":   200.0,
					},
					"currency":     "USD",
					"generated_at": "2024-01-01T00:00:00Z",
				},
			})
		})

		api.POST("/costs/analysis", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"success": true,
				"data": gin.H{
					"id":           "analysis-123",
					"analysis_type": "summary",
					"period":       "monthly",
					"data": gin.H{
						"total_cost":   1000.0,
						"cost_by_type": gin.H{"inference": 500, "training": 300, "storage": 200},
						"currency":     "USD",
						"generated_at": "2024-01-01T00:00:00Z",
					},
				},
			})
		})

		api.GET("/costs/analysis/:id", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"success": true,
				"data": gin.H{
					"id":           c.Param("id"),
					"analysis_type": "summary",
					"period":       "monthly",
					"data": gin.H{
						"total_cost":   1000.0,
						"cost_by_type": gin.H{"inference": 500, "training": 300, "storage": 200},
						"currency":     "USD",
						"generated_at": "2024-01-01T00:00:00Z",
					},
				},
			})
		})

		// 预算管理路由
		api.GET("/budgets", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"success": true,
				"data": gin.H{
					"budgets": []gin.H{
						{
							"id":             "budget-123",
							"project_id":     "project-456",
							"name":           "Monthly Budget",
							"amount":         1000.0,
							"currency":       "USD",
							"period":         "monthly",
							"alert_threshold": 80.0,
							"status":         "active",
							"created_at":     "2024-01-01T00:00:00Z",
						},
					},
					"total": 1,
				},
			})
		})

		// 优化建议路由
		api.GET("/optimization/suggestions", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"success": true,
				"data": gin.H{
					"suggestions": []gin.H{
						{
							"id":               "opt-1",
							"title":            "Optimize Model Inference",
							"description":      "Consider using smaller models for non-critical tasks",
							"category":         "model",
							"priority":         "high",
							"potential_savings": 200.0,
							"currency":         "USD",
						},
						{
							"id":               "opt-2",
							"title":            "Reduce Storage Costs",
							"description":      "Archive old model versions and unused data",
							"category":         "storage",
							"priority":         "medium",
							"potential_savings": 150.0,
							"currency":         "USD",
						},
					},
					"total": 2,
				},
			})
		})
	}

	// 创建HTTP服务器
	srv := &http.Server{
		Addr:    ":8085",
		Handler: r,
	}

	// 启动服务器
	go func() {
		log.Println("Cost Service starting on port 8085")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down Cost Service...")

	// 优雅关闭服务器
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
	}

	log.Println("Cost Service exited")
}