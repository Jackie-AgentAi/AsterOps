-- 模型管理服务数据库初始化脚本

-- 创建数据库
CREATE DATABASE IF NOT EXISTS model_db;

-- 使用数据库
\c model_db;

-- 启用UUID扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 模型表
CREATE TABLE IF NOT EXISTS models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    framework VARCHAR(100) NOT NULL,
    task_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    owner_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    is_public BOOLEAN DEFAULT false,
    tags TEXT[],
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 模型版本表
CREATE TABLE IF NOT EXISTS model_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    file_path VARCHAR(500),
    file_size BIGINT,
    checksum VARCHAR(64),
    status VARCHAR(50) DEFAULT 'active',
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(model_id, version)
);

-- 模型部署表
CREATE TABLE IF NOT EXISTS model_deployments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    model_version_id UUID NOT NULL REFERENCES model_versions(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    deployment_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    endpoint VARCHAR(500),
    replicas BIGINT DEFAULT 1,
    cpu_limit VARCHAR(50),
    memory_limit VARCHAR(50),
    gpu_limit VARCHAR(50),
    config JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 模型评测表
CREATE TABLE IF NOT EXISTS model_evaluations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    model_version_id UUID NOT NULL REFERENCES model_versions(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    dataset_id VARCHAR(255),
    evaluation_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    results JSONB,
    metrics JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 模型指标表
CREATE TABLE IF NOT EXISTS model_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deployment_id UUID NOT NULL REFERENCES model_deployments(id) ON DELETE CASCADE,
    metric_name VARCHAR(100) NOT NULL,
    metric_value VARCHAR(100) NOT NULL,
    metric_unit VARCHAR(20),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    labels JSONB
);

-- 模型文件表
CREATE TABLE IF NOT EXISTS model_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    model_version_id UUID NOT NULL REFERENCES model_versions(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    checksum VARCHAR(64) NOT NULL,
    storage_type VARCHAR(50) DEFAULT 'local',
    storage_config JSONB,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 模型元数据表
CREATE TABLE IF NOT EXISTS model_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    model_version_id UUID REFERENCES model_versions(id) ON DELETE CASCADE,
    metadata_key VARCHAR(100) NOT NULL,
    metadata_value TEXT NOT NULL,
    metadata_type VARCHAR(50) DEFAULT 'string',
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(model_id, model_version_id, metadata_key)
);

-- 模型使用统计表
CREATE TABLE IF NOT EXISTS model_usage_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    model_version_id UUID REFERENCES model_versions(id) ON DELETE CASCADE,
    deployment_id UUID REFERENCES model_deployments(id) ON DELETE CASCADE,
    user_id UUID,
    tenant_id UUID NOT NULL,
    usage_type VARCHAR(50) NOT NULL,
    usage_count BIGINT DEFAULT 0,
    usage_duration_ms BIGINT DEFAULT 0,
    tokens_processed BIGINT DEFAULT 0,
    cost_amount DECIMAL(15,4) DEFAULT 0.0,
    currency VARCHAR(3) DEFAULT 'USD',
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_models_name ON models(name);
CREATE INDEX IF NOT EXISTS idx_models_framework ON models(framework);
CREATE INDEX IF NOT EXISTS idx_models_task_type ON models(task_type);
CREATE INDEX IF NOT EXISTS idx_models_status ON models(status);
CREATE INDEX IF NOT EXISTS idx_models_owner_id ON models(owner_id);
CREATE INDEX IF NOT EXISTS idx_models_tenant_id ON models(tenant_id);
CREATE INDEX IF NOT EXISTS idx_models_is_public ON models(is_public);
CREATE INDEX IF NOT EXISTS idx_models_created_at ON models(created_at);

CREATE INDEX IF NOT EXISTS idx_model_versions_model_id ON model_versions(model_id);
CREATE INDEX IF NOT EXISTS idx_model_versions_version ON model_versions(version);
CREATE INDEX IF NOT EXISTS idx_model_versions_status ON model_versions(status);
CREATE INDEX IF NOT EXISTS idx_model_versions_created_at ON model_versions(created_at);

CREATE INDEX IF NOT EXISTS idx_model_deployments_model_id ON model_deployments(model_id);
CREATE INDEX IF NOT EXISTS idx_model_deployments_model_version_id ON model_deployments(model_version_id);
CREATE INDEX IF NOT EXISTS idx_model_deployments_name ON model_deployments(name);
CREATE INDEX IF NOT EXISTS idx_model_deployments_deployment_type ON model_deployments(deployment_type);
CREATE INDEX IF NOT EXISTS idx_model_deployments_status ON model_deployments(status);
CREATE INDEX IF NOT EXISTS idx_model_deployments_created_at ON model_deployments(created_at);

CREATE INDEX IF NOT EXISTS idx_model_evaluations_model_id ON model_evaluations(model_id);
CREATE INDEX IF NOT EXISTS idx_model_evaluations_model_version_id ON model_evaluations(model_version_id);
CREATE INDEX IF NOT EXISTS idx_model_evaluations_name ON model_evaluations(name);
CREATE INDEX IF NOT EXISTS idx_model_evaluations_evaluation_type ON model_evaluations(evaluation_type);
CREATE INDEX IF NOT EXISTS idx_model_evaluations_status ON model_evaluations(status);
CREATE INDEX IF NOT EXISTS idx_model_evaluations_created_at ON model_evaluations(created_at);

CREATE INDEX IF NOT EXISTS idx_model_metrics_deployment_id ON model_metrics(deployment_id);
CREATE INDEX IF NOT EXISTS idx_model_metrics_metric_name ON model_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_model_metrics_timestamp ON model_metrics(timestamp);

CREATE INDEX IF NOT EXISTS idx_model_files_model_id ON model_files(model_id);
CREATE INDEX IF NOT EXISTS idx_model_files_model_version_id ON model_files(model_version_id);
CREATE INDEX IF NOT EXISTS idx_model_files_file_name ON model_files(file_name);
CREATE INDEX IF NOT EXISTS idx_model_files_file_type ON model_files(file_type);
CREATE INDEX IF NOT EXISTS idx_model_files_storage_type ON model_files(storage_type);
CREATE INDEX IF NOT EXISTS idx_model_files_is_primary ON model_files(is_primary);

CREATE INDEX IF NOT EXISTS idx_model_metadata_model_id ON model_metadata(model_id);
CREATE INDEX IF NOT EXISTS idx_model_metadata_model_version_id ON model_metadata(model_version_id);
CREATE INDEX IF NOT EXISTS idx_model_metadata_metadata_key ON model_metadata(metadata_key);
CREATE INDEX IF NOT EXISTS idx_model_metadata_is_public ON model_metadata(is_public);

CREATE INDEX IF NOT EXISTS idx_model_usage_stats_model_id ON model_usage_stats(model_id);
CREATE INDEX IF NOT EXISTS idx_model_usage_stats_model_version_id ON model_usage_stats(model_version_id);
CREATE INDEX IF NOT EXISTS idx_model_usage_stats_deployment_id ON model_usage_stats(deployment_id);
CREATE INDEX IF NOT EXISTS idx_model_usage_stats_user_id ON model_usage_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_model_usage_stats_tenant_id ON model_usage_stats(tenant_id);
CREATE INDEX IF NOT EXISTS idx_model_usage_stats_usage_type ON model_usage_stats(usage_type);
CREATE INDEX IF NOT EXISTS idx_model_usage_stats_created_at ON model_usage_stats(created_at);

-- 创建复合索引
CREATE INDEX IF NOT EXISTS idx_models_tenant_status ON models(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_models_owner_status ON models(owner_id, status);
CREATE INDEX IF NOT EXISTS idx_models_public_status ON models(is_public, status);

CREATE INDEX IF NOT EXISTS idx_model_versions_model_version ON model_versions(model_id, version);
CREATE INDEX IF NOT EXISTS idx_model_versions_model_status ON model_versions(model_id, status);

CREATE INDEX IF NOT EXISTS idx_model_deployments_model_status ON model_deployments(model_id, status);
CREATE INDEX IF NOT EXISTS idx_model_deployments_type_status ON model_deployments(deployment_type, status);

CREATE INDEX IF NOT EXISTS idx_model_evaluations_model_status ON model_evaluations(model_id, status);
CREATE INDEX IF NOT EXISTS idx_model_evaluations_type_status ON model_evaluations(evaluation_type, status);

CREATE INDEX IF NOT EXISTS idx_model_metrics_deployment_name ON model_metrics(deployment_id, metric_name);
CREATE INDEX IF NOT EXISTS idx_model_metrics_timestamp ON model_metrics(timestamp);

CREATE INDEX IF NOT EXISTS idx_model_files_model_version ON model_files(model_id, model_version_id);
CREATE INDEX IF NOT EXISTS idx_model_files_model_primary ON model_files(model_id, is_primary);

CREATE INDEX IF NOT EXISTS idx_model_metadata_model_version ON model_metadata(model_id, model_version_id);
CREATE INDEX IF NOT EXISTS idx_model_metadata_model_public ON model_metadata(model_id, is_public);

CREATE INDEX IF NOT EXISTS idx_model_usage_stats_model_tenant ON model_usage_stats(model_id, tenant_id);
CREATE INDEX IF NOT EXISTS idx_model_usage_stats_model_type ON model_usage_stats(model_id, usage_type);
CREATE INDEX IF NOT EXISTS idx_model_usage_stats_tenant_type ON model_usage_stats(tenant_id, usage_type);
CREATE INDEX IF NOT EXISTS idx_model_usage_stats_tenant_created ON model_usage_stats(tenant_id, created_at);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有表添加更新时间触发器
CREATE TRIGGER update_models_updated_at BEFORE UPDATE ON models
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_model_versions_updated_at BEFORE UPDATE ON model_versions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_model_deployments_updated_at BEFORE UPDATE ON model_deployments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_model_evaluations_updated_at BEFORE UPDATE ON model_evaluations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_model_files_updated_at BEFORE UPDATE ON model_files
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_model_metadata_updated_at BEFORE UPDATE ON model_metadata
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_model_usage_stats_updated_at BEFORE UPDATE ON model_usage_stats
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入示例数据
INSERT INTO models (id, name, description, framework, task_type, status, owner_id, tenant_id, is_public, tags, metadata) VALUES 
('00000000-0000-0000-0000-000000000001', 'GPT-3.5-turbo', 'OpenAI GPT-3.5 Turbo model', 'openai', 'text-generation', 'active', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true, ARRAY['nlp', 'text', 'generation'], '{"provider": "openai", "model_size": "175B"}'),
('00000000-0000-0000-0000-000000000002', 'BERT-base', 'Google BERT base model', 'transformers', 'text-classification', 'active', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true, ARRAY['nlp', 'classification', 'bert'], '{"provider": "huggingface", "model_size": "110M"}'),
('00000000-0000-0000-0000-000000000003', 'ResNet-50', 'ResNet-50 image classification model', 'pytorch', 'image-classification', 'active', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true, ARRAY['cv', 'classification', 'resnet'], '{"provider": "pytorch", "model_size": "25M"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO model_versions (id, model_id, version, description, file_path, file_size, checksum, status, metadata) VALUES 
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '1.0.0', 'Initial version', '/models/gpt-3.5-turbo-v1.0.0.pt', 1024000000, 'abc123def456', 'active', '{"accuracy": 0.95, "latency": 100}'),
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', '1.0.0', 'Initial version', '/models/bert-base-v1.0.0.pt', 512000000, 'def456ghi789', 'active', '{"accuracy": 0.92, "latency": 50}'),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', '1.0.0', 'Initial version', '/models/resnet-50-v1.0.0.pt', 256000000, 'ghi789jkl012', 'active', '{"accuracy": 0.88, "latency": 30}')
ON CONFLICT (id) DO NOTHING;



