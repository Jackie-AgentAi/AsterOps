-- 推理服务数据库表结构
-- 生产环境初始化脚本

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 推理请求表
CREATE TABLE IF NOT EXISTS inference_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    project_id UUID,
    model_id UUID NOT NULL,
    model_version_id UUID,
    user_id UUID NOT NULL,
    request_id VARCHAR(255) UNIQUE,
    status VARCHAR(50) DEFAULT 'pending',
    input_data JSONB NOT NULL,
    output_data JSONB,
    error_message TEXT,
    processing_time_ms INTEGER,
    tokens_used INTEGER,
    cost DECIMAL(15,6),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 推理会话表
CREATE TABLE IF NOT EXISTS inference_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL,
    model_id UUID NOT NULL,
    session_name VARCHAR(255),
    status VARCHAR(50) DEFAULT 'active',
    context_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 推理配置表
CREATE TABLE IF NOT EXISTS inference_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    model_id UUID NOT NULL,
    config_data JSONB NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, name)
);

-- 推理性能指标表
CREATE TABLE IF NOT EXISTS inference_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,6) NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);

-- 推理队列表
CREATE TABLE IF NOT EXISTS inference_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    model_id UUID NOT NULL,
    priority INTEGER DEFAULT 0,
    status VARCHAR(50) DEFAULT 'queued',
    input_data JSONB NOT NULL,
    config_data JSONB DEFAULT '{}',
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 推理限制表
CREATE TABLE IF NOT EXISTS inference_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    user_id UUID,
    model_id UUID,
    limit_type VARCHAR(50) NOT NULL,
    limit_value INTEGER NOT NULL,
    time_window INTEGER NOT NULL,
    current_usage INTEGER DEFAULT 0,
    reset_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_inference_requests_tenant_id ON inference_requests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inference_requests_project_id ON inference_requests(project_id);
CREATE INDEX IF NOT EXISTS idx_inference_requests_model_id ON inference_requests(model_id);
CREATE INDEX IF NOT EXISTS idx_inference_requests_user_id ON inference_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_inference_requests_status ON inference_requests(status);
CREATE INDEX IF NOT EXISTS idx_inference_requests_created_at ON inference_requests(created_at);

CREATE INDEX IF NOT EXISTS idx_inference_sessions_tenant_id ON inference_sessions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inference_sessions_user_id ON inference_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_inference_sessions_model_id ON inference_sessions(model_id);
CREATE INDEX IF NOT EXISTS idx_inference_sessions_status ON inference_sessions(status);

CREATE INDEX IF NOT EXISTS idx_inference_configs_tenant_id ON inference_configs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inference_configs_model_id ON inference_configs(model_id);
CREATE INDEX IF NOT EXISTS idx_inference_configs_is_default ON inference_configs(is_default);

CREATE INDEX IF NOT EXISTS idx_inference_metrics_model_id ON inference_metrics(model_id);
CREATE INDEX IF NOT EXISTS idx_inference_metrics_metric_name ON inference_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_inference_metrics_recorded_at ON inference_metrics(recorded_at);

CREATE INDEX IF NOT EXISTS idx_inference_queue_tenant_id ON inference_queue(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inference_queue_model_id ON inference_queue(model_id);
CREATE INDEX IF NOT EXISTS idx_inference_queue_status ON inference_queue(status);
CREATE INDEX IF NOT EXISTS idx_inference_queue_priority ON inference_queue(priority);
CREATE INDEX IF NOT EXISTS idx_inference_queue_scheduled_at ON inference_queue(scheduled_at);

CREATE INDEX IF NOT EXISTS idx_inference_limits_tenant_id ON inference_limits(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inference_limits_user_id ON inference_limits(user_id);
CREATE INDEX IF NOT EXISTS idx_inference_limits_model_id ON inference_limits(model_id);
CREATE INDEX IF NOT EXISTS idx_inference_limits_limit_type ON inference_limits(limit_type);

-- 创建触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 创建更新时间触发器
CREATE TRIGGER update_inference_requests_updated_at BEFORE UPDATE ON inference_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inference_sessions_updated_at BEFORE UPDATE ON inference_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inference_configs_updated_at BEFORE UPDATE ON inference_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inference_limits_updated_at BEFORE UPDATE ON inference_limits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
