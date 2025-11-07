# Consul配置文件
# 用于LLMOps平台的服务发现

# 数据中心名称
datacenter = "llmops-dc"

# 数据目录
data_dir = "/consul/data"

# 日志级别
log_level = "INFO"

# 服务器配置
server = true
bootstrap_expect = 3

# UI配置
ui_config {
  enabled = true
}

# 客户端配置
client_addr = "0.0.0.0"
bind_addr = "0.0.0.0"

# 重试加入配置
retry_join = ["consul-1", "consul-2", "consul-3"]

# 性能配置
performance {
  raft_multiplier = 1
}

# 网络配置
ports {
  grpc = 8502
}

# 连接配置
connect {
  enabled = true
}

# 安全配置
acl {
  enabled = false
  default_policy = "allow"
}

# 自动加密配置
auto_encrypt {
  allow_tls = true
}

# 加密配置
encrypt = "your-encryption-key-here"

# 服务配置
services {
  name = "consul"
  port = 8500
  tags = ["consul", "server"]
}

# 健康检查配置
checks {
  name = "consul-health"
  http = "http://localhost:8500/v1/status/leader"
  interval = "10s"
  timeout = "3s"
}



