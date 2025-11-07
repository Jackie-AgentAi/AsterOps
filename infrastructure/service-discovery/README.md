# 服务发现 (Service Discovery)

## 服务概述

服务发现是LLMOps平台的基础设施组件，基于Consul实现服务注册、发现、健康检查、配置管理等功能。为微服务架构提供可靠的服务治理能力。

## 技术栈

- **服务发现**: Consul 1.16+
- **健康检查**: HTTP/TCP健康检查
- **配置管理**: Consul KV存储
- **服务网格**: Consul Connect (可选)

## 功能特性

### 核心功能
- ✅ **服务注册**: 自动服务注册和注销
- ✅ **服务发现**: 动态服务发现和负载均衡
- ✅ **健康检查**: 多类型健康检查支持
- ✅ **配置管理**: 分布式配置管理
- ✅ **服务网格**: 服务间通信加密
- ✅ **故障转移**: 自动故障检测和转移

### 技术特性
- ✅ **高可用**: 多节点集群部署
- ✅ **一致性**: Raft一致性算法
- ✅ **可扩展**: 水平扩展支持
- ✅ **安全**: ACL访问控制
- ✅ **监控**: 完整的监控指标
- ✅ **日志**: 结构化日志记录

## 服务架构

### Consul集群架构
```
┌─────────────────┐
│   Consul Server │  Leader节点
├─────────────────┤
│   Consul Server │  Follower节点
├─────────────────┤
│   Consul Server │  Follower节点
├─────────────────┤
│   Consul Client │  客户端节点
└─────────────────┘
```

### 服务注册流程
1. **服务启动** → 向Consul注册服务信息
2. **健康检查** → 定期检查服务健康状态
3. **服务发现** → 其他服务通过Consul发现服务
4. **负载均衡** → 基于健康状态进行负载均衡

## 配置管理

### Consul配置
```hcl
# consul.hcl
datacenter = "llmops-dc"
data_dir = "/consul/data"
log_level = "INFO"
server = true
bootstrap_expect = 3
ui_config {
  enabled = true
}
client_addr = "0.0.0.0"
bind_addr = "0.0.0.0"
retry_join = ["consul-1", "consul-2", "consul-3"]
```

### 服务注册配置
```json
{
  "ID": "user-service-1",
  "Name": "user-service",
  "Tags": ["api", "user", "auth"],
  "Address": "user-service",
  "Port": 8081,
  "Check": {
    "HTTP": "http://user-service:8081/health",
    "Interval": "10s",
    "Timeout": "3s"
  }
}
```

## 部署配置

### Docker Compose配置
```yaml
version: '3.8'

services:
  consul-1:
    image: consul:1.16
    hostname: consul-1
    ports:
      - "8500:8500"
    volumes:
      - consul1_data:/consul/data
    command: consul agent -server -bootstrap-expect=3 -ui -client=0.0.0.0 -bind=0.0.0.0 -retry-join=consul-2 -retry-join=consul-3
    networks:
      - llmops-network

  consul-2:
    image: consul:1.16
    hostname: consul-2
    volumes:
      - consul2_data:/consul/data
    command: consul agent -server -ui -client=0.0.0.0 -bind=0.0.0.0 -retry-join=consul-1 -retry-join=consul-3
    networks:
      - llmops-network

  consul-3:
    image: consul:1.16
    hostname: consul-3
    volumes:
      - consul3_data:/consul/data
    command: consul agent -server -ui -client=0.0.0.0 -bind=0.0.0.0 -retry-join=consul-1 -retry-join=consul-2
    networks:
      - llmops-network

volumes:
  consul1_data:
  consul2_data:
  consul3_data:

networks:
  llmops-network:
    driver: bridge
```

## 服务注册

