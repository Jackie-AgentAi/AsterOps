-- 评测管理服务数据库初始化脚本

-- 创建数据库
CREATE DATABASE IF NOT EXISTS evaluation_db;

-- 使用数据库
\c evaluation_db;

-- 启用UUID扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 评测任务表
CREATE TABLE IF NOT EXISTS evaluation_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    model_id UUID NOT NULL,
    model_version_id UUID,
    dataset_id VARCHAR(255),
    evaluation_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    config JSONB DEFAULT '{}',
    results JSONB,
    metrics JSONB,
    created_by UUID NOT NULL,
    tenant_id UUID NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 评测指标表
CREATE TABLE IF NOT EXISTS evaluation_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES evaluation_tasks(id) ON DELETE CASCADE,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,6) NOT NULL,
    metric_unit VARCHAR(20),
    metric_type VARCHAR(50) NOT NULL,
    threshold_value DECIMAL(15,6),
    is_passed BOOLEAN,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 评测数据集表
CREATE TABLE IF NOT EXISTS evaluation_datasets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    dataset_type VARCHAR(50) NOT NULL,
    file_path VARCHAR(500),
    file_size BIGINT,
    checksum VARCHAR(64),
    total_samples INTEGER NOT NULL,
    metadata JSONB,
    created_by UUID NOT NULL,
    tenant_id UUID NOT NULL,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 评测报告表
CREATE TABLE IF NOT EXISTS evaluation_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES evaluation_tasks(id) ON DELETE CASCADE,
    report_name VARCHAR(255) NOT NULL,
    report_type VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    file_path VARCHAR(500),
    file_size BIGINT,
    is_public BOOLEAN DEFAULT false,
    created_by UUID NOT NULL,
    tenant_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 评测基准表
CREATE TABLE IF NOT EXISTS evaluation_benchmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    benchmark_type VARCHAR(50) NOT NULL,
    domain VARCHAR(100),
    language VARCHAR(50),
    difficulty VARCHAR(20),
    total_tasks INTEGER NOT NULL,
    config JSONB DEFAULT '{}',
    is_public BOOLEAN DEFAULT false,
    created_by UUID NOT NULL,
    tenant_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 评测结果详情表
