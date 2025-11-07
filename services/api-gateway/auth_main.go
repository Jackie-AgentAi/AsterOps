package main

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

// 服务配置
type ServiceConfig struct {
	Name string
	URL  string
}

// 用户信息
type UserInfo struct {
	ID       string   `json:"id"`
	Username string   `json:"username"`
	Email    string   `json:"email"`
	Roles    []string `json:"roles"`
	TenantID string   `json:"tenant_id"`
}

// 认证响应
type AuthResponse struct {
	Success bool     `json:"success"`
	Data    UserInfo `json:"data"`
	Error   string   `json:"error,omitempty"`
}

var services = map[string]ServiceConfig{
	"user":      {Name: "user-service", URL: "http://user-service:8081"},
	"project":   {Name: "project-service", URL: "http://project-service:8082"},
	"model":     {Name: "model-service", URL: "http://model-service:8083"},
	"inference": {Name: "inference-service", URL: "http://inference-service:8084"},
	"cost":      {Name: "cost-service", URL: "http://cost-service:8085"},
	"monitoring": {Name: "monitoring-service", URL: "http://monitoring-service:8086"},
}

// 公开API路径（不需要认证）
var publicPaths = map[string]bool{
	"/health":                    true,
	"/services":                  true,
	"/api/v1/auth/login":         true,
	"/api/v1/auth/register":      true,
	"/api/v1/auth/refresh":       true,
}

func main() {
	// 创建HTTP服务器
	mux := http.NewServeMux()

	// CORS中间件
	corsHandler := func(next http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			// 添加CORS头
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			
			// 处理预检请求
			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return
			}
			
			next(w, r)
		}
	}

	// 健康检查
	mux.HandleFunc("/health", corsHandler(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		response := map[string]interface{}{
			"service": "api-gateway",
			"status":  "healthy",
			"version": "1.0.0",
			"time":    time.Now().Format(time.RFC3339),
		}
		json.NewEncoder(w).Encode(response)
	}))

	// 服务状态
	mux.HandleFunc("/services", corsHandler(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(services)
	}))

	// 根路径
	mux.HandleFunc("/", corsHandler(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		response := map[string]interface{}{
			"message": "LLMOps API Gateway with Authentication",
			"version": "1.0.0",
			"services": map[string]string{
				"user":      "/api/v1/users",
				"project":   "/api/v1/projects",
				"model":     "/api/v1/models",
				"inference": "/api/v1/inference",
				"cost":      "/api/v1/costs",
				"monitoring": "/api/v1/monitoring",
			},
			"auth": map[string]string{
				"login":    "/api/v1/auth/login",
				"register": "/api/v1/auth/register",
				"refresh":  "/api/v1/auth/refresh",
			},
		}
		json.NewEncoder(w).Encode(response)
	}))

	// 用户服务代理（包含认证）
	mux.HandleFunc("/api/v1/users/", authMiddleware(createProxy("user")))
	mux.HandleFunc("/api/v1/auth/", createProxy("user")) // 认证相关API不需要额外认证
	
	// 用户服务健康检查（不需要认证）
	mux.HandleFunc("/api/v1/users/health", createProxy("user"))

	// 项目管理服务代理（需要认证）
	mux.HandleFunc("/api/v1/projects/", authMiddleware(createProxy("project")))
	
	// 项目管理服务健康检查（不需要认证）
	mux.HandleFunc("/api/v1/projects/health", createProxy("project"))

	// 模型服务代理（需要认证）
	mux.HandleFunc("/api/v1/models", authMiddleware(createProxy("model")))
	mux.HandleFunc("/api/v1/models/", authMiddleware(createProxy("model")))

	// 推理服务代理（需要认证）
	mux.HandleFunc("/api/v1/inference/", authMiddleware(createProxy("inference")))

	// 成本服务代理（需要认证）
	mux.HandleFunc("/api/v1/costs", authMiddleware(createProxy("cost")))
	mux.HandleFunc("/api/v1/costs/", authMiddleware(createProxy("cost")))

	// 监控服务代理（需要认证）
	mux.HandleFunc("/api/v1/monitoring/", authMiddleware(createProxy("monitoring")))

	// 创建HTTP服务器
	srv := &http.Server{
		Addr:    ":8087",
		Handler: mux,
	}

	// 启动服务器
	go func() {
		log.Println("API Gateway with Authentication starting on port 8087")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down API Gateway...")

	// 优雅关闭服务器
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
	}

	log.Println("API Gateway exited")
}

