"""
监控服务API路由
"""
import logging
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.schemas.monitoring import (
    MetricCreate, MetricResponse, MetricQuery,
    AlertCreate, AlertUpdate, AlertResponse, AlertAcknowledge,
    DashboardCreate, DashboardUpdate, DashboardResponse,
    LogEntryCreate, LogEntryResponse, LogQuery,
    ServiceHealthResponse, ServiceHealthUpdate,
    HealthResponse, MetricsSummary, AlertSummary
)
from app.services.monitoring_service import MonitoringService
from app.core.database import get_db

logger = logging.getLogger(__name__)
router = APIRouter()

def get_monitoring_service(db: Session = Depends(get_db)) -> MonitoringService:
    """获取监控服务实例"""
    return MonitoringService(db)

# 健康检查
@router.get("/health", response_model=HealthResponse)
async def health_check():
    """健康检查"""
    return HealthResponse(
        status="healthy",
        service="monitoring-service",
        version="1.0.0",
        timestamp=datetime.utcnow()
    )

# 监控指标相关API
@router.post("/metrics", response_model=MetricResponse)
async def create_metric(
    metric_data: MetricCreate,
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """创建监控指标"""
    try:
        metric = await monitoring_service.create_metric(metric_data)
        return MetricResponse.from_orm(metric)
    except Exception as e:
        logger.error(f"Failed to create metric: {e}")
        raise HTTPException(status_code=500, detail="Failed to create metric")

@router.get("/metrics", response_model=List[MetricResponse])
async def get_metrics(
    service_id: Optional[str] = Query(None, description="服务ID"),
    metric_name: Optional[str] = Query(None, description="指标名称"),
    start_time: Optional[datetime] = Query(None, description="开始时间"),
    end_time: Optional[datetime] = Query(None, description="结束时间"),
    limit: int = Query(100, ge=1, le=1000, description="限制数量"),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取监控指标"""
    try:
        metrics = await monitoring_service.get_metrics(
            service_id=service_id,
            metric_name=metric_name,
            start_time=start_time,
            end_time=end_time,
            limit=limit
        )
        return [MetricResponse.from_orm(metric) for metric in metrics]
    except Exception as e:
        logger.error(f"Failed to get metrics: {e}")
        raise HTTPException(status_code=500, detail="Failed to get metrics")

@router.get("/metrics/summary", response_model=MetricsSummary)
async def get_metrics_summary(
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取指标汇总"""
    try:
        return await monitoring_service.get_metrics_summary()
    except Exception as e:
        logger.error(f"Failed to get metrics summary: {e}")
        raise HTTPException(status_code=500, detail="Failed to get metrics summary")

# 告警相关API
@router.post("/alerts", response_model=AlertResponse)
async def create_alert(
    alert_data: AlertCreate,
    created_by: str = "system",  # 在实际应用中从JWT token获取
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """创建告警规则"""
    try:
        alert = await monitoring_service.create_alert(alert_data, created_by)
        return AlertResponse.from_orm(alert)
    except Exception as e:
        logger.error(f"Failed to create alert: {e}")
        raise HTTPException(status_code=500, detail="Failed to create alert")

@router.get("/alerts", response_model=List[AlertResponse])
async def get_alerts(
    service_id: Optional[str] = Query(None, description="服务ID"),
    status: Optional[str] = Query(None, description="状态"),
    severity: Optional[str] = Query(None, description="严重程度"),
    limit: int = Query(100, ge=1, le=1000, description="限制数量"),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取告警列表"""
    try:
        alerts = await monitoring_service.get_alerts(
            service_id=service_id,
            status=status,
            severity=severity,
            limit=limit
        )
        return [AlertResponse.from_orm(alert) for alert in alerts]
    except Exception as e:
        logger.error(f"Failed to get alerts: {e}")
        raise HTTPException(status_code=500, detail="Failed to get alerts")

@router.put("/alerts/{alert_id}", response_model=AlertResponse)
async def update_alert(
    alert_id: str,
    alert_data: AlertUpdate,
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """更新告警规则"""
    try:
        alert = await monitoring_service.update_alert(alert_id, alert_data)
        if not alert:
            raise HTTPException(status_code=404, detail="Alert not found")
        return AlertResponse.from_orm(alert)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update alert: {e}")
        raise HTTPException(status_code=500, detail="Failed to update alert")

@router.delete("/alerts/{alert_id}")
async def delete_alert(
    alert_id: str,
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """删除告警规则"""
    try:
        success = await monitoring_service.delete_alert(alert_id)
        if not success:
            raise HTTPException(status_code=404, detail="Alert not found")
        return {"message": "Alert deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete alert: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete alert")

@router.post("/alerts/{alert_id}/acknowledge", response_model=AlertResponse)
async def acknowledge_alert(
    alert_id: str,
    acknowledge_data: AlertAcknowledge,
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """确认告警"""
    try:
        alert = await monitoring_service.acknowledge_alert(alert_id, acknowledge_data.acknowledged_by)
        if not alert:
            raise HTTPException(status_code=404, detail="Alert not found")
        return AlertResponse.from_orm(alert)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to acknowledge alert: {e}")
        raise HTTPException(status_code=500, detail="Failed to acknowledge alert")

@router.get("/alerts/summary", response_model=AlertSummary)
async def get_alert_summary(
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取告警汇总"""
    try:
        return await monitoring_service.get_alert_summary()
    except Exception as e:
        logger.error(f"Failed to get alert summary: {e}")
        raise HTTPException(status_code=500, detail="Failed to get alert summary")

# 仪表板相关API
@router.post("/dashboards", response_model=DashboardResponse)
async def create_dashboard(
    dashboard_data: DashboardCreate,
    created_by: str = "system",  # 在实际应用中从JWT token获取
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """创建仪表板"""
    try:
        dashboard = await monitoring_service.create_dashboard(dashboard_data, created_by)
        return DashboardResponse.from_orm(dashboard)
    except Exception as e:
        logger.error(f"Failed to create dashboard: {e}")
        raise HTTPException(status_code=500, detail="Failed to create dashboard")

@router.get("/dashboards", response_model=List[DashboardResponse])
async def get_dashboards(
    created_by: Optional[str] = Query(None, description="创建者"),
    is_public: Optional[bool] = Query(None, description="是否公开"),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取仪表板列表"""
    try:
        dashboards = await monitoring_service.get_dashboards(created_by, is_public)
        return [DashboardResponse.from_orm(dashboard) for dashboard in dashboards]
    except Exception as e:
        logger.error(f"Failed to get dashboards: {e}")
        raise HTTPException(status_code=500, detail="Failed to get dashboards")

@router.get("/dashboards/{dashboard_id}", response_model=DashboardResponse)
async def get_dashboard(
    dashboard_id: str,
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取仪表板详情"""
    try:
        dashboard = await monitoring_service.get_dashboard(dashboard_id)
        if not dashboard:
            raise HTTPException(status_code=404, detail="Dashboard not found")
        return DashboardResponse.from_orm(dashboard)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get dashboard: {e}")
        raise HTTPException(status_code=500, detail="Failed to get dashboard")

@router.put("/dashboards/{dashboard_id}", response_model=DashboardResponse)
async def update_dashboard(
    dashboard_id: str,
    dashboard_data: DashboardUpdate,
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """更新仪表板"""
    try:
        dashboard = await monitoring_service.update_dashboard(dashboard_id, dashboard_data)
        if not dashboard:
            raise HTTPException(status_code=404, detail="Dashboard not found")
        return DashboardResponse.from_orm(dashboard)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update dashboard: {e}")
        raise HTTPException(status_code=500, detail="Failed to update dashboard")

@router.delete("/dashboards/{dashboard_id}")
async def delete_dashboard(
    dashboard_id: str,
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """删除仪表板"""
    try:
        success = await monitoring_service.delete_dashboard(dashboard_id)
        if not success:
            raise HTTPException(status_code=404, detail="Dashboard not found")
        return {"message": "Dashboard deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete dashboard: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete dashboard")

# 日志相关API
@router.post("/logs", response_model=LogEntryResponse)
async def create_log_entry(
    log_data: LogEntryCreate,
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """创建日志条目"""
    try:
        log_entry = await monitoring_service.create_log_entry(log_data)
        return LogEntryResponse.from_orm(log_entry)
    except Exception as e:
        logger.error(f"Failed to create log entry: {e}")
        raise HTTPException(status_code=500, detail="Failed to create log entry")

@router.get("/logs", response_model=List[LogEntryResponse])
async def get_log_entries(
    service_id: Optional[str] = Query(None, description="服务ID"),
    level: Optional[str] = Query(None, description="日志级别"),
    start_time: Optional[datetime] = Query(None, description="开始时间"),
    end_time: Optional[datetime] = Query(None, description="结束时间"),
    search: Optional[str] = Query(None, description="搜索关键词"),
    limit: int = Query(100, ge=1, le=1000, description="限制数量"),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取日志条目"""
    try:
        log_entries = await monitoring_service.get_log_entries(
            service_id=service_id,
            level=level,
            start_time=start_time,
            end_time=end_time,
            search=search,
            limit=limit
        )
        return [LogEntryResponse.from_orm(log_entry) for log_entry in log_entries]
    except Exception as e:
        logger.error(f"Failed to get log entries: {e}")
        raise HTTPException(status_code=500, detail="Failed to get log entries")

# 服务健康相关API
@router.get("/health/services", response_model=List[ServiceHealthResponse])
async def get_services_health(
    service_id: Optional[str] = Query(None, description="服务ID"),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取服务健康状态"""
    try:
        if service_id:
            services_health = await monitoring_service.get_service_health(service_id)
        else:
            services_health = await monitoring_service.get_all_services_health()
        return [ServiceHealthResponse.from_orm(service) for service in services_health]
    except Exception as e:
        logger.error(f"Failed to get services health: {e}")
        raise HTTPException(status_code=500, detail="Failed to get services health")

@router.put("/health/services/{service_id}", response_model=ServiceHealthResponse)
async def update_service_health(
    service_id: str,
    health_data: ServiceHealthUpdate,
    service_name: str = Query(..., description="服务名称"),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """更新服务健康状态"""
    try:
        service_health = await monitoring_service.update_service_health(
            service_id, service_name, health_data
        )
        return ServiceHealthResponse.from_orm(service_health)
    except Exception as e:
        logger.error(f"Failed to update service health: {e}")
        raise HTTPException(status_code=500, detail="Failed to update service health")