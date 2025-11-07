#!/bin/bash

# 生产环境数据库初始化脚本
# 创建所有微服务所需的数据库和用户

set -e

echo "=== 开始初始化生产环境数据库 ==="
echo "时间: $(date)"

# 数据库连接参数
DB_HOST="${POSTGRES_HOST:-postgres}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-llmops}"
DB_USER="${POSTGRES_USER:-llmops_prod}"
DB_PASSWORD="${POSTGRES_PASSWORD}"

# 等待PostgreSQL启动
echo "等待PostgreSQL启动..."
until pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER; do
    echo "PostgreSQL未就绪，等待中..."
    sleep 2
done

echo "PostgreSQL已就绪"

# 创建数据库函数
create_database() {
    local db_name=$1
    local description=$2
    
    echo "创建数据库: $db_name ($description)"
    
    # 检查数据库是否已存在
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -tc "SELECT 1 FROM pg_database WHERE datname = '$db_name'" | grep -q 1; then
        echo "数据库 $db_name 已存在，跳过创建"
    else
        # 创建数据库
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "CREATE DATABASE $db_name;"
        echo "数据库 $db_name 创建成功"
    fi
}

# 创建用户函数
create_user() {
    local username=$1
    local password=$2
    local description=$3
    
    echo "创建用户: $username ($description)"
    
    # 检查用户是否已存在
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -tc "SELECT 1 FROM pg_user WHERE usename = '$username'" | grep -q 1; then
        echo "用户 $username 已存在，跳过创建"
    else
        # 创建用户
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "CREATE USER $username WITH PASSWORD '$password';"
        echo "用户 $username 创建成功"
    fi
}

# 授权函数
grant_privileges() {
    local username=$1
    local db_name=$2
    
    echo "授权用户 $username 访问数据库 $db_name"
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $username;"
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $db_name -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $username;"
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $db_name -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $username;"
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $db_name -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $username;"
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $db_name -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $username;"
}

# 执行SQL文件函数
execute_sql_file() {
    local db_name=$1
    local sql_file=$2
    local description=$3
    
    if [ -f "$sql_file" ]; then
        echo "执行SQL文件: $sql_file ($description)"
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $db_name -f "$sql_file"
        echo "SQL文件 $sql_file 执行成功"
    else
        echo "SQL文件 $sql_file 不存在，跳过"
    fi
}

# 1. 创建各服务数据库
echo "=== 创建数据库 ==="
create_database "user_db_prod" "用户权限服务数据库"
create_database "project_db_prod" "项目管理服务数据库"
create_database "model_db_prod" "模型管理服务数据库"
create_database "inference_db_prod" "推理服务数据库"
create_database "cost_db_prod" "成本管理服务数据库"
create_database "monitoring_db_prod" "监控服务数据库"

# 2. 创建各服务用户
echo "=== 创建用户 ==="
create_user "user_service" "User_Service_2024!@#Secure" "用户服务数据库用户"
create_user "project_service" "Project_Service_2024!@#Secure" "项目管理服务数据库用户"
create_user "model_service" "Model_Service_2024!@#Secure" "模型管理服务数据库用户"
create_user "inference_service" "Inference_Service_2024!@#Secure" "推理服务数据库用户"
create_user "cost_service" "Cost_Service_2024!@#Secure" "成本管理服务数据库用户"
create_user "monitoring_service" "Monitoring_Service_2024!@#Secure" "监控服务数据库用户"

# 3. 授权用户访问对应数据库
echo "=== 授权用户 ==="
grant_privileges "user_service" "user_db_prod"
grant_privileges "project_service" "project_db_prod"
grant_privileges "model_service" "model_db_prod"
grant_privileges "inference_service" "inference_db_prod"
grant_privileges "cost_service" "cost_db_prod"
grant_privileges "monitoring_service" "monitoring_db_prod"