// 认证中间件
func authMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 检查是否为公开API
		if isPublicPath(r.URL.Path) {
			next(w, r)
			return
		}

		// 获取Authorization头
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			writeErrorResponse(w, "unauthorized", "Authorization header is required", http.StatusUnauthorized)
			return
		}

		// 检查Bearer格式
		if !strings.HasPrefix(authHeader, "Bearer ") {
			writeErrorResponse(w, "unauthorized", "Invalid authorization header format", http.StatusUnauthorized)
			return
		}

		token := strings.TrimPrefix(authHeader, "Bearer ")

		// 验证令牌并获取用户信息
		userInfo, err := validateToken(token)
		if err != nil {
			writeErrorResponse(w, "unauthorized", "Invalid or expired token", http.StatusUnauthorized)
			return
		}

		// 将用户信息添加到请求头中传递给后端服务
		r.Header.Set("X-User-ID", userInfo.ID)
		r.Header.Set("X-Username", userInfo.Username)
		r.Header.Set("X-Email", userInfo.Email)
		r.Header.Set("X-Tenant-ID", userInfo.TenantID)
		r.Header.Set("X-User-Roles", strings.Join(userInfo.Roles, ","))

		// 记录认证日志
		log.Printf("Authenticated user %s (%s) accessing %s", userInfo.Username, userInfo.ID, r.URL.Path)

		// 继续处理请求
		next(w, r)
	}
}

// 检查是否为公开API路径
func isPublicPath(path string) bool {
	// 精确匹配
	if publicPaths[path] {
		return true
	}

	// 检查认证相关路径
	if strings.HasPrefix(path, "/api/v1/auth/") {
		return true
	}

	return false
}

// 验证令牌并获取用户信息
func validateToken(token string) (*UserInfo, error) {
	// 简化的令牌验证 - 在实际应用中应该调用用户服务验证
	// 这里为了演示，直接返回模拟用户信息
	if token == "" {
		return nil, errors.New("empty token")
	}
	
	// 模拟用户信息
	userInfo := &UserInfo{
		ID:       "550e8400-e29b-41d4-a716-446655440001",
		Username: "testuser2",
		Email:    "test2@example.com",
		Roles:    []string{"user"},
		TenantID: "550e8400-e29b-41d4-a716-446655440000",
	}
	
	return userInfo, nil
}

// 创建反向代理
func createProxy(serviceName string) http.HandlerFunc {
	service, exists := services[serviceName]
	if !exists {
		return func(w http.ResponseWriter, r *http.Request) {
			writeErrorResponse(w, "service_not_found", "Service not found", http.StatusNotFound)
		}
	}

	target, err := url.Parse(service.URL)
	if err != nil {
		return func(w http.ResponseWriter, r *http.Request) {
			writeErrorResponse(w, "internal_error", "Invalid service URL", http.StatusInternalServerError)
		}
	}

	proxy := httputil.NewSingleHostReverseProxy(target)
	
	// 自定义代理修改器
	proxy.Director = func(req *http.Request) {
		req.URL.Scheme = target.Scheme
		req.URL.Host = target.Host
		req.URL.Path = singleJoiningSlash(target.Path, req.URL.Path)
		if target.RawQuery == "" || req.URL.RawQuery == "" {
			req.URL.RawQuery = target.RawQuery + req.URL.RawQuery
		} else {
			req.URL.RawQuery = target.RawQuery + "&" + req.URL.RawQuery
		}
		if req.Header.Get("User-Agent") == "" {
			req.Header.Set("User-Agent", "")
		}
		
		// 特殊处理健康检查路径
		if strings.HasSuffix(req.URL.Path, "/health") && (serviceName == "user" || serviceName == "project") {
			req.URL.Path = "/health"
		}
	}
	
	return func(w http.ResponseWriter, r *http.Request) {
		// 添加CORS头
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-User-ID, X-Username, X-Email, X-Tenant-ID, X-User-Roles")
		
		// 处理预检请求
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		// 记录请求
		userID := r.Header.Get("X-User-ID")
		if userID != "" {
			log.Printf("Proxying %s %s to %s (User: %s)", r.Method, r.URL.Path, service.Name, userID)
		} else {
			log.Printf("Proxying %s %s to %s", r.Method, r.URL.Path, service.Name)
		}
		
		proxy.ServeHTTP(w, r)
	}
}

// 辅助函数：连接路径
func singleJoiningSlash(a, b string) string {
	aslash := strings.HasSuffix(a, "/")
	bslash := strings.HasPrefix(b, "/")
	switch {
	case aslash && bslash:
		return a + b[1:]
	case !aslash && !bslash:
		return a + "/" + b
	}
	return a + b
}

// 写入错误响应
func writeErrorResponse(w http.ResponseWriter, errorType, message string, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	
	response := map[string]interface{}{
		"error":   errorType,
		"message": message,
	}
	
	json.NewEncoder(w).Encode(response)
}

