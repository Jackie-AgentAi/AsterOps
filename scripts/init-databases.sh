#!/bin/bash

# 数据库初始化脚本
set -e

echo "开始初始化数据库..."

# 等待PostgreSQL启动
echo "等待PostgreSQL启动..."
until docker exec asterops-postgres-1 pg_isready -U user; do
  echo "PostgreSQL未就绪，等待中..."
  sleep 2
done

echo "PostgreSQL已就绪"

# 创建数据库
echo "创建数据库..."
docker exec asterops-postgres-1 psql -U user -c "CREATE DATABASE IF NOT EXISTS user_db;" || true
docker exec asterops-postgres-1 psql -U user -c "CREATE DATABASE IF NOT EXISTS project_db;" || true
docker exec asterops-postgres-1 psql -U user -c "CREATE DATABASE IF NOT EXISTS model_db;" || true
docker exec asterops-postgres-1 psql -U user -c "CREATE DATABASE IF NOT EXISTS inference_db;" || true
docker exec asterops-postgres-1 psql -U user -c "CREATE DATABASE IF NOT EXISTS cost_db;" || true
docker exec asterops-postgres-1 psql -U user -c "CREATE DATABASE IF NOT EXISTS monitoring_db;" || true

echo "数据库创建完成"

# 运行数据库迁移
echo "运行数据库迁移..."

# 项目管理服务迁移
echo "运行项目管理服务数据库迁移..."
curl -X POST http://localhost:8082/api/v1/migrate || echo "项目管理服务迁移失败或不需要"

# 用户服务迁移
echo "运行用户服务数据库迁移..."
curl -X POST http://localhost:8081/api/v1/migrate || echo "用户服务迁移失败或不需要"

echo "数据库初始化完成！"
