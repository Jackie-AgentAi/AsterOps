"""
推理相关数据模型
"""
import uuid
from datetime import datetime
from typing import List, Optional, Dict, Any
from sqlalchemy import Column, String, Text, Boolean, DateTime, BigInteger, JSON, ForeignKey, Float, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

Base = declarative_base()


class InferenceRequest(Base):
    """推理请求实体"""
    __tablename__ = "inference_requests"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    model_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    session_id = Column(UUID(as_uuid=True), nullable=True, index=True)
    user_id = Column(UUID(as_uuid=True), nullable=True, index=True)
    tenant_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    
    # 请求数据
    request_data = Column(JSON, nullable=False)
    response_data = Column(JSON, nullable=True)
    
    # 状态和性能
    status = Column(String(50), default="pending", index=True)
    processing_time_ms = Column(Integer, nullable=True)
    gpu_memory_used = Column(BigInteger, nullable=True)
    cpu_usage = Column(Float, nullable=True)
    memory_usage = Column(Float, nullable=True)
    
    # 错误信息
    error_message = Column(Text, nullable=True)
    error_code = Column(String(100), nullable=True)
    
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    
    # 索引
    __table_args__ = (
        # 复合索引
        {"postgresql_partition_by": "RANGE (created_at)"}
    )


class ModelInstance(Base):
    """模型实例实体"""
    __tablename__ = "model_instances"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    model_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    instance_id = Column(String(255), nullable=False, unique=True, index=True)
    
    # 状态信息
    status = Column(String(50), default="loading", index=True)
    engine_type = Column(String(50), nullable=False, index=True)  # vllm, transformers, onnx
    
    # 资源使用
    gpu_memory_used = Column(BigInteger, nullable=True)
    gpu_memory_total = Column(BigInteger, nullable=True)
    cpu_usage = Column(Float, nullable=True)
    memory_usage = Column(Float, nullable=True)
    memory_total = Column(BigInteger, nullable=True)
    
    # 性能指标
    requests_processed = Column(BigInteger, default=0)
    total_processing_time_ms = Column(BigInteger, default=0)
    average_processing_time_ms = Column(Float, nullable=True)
    
    # 配置信息
    config = Column(JSON, default={})
    metadata = Column(JSON, default={})
    
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    last_used_at = Column(DateTime(timezone=True), nullable=True)
    
    # 索引
    __table_args__ = (
        # 复合索引
    )


class InferenceSession(Base):
    """推理会话实体"""
    __tablename__ = "inference_sessions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    tenant_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    model_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    
    # 会话信息
    session_name = Column(String(255), nullable=True)
    session_type = Column(String(50), default="chat", index=True)  # chat, completion, embedding
    
    # 会话状态
    status = Column(String(50), default="active", index=True)
    is_streaming = Column(Boolean, default=False)
    
    # 会话配置
    config = Column(JSON, default={})
    context = Column(JSON, default={})
    
    # 统计信息
    request_count = Column(BigInteger, default=0)
    total_tokens = Column(BigInteger, default=0)
    total_cost = Column(Float, default=0.0)
    
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    last_activity_at = Column(DateTime(timezone=True), nullable=True)
    expires_at = Column(DateTime(timezone=True), nullable=True)
    
    # 索引
    __table_args__ = (
        # 复合索引
    )


class InferenceMetric(Base):
    """推理指标实体"""
    __tablename__ = "inference_metrics"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    model_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    instance_id = Column(UUID(as_uuid=True), nullable=True, index=True)
    
    # 指标信息
    metric_name = Column(String(100), nullable=False, index=True)
    metric_value = Column(Float, nullable=False)
    metric_unit = Column(String(20), nullable=True)
    
    # 标签和元数据
    labels = Column(JSON, default={})
    metadata = Column(JSON, default={})
    
    # 时间戳
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    
    # 索引
    __table_args__ = (
        # 复合索引
    )


class InferenceCache(Base):
    """推理缓存实体"""
    __tablename__ = "inference_cache"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    model_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    
    # 缓存键值
    cache_key = Column(String(255), nullable=False, unique=True, index=True)
    cache_data = Column(JSON, nullable=False)
    
    # 缓存元数据
    hit_count = Column(BigInteger, default=0)
    last_hit_at = Column(DateTime(timezone=True), nullable=True)
    
    # 过期时间
    expires_at = Column(DateTime(timezone=True), nullable=True, index=True)
    
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # 索引
    __table_args__ = (
        # 复合索引
    )


class InferenceQueue(Base):
    """推理队列实体"""
    __tablename__ = "inference_queue"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    model_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    request_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    
    # 队列信息
    priority = Column(Integer, default=0, index=True)
    status = Column(String(50), default="queued", index=True)
    
    # 请求数据
    request_data = Column(JSON, nullable=False)
    
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    
    # 索引
    __table_args__ = (
        # 复合索引
    )



