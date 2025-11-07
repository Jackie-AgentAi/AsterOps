-- 成本管理服务数据库初始化脚本

-- 创建数据库
CREATE DATABASE IF NOT EXISTS cost_db;

-- 使用数据库
\c cost_db;

-- 启用UUID扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 成本记录表
CREATE TABLE IF NOT EXISTS cost_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    model_id UUID,
    user_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    cost_type VARCHAR(50) NOT NULL,
    amount DECIMAL(15,4) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 预算表
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    amount DECIMAL(15,4) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    period VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    alert_threshold DECIMAL(5,2) DEFAULT 80.00,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 成本分析表
CREATE TABLE IF NOT EXISTS cost_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    analysis_type VARCHAR(50) NOT NULL,
    period VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    results JSONB,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 计费规则表
CREATE TABLE IF NOT EXISTS billing_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    rule_type VARCHAR(50) NOT NULL,
    rate DECIMAL(10,6) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    unit VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 成本优化表
CREATE TABLE IF NOT EXISTS cost_optimizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium',
    impact VARCHAR(20) DEFAULT 'medium',
    savings DECIMAL(15,4),
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'pending',
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 成本分配表
CREATE TABLE IF NOT EXISTS cost_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    cost_record_id UUID NOT NULL,
    allocation_type VARCHAR(50) NOT NULL,
    allocated_to VARCHAR(100) NOT NULL,
    allocated_amount DECIMAL(15,4) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    allocation_percentage DECIMAL(5,2),
    allocation_reason TEXT,
    created_by UUID NOT NULL,
    tenant_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 使用统计表
