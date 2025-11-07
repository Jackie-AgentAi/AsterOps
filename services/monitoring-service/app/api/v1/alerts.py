"""
告警API路由
"""
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse
import structlog

from app.schemas.monitoring import (
    AlertCreate, AlertUpdate, AlertResponse, AlertListResponse,
    AlertInstanceResponse, AlertInstanceListResponse,
    AlertNotificationResponse, AlertAcknowledgeRequest, AlertResolveRequest
)
from app.services.monitoring_service import MonitoringService
from app.core.dependencies import get_monitoring_service, get_current_user

logger = structlog.get_logger(__name__)
router = APIRouter()


@router.post("/", response_model=AlertResponse, status_code=201)
async def create_alert(
    alert_data: AlertCreate,
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """创建告警规则"""
    try:
        alert = await monitoring_service.create_alert(
            alert_data=alert_data,
            tenant_id=current_user["tenant_id"]
        )
        logger.info("Alert created", alert_id=str(alert.id), name=alert_data.name)
        return alert
    except Exception as e:
        logger.error("Failed to create alert", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to create alert")


@router.get("/", response_model=AlertListResponse)
async def list_alerts(
    service_id: Optional[str] = Query(None, description="服务ID过滤"),
    status: Optional[str] = Query(None, description="状态过滤"),
    severity: Optional[str] = Query(None, description="严重程度过滤"),
    offset: int = Query(0, ge=0, description="偏移量"),
    limit: int = Query(20, ge=1, le=100, description="限制数量"),
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取告警列表"""
    try:
        alerts = await monitoring_service.list_alerts(
            service_id=service_id,
            status=status,
            severity=severity,
            offset=offset,
            limit=limit,
            tenant_id=current_user["tenant_id"]
        )
        return alerts
    except Exception as e:
        logger.error("Failed to list alerts", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list alerts")


@router.get("/{alert_id}", response_model=AlertResponse)
async def get_alert(
    alert_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取告警详情"""
    try:
        alert = await monitoring_service.get_alert(
            alert_id=alert_id,
            tenant_id=current_user["tenant_id"]
        )
        if not alert:
            raise HTTPException(status_code=404, detail="Alert not found")
        return alert
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get alert", alert_id=str(alert_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get alert")


@router.put("/{alert_id}", response_model=AlertResponse)
async def update_alert(
    alert_id: uuid.UUID,
    alert_data: AlertUpdate,
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """更新告警规则"""
    try:
        alert = await monitoring_service.update_alert(
            alert_id=alert_id,
            alert_data=alert_data,
            tenant_id=current_user["tenant_id"]
        )
        if not alert:
            raise HTTPException(status_code=404, detail="Alert not found")
        logger.info("Alert updated", alert_id=str(alert_id))
        return alert
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to update alert", alert_id=str(alert_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to update alert")


@router.delete("/{alert_id}", status_code=204)
async def delete_alert(
    alert_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """删除告警规则"""
    try:
        success = await monitoring_service.delete_alert(
            alert_id=alert_id,
            tenant_id=current_user["tenant_id"]
        )
        if not success:
            raise HTTPException(status_code=404, detail="Alert not found")
        logger.info("Alert deleted", alert_id=str(alert_id))
        return None
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to delete alert", alert_id=str(alert_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to delete alert")


@router.get("/{alert_id}/instances", response_model=AlertInstanceListResponse)
async def list_alert_instances(
    alert_id: uuid.UUID,
    status: Optional[str] = Query(None, description="状态过滤"),
    offset: int = Query(0, ge=0, description="偏移量"),
    limit: int = Query(20, ge=1, le=100, description="限制数量"),
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取告警实例列表"""
    try:
        instances = await monitoring_service.list_alert_instances(
            alert_id=alert_id,
            status=status,
            offset=offset,
            limit=limit,
            tenant_id=current_user["tenant_id"]
        )
        return instances
    except Exception as e:
        logger.error("Failed to list alert instances", alert_id=str(alert_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list alert instances")


@router.get("/instances", response_model=AlertInstanceListResponse)
async def list_all_alert_instances(
    service_id: Optional[str] = Query(None, description="服务ID过滤"),
    status: Optional[str] = Query(None, description="状态过滤"),
    severity: Optional[str] = Query(None, description="严重程度过滤"),
    offset: int = Query(0, ge=0, description="偏移量"),
    limit: int = Query(20, ge=1, le=100, description="限制数量"),
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取所有告警实例"""
    try:
        instances = await monitoring_service.list_all_alert_instances(
            service_id=service_id,
            status=status,
            severity=severity,
            offset=offset,
            limit=limit,
            tenant_id=current_user["tenant_id"]
        )
        return instances
    except Exception as e:
        logger.error("Failed to list all alert instances", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list all alert instances")


@router.get("/instances/{instance_id}", response_model=AlertInstanceResponse)
async def get_alert_instance(
    instance_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取告警实例详情"""
    try:
        instance = await monitoring_service.get_alert_instance(
            instance_id=instance_id,
            tenant_id=current_user["tenant_id"]
        )
        if not instance:
            raise HTTPException(status_code=404, detail="Alert instance not found")
        return instance
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get alert instance", instance_id=str(instance_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get alert instance")


@router.post("/instances/{instance_id}/acknowledge")
async def acknowledge_alert_instance(
    instance_id: uuid.UUID,
    request_data: AlertAcknowledgeRequest,
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """确认告警实例"""
    try:
        success = await monitoring_service.acknowledge_alert_instance(
            instance_id=instance_id,
            acknowledged_by=request_data.acknowledged_by,
            comment=request_data.comment,
            tenant_id=current_user["tenant_id"]
        )
        if not success:
            raise HTTPException(status_code=404, detail="Alert instance not found")
        logger.info("Alert instance acknowledged", instance_id=str(instance_id))
        return {"message": "Alert instance acknowledged successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to acknowledge alert instance", instance_id=str(instance_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to acknowledge alert instance")


@router.post("/instances/{instance_id}/resolve")
async def resolve_alert_instance(
    instance_id: uuid.UUID,
    request_data: AlertResolveRequest,
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """解决告警实例"""
    try:
        success = await monitoring_service.resolve_alert_instance(
            instance_id=instance_id,
            resolved_by=request_data.resolved_by,
            comment=request_data.comment,
            tenant_id=current_user["tenant_id"]
        )
        if not success:
            raise HTTPException(status_code=404, detail="Alert instance not found")
        logger.info("Alert instance resolved", instance_id=str(instance_id))
        return {"message": "Alert instance resolved successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to resolve alert instance", instance_id=str(instance_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to resolve alert instance")


@router.get("/instances/{instance_id}/notifications", response_model=List[AlertNotificationResponse])
async def list_alert_notifications(
    instance_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """获取告警通知列表"""
    try:
        notifications = await monitoring_service.list_alert_notifications(
            instance_id=instance_id,
            tenant_id=current_user["tenant_id"]
        )
        return notifications
    except Exception as e:
        logger.error("Failed to list alert notifications", instance_id=str(instance_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list alert notifications")


@router.post("/{alert_id}/enable")
async def enable_alert(
    alert_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """启用告警规则"""
    try:
        success = await monitoring_service.enable_alert(
            alert_id=alert_id,
            tenant_id=current_user["tenant_id"]
        )
        if not success:
            raise HTTPException(status_code=404, detail="Alert not found")
        logger.info("Alert enabled", alert_id=str(alert_id))
        return {"message": "Alert enabled successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to enable alert", alert_id=str(alert_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to enable alert")


@router.post("/{alert_id}/disable")
async def disable_alert(
    alert_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """禁用告警规则"""
    try:
        success = await monitoring_service.disable_alert(
            alert_id=alert_id,
            tenant_id=current_user["tenant_id"]
        )
        if not success:
            raise HTTPException(status_code=404, detail="Alert not found")
        logger.info("Alert disabled", alert_id=str(alert_id))
        return {"message": "Alert disabled successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to disable alert", alert_id=str(alert_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to disable alert")


@router.post("/{alert_id}/test")
async def test_alert(
    alert_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    monitoring_service: MonitoringService = Depends(get_monitoring_service)
):
    """测试告警规则"""
    try:
        result = await monitoring_service.test_alert(
            alert_id=alert_id,
            tenant_id=current_user["tenant_id"]
        )
        logger.info("Alert tested", alert_id=str(alert_id), result=result)
        return result
    except Exception as e:
        logger.error("Failed to test alert", alert_id=str(alert_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to test alert")