### Go服务注册
```go
package main

import (
    "github.com/hashicorp/consul/api"
    "log"
)

func registerService() {
    client, err := api.NewClient(api.DefaultConfig())
    if err != nil {
        log.Fatal(err)
    }

    registration := &api.AgentServiceRegistration{
        ID:      "user-service-1",
        Name:    "user-service",
        Tags:    []string{"api", "user", "auth"},
        Port:    8081,
        Address: "user-service",
        Check: &api.AgentServiceCheck{
            HTTP:                           "http://user-service:8081/health",
            Interval:                       "10s",
            Timeout:                        "3s",
            DeregisterCriticalServiceAfter: "30s",
        },
    }

    err = client.Agent().ServiceRegister(registration)
    if err != nil {
        log.Fatal(err)
    }
}
```

### Python服务注册
```python
import consul

def register_service():
    c = consul.Consul()
    
    c.agent.service.register(
        name='model-service',
        service_id='model-service-1',
        address='model-service',
        port=8083,
        tags=['api', 'model', 'ml'],
        check=consul.Check.http('http://model-service:8083/health', interval='10s')
    )
```

## 服务发现

### Go服务发现
```go
func discoverService(serviceName string) ([]*api.ServiceEntry, error) {
    client, err := api.NewClient(api.DefaultConfig())
    if err != nil {
        return nil, err
    }

    services, _, err := client.Health().Service(serviceName, "", false, nil)
    if err != nil {
        return nil, err
    }

    return services, nil
}
```

### Python服务发现
```python
def discover_service(service_name):
    c = consul.Consul()
    services = c.health.service(service_name, passing=True)[1]
    return services
```

## 健康检查

### HTTP健康检查
```bash
# 检查服务健康状态
curl http://localhost:8500/v1/health/service/user-service

# 检查所有服务
curl http://localhost:8500/v1/catalog/services
```

### 健康检查配置
```json
{
  "Check": {
    "HTTP": "http://service:port/health",
    "Interval": "10s",
    "Timeout": "3s",
    "DeregisterCriticalServiceAfter": "30s"
  }
}
```

## 配置管理

### 存储配置
```bash
# 存储配置
consul kv put config/user-service/database_url "postgresql://user:password@localhost:5432/user_db"

# 获取配置
consul kv get config/user-service/database_url
```

### 监听配置变化
```go
func watchConfig(key string) {
    client, _ := api.NewClient(api.DefaultConfig())
    
    q := &api.QueryOptions{
        WaitIndex: 0,
    }
    
    for {
        kv, meta, err := client.KV().Get(key, q)
        if err != nil {
            log.Printf("Error: %v", err)
            continue
        }
        
        if kv != nil {
            log.Printf("Config updated: %s", string(kv.Value))
        }
        
        q.WaitIndex = meta.LastIndex
    }
}
```

## 监控和运维

### 健康检查
- `GET /v1/health/service/{service}` - 服务健康状态
- `GET /v1/catalog/services` - 所有服务列表
- `GET /v1/agent/services` - 本地代理服务

### 日志记录
- 结构化日志输出
- 服务注册日志
- 健康检查日志
- 配置变更日志

### 监控指标
- 服务注册数量
- 健康检查成功率
- 配置变更次数
- 集群一致性状态

## 安全考虑

### 数据安全
- 服务信息加密存储
- 敏感配置加密
- 传输层安全
- 访问控制列表

### 访问控制
- ACL权限控制
- 服务间认证
- 配置访问控制
- 审计日志记录

### 审计日志
- 服务注册记录
- 健康检查记录
- 配置变更记录
- 安全事件记录

## 扩展性

### 水平扩展
- 多节点集群
- 负载均衡支持
- 数据分片支持
- 跨数据中心复制

### 功能扩展
- 支持更多协议
- 支持更多健康检查类型
- 支持服务网格
- 支持配置模板

---

**文档版本**: 1.0.0  
**创建时间**: 2024-01-01  
**更新时间**: 2024-01-01  
**维护者**: LLMOps开发团队



