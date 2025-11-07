"""
应用配置管理
"""
import os
from typing import List, Optional
from pydantic_settings import BaseSettings
from pydantic import field_validator


class Settings(BaseSettings):
    """应用设置"""
    
    # 应用配置
    APP_NAME: str = "Model Service"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # 服务器配置
    HOST: str = "0.0.0.0"
    PORT: int = 8083
    
    # 数据库配置
    DATABASE_URL: str = "postgresql://user:password@localhost:5432/model_db"
    DATABASE_POOL_SIZE: int = 10
    DATABASE_MAX_OVERFLOW: int = 20
    DATABASE_POOL_TIMEOUT: int = 30
    DATABASE_POOL_RECYCLE: int = 3600
    
    # Redis配置
    REDIS_URL: str = "redis://localhost:6379/0"
    REDIS_POOL_SIZE: int = 10
    REDIS_TIMEOUT: int = 5
    
    # JWT配置
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # CORS配置
    ALLOWED_HOSTS: List[str] = ["*"]
    ALLOWED_ORIGINS: List[str] = ["*"]
    
    # 文件存储配置
    UPLOAD_DIR: str = "/tmp/uploads"
    MAX_FILE_SIZE: int = 100 * 1024 * 1024  # 100MB
    ALLOWED_EXTENSIONS: List[str] = [".pt", ".pth", ".onnx", ".h5", ".pb", ".tflite"]
    
    # 模型存储配置
    MODEL_STORAGE_PATH: str = "/tmp/models"
    MODEL_CACHE_SIZE: int = 1000
    
    # 部署配置
    KUBERNETES_NAMESPACE: str = "llmops"
    KUBERNETES_CONFIG_PATH: Optional[str] = None
    
    # 监控配置
    PROMETHEUS_ENABLED: bool = True
    SENTRY_DSN: Optional[str] = None
    
    # 日志配置
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"
    
    # 服务发现配置
    CONSUL_HOST: str = "localhost"
    CONSUL_PORT: int = 8500
    SERVICE_NAME: str = "model-service"
    SERVICE_ID: str = "model-service-1"
    SERVICE_TAGS: List[str] = ["model", "ml", "api"]
    
    @field_validator("ALLOWED_HOSTS", mode="before")
    @classmethod
    def parse_allowed_hosts(cls, v):
        if isinstance(v, str):
            return [host.strip() for host in v.split(",")]
        return v
    
    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def parse_allowed_origins(cls, v):
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",")]
        return v
    
    @field_validator("ALLOWED_EXTENSIONS", mode="before")
    @classmethod
    def parse_allowed_extensions(cls, v):
        if isinstance(v, str):
            return [ext.strip() for ext in v.split(",")]
        return v
    
    @field_validator("SERVICE_TAGS", mode="before")
    @classmethod
    def parse_service_tags(cls, v):
        if isinstance(v, str):
            return [tag.strip() for tag in v.split(",")]
        return v
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# 创建全局设置实例
settings = Settings()



