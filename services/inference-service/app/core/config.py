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
    APP_NAME: str = "Inference Service"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # 服务器配置
    HOST: str = "0.0.0.0"
    PORT: int = 8084
    
    # 数据库配置
    DATABASE_URL: str = "postgresql://user:password@localhost:5432/inference_db"
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
    
    # 推理配置
    MAX_CONCURRENT_REQUESTS: int = 100
    REQUEST_TIMEOUT: int = 300  # 5分钟
    BATCH_SIZE: int = 32
    MAX_BATCH_SIZE: int = 128
    
    # 模型配置
    MODEL_CACHE_SIZE: int = 10
    MODEL_LOAD_TIMEOUT: int = 300  # 5分钟
    MODEL_UNLOAD_TIMEOUT: int = 60  # 1分钟
    MODEL_STORAGE_PATH: str = "/app/models"
    MODEL_CACHE_PATH: str = "/app/cache"
    
    # GPU配置
    GPU_MEMORY_FRACTION: float = 0.8
    GPU_MEMORY_GROWTH: bool = True
    CUDA_VISIBLE_DEVICES: Optional[str] = None
    
    # vLLM配置
    VLLM_ENGINE: str = "vllm"
    VLLM_TENSOR_PARALLEL_SIZE: int = 1
    VLLM_PIPELINE_PARALLEL_SIZE: int = 1
    VLLM_MAX_MODEL_LEN: int = 4096
    VLLM_QUANTIZATION: Optional[str] = None
    
    # 监控配置
    PROMETHEUS_ENABLED: bool = True
    SENTRY_DSN: Optional[str] = None
    METRICS_INTERVAL: int = 30  # 秒
    
    # 日志配置
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"
    
    # 服务发现配置
    CONSUL_HOST: str = "localhost"
    CONSUL_PORT: int = 8500
    SERVICE_NAME: str = "inference-service"
    SERVICE_ID: str = "inference-service-1"
    SERVICE_TAGS: List[str] = ["inference", "ml", "api"]
    
    # 缓存配置
    CACHE_ENABLED: bool = True
    CACHE_TTL: int = 3600  # 1小时
    CACHE_MAX_SIZE: int = 1000
    
    # 限流配置
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_REQUESTS: int = 100
    RATE_LIMIT_WINDOW: int = 60  # 秒
    
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



