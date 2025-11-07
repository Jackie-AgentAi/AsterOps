package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	// 创建HTTP服务器
	mux := http.NewServeMux()

	// 健康检查路由
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		response := map[string]string{
			"service": "cost-service",
			"status":  "healthy",
			"version": "1.0.0",
		}
		json.NewEncoder(w).Encode(response)
	})

	// 就绪检查路由
	mux.HandleFunc("/ready", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		response := map[string]string{"status": "ready"}
		json.NewEncoder(w).Encode(response)
	})

	// 根路径
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		response := map[string]string{
			"message": "Cost Service API",
			"version": "1.0.0",
		}
		json.NewEncoder(w).Encode(response)
	})

	// 创建HTTP服务器
	srv := &http.Server{
		Addr:    ":8085",
		Handler: mux,
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
