-- 模型管理服务数据库表结构
-- 生产环境初始化脚本

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 模型表
CREATE TABLE IF NOT EXISTS models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    project_id UUID,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    model_type VARCHAR(100) NOT NULL,
    framework VARCHAR(100),
    status VARCHAR(50) DEFAULT 'draft',
    visibility VARCHAR(50) DEFAULT 'private',
    tags JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}',
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, name)
);

-- 模型版本表
CREATE TABLE IF NOT EXISTS model_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    file_path VARCHAR(500),
    file_size BIGINT,
    checksum VARCHAR(64),
    status VARCHAR(50) DEFAULT 'uploading',
    performance_metrics JSONB DEFAULT '{}',
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(model_id, version)
);

-- 模型部署表
CREATE TABLE IF NOT EXISTS model_deployments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_version_id UUID NOT NULL REFERENCES model_versions(id) ON DELETE CASCADE,
    deployment_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    endpoint_url VARCHAR(500),
    replicas INTEGER DEFAULT 1,
    resource_requirements JSONB DEFAULT '{}',
    environment_variables JSONB DEFAULT '{}',
    health_check_config JSONB DEFAULT '{}',
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 模型性能指标表
CREATE TABLE IF NOT EXISTS model_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,6) NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    dataset_name VARCHAR(255),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);

-- 模型使用记录表
CREATE TABLE IF NOT EXISTS model_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    action VARCHAR(100) NOT NULL,
    details JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 模型标签表
CREATE TABLE IF NOT EXISTS model_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    tag_name VARCHAR(100) NOT NULL,
    tag_value VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(model_id, tag_name)
);

-- 模型评估表
CREATE TABLE IF NOT EXISTS model_evaluations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_version_id UUID NOT NULL REFERENCES model_versions(id) ON DELETE CASCADE,
    evaluation_name VARCHAR(255) NOT NULL,
    dataset_name VARCHAR(255) NOT NULL,
    metrics JSONB NOT NULL,
    status VARCHAR(50) DEFAULT 'running',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_by UUID NOT NULL
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_models_tenant_id ON models(tenant_id);
CREATE INDEX IF NOT EXISTS idx_models_project_id ON models(project_id);
CREATE INDEX IF NOT EXISTS idx_models_model_type ON models(model_type);
CREATE INDEX IF NOT EXISTS idx_models_status ON models(status);
CREATE INDEX IF NOT EXISTS idx_models_created_at ON models(created_at);

CREATE INDEX IF NOT EXISTS idx_model_versions_model_id ON model_versions(model_id);
CREATE INDEX IF NOT EXISTS idx_model_versions_version ON model_versions(version);
CREATE INDEX IF NOT EXISTS idx_model_versions_status ON model_versions(status);

CREATE INDEX IF NOT EXISTS idx_model_deployments_model_version_id ON model_deployments(model_version_id);
CREATE INDEX IF NOT EXISTS idx_model_deployments_status ON model_deployments(status);
CREATE INDEX IF NOT EXISTS idx_model_deployments_created_at ON model_deployments(created_at);

CREATE INDEX IF NOT EXISTS idx_model_metrics_model_id ON model_metrics(model_id);
CREATE INDEX IF NOT EXISTS idx_model_metrics_metric_name ON model_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_model_metrics_recorded_at ON model_metrics(recorded_at);

CREATE INDEX IF NOT EXISTS idx_model_usage_model_id ON model_usage(model_id);
CREATE INDEX IF NOT EXISTS idx_model_usage_user_id ON model_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_model_usage_action ON model_usage(action);
CREATE INDEX IF NOT EXISTS idx_model_usage_created_at ON model_usage(created_at);

CREATE INDEX IF NOT EXISTS idx_model_tags_model_id ON model_tags(model_id);
CREATE INDEX IF NOT EXISTS idx_model_tags_tag_name ON model_tags(tag_name);

CREATE INDEX IF NOT EXISTS idx_model_evaluations_model_version_id ON model_evaluations(model_version_id);
CREATE INDEX IF NOT EXISTS idx_model_evaluations_status ON model_evaluations(status);
CREATE INDEX IF NOT EXISTS idx_model_evaluations_started_at ON model_evaluations(started_at);

-- 创建触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 创建更新时间触发器
CREATE TRIGGER update_models_updated_at BEFORE UPDATE ON models
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_model_deployments_updated_at BEFORE UPDATE ON model_deployments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
