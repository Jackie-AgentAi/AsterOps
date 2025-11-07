package gateway

import (
	"api-gateway/internal/config"
	"api-gateway/internal/middleware"
	"context"
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/hashicorp/consul/api"
)

type Gateway struct {
	config     *config.Config
	consul     *api.Client
	httpClient *http.Client
}

func NewGateway(cfg *config.Config) *Gateway {
	// 创建Consul客户端
	consulConfig := api.DefaultConfig()
	consulConfig.Address = fmt.Sprintf("%s:%d", cfg.ConsulHost, cfg.ConsulPort)
	consulClient, _ := api.NewClient(consulConfig)
	
	// 创建HTTP客户端
	httpClient := &http.Client{
		Timeout: 30 * time.Second,
	}
	
	return &Gateway{
		config:     cfg,
		consul:     consulClient,
		httpClient: httpClient,
	}
}

// 代理到用户服务
func (g *Gateway) ProxyToUserService(c *gin.Context) {
	g.proxyToService(c, "user-service", "/api/v1")
}

// 代理到模型服务
func (g *Gateway) ProxyToModelService(c *gin.Context) {
	g.proxyToService(c, "model-service", "/api/v2")
}

// 代理到推理服务
func (g *Gateway) ProxyToInferenceService(c *gin.Context) {
	g.proxyToService(c, "inference-service", "/api/v3")
}

// 代理到成本服务
func (g *Gateway) ProxyToCostService(c *gin.Context) {
	g.proxyToService(c, "cost-service", "/api/v4")
}

// 代理到监控服务
func (g *Gateway) ProxyToMonitoringService(c *gin.Context) {
	g.proxyToService(c, "monitoring-service", "/api/v5")
}

// 代理到项目服务
func (g *Gateway) ProxyToProjectService(c *gin.Context) {
	g.proxyToService(c, "project-service", "/api/v6")
}

// 通用代理方法
func (g *Gateway) proxyToService(c *gin.Context, serviceName, apiPrefix string) {
	// 从Consul获取服务实例
	serviceInstances, err := g.getServiceInstances(serviceName)
	if err != nil || len(serviceInstances) == 0 {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"error": "Service unavailable",
			"message": fmt.Sprintf("Service %s is not available", serviceName),
		})
		return
	}
	
	// 负载均衡选择实例
	instance := g.selectInstance(serviceInstances)
	if instance == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"error": "No healthy instances available",
		})
		return
	}
	
	// 构建目标URL
	targetURL := fmt.Sprintf("http://%s:%d", instance.Address, instance.Port)
	target, err := url.Parse(targetURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Invalid target URL",
		})
		return
	}
	
	// 创建反向代理
	proxy := httputil.NewSingleHostReverseProxy(target)
	
	// 修改请求路径
	originalPath := c.Request.URL.Path
	c.Request.URL.Path = strings.TrimPrefix(originalPath, apiPrefix)
	
	// 设置代理修改器
	proxy.ModifyResponse = func(resp *http.Response) error {
		// 添加CORS头
		resp.Header.Set("Access-Control-Allow-Origin", "*")
		resp.Header.Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		resp.Header.Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		return nil
	}
	
	// 执行代理
	proxy.ServeHTTP(c.Writer, c.Request)
}

// 从Consul获取服务实例
func (g *Gateway) getServiceInstances(serviceName string) ([]*api.ServiceEntry, error) {
	services, _, err := g.consul.Health().Service(serviceName, "", true, nil)
	return services, err
}

// 负载均衡选择实例
func (g *Gateway) selectInstance(instances []*api.ServiceEntry) *api.ServiceEntry {
	if len(instances) == 0 {
		return nil
	}
	
	// 简单的轮询负载均衡
	// 这里可以实现更复杂的负载均衡算法
	return instances[0]
}

// 健康检查
func (g *Gateway) HealthCheck() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 检查Consul连接
		_, err := g.consul.Status().Leader()
		if err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status": "unhealthy",
				"reason": "consul_connection_failed",
			})
			return
		}
		
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
			"service": "api-gateway",
		})
	}
}



