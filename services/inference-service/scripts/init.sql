-- 推理服务数据库初始化脚本

-- 创建数据库
CREATE DATABASE IF NOT EXISTS inference_db;

-- 使用数据库
\c inference_db;

-- 启用UUID扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 推理请求表
CREATE TABLE IF NOT EXISTS inference_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL,
    session_id UUID,
    user_id UUID,
    tenant_id UUID NOT NULL,
    request_data JSONB NOT NULL,
    response_data JSONB,
    status VARCHAR(50) DEFAULT 'pending',
    processing_time_ms INTEGER,
    gpu_memory_used BIGINT,
    cpu_usage FLOAT,
    memory_usage FLOAT,
    error_message TEXT,
    error_code VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 模型实例表
CREATE TABLE IF NOT EXISTS model_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL,
    instance_id VARCHAR(255) NOT NULL UNIQUE,
    status VARCHAR(50) DEFAULT 'loading',
    engine_type VARCHAR(50) NOT NULL,
    gpu_memory_used BIGINT,
    gpu_memory_total BIGINT,
    cpu_usage FLOAT,
    memory_usage FLOAT,
    memory_total BIGINT,
    requests_processed BIGINT DEFAULT 0,
    total_processing_time_ms BIGINT DEFAULT 0,
    average_processing_time_ms FLOAT,
    config JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP WITH TIME ZONE
);

-- 推理会话表
CREATE TABLE IF NOT EXISTS inference_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    model_id UUID NOT NULL,
    session_name VARCHAR(255),
    session_type VARCHAR(50) DEFAULT 'chat',
    status VARCHAR(50) DEFAULT 'active',
    is_streaming BOOLEAN DEFAULT false,
    config JSONB DEFAULT '{}',
    context JSONB DEFAULT '{}',
    request_count BIGINT DEFAULT 0,
    total_tokens BIGINT DEFAULT 0,
    total_cost FLOAT DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- 推理指标表
CREATE TABLE IF NOT EXISTS inference_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL,
    instance_id UUID,
    metric_name VARCHAR(100) NOT NULL,
    metric_value FLOAT NOT NULL,
    metric_unit VARCHAR(20),
    labels JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 推理缓存表
CREATE TABLE IF NOT EXISTS inference_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL,
    cache_key VARCHAR(255) NOT NULL UNIQUE,
    cache_data JSONB NOT NULL,
    hit_count BIGINT DEFAULT 0,
    last_hit_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 推理队列表
CREATE TABLE IF NOT EXISTS inference_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL,
    request_id UUID NOT NULL,
    priority INTEGER DEFAULT 0,
    status VARCHAR(50) DEFAULT 'queued',
    request_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 推理结果表
CREATE TABLE IF NOT EXISTS inference_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL,
    model_id UUID NOT NULL,
    session_id UUID,
    user_id UUID,
    tenant_id UUID NOT NULL,
    result_data JSONB NOT NULL,
    result_type VARCHAR(50) NOT NULL,
    confidence_score FLOAT,
    processing_time_ms INTEGER,
    tokens_generated INTEGER,
    tokens_consumed INTEGER,
    cost_amount DECIMAL(15,4),
    currency VARCHAR(3) DEFAULT 'USD',
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 服务配置表
CREATE TABLE IF NOT EXISTS service_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_name VARCHAR(100) NOT NULL,
    config_key VARCHAR(100) NOT NULL,
    config_value TEXT NOT NULL,
    config_type VARCHAR(50) DEFAULT 'string',
    is_encrypted BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(service_name, config_key)
);

-- 请求日志表
CREATE TABLE IF NOT EXISTS request_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL,
    model_id UUID NOT NULL,
    user_id UUID,
    tenant_id UUID NOT NULL,
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER NOT NULL,
    request_size BIGINT,
    response_size BIGINT,
    processing_time_ms INTEGER,
    error_message TEXT,
    user_agent VARCHAR(500),
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_inference_requests_model_id ON inference_requests(model_id);
CREATE INDEX IF NOT EXISTS idx_inference_requests_session_id ON inference_requests(session_id);
CREATE INDEX IF NOT EXISTS idx_inference_requests_user_id ON inference_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_inference_requests_tenant_id ON inference_requests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inference_requests_status ON inference_requests(status);
CREATE INDEX IF NOT EXISTS idx_inference_requests_created_at ON inference_requests(created_at);

CREATE INDEX IF NOT EXISTS idx_model_instances_model_id ON model_instances(model_id);
CREATE INDEX IF NOT EXISTS idx_model_instances_instance_id ON model_instances(instance_id);
CREATE INDEX IF NOT EXISTS idx_model_instances_status ON model_instances(status);
CREATE INDEX IF NOT EXISTS idx_model_instances_engine_type ON model_instances(engine_type);
CREATE INDEX IF NOT EXISTS idx_model_instances_created_at ON model_instances(created_at);

CREATE INDEX IF NOT EXISTS idx_inference_sessions_user_id ON inference_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_inference_sessions_tenant_id ON inference_sessions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inference_sessions_model_id ON inference_sessions(model_id);
CREATE INDEX IF NOT EXISTS idx_inference_sessions_status ON inference_sessions(status);
CREATE INDEX IF NOT EXISTS idx_inference_sessions_created_at ON inference_sessions(created_at);

CREATE INDEX IF NOT EXISTS idx_inference_metrics_model_id ON inference_metrics(model_id);
CREATE INDEX IF NOT EXISTS idx_inference_metrics_instance_id ON inference_metrics(instance_id);
CREATE INDEX IF NOT EXISTS idx_inference_metrics_metric_name ON inference_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_inference_metrics_timestamp ON inference_metrics(timestamp);