CREATE TABLE IF NOT EXISTS evaluation_result_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES evaluation_tasks(id) ON DELETE CASCADE,
    sample_id VARCHAR(255) NOT NULL,
    input_data JSONB NOT NULL,
    expected_output JSONB,
    actual_output JSONB,
    is_correct BOOLEAN,
    score DECIMAL(5,4),
    error_message TEXT,
    processing_time_ms INTEGER,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_evaluation_tasks_model_id ON evaluation_tasks(model_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_tasks_model_version_id ON evaluation_tasks(model_version_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_tasks_evaluation_type ON evaluation_tasks(evaluation_type);
CREATE INDEX IF NOT EXISTS idx_evaluation_tasks_status ON evaluation_tasks(status);
CREATE INDEX IF NOT EXISTS idx_evaluation_tasks_created_by ON evaluation_tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_evaluation_tasks_tenant_id ON evaluation_tasks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_tasks_created_at ON evaluation_tasks(created_at);

CREATE INDEX IF NOT EXISTS idx_evaluation_metrics_task_id ON evaluation_metrics(task_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_metrics_metric_name ON evaluation_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_evaluation_metrics_metric_type ON evaluation_metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_evaluation_metrics_is_passed ON evaluation_metrics(is_passed);

CREATE INDEX IF NOT EXISTS idx_evaluation_datasets_name ON evaluation_datasets(name);
CREATE INDEX IF NOT EXISTS idx_evaluation_datasets_dataset_type ON evaluation_datasets(dataset_type);
CREATE INDEX IF NOT EXISTS idx_evaluation_datasets_created_by ON evaluation_datasets(created_by);
CREATE INDEX IF NOT EXISTS idx_evaluation_datasets_tenant_id ON evaluation_datasets(tenant_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_datasets_is_public ON evaluation_datasets(is_public);

CREATE INDEX IF NOT EXISTS idx_evaluation_reports_task_id ON evaluation_reports(task_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_reports_report_type ON evaluation_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_evaluation_reports_created_by ON evaluation_reports(created_by);
CREATE INDEX IF NOT EXISTS idx_evaluation_reports_tenant_id ON evaluation_reports(tenant_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_reports_is_public ON evaluation_reports(is_public);

CREATE INDEX IF NOT EXISTS idx_evaluation_benchmarks_name ON evaluation_benchmarks(name);
CREATE INDEX IF NOT EXISTS idx_evaluation_benchmarks_benchmark_type ON evaluation_benchmarks(benchmark_type);
CREATE INDEX IF NOT EXISTS idx_evaluation_benchmarks_domain ON evaluation_benchmarks(domain);
CREATE INDEX IF NOT EXISTS idx_evaluation_benchmarks_created_by ON evaluation_benchmarks(created_by);
CREATE INDEX IF NOT EXISTS idx_evaluation_benchmarks_tenant_id ON evaluation_benchmarks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_benchmarks_is_public ON evaluation_benchmarks(is_public);

CREATE INDEX IF NOT EXISTS idx_evaluation_result_details_task_id ON evaluation_result_details(task_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_result_details_sample_id ON evaluation_result_details(sample_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_result_details_is_correct ON evaluation_result_details(is_correct);

-- 创建复合索引
CREATE INDEX IF NOT EXISTS idx_evaluation_tasks_tenant_status ON evaluation_tasks(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_evaluation_tasks_tenant_type ON evaluation_tasks(tenant_id, evaluation_type);
CREATE INDEX IF NOT EXISTS idx_evaluation_tasks_tenant_created ON evaluation_tasks(tenant_id, created_at);

CREATE INDEX IF NOT EXISTS idx_evaluation_metrics_task_name ON evaluation_metrics(task_id, metric_name);
CREATE INDEX IF NOT EXISTS idx_evaluation_metrics_task_type ON evaluation_metrics(task_id, metric_type);

CREATE INDEX IF NOT EXISTS idx_evaluation_datasets_tenant_type ON evaluation_datasets(tenant_id, dataset_type);
CREATE INDEX IF NOT EXISTS idx_evaluation_datasets_tenant_public ON evaluation_datasets(tenant_id, is_public);

CREATE INDEX IF NOT EXISTS idx_evaluation_reports_task_type ON evaluation_reports(task_id, report_type);
CREATE INDEX IF NOT EXISTS idx_evaluation_reports_tenant_public ON evaluation_reports(tenant_id, is_public);

CREATE INDEX IF NOT EXISTS idx_evaluation_benchmarks_tenant_type ON evaluation_benchmarks(tenant_id, benchmark_type);
CREATE INDEX IF NOT EXISTS idx_evaluation_benchmarks_tenant_public ON evaluation_benchmarks(tenant_id, is_public);

CREATE INDEX IF NOT EXISTS idx_evaluation_result_details_task_correct ON evaluation_result_details(task_id, is_correct);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有表添加更新时间触发器
CREATE TRIGGER update_evaluation_tasks_updated_at BEFORE UPDATE ON evaluation_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_evaluation_datasets_updated_at BEFORE UPDATE ON evaluation_datasets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_evaluation_reports_updated_at BEFORE UPDATE ON evaluation_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_evaluation_benchmarks_updated_at BEFORE UPDATE ON evaluation_benchmarks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入示例数据
INSERT INTO evaluation_benchmarks (id, name, description, benchmark_type, domain, language, difficulty, total_tasks, is_public, created_by, tenant_id) VALUES 
('00000000-0000-0000-0000-000000000001', 'GLUE Benchmark', 'General Language Understanding Evaluation', 'nlp', 'natural_language_processing', 'en', 'medium', 9, true, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000002', 'ImageNet Classification', 'Image classification benchmark', 'cv', 'computer_vision', 'multilingual', 'hard', 1000, true, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000003', 'SQuAD 2.0', 'Stanford Question Answering Dataset', 'qa', 'question_answering', 'en', 'medium', 150000, true, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001')
ON CONFLICT (id) DO NOTHING;

INSERT INTO evaluation_datasets (id, name, description, dataset_type, file_path, file_size, total_samples, created_by, tenant_id, is_public) VALUES 
('00000000-0000-0000-0000-000000000001', 'GLUE CoLA', 'Corpus of Linguistic Acceptability', 'classification', '/datasets/glue_cola.json', 1048576, 8551, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true),
('00000000-0000-0000-0000-000000000002', 'GLUE SST-2', 'Stanford Sentiment Treebank', 'classification', '/datasets/glue_sst2.json', 2097152, 70042, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true),
('00000000-0000-0000-0000-000000000003', 'SQuAD 2.0 Train', 'SQuAD 2.0 Training Set', 'question_answering', '/datasets/squad2_train.json', 52428800, 130319, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO evaluation_tasks (id, name, description, model_id, model_version_id, dataset_id, evaluation_type, status, created_by, tenant_id, started_at, completed_at) VALUES 
('00000000-0000-0000-0000-000000000001', 'BERT CoLA Evaluation', 'BERT model evaluation on CoLA dataset', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'classification', 'completed', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '2024-01-01 10:00:00+00', '2024-01-01 10:30:00+00'),
('00000000-0000-0000-0000-000000000002', 'GPT-3.5 SQuAD Evaluation', 'GPT-3.5 evaluation on SQuAD 2.0', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', 'question_answering', 'completed', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '2024-01-02 14:00:00+00', '2024-01-02 15:00:00+00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO evaluation_metrics (id, task_id, metric_name, metric_value, metric_unit, metric_type, threshold_value, is_passed) VALUES 
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'accuracy', 0.8750, 'ratio', 'performance', 0.80, true),
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'f1_score', 0.8234, 'ratio', 'performance', 0.75, true),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'precision', 0.8567, 'ratio', 'performance', 0.80, true),
('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'recall', 0.7923, 'ratio', 'performance', 0.75, true),
('00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000002', 'exact_match', 0.7234, 'ratio', 'performance', 0.70, true),
('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000002', 'f1_score', 0.8156, 'ratio', 'performance', 0.80, true)
ON CONFLICT (id) DO NOTHING;