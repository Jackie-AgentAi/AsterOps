"""
监控服务Pydantic模式
"""
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
from uuid import UUID

# 监控指标相关模式
class MetricCreate(BaseModel):
    service_id: str = Field(..., description="服务ID")
    metric_name: str = Field(..., description="指标名称")
    metric_value: float = Field(..., description="指标值")
    metric_unit: Optional[str] = Field(None, description="指标单位")
    labels: Optional[Dict[str, Any]] = Field(None, description="标签")

class MetricResponse(BaseModel):
    id: UUID
    service_id: str
    metric_name: str
    metric_value: float
    metric_unit: Optional[str]
    labels: Optional[Dict[str, Any]]
    timestamp: datetime
    created_at: datetime

    class Config:
        from_attributes = True

class MetricQuery(BaseModel):
    service_id: Optional[str] = None
    metric_name: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    limit: int = Field(100, ge=1, le=1000)

# 告警相关模式
class AlertCreate(BaseModel):
    name: str = Field(..., description="告警名称")
    description: Optional[str] = Field(None, description="告警描述")
    service_id: str = Field(..., description="服务ID")
    metric_name: str = Field(..., description="指标名称")
    threshold: float = Field(..., description="阈值")
    operator: str = Field(..., description="操作符", pattern="^(>|<|>=|<=|==|!=)$")
    duration: Optional[str] = Field(None, description="持续时间")
    severity: str = Field(..., description="严重程度", pattern="^(critical|warning|info)$")

class AlertUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    threshold: Optional[float] = None
    operator: Optional[str] = Field(None, pattern="^(>|<|>=|<=|==|!=)$")
    duration: Optional[str] = None
    severity: Optional[str] = Field(None, pattern="^(critical|warning|info)$")
    status: Optional[str] = Field(None, pattern="^(active|inactive)$")

class AlertResponse(BaseModel):
    id: UUID
    name: str
    description: Optional[str]
    service_id: str
    metric_name: str
    threshold: float
    operator: str
    duration: Optional[str]
    severity: str
    status: str
    is_acknowledged: bool
    acknowledged_by: Optional[str]
    acknowledged_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class AlertAcknowledge(BaseModel):
    acknowledged_by: str = Field(..., description="确认人")

# 仪表板相关模式
class DashboardCreate(BaseModel):
    name: str = Field(..., description="仪表板名称")
    description: Optional[str] = Field(None, description="仪表板描述")
    config: Dict[str, Any] = Field(..., description="仪表板配置")
    is_public: bool = Field(False, description="是否公开")

class DashboardUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    config: Optional[Dict[str, Any]] = None
    is_public: Optional[bool] = None

class DashboardResponse(BaseModel):
    id: UUID
    name: str
    description: Optional[str]
    config: Dict[str, Any]
    is_public: bool
    created_by: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# 日志相关模式
class LogEntryCreate(BaseModel):
    service_id: str = Field(..., description="服务ID")
    level: str = Field(..., description="日志级别", pattern="^(DEBUG|INFO|WARN|ERROR|FATAL)$")
    message: str = Field(..., description="日志消息")
    source: Optional[str] = Field(None, description="日志源")
    trace_id: Optional[str] = Field(None, description="追踪ID")
    user_id: Optional[str] = Field(None, description="用户ID")
    metadata: Optional[Dict[str, Any]] = Field(None, description="元数据")

class LogEntryResponse(BaseModel):
    id: UUID
    service_id: str
    level: str
    message: str
    source: Optional[str]
    trace_id: Optional[str]
    user_id: Optional[str]
    metadata: Optional[Dict[str, Any]]
    timestamp: datetime
    created_at: datetime

    class Config:
        from_attributes = True

class LogQuery(BaseModel):
    service_id: Optional[str] = None
    level: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    search: Optional[str] = None
    limit: int = Field(100, ge=1, le=1000)

# 服务健康相关模式
class ServiceHealthResponse(BaseModel):
    id: UUID
    service_id: str
    service_name: str
    status: str
    last_check: datetime
    response_time: Optional[float]
    error_message: Optional[str]
    metadata: Optional[Dict[str, Any]]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ServiceHealthUpdate(BaseModel):
    status: str = Field(..., description="健康状态", pattern="^(healthy|unhealthy|unknown)$")
    response_time: Optional[float] = Field(None, description="响应时间")
    error_message: Optional[str] = Field(None, description="错误消息")
    metadata: Optional[Dict[str, Any]] = Field(None, description="元数据")

# 通用响应模式
class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    timestamp: datetime

class MetricsSummary(BaseModel):
    total_metrics: int
    services_count: int
    alerts_count: int
    active_alerts: int
    last_updated: datetime

class AlertSummary(BaseModel):
    total_alerts: int
    active_alerts: int
    acknowledged_alerts: int
    critical_alerts: int
    warning_alerts: int
    info_alerts: int