CREATE INDEX IF NOT EXISTS idx_inference_cache_model_id ON inference_cache(model_id);
CREATE INDEX IF NOT EXISTS idx_inference_cache_cache_key ON inference_cache(cache_key);
CREATE INDEX IF NOT EXISTS idx_inference_cache_expires_at ON inference_cache(expires_at);

CREATE INDEX IF NOT EXISTS idx_inference_queue_model_id ON inference_queue(model_id);
CREATE INDEX IF NOT EXISTS idx_inference_queue_request_id ON inference_queue(request_id);
CREATE INDEX IF NOT EXISTS idx_inference_queue_priority ON inference_queue(priority);
CREATE INDEX IF NOT EXISTS idx_inference_queue_status ON inference_queue(status);
CREATE INDEX IF NOT EXISTS idx_inference_queue_created_at ON inference_queue(created_at);

CREATE INDEX IF NOT EXISTS idx_inference_results_request_id ON inference_results(request_id);
CREATE INDEX IF NOT EXISTS idx_inference_results_model_id ON inference_results(model_id);
CREATE INDEX IF NOT EXISTS idx_inference_results_session_id ON inference_results(session_id);
CREATE INDEX IF NOT EXISTS idx_inference_results_user_id ON inference_results(user_id);
CREATE INDEX IF NOT EXISTS idx_inference_results_tenant_id ON inference_results(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inference_results_result_type ON inference_results(result_type);
CREATE INDEX IF NOT EXISTS idx_inference_results_created_at ON inference_results(created_at);

CREATE INDEX IF NOT EXISTS idx_service_configs_service_name ON service_configs(service_name);
CREATE INDEX IF NOT EXISTS idx_service_configs_config_key ON service_configs(config_key);
CREATE INDEX IF NOT EXISTS idx_service_configs_is_active ON service_configs(is_active);

CREATE INDEX IF NOT EXISTS idx_request_logs_request_id ON request_logs(request_id);
CREATE INDEX IF NOT EXISTS idx_request_logs_model_id ON request_logs(model_id);
CREATE INDEX IF NOT EXISTS idx_request_logs_user_id ON request_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_request_logs_tenant_id ON request_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_request_logs_endpoint ON request_logs(endpoint);
CREATE INDEX IF NOT EXISTS idx_request_logs_status_code ON request_logs(status_code);
CREATE INDEX IF NOT EXISTS idx_request_logs_created_at ON request_logs(created_at);

-- 创建复合索引
CREATE INDEX IF NOT EXISTS idx_inference_requests_model_status ON inference_requests(model_id, status);
CREATE INDEX IF NOT EXISTS idx_inference_requests_tenant_status ON inference_requests(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_inference_requests_user_created ON inference_requests(user_id, created_at);

CREATE INDEX IF NOT EXISTS idx_model_instances_model_status ON model_instances(model_id, status);
CREATE INDEX IF NOT EXISTS idx_model_instances_engine_status ON model_instances(engine_type, status);

CREATE INDEX IF NOT EXISTS idx_inference_sessions_user_model ON inference_sessions(user_id, model_id);
CREATE INDEX IF NOT EXISTS idx_inference_sessions_tenant_status ON inference_sessions(tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_inference_metrics_model_name ON inference_metrics(model_id, metric_name);
CREATE INDEX IF NOT EXISTS idx_inference_metrics_model_timestamp ON inference_metrics(model_id, timestamp);

CREATE INDEX IF NOT EXISTS idx_inference_queue_model_priority ON inference_queue(model_id, priority);
CREATE INDEX IF NOT EXISTS idx_inference_queue_model_status ON inference_queue(model_id, status);

CREATE INDEX IF NOT EXISTS idx_inference_results_model_tenant ON inference_results(model_id, tenant_id);
CREATE INDEX IF NOT EXISTS idx_inference_results_user_created ON inference_results(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_inference_results_tenant_type ON inference_results(tenant_id, result_type);

CREATE INDEX IF NOT EXISTS idx_request_logs_model_tenant ON request_logs(model_id, tenant_id);
CREATE INDEX IF NOT EXISTS idx_request_logs_user_created ON request_logs(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_request_logs_tenant_status ON request_logs(tenant_id, status_code);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有表添加更新时间触发器
CREATE TRIGGER update_model_instances_updated_at BEFORE UPDATE ON model_instances
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inference_sessions_updated_at BEFORE UPDATE ON inference_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inference_cache_updated_at BEFORE UPDATE ON inference_cache
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inference_results_updated_at BEFORE UPDATE ON inference_results
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_service_configs_updated_at BEFORE UPDATE ON service_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入示例数据
INSERT INTO model_instances (id, model_id, instance_id, status, engine_type, config, metadata) VALUES 
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'gpt-3.5-turbo-instance-1', 'active', 'vllm', '{"max_tokens": 4096, "temperature": 0.7}', '{"gpu_memory": "8GB", "model_size": "175B"}'),
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'bert-base-instance-1', 'active', 'transformers', '{"max_length": 512, "batch_size": 32}', '{"gpu_memory": "4GB", "model_size": "110M"}'),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', 'resnet-50-instance-1', 'active', 'onnx', '{"batch_size": 16, "input_size": 224}', '{"gpu_memory": "2GB", "model_size": "25M"}')
ON CONFLICT (id) DO NOTHING;