# 4. 执行各服务的SQL初始化文件
echo "=== 执行SQL初始化文件 ==="
execute_sql_file "user_db_prod" "/docker-entrypoint-initdb.d/sql/user-service.sql" "用户服务表结构"
execute_sql_file "project_db_prod" "/docker-entrypoint-initdb.d/sql/project-service.sql" "项目管理服务表结构"
execute_sql_file "model_db_prod" "/docker-entrypoint-initdb.d/sql/model-service.sql" "模型管理服务表结构"
execute_sql_file "inference_db_prod" "/docker-entrypoint-initdb.d/sql/inference-service.sql" "推理服务表结构"
execute_sql_file "cost_db_prod" "/docker-entrypoint-initdb.d/sql/cost-service.sql" "成本管理服务表结构"
execute_sql_file "monitoring_db_prod" "/docker-entrypoint-initdb.d/sql/monitoring-service.sql" "监控服务表结构"

# 5. 创建索引优化
echo "=== 创建索引优化 ==="
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d user_db_prod -c "
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_tenant_id ON users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON sessions(expires_at);
"

psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d project_db_prod -c "
CREATE INDEX IF NOT EXISTS idx_projects_tenant_id ON projects(tenant_id);
CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects(created_at);
CREATE INDEX IF NOT EXISTS idx_project_members_project_id ON project_members(project_id);
CREATE INDEX IF NOT EXISTS idx_project_members_user_id ON project_members(user_id);
"

psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d model_db_prod -c "
CREATE INDEX IF NOT EXISTS idx_models_tenant_id ON models(tenant_id);
CREATE INDEX IF NOT EXISTS idx_models_project_id ON models(project_id);
CREATE INDEX IF NOT EXISTS idx_models_created_at ON models(created_at);
CREATE INDEX IF NOT EXISTS idx_model_versions_model_id ON model_versions(model_id);
CREATE INDEX IF NOT EXISTS idx_model_versions_version ON model_versions(version);
"

psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d inference_db_prod -c "
CREATE INDEX IF NOT EXISTS idx_inference_requests_tenant_id ON inference_requests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inference_requests_project_id ON inference_requests(project_id);
CREATE INDEX IF NOT EXISTS idx_inference_requests_created_at ON inference_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_inference_requests_status ON inference_requests(status);
"

psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d cost_db_prod -c "
CREATE INDEX IF NOT EXISTS idx_cost_records_tenant_id ON cost_records(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cost_records_project_id ON cost_records(project_id);
CREATE INDEX IF NOT EXISTS idx_cost_records_created_at ON cost_records(created_at);
CREATE INDEX IF NOT EXISTS idx_cost_records_resource_type ON cost_records(resource_type);
"

psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d monitoring_db_prod -c "
CREATE INDEX IF NOT EXISTS idx_metrics_tenant_id ON metrics(tenant_id);
CREATE INDEX IF NOT EXISTS idx_metrics_service_name ON metrics(service_name);
CREATE INDEX IF NOT EXISTS idx_metrics_created_at ON metrics(created_at);
CREATE INDEX IF NOT EXISTS idx_alerts_tenant_id ON alerts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
CREATE INDEX IF NOT EXISTS idx_alerts_created_at ON alerts(created_at);
"

# 6. 设置数据库参数优化
echo "=== 优化数据库参数 ==="
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
-- 设置连接数限制
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET min_wal_size = '1GB';
ALTER SYSTEM SET max_wal_size = '4GB';

-- 重新加载配置
SELECT pg_reload_conf();
"

# 7. 创建监控视图
echo "=== 创建监控视图 ==="
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d monitoring_db_prod -c "
-- 创建数据库连接数监控视图
CREATE OR REPLACE VIEW db_connections AS
SELECT 
    datname as database_name,
    count(*) as connection_count,
    max(now() - state_change) as max_idle_time
FROM pg_stat_activity 
WHERE state = 'active'
GROUP BY datname;

-- 创建表大小监控视图
CREATE OR REPLACE VIEW table_sizes AS
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"

echo "=== 数据库初始化完成 ==="
echo "时间: $(date)"
echo "已创建的数据库:"
echo "- user_db_prod (用户权限服务)"
echo "- project_db_prod (项目管理服务)"
echo "- model_db_prod (模型管理服务)"
echo "- inference_db_prod (推理服务)"
echo "- cost_db_prod (成本管理服务)"
echo "- monitoring_db_prod (监控服务)"
echo ""
echo "已创建的用户:"
echo "- user_service"
echo "- project_service"
echo "- model_service"
echo "- inference_service"
echo "- cost_service"
echo "- monitoring_service"
echo ""
echo "数据库优化完成，索引已创建，参数已优化"
