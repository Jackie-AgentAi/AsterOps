-- 监控服务数据库表结构
-- 生产环境初始化脚本

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 指标表
CREATE TABLE IF NOT EXISTS metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,6) NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    tags JSONB DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 告警表
CREATE TABLE IF NOT EXISTS alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    alert_name VARCHAR(255) NOT NULL,
    alert_type VARCHAR(100) NOT NULL,
    severity VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    message TEXT NOT NULL,
    source_service VARCHAR(100),
    metric_name VARCHAR(100),
    threshold_value DECIMAL(15,6),
    current_value DECIMAL(15,6),
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    acknowledged_by UUID,
    metadata JSONB DEFAULT '{}'
);

-- 告警规则表
CREATE TABLE IF NOT EXISTS alert_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    rule_name VARCHAR(255) NOT NULL,
    description TEXT,
    service_name VARCHAR(100) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    condition_operator VARCHAR(10) NOT NULL,
    threshold_value DECIMAL(15,6) NOT NULL,
    evaluation_interval INTEGER DEFAULT 60,
    severity VARCHAR(50) NOT NULL,
    is_enabled BOOLEAN DEFAULT TRUE,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 健康检查表
CREATE TABLE IF NOT EXISTS health_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    endpoint VARCHAR(500) NOT NULL,
    status VARCHAR(50) NOT NULL,
    response_time_ms INTEGER,
    status_code INTEGER,
    error_message TEXT,
    checked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);

-- 日志表
CREATE TABLE IF NOT EXISTS logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    log_level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    context JSONB DEFAULT '{}',
    user_id UUID,
    request_id VARCHAR(255),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 仪表板表
CREATE TABLE IF NOT EXISTS dashboards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    dashboard_config JSONB NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 通知配置表
CREATE TABLE IF NOT EXISTS notification_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    config_data JSONB NOT NULL,
    is_enabled BOOLEAN DEFAULT TRUE,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 监控报告表
CREATE TABLE IF NOT EXISTS monitoring_reports (
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
CREATE INDEX IF NOT EXISTS idx_metrics_tenant_id ON metrics(tenant_id);
CREATE INDEX IF NOT EXISTS idx_metrics_service_name ON metrics(service_name);
CREATE INDEX IF NOT EXISTS idx_metrics_metric_name ON metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_metrics_metric_type ON metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON metrics(timestamp);

CREATE INDEX IF NOT EXISTS idx_alerts_tenant_id ON alerts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_alerts_alert_type ON alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_alerts_severity ON alerts(severity);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
CREATE INDEX IF NOT EXISTS idx_alerts_triggered_at ON alerts(triggered_at);

CREATE INDEX IF NOT EXISTS idx_alert_rules_tenant_id ON alert_rules(tenant_id);
CREATE INDEX IF NOT EXISTS idx_alert_rules_service_name ON alert_rules(service_name);
CREATE INDEX IF NOT EXISTS idx_alert_rules_metric_name ON alert_rules(metric_name);
CREATE INDEX IF NOT EXISTS idx_alert_rules_is_enabled ON alert_rules(is_enabled);

CREATE INDEX IF NOT EXISTS idx_health_checks_tenant_id ON health_checks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_health_checks_service_name ON health_checks(service_name);
CREATE INDEX IF NOT EXISTS idx_health_checks_status ON health_checks(status);
CREATE INDEX IF NOT EXISTS idx_health_checks_checked_at ON health_checks(checked_at);

CREATE INDEX IF NOT EXISTS idx_logs_tenant_id ON logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_logs_service_name ON logs(service_name);
CREATE INDEX IF NOT EXISTS idx_logs_log_level ON logs(log_level);
CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_logs_user_id ON logs(user_id);
CREATE INDEX IF NOT EXISTS idx_logs_request_id ON logs(request_id);

CREATE INDEX IF NOT EXISTS idx_dashboards_tenant_id ON dashboards(tenant_id);
CREATE INDEX IF NOT EXISTS idx_dashboards_is_public ON dashboards(is_public);
CREATE INDEX IF NOT EXISTS idx_dashboards_created_by ON dashboards(created_by);

CREATE INDEX IF NOT EXISTS idx_notification_configs_tenant_id ON notification_configs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_notification_configs_notification_type ON notification_configs(notification_type);
CREATE INDEX IF NOT EXISTS idx_notification_configs_is_enabled ON notification_configs(is_enabled);

CREATE INDEX IF NOT EXISTS idx_monitoring_reports_tenant_id ON monitoring_reports(tenant_id);
CREATE INDEX IF NOT EXISTS idx_monitoring_reports_report_type ON monitoring_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_monitoring_reports_period_start ON monitoring_reports(period_start);
CREATE INDEX IF NOT EXISTS idx_monitoring_reports_generated_at ON monitoring_reports(generated_at);

-- 创建触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 创建更新时间触发器
CREATE TRIGGER update_alert_rules_updated_at BEFORE UPDATE ON alert_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dashboards_updated_at BEFORE UPDATE ON dashboards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notification_configs_updated_at BEFORE UPDATE ON notification_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入默认告警规则
INSERT INTO alert_rules (tenant_id, rule_name, description, service_name, metric_name, condition_operator, threshold_value, evaluation_interval, severity, created_by) VALUES 
    ('550e8400-e29b-41d4-a716-446655440000', 'High CPU Usage', 'CPU使用率过高告警', 'all', 'cpu_usage_percent', '>', 80.0, 60, 'warning', '550e8400-e29b-41d4-a716-446655440000'),
    ('550e8400-e29b-41d4-a716-446655440000', 'High Memory Usage', '内存使用率过高告警', 'all', 'memory_usage_percent', '>', 85.0, 60, 'warning', '550e8400-e29b-41d4-a716-446655440000'),
    ('550e8400-e29b-41d4-a716-446655440000', 'High Disk Usage', '磁盘使用率过高告警', 'all', 'disk_usage_percent', '>', 90.0, 60, 'critical', '550e8400-e29b-41d4-a716-446655440000'),
    ('550e8400-e29b-41d4-a716-446655440000', 'Service Down', '服务不可用告警', 'all', 'service_status', '=', 0, 30, 'critical', '550e8400-e29b-41d4-a716-446655440000'),
    ('550e8400-e29b-41d4-a716-446655440000', 'High Error Rate', '错误率过高告警', 'all', 'error_rate_percent', '>', 5.0, 60, 'warning', '550e8400-e29b-41d4-a716-446655440000')
ON CONFLICT DO NOTHING;
