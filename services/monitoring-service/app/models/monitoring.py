"""
监控服务数据模型
"""
from sqlalchemy import Column, String, Float, DateTime, Text, JSON, Boolean, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
import uuid

Base = declarative_base()

class Metric(Base):
    """监控指标实体"""
    __tablename__ = "monitoring_metrics"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    service_id = Column(String(255), nullable=False, index=True)
    metric_name = Column(String(255), nullable=False)
    metric_value = Column(Float, nullable=False)
    metric_unit = Column(String(50))
    labels = Column(JSON)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Alert(Base):
    """告警实体"""
    __tablename__ = "alert_rules"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    service_id = Column(String(255), nullable=False, index=True)
    metric_name = Column(String(255), nullable=False)
    threshold = Column(Float, nullable=False)
    operator = Column(String(10), nullable=False)  # >, <, >=, <=, ==, !=
    duration = Column(String(50))  # 持续时间，如 "5m", "1h"
    severity = Column(String(20), nullable=False)  # critical, warning, info
    status = Column(String(20), default="active")  # active, inactive, triggered
    is_acknowledged = Column(Boolean, default=False)
    acknowledged_by = Column(String(255))
    acknowledged_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class Dashboard(Base):
    """仪表板实体"""
    __tablename__ = "dashboards"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    config = Column(JSON)  # 仪表板配置
    is_public = Column(Boolean, default=False)
    created_by = Column(String(255), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class LogEntry(Base):
    """日志条目实体"""
    __tablename__ = "system_logs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    service_id = Column(String(255), nullable=False, index=True)
    level = Column(String(20), nullable=False)  # DEBUG, INFO, WARN, ERROR, FATAL
    message = Column(Text, nullable=False)
    source = Column(String(255))
    trace_id = Column(String(255), index=True)
    user_id = Column(String(255), index=True)
    model_metadata = Column(JSON)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class ServiceHealth(Base):
    """服务健康实体"""
    __tablename__ = "service_health"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    service_id = Column(String(255), nullable=False, unique=True, index=True)
    service_name = Column(String(255), nullable=False)
    status = Column(String(20), nullable=False)  # healthy, unhealthy, unknown
    last_check = Column(DateTime(timezone=True), server_default=func.now())
    response_time = Column(Float)  # 响应时间（毫秒）
    error_message = Column(Text)
    model_metadata = Column(JSON)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class MetricData(Base):
    """指标数据实体"""
    __tablename__ = "metric_data"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    metric_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    value = Column(Float, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    labels = Column(JSON)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class AlertEvent(Base):
    """告警事件实体"""
    __tablename__ = "alert_events"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    alert_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    event_type = Column(String(50), nullable=False)  # triggered, resolved, acknowledged
    severity = Column(String(20), nullable=False)  # critical, warning, info
    message = Column(Text, nullable=False)
    value = Column(Float)
    threshold = Column(Float)
    service_id = Column(String(255), nullable=False, index=True)
    is_acknowledged = Column(Boolean, default=False)
    acknowledged_by = Column(String(255))
    acknowledged_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class AuditLog(Base):
    """审计日志实体"""
    __tablename__ = "audit_logs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(255), nullable=False, index=True)
    action = Column(String(100), nullable=False)
    resource_type = Column(String(100), nullable=False)
    resource_id = Column(String(255), nullable=False)
    details = Column(JSON)
    ip_address = Column(String(45))
    user_agent = Column(String(500))
    tenant_id = Column(String(255), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())