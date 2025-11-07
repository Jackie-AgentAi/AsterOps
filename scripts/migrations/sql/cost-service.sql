-- 成本管理服务数据库表结构
-- 生产环境初始化脚本

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 成本记录表
CREATE TABLE IF NOT EXISTS cost_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    project_id UUID,
    user_id UUID,
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(255),
    service_name VARCHAR(100) NOT NULL,
    cost_amount DECIMAL(15,6) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    billing_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    billing_period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    usage_quantity DECIMAL(15,6),
    usage_unit VARCHAR(50),
    unit_price DECIMAL(15,6),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 预算表
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    project_id UUID,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    budget_amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    alert_threshold DECIMAL(5,2) DEFAULT 80.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 成本分析表
CREATE TABLE IF NOT EXISTS cost_analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    analysis_name VARCHAR(255) NOT NULL,
    analysis_type VARCHAR(100) NOT NULL,
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    total_cost DECIMAL(15,2) NOT NULL,
    cost_breakdown JSONB NOT NULL,
    insights JSONB DEFAULT '{}',
    recommendations JSONB DEFAULT '[]',
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 成本告警表
CREATE TABLE IF NOT EXISTS cost_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    budget_id UUID REFERENCES budgets(id) ON DELETE CASCADE,
    alert_type VARCHAR(50) NOT NULL,
    threshold_value DECIMAL(5,2) NOT NULL,
    current_value DECIMAL(5,2) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    sent_at TIMESTAMP WITH TIME ZONE,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    acknowledged_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 资源定价表
CREATE TABLE IF NOT EXISTS resource_pricing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    pricing_model VARCHAR(50) NOT NULL,
    unit_price DECIMAL(15,6) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    billing_unit VARCHAR(50) NOT NULL,
    effective_from TIMESTAMP WITH TIME ZONE NOT NULL,
    effective_to TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 成本优化建议表
CREATE TABLE IF NOT EXISTS cost_optimizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    project_id UUID,
    optimization_type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    potential_savings DECIMAL(15,2) NOT NULL,
    implementation_effort VARCHAR(50) NOT NULL,
    priority VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 成本报告表
CREATE TABLE IF NOT EXISTS cost_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    report_name VARCHAR(255) NOT NULL,
    report_type VARCHAR(100) NOT NULL,
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    report_data JSONB NOT NULL,
    file_path VARCHAR(500),
    generated_by UUID NOT NULL,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_cost_records_tenant_id ON cost_records(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cost_records_project_id ON cost_records(project_id);
CREATE INDEX IF NOT EXISTS idx_cost_records_user_id ON cost_records(user_id);
CREATE INDEX IF NOT EXISTS idx_cost_records_resource_type ON cost_records(resource_type);
CREATE INDEX IF NOT EXISTS idx_cost_records_service_name ON cost_records(service_name);
CREATE INDEX IF NOT EXISTS idx_cost_records_billing_period_start ON cost_records(billing_period_start);
CREATE INDEX IF NOT EXISTS idx_cost_records_created_at ON cost_records(created_at);

CREATE INDEX IF NOT EXISTS idx_budgets_tenant_id ON budgets(tenant_id);
CREATE INDEX IF NOT EXISTS idx_budgets_project_id ON budgets(project_id);
CREATE INDEX IF NOT EXISTS idx_budgets_is_active ON budgets(is_active);
CREATE INDEX IF NOT EXISTS idx_budgets_period_start ON budgets(period_start);

CREATE INDEX IF NOT EXISTS idx_cost_analyses_tenant_id ON cost_analyses(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cost_analyses_analysis_type ON cost_analyses(analysis_type);
CREATE INDEX IF NOT EXISTS idx_cost_analyses_period_start ON cost_analyses(period_start);

CREATE INDEX IF NOT EXISTS idx_cost_alerts_tenant_id ON cost_alerts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cost_alerts_budget_id ON cost_alerts(budget_id);
CREATE INDEX IF NOT EXISTS idx_cost_alerts_alert_type ON cost_alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_cost_alerts_status ON cost_alerts(status);
CREATE INDEX IF NOT EXISTS idx_cost_alerts_created_at ON cost_alerts(created_at);

CREATE INDEX IF NOT EXISTS idx_resource_pricing_tenant_id ON resource_pricing(tenant_id);
CREATE INDEX IF NOT EXISTS idx_resource_pricing_resource_type ON resource_pricing(resource_type);
CREATE INDEX IF NOT EXISTS idx_resource_pricing_is_active ON resource_pricing(is_active);
CREATE INDEX IF NOT EXISTS idx_resource_pricing_effective_from ON resource_pricing(effective_from);

CREATE INDEX IF NOT EXISTS idx_cost_optimizations_tenant_id ON cost_optimizations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cost_optimizations_project_id ON cost_optimizations(project_id);
CREATE INDEX IF NOT EXISTS idx_cost_optimizations_optimization_type ON cost_optimizations(optimization_type);
CREATE INDEX IF NOT EXISTS idx_cost_optimizations_priority ON cost_optimizations(priority);
CREATE INDEX IF NOT EXISTS idx_cost_optimizations_status ON cost_optimizations(status);

CREATE INDEX IF NOT EXISTS idx_cost_reports_tenant_id ON cost_reports(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cost_reports_report_type ON cost_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_cost_reports_period_start ON cost_reports(period_start);
CREATE INDEX IF NOT EXISTS idx_cost_reports_generated_at ON cost_reports(generated_at);

-- 创建触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 创建更新时间触发器
CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_resource_pricing_updated_at BEFORE UPDATE ON resource_pricing
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cost_optimizations_updated_at BEFORE UPDATE ON cost_optimizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入默认资源定价数据
INSERT INTO resource_pricing (tenant_id, resource_type, pricing_model, unit_price, currency, billing_unit, effective_from) VALUES 
    ('550e8400-e29b-41d4-a716-446655440000', 'cpu', 'per_hour', 0.05, 'USD', 'core', CURRENT_TIMESTAMP),
    ('550e8400-e29b-41d4-a716-446655440000', 'memory', 'per_hour', 0.01, 'USD', 'GB', CURRENT_TIMESTAMP),
    ('550e8400-e29b-41d4-a716-446655440000', 'gpu', 'per_hour', 1.00, 'USD', 'unit', CURRENT_TIMESTAMP),
    ('550e8400-e29b-41d4-a716-446655440000', 'storage', 'per_month', 0.10, 'USD', 'GB', CURRENT_TIMESTAMP),
    ('550e8400-e29b-41d4-a716-446655440000', 'inference', 'per_request', 0.001, 'USD', 'request', CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;
