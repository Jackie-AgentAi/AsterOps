"""
模型相关数据模型
"""
import uuid
from datetime import datetime
from typing import List, Optional, Dict, Any
from sqlalchemy import Column, String, Text, Boolean, DateTime, BigInteger, JSON, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

Base = declarative_base()


class Model(Base):
    """模型实体"""
    __tablename__ = "models"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False, index=True)
    description = Column(Text)
    framework = Column(String(100), nullable=False, index=True)
    task_type = Column(String(100), nullable=False, index=True)
    status = Column(String(50), default="active", index=True)
    owner_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    tenant_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    is_public = Column(Boolean, default=False, index=True)
    tags = Column(ARRAY(String), default=[])
    model_metadata = Column(JSON, default={})
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)
    
    # 关联关系
    versions = relationship("ModelVersion", back_populates="model", cascade="all, delete-orphan")
    deployments = relationship("ModelDeployment", back_populates="model", cascade="all, delete-orphan")
    evaluations = relationship("ModelEvaluation", back_populates="model", cascade="all, delete-orphan")
    
    # 索引
    __table_args__ = (
        Index("idx_models_tenant_status", "tenant_id", "status"),
        Index("idx_models_owner_status", "owner_id", "status"),
        Index("idx_models_public_status", "is_public", "status"),
    )


class ModelVersion(Base):
    """模型版本实体"""
    __tablename__ = "model_versions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    model_id = Column(UUID(as_uuid=True), ForeignKey("models.id", ondelete="CASCADE"), nullable=False, index=True)
    version = Column(String(50), nullable=False, index=True)
    description = Column(Text)
    file_path = Column(String(500))
    file_size = Column(BigInteger)
    checksum = Column(String(64), index=True)
    status = Column(String(50), default="active", index=True)
    model_metadata = Column(JSON, default={})
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)
    
    # 关联关系
    model = relationship("Model", back_populates="versions")
    deployments = relationship("ModelDeployment", back_populates="model_version", cascade="all, delete-orphan")
    evaluations = relationship("ModelEvaluation", back_populates="model_version", cascade="all, delete-orphan")
    
    # 索引
    __table_args__ = (
        Index("idx_model_versions_model_version", "model_id", "version", unique=True),
        Index("idx_model_versions_model_status", "model_id", "status"),
    )


class ModelDeployment(Base):
    """模型部署实体"""
    __tablename__ = "model_deployments"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    model_id = Column(UUID(as_uuid=True), ForeignKey("models.id", ondelete="CASCADE"), nullable=False, index=True)
    model_version_id = Column(UUID(as_uuid=True), ForeignKey("model_versions.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False, index=True)
    description = Column(Text)
    deployment_type = Column(String(50), nullable=False, index=True)  # kubernetes, docker, local
    status = Column(String(50), default="pending", index=True)
    endpoint = Column(String(500))
    replicas = Column(BigInteger, default=1)
    cpu_limit = Column(String(50))
    memory_limit = Column(String(50))
    gpu_limit = Column(String(50))
    config = Column(JSON, default={})
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)
    
    # 关联关系
    model = relationship("Model", back_populates="deployments")
    model_version = relationship("ModelVersion", back_populates="deployments")
    metrics = relationship("ModelMetric", back_populates="deployment", cascade="all, delete-orphan")
    
    # 索引
    __table_args__ = (
        Index("idx_model_deployments_model_status", "model_id", "status"),
        Index("idx_model_deployments_type_status", "deployment_type", "status"),
    )


class ModelEvaluation(Base):
    """模型评测实体"""
    __tablename__ = "model_evaluations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    model_id = Column(UUID(as_uuid=True), ForeignKey("models.id", ondelete="CASCADE"), nullable=False, index=True)
    model_version_id = Column(UUID(as_uuid=True), ForeignKey("model_versions.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False, index=True)
    description = Column(Text)
    dataset_id = Column(String(255), index=True)
    evaluation_type = Column(String(50), nullable=False, index=True)  # accuracy, f1, precision, recall, etc.
    status = Column(String(50), default="pending", index=True)
    results = Column(JSON, default={})
    metrics = Column(JSON, default={})
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)
    
    # 关联关系
    model = relationship("Model", back_populates="evaluations")
    model_version = relationship("ModelVersion", back_populates="evaluations")
    
    # 索引
    __table_args__ = (
        Index("idx_model_evaluations_model_status", "model_id", "status"),
        Index("idx_model_evaluations_type_status", "evaluation_type", "status"),
    )


class ModelMetric(Base):
    """模型指标实体"""
    __tablename__ = "model_metrics"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    deployment_id = Column(UUID(as_uuid=True), ForeignKey("model_deployments.id", ondelete="CASCADE"), nullable=False, index=True)
    metric_name = Column(String(100), nullable=False, index=True)
    metric_value = Column(String(100), nullable=False)
    metric_unit = Column(String(20))
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    labels = Column(JSON, default={})
    
    # 关联关系
    deployment = relationship("ModelDeployment", back_populates="metrics")
    
    # 索引
    __table_args__ = (
        Index("idx_model_metrics_deployment_name", "deployment_id", "metric_name"),
        Index("idx_model_metrics_timestamp", "timestamp"),
    )



