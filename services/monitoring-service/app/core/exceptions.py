"""
自定义异常
"""
from fastapi import HTTPException
from typing import Any, Dict, Optional

class MonitoringServiceException(Exception):
    """监控服务基础异常"""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        self.message = message
        self.details = details or {}
        super().__init__(self.message)

class MetricNotFoundException(MonitoringServiceException):
    """指标未找到异常"""
    pass

class AlertNotFoundException(MonitoringServiceException):
    """告警未找到异常"""
    pass

class DashboardNotFoundException(MonitoringServiceException):
    """仪表板未找到异常"""
    pass

class ServiceHealthException(MonitoringServiceException):
    """服务健康异常"""
    pass

class ValidationException(MonitoringServiceException):
    """验证异常"""
    pass

# HTTP异常映射
def map_to_http_exception(exc: MonitoringServiceException) -> HTTPException:
    """将业务异常映射为HTTP异常"""
    if isinstance(exc, MetricNotFoundException):
        return HTTPException(status_code=404, detail=exc.message)
    elif isinstance(exc, AlertNotFoundException):
        return HTTPException(status_code=404, detail=exc.message)
    elif isinstance(exc, DashboardNotFoundException):
        return HTTPException(status_code=404, detail=exc.message)
    elif isinstance(exc, ValidationException):
        return HTTPException(status_code=400, detail=exc.message)
    else:
        return HTTPException(status_code=500, detail=exc.message)
