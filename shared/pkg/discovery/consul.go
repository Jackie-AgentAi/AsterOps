package discovery

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"sync"
	"time"

	"github.com/hashicorp/consul/api"
)

// Consul服务发现管理器
type ConsulDiscovery struct {
	client   *api.Client
	services map[string][]*api.ServiceEntry
	mutex    sync.RWMutex
	config   ConsulConfig
}

// Consul配置
type ConsulConfig struct {
	Host    string
	Port    int
	Timeout time.Duration
}

// 服务选择器接口
type ServiceSelector interface {
	Select(services []*api.ServiceEntry) *api.ServiceEntry
}

// 随机选择器
type RandomSelector struct{}

func (r *RandomSelector) Select(services []*api.ServiceEntry) *api.ServiceEntry {
	if len(services) == 0 {
		return nil
	}
	return services[rand.Intn(len(services))]
}

// 轮询选择器
type RoundRobinSelector struct {
	index int
	mutex sync.Mutex
}

func (r *RoundRobinSelector) Select(services []*api.ServiceEntry) *api.ServiceEntry {
	if len(services) == 0 {
		return nil
	}
	
	r.mutex.Lock()
	defer r.mutex.Unlock()
	
	service := services[r.index%len(services)]
	r.index++
	return service
}

// 加权选择器
type WeightedSelector struct{}

func (w *WeightedSelector) Select(services []*api.ServiceEntry) *api.ServiceEntry {
	if len(services) == 0 {
		return nil
	}
	
	// 简单的加权选择（可以根据服务健康状态、负载等调整权重）
	totalWeight := 0
	for _, service := range services {
		weight := 1
		if service.Checks.AggregatedStatus() == api.HealthPassing {
			weight = 2
		}
		totalWeight += weight
	}
	
	if totalWeight == 0 {
		return services[0]
	}
	
	random := rand.Intn(totalWeight)
	current := 0
	
	for _, service := range services {
		weight := 1
		if service.Checks.AggregatedStatus() == api.HealthPassing {
			weight = 2
		}
		current += weight
		if random < current {
			return service
		}
	}
	
	return services[0]
}

// 创建Consul服务发现
func NewConsulDiscovery(config ConsulConfig) (*ConsulDiscovery, error) {
	consulConfig := api.DefaultConfig()
	consulConfig.Address = fmt.Sprintf("%s:%d", config.Host, config.Port)
	
	client, err := api.NewClient(consulConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create consul client: %w", err)
	}
	
	discovery := &ConsulDiscovery{
		client:   client,
		services: make(map[string][]*api.ServiceEntry),
		config:   config,
	}
	
	// 启动服务发现
	go discovery.startDiscovery()
	
	return discovery, nil
}

// 启动服务发现
func (c *ConsulDiscovery) startDiscovery() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()
	
	for {
		select {
		case <-ticker.C:
			c.refreshServices()
		}
	}
}

// 刷新服务列表
func (c *ConsulDiscovery) refreshServices() {
	c.mutex.Lock()
	defer c.mutex.Unlock()
	
	// 获取所有服务
	services, _, err := c.client.Catalog().Services(nil)
	if err != nil {
		log.Printf("Failed to get services: %v", err)
		return
	}
	
	// 更新每个服务的实例
	for serviceName := range services {
		instances, _, err := c.client.Health().Service(serviceName, "", true, nil)
		if err != nil {
			log.Printf("Failed to get service instances for %s: %v", serviceName, err)
			continue
		}
		
		c.services[serviceName] = instances
	}
}

// 获取服务实例
func (c *ConsulDiscovery) GetService(serviceName string, selector ServiceSelector) (*api.ServiceEntry, error) {
	c.mutex.RLock()
	services, exists := c.services[serviceName]
	c.mutex.RUnlock()
	
	if !exists || len(services) == 0 {
		// 实时查询服务
		instances, _, err := c.client.Health().Service(serviceName, "", true, nil)
		if err != nil {
			return nil, fmt.Errorf("failed to get service %s: %w", serviceName, err)
		}
		
		if len(instances) == 0 {
			return nil, fmt.Errorf("no healthy instances found for service %s", serviceName)
		}
		
		services = instances
	}
	
	if selector == nil {
		selector = &RandomSelector{}
	}
	
	instance := selector.Select(services)
	if instance == nil {
		return nil, fmt.Errorf("no available instances for service %s", serviceName)
	}
	
	return instance, nil
}

