"""
监控服务配置
"""
from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import Optional
import os

class Settings(BaseSettings):
    """应用设置"""
    
    # 应用配置
    app_name: str = "LLMOps Monitoring Service"
    app_version: str = "1.0.0"
    debug: bool = False
    
    # 服务器配置
    host: str = "0.0.0.0"
    port: int = 8086
    
    # 数据库配置
    db_host: str = "postgres"
    db_port: int = 5432
    db_name: str = "monitoring_db"
    db_user: str = "user"
    db_password: str = "password"
    db_url: Optional[str] = None
    
    # Redis配置
    redis_host: str = "redis"
    redis_port: int = 6379
    redis_password: Optional[str] = None
    redis_db: int = 0
    
    # Consul配置
    consul_host: str = "consul"
    consul_port: int = 8500
    
    # Prometheus配置
    prometheus_host: str = "prometheus"
    prometheus_port: int = 9090
    
    # Grafana配置
    grafana_host: str = "grafana"
    grafana_port: int = 3000
    
    # JWT配置
    secret_key: str = "your-secret-key-here"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # 监控配置
    metrics_retention_days: int = 30
    alert_check_interval: int = 60  # 秒
    health_check_interval: int = 30  # 秒
    
    # 日志配置
    log_level: str = "INFO"
    log_format: str = "json"
    
    @field_validator("db_url", mode="before")
    def assemble_db_connection(cls, v: Optional[str], info) -> str:
        """构建数据库连接URL"""
        if isinstance(v, str):
            return v
        # 从环境变量获取数据库配置
        import os
        return f"postgresql://{os.getenv('DB_USER', 'user')}:{os.getenv('DB_PASSWORD', 'password')}@{os.getenv('DB_HOST', 'postgres')}:{os.getenv('DB_PORT', '5432')}/{os.getenv('DB_NAME', 'monitoring_db')}"
    
    @field_validator("redis_host", mode="before")
    def validate_redis_host(cls, v: str) -> str:
        """验证Redis主机"""
        if not v:
            raise ValueError("Redis host cannot be empty")
        return v
    
    class Config:
        env_file = ".env"
        case_sensitive = False

# 创建全局设置实例
settings = Settings()