CREATE TABLE IF NOT EXISTS usage_statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,4) NOT NULL,
    metric_unit VARCHAR(20),
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    tenant_id UUID NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 成本优化建议表
CREATE TABLE IF NOT EXISTS cost_optimization_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    suggestion_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    potential_savings DECIMAL(15,4) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    implementation_effort VARCHAR(20) DEFAULT 'medium',
    priority_score INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    is_auto_generated BOOLEAN DEFAULT false,
    generated_by VARCHAR(100),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 项目表（来自项目服务）
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 模型表（来自模型服务）
CREATE TABLE IF NOT EXISTS models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    framework VARCHAR(100) NOT NULL,
    task_type VARCHAR(100) NOT NULL,
    owner_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 用户表（来自用户服务）
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    tenant_id UUID NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_cost_records_project_id ON cost_records(project_id);
CREATE INDEX IF NOT EXISTS idx_cost_records_model_id ON cost_records(model_id);
CREATE INDEX IF NOT EXISTS idx_cost_records_user_id ON cost_records(user_id);
CREATE INDEX IF NOT EXISTS idx_cost_records_tenant_id ON cost_records(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cost_records_cost_type ON cost_records(cost_type);
CREATE INDEX IF NOT EXISTS idx_cost_records_created_at ON cost_records(created_at);

CREATE INDEX IF NOT EXISTS idx_budgets_project_id ON budgets(project_id);
CREATE INDEX IF NOT EXISTS idx_budgets_period ON budgets(period);
CREATE INDEX IF NOT EXISTS idx_budgets_status ON budgets(status);
CREATE INDEX IF NOT EXISTS idx_budgets_start_date ON budgets(start_date);
CREATE INDEX IF NOT EXISTS idx_budgets_end_date ON budgets(end_date);

CREATE INDEX IF NOT EXISTS idx_cost_analyses_project_id ON cost_analyses(project_id);
CREATE INDEX IF NOT EXISTS idx_cost_analyses_analysis_type ON cost_analyses(analysis_type);
CREATE INDEX IF NOT EXISTS idx_cost_analyses_period ON cost_analyses(period);
CREATE INDEX IF NOT EXISTS idx_cost_analyses_start_date ON cost_analyses(start_date);
CREATE INDEX IF NOT EXISTS idx_cost_analyses_end_date ON cost_analyses(end_date);

CREATE INDEX IF NOT EXISTS idx_billing_rules_project_id ON billing_rules(project_id);
CREATE INDEX IF NOT EXISTS idx_billing_rules_rule_type ON billing_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_billing_rules_is_active ON billing_rules(is_active);

CREATE INDEX IF NOT EXISTS idx_cost_optimizations_project_id ON cost_optimizations(project_id);
CREATE INDEX IF NOT EXISTS idx_cost_optimizations_category ON cost_optimizations(category);
CREATE INDEX IF NOT EXISTS idx_cost_optimizations_priority ON cost_optimizations(priority);
CREATE INDEX IF NOT EXISTS idx_cost_optimizations_status ON cost_optimizations(status);

CREATE INDEX IF NOT EXISTS idx_cost_allocations_project_id ON cost_allocations(project_id);
CREATE INDEX IF NOT EXISTS idx_cost_allocations_cost_record_id ON cost_allocations(cost_record_id);
CREATE INDEX IF NOT EXISTS idx_cost_allocations_allocation_type ON cost_allocations(allocation_type);
CREATE INDEX IF NOT EXISTS idx_cost_allocations_allocated_to ON cost_allocations(allocated_to);
CREATE INDEX IF NOT EXISTS idx_cost_allocations_tenant_id ON cost_allocations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cost_allocations_created_at ON cost_allocations(created_at);

CREATE INDEX IF NOT EXISTS idx_usage_statistics_project_id ON usage_statistics(project_id);
CREATE INDEX IF NOT EXISTS idx_usage_statistics_resource_type ON usage_statistics(resource_type);
CREATE INDEX IF NOT EXISTS idx_usage_statistics_resource_id ON usage_statistics(resource_id);
CREATE INDEX IF NOT EXISTS idx_usage_statistics_metric_name ON usage_statistics(metric_name);
CREATE INDEX IF NOT EXISTS idx_usage_statistics_tenant_id ON usage_statistics(tenant_id);
CREATE INDEX IF NOT EXISTS idx_usage_statistics_period_start ON usage_statistics(period_start);
CREATE INDEX IF NOT EXISTS idx_usage_statistics_period_end ON usage_statistics(period_end);

CREATE INDEX IF NOT EXISTS idx_cost_optimization_suggestions_project_id ON cost_optimization_suggestions(project_id);
CREATE INDEX IF NOT EXISTS idx_cost_optimization_suggestions_suggestion_type ON cost_optimization_suggestions(suggestion_type);
CREATE INDEX IF NOT EXISTS idx_cost_optimization_suggestions_priority_score ON cost_optimization_suggestions(priority_score);
CREATE INDEX IF NOT EXISTS idx_cost_optimization_suggestions_status ON cost_optimization_suggestions(status);
CREATE INDEX IF NOT EXISTS idx_cost_optimization_suggestions_is_auto_generated ON cost_optimization_suggestions(is_auto_generated);

-- 创建复合索引
CREATE INDEX IF NOT EXISTS idx_cost_records_tenant_project ON cost_records(tenant_id, project_id);
CREATE INDEX IF NOT EXISTS idx_cost_records_tenant_type ON cost_records(tenant_id, cost_type);
CREATE INDEX IF NOT EXISTS idx_cost_records_tenant_created ON cost_records(tenant_id, created_at);

CREATE INDEX IF NOT EXISTS idx_budgets_project_status ON budgets(project_id, status);
CREATE INDEX IF NOT EXISTS idx_budgets_project_period ON budgets(project_id, period);
CREATE INDEX IF NOT EXISTS idx_budgets_project_dates ON budgets(project_id, start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_cost_analyses_project_type ON cost_analyses(project_id, analysis_type);
CREATE INDEX IF NOT EXISTS idx_cost_analyses_project_period ON cost_analyses(project_id, period);
CREATE INDEX IF NOT EXISTS idx_cost_analyses_project_dates ON cost_analyses(project_id, start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_billing_rules_project_type ON billing_rules(project_id, rule_type);
CREATE INDEX IF NOT EXISTS idx_billing_rules_project_active ON billing_rules(project_id, is_active);

CREATE INDEX IF NOT EXISTS idx_cost_optimizations_project_category ON cost_optimizations(project_id, category);
CREATE INDEX IF NOT EXISTS idx_cost_optimizations_project_priority ON cost_optimizations(project_id, priority);
CREATE INDEX IF NOT EXISTS idx_cost_optimizations_project_status ON cost_optimizations(project_id, status);

CREATE INDEX IF NOT EXISTS idx_cost_allocations_project_type ON cost_allocations(project_id, allocation_type);
CREATE INDEX IF NOT EXISTS idx_cost_allocations_project_tenant ON cost_allocations(project_id, tenant_id);
CREATE INDEX IF NOT EXISTS idx_cost_allocations_tenant_created ON cost_allocations(tenant_id, created_at);

CREATE INDEX IF NOT EXISTS idx_usage_statistics_project_resource ON usage_statistics(project_id, resource_type);
CREATE INDEX IF NOT EXISTS idx_usage_statistics_project_metric ON usage_statistics(project_id, metric_name);
CREATE INDEX IF NOT EXISTS idx_usage_statistics_tenant_period ON usage_statistics(tenant_id, period_start, period_end);

CREATE INDEX IF NOT EXISTS idx_cost_optimization_suggestions_project_type ON cost_optimization_suggestions(project_id, suggestion_type);
CREATE INDEX IF NOT EXISTS idx_cost_optimization_suggestions_project_priority ON cost_optimization_suggestions(project_id, priority_score);
CREATE INDEX IF NOT EXISTS idx_cost_optimization_suggestions_project_status ON cost_optimization_suggestions(project_id, status);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有表添加更新时间触发器
CREATE TRIGGER update_cost_records_updated_at BEFORE UPDATE ON cost_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cost_analyses_updated_at BEFORE UPDATE ON cost_analyses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_billing_rules_updated_at BEFORE UPDATE ON billing_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cost_optimizations_updated_at BEFORE UPDATE ON cost_optimizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cost_allocations_updated_at BEFORE UPDATE ON cost_allocations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_usage_statistics_updated_at BEFORE UPDATE ON usage_statistics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cost_optimization_suggestions_updated_at BEFORE UPDATE ON cost_optimization_suggestions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入示例数据
INSERT INTO projects (id, name, description, owner_id, tenant_id, status) VALUES 
('00000000-0000-0000-0000-000000000001', 'AI Research Project', 'Research project for AI model development', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'active'),
('00000000-0000-0000-0000-000000000002', 'ML Production Project', 'Production project for ML model deployment', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'active')
ON CONFLICT (id) DO NOTHING;

INSERT INTO models (id, name, description, framework, task_type, owner_id, tenant_id, status) VALUES 
('00000000-0000-0000-0000-000000000001', 'GPT-3.5-turbo', 'OpenAI GPT-3.5 Turbo model', 'openai', 'text-generation', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'active'),
('00000000-0000-0000-0000-000000000002', 'BERT-base', 'Google BERT base model', 'transformers', 'text-classification', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'active')
ON CONFLICT (id) DO NOTHING;

INSERT INTO users (id, username, email, tenant_id, is_active) VALUES 
('00000000-0000-0000-0000-000000000001', 'admin', 'admin@example.com', '00000000-0000-0000-0000-000000000001', true),
('00000000-0000-0000-0000-000000000002', 'user1', 'user1@example.com', '00000000-0000-0000-0000-000000000001', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO budgets (id, project_id, name, amount, currency, period, start_date, end_date, alert_threshold, status) VALUES 
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Monthly AI Research Budget', 10000.00, 'USD', 'monthly', '2024-01-01', '2024-01-31', 80.00, 'active'),
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'Quarterly ML Production Budget', 50000.00, 'USD', 'quarterly', '2024-01-01', '2024-03-31', 85.00, 'active')
ON CONFLICT (id) DO NOTHING;

INSERT INTO cost_records (id, project_id, model_id, user_id, tenant_id, cost_type, amount, currency, description, metadata) VALUES 
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'compute', 150.00, 'USD', 'GPU compute cost for model training', '{"gpu_hours": 10, "instance_type": "g4dn.xlarge"}'),
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'storage', 25.00, 'USD', 'Model storage cost', '{"storage_gb": 100, "storage_type": "ssd"}'),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'inference', 75.00, 'USD', 'Model inference cost', '{"requests": 1000, "tokens": 50000}')
ON CONFLICT (id) DO NOTHING;