// 注册服务
func (c *ConsulDiscovery) RegisterService(serviceName, serviceID, address string, port int, tags []string, check *api.AgentServiceCheck) error {
	registration := &api.AgentServiceRegistration{
		ID:      serviceID,
		Name:    serviceName,
		Tags:    tags,
		Port:    port,
		Address: address,
		Check:   check,
	}
	
	return c.client.Agent().ServiceRegister(registration)
}

// 注销服务
func (c *ConsulDiscovery) DeregisterService(serviceID string) error {
	return c.client.Agent().ServiceDeregister(serviceID)
}

// 健康检查
func (c *ConsulDiscovery) HealthCheck(serviceName string) error {
	services, _, err := c.client.Health().Service(serviceName, "", true, nil)
	if err != nil {
		return err
	}
	
	if len(services) == 0 {
		return fmt.Errorf("no healthy instances for service %s", serviceName)
	}
	
	return nil
}

// 获取服务地址
func (c *ConsulDiscovery) GetServiceAddress(serviceName string, selector ServiceSelector) (string, error) {
	instance, err := c.GetService(serviceName, selector)
	if err != nil {
		return "", err
	}
	
	return fmt.Sprintf("%s:%d", instance.Service.Address, instance.Service.Port), nil
}

// 服务发现客户端
type ServiceClient struct {
	discovery *ConsulDiscovery
	selector  ServiceSelector
}

// 创建服务客户端
func NewServiceClient(discovery *ConsulDiscovery, selector ServiceSelector) *ServiceClient {
	if selector == nil {
		selector = &RandomSelector{}
	}
	
	return &ServiceClient{
		discovery: discovery,
		selector:  selector,
	}
}

// 调用服务
func (c *ServiceClient) CallService(ctx context.Context, serviceName, path string) (string, error) {
	address, err := c.discovery.GetServiceAddress(serviceName, c.selector)
	if err != nil {
		return "", err
	}
	
	// 这里应该实现HTTP客户端调用
	// 为了简化，直接返回地址
	return fmt.Sprintf("http://%s%s", address, path), nil
}

// 服务发现工厂
type DiscoveryFactory struct {
	consul *ConsulDiscovery
}

// 创建服务发现工厂
func NewDiscoveryFactory(config ConsulConfig) (*DiscoveryFactory, error) {
	consul, err := NewConsulDiscovery(config)
	if err != nil {
		return nil, err
	}
	
	return &DiscoveryFactory{
		consul: consul,
	}, nil
}

// 获取用户服务客户端
func (f *DiscoveryFactory) GetUserServiceClient() *ServiceClient {
	return NewServiceClient(f.consul, &RoundRobinSelector{})
}

// 获取模型服务客户端
func (f *DiscoveryFactory) GetModelServiceClient() *ServiceClient {
	return NewServiceClient(f.consul, &WeightedSelector{})
}

// 获取推理服务客户端
func (f *DiscoveryFactory) GetInferenceServiceClient() *ServiceClient {
	return NewServiceClient(f.consul, &WeightedSelector{})
}

// 获取成本服务客户端
func (f *DiscoveryFactory) GetCostServiceClient() *ServiceClient {
	return NewServiceClient(f.consul, &RoundRobinSelector{})
}

// 获取监控服务客户端
func (f *DiscoveryFactory) GetMonitoringServiceClient() *ServiceClient {
	return NewServiceClient(f.consul, &RandomSelector{})
}

// 获取项目服务客户端
func (f *DiscoveryFactory) GetProjectServiceClient() *ServiceClient {
	return NewServiceClient(f.consul, &RoundRobinSelector{})
}



