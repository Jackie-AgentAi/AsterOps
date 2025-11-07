"""
监控服务业务逻辑
"""
import asyncio
import logging
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc, func

from app.models.monitoring import Metric, Alert, Dashboard, LogEntry, ServiceHealth
from app.schemas.monitoring import (
    MetricCreate, AlertCreate, AlertUpdate, DashboardCreate, DashboardUpdate,
    LogEntryCreate, ServiceHealthUpdate, MetricsSummary, AlertSummary
)

logger = logging.getLogger(__name__)

class MonitoringService:
    """监控服务"""
    
    def __init__(self, db: Session):
        self.db = db

    # 监控指标相关方法
    async def create_metric(self, metric_data: MetricCreate) -> Metric:
        """创建监控指标"""
        metric = Metric(
            service_id=metric_data.service_id,
            metric_name=metric_data.metric_name,
            metric_value=metric_data.metric_value,
            metric_unit=metric_data.metric_unit,
            labels=metric_data.labels
        )
        self.db.add(metric)
        self.db.commit()
        self.db.refresh(metric)
        logger.info(f"Created metric: {metric.id} for service {metric_data.service_id}")
        return metric

    async def get_metrics(
        self, 
        service_id: Optional[str] = None,
        metric_name: Optional[str] = None,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        limit: int = 100
    ) -> List[Metric]:
        """获取监控指标"""
        query = self.db.query(Metric)
        
        if service_id:
            query = query.filter(Metric.service_id == service_id)
        if metric_name:
            query = query.filter(Metric.metric_name == metric_name)
        if start_time:
            query = query.filter(Metric.timestamp >= start_time)
        if end_time:
            query = query.filter(Metric.timestamp <= end_time)
            
        return query.order_by(desc(Metric.timestamp)).limit(limit).all()

    async def get_metrics_summary(self) -> MetricsSummary:
        """获取指标汇总"""
        total_metrics = self.db.query(Metric).count()
        services_count = self.db.query(Metric.service_id).distinct().count()
        alerts_count = self.db.query(Alert).count()
        active_alerts = self.db.query(Alert).filter(Alert.status == "active").count()
        
        return MetricsSummary(
            total_metrics=total_metrics,
            services_count=services_count,
            alerts_count=alerts_count,
            active_alerts=active_alerts,
            last_updated=datetime.utcnow()
        )

    # 告警相关方法
    async def create_alert(self, alert_data: AlertCreate, created_by: str) -> Alert:
        """创建告警规则"""
        alert = Alert(
            name=alert_data.name,
            description=alert_data.description,
            service_id=alert_data.service_id,
            metric_name=alert_data.metric_name,
            threshold=alert_data.threshold,
            operator=alert_data.operator,
            duration=alert_data.duration,
            severity=alert_data.severity
        )
        self.db.add(alert)
        self.db.commit()
        self.db.refresh(alert)
        logger.info(f"Created alert: {alert.id} for service {alert_data.service_id}")
        return alert

    async def get_alerts(
        self,
        service_id: Optional[str] = None,
        status: Optional[str] = None,
        severity: Optional[str] = None,
        limit: int = 100
    ) -> List[Alert]:
        """获取告警列表"""
        query = self.db.query(Alert)
        
        if service_id:
            query = query.filter(Alert.service_id == service_id)
        if status:
            query = query.filter(Alert.status == status)
        if severity:
            query = query.filter(Alert.severity == severity)
            
        return query.order_by(desc(Alert.created_at)).limit(limit).all()

    async def update_alert(self, alert_id: str, alert_data: AlertUpdate) -> Optional[Alert]:
        """更新告警规则"""
        alert = self.db.query(Alert).filter(Alert.id == alert_id).first()
        if not alert:
            return None
            
        update_data = alert_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(alert, field, value)
            
        self.db.commit()
        self.db.refresh(alert)
        logger.info(f"Updated alert: {alert_id}")
        return alert

    async def delete_alert(self, alert_id: str) -> bool:
        """删除告警规则"""
        alert = self.db.query(Alert).filter(Alert.id == alert_id).first()
        if not alert:
            return False
            
        self.db.delete(alert)
        self.db.commit()
        logger.info(f"Deleted alert: {alert_id}")
        return True

    async def acknowledge_alert(self, alert_id: str, acknowledged_by: str) -> Optional[Alert]:
        """确认告警"""
        alert = self.db.query(Alert).filter(Alert.id == alert_id).first()
        if not alert:
            return None
            
        alert.is_acknowledged = True
        alert.acknowledged_by = acknowledged_by
        alert.acknowledged_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(alert)
        logger.info(f"Acknowledged alert: {alert_id} by {acknowledged_by}")
        return alert

    async def get_alert_summary(self) -> AlertSummary:
        """获取告警汇总"""
        total_alerts = self.db.query(Alert).count()
        active_alerts = self.db.query(Alert).filter(Alert.status == "active").count()
        acknowledged_alerts = self.db.query(Alert).filter(Alert.is_acknowledged == True).count()
        critical_alerts = self.db.query(Alert).filter(Alert.severity == "critical").count()
        warning_alerts = self.db.query(Alert).filter(Alert.severity == "warning").count()
        info_alerts = self.db.query(Alert).filter(Alert.severity == "info").count()
        
        return AlertSummary(
            total_alerts=total_alerts,
            active_alerts=active_alerts,
            acknowledged_alerts=acknowledged_alerts,
            critical_alerts=critical_alerts,
            warning_alerts=warning_alerts,
            info_alerts=info_alerts
        )

    # 仪表板相关方法
    async def create_dashboard(self, dashboard_data: DashboardCreate, created_by: str) -> Dashboard:
        """创建仪表板"""
        dashboard = Dashboard(
            name=dashboard_data.name,
            description=dashboard_data.description,
            config=dashboard_data.config,
            is_public=dashboard_data.is_public,
            created_by=created_by
        )
        self.db.add(dashboard)
        self.db.commit()
        self.db.refresh(dashboard)
        logger.info(f"Created dashboard: {dashboard.id} by {created_by}")
        return dashboard

    async def get_dashboards(self, created_by: Optional[str] = None, is_public: Optional[bool] = None) -> List[Dashboard]:
        """获取仪表板列表"""
        query = self.db.query(Dashboard)
        
        if created_by:
            query = query.filter(Dashboard.created_by == created_by)
        if is_public is not None:
            query = query.filter(Dashboard.is_public == is_public)
            
        return query.order_by(desc(Dashboard.created_at)).all()

    async def get_dashboard(self, dashboard_id: str) -> Optional[Dashboard]:
        """获取仪表板详情"""
        return self.db.query(Dashboard).filter(Dashboard.id == dashboard_id).first()

    async def update_dashboard(self, dashboard_id: str, dashboard_data: DashboardUpdate) -> Optional[Dashboard]:
        """更新仪表板"""
        dashboard = self.db.query(Dashboard).filter(Dashboard.id == dashboard_id).first()
        if not dashboard:
            return None
            
        update_data = dashboard_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(dashboard, field, value)
            
        self.db.commit()
        self.db.refresh(dashboard)
        logger.info(f"Updated dashboard: {dashboard_id}")
        return dashboard

    async def delete_dashboard(self, dashboard_id: str) -> bool:
        """删除仪表板"""
        dashboard = self.db.query(Dashboard).filter(Dashboard.id == dashboard_id).first()
        if not dashboard:
            return False
            
        self.db.delete(dashboard)
        self.db.commit()
        logger.info(f"Deleted dashboard: {dashboard_id}")
        return True

    # 日志相关方法
    async def create_log_entry(self, log_data: LogEntryCreate) -> LogEntry:
        """创建日志条目"""
        log_entry = LogEntry(
            service_id=log_data.service_id,
            level=log_data.level,
            message=log_data.message,
            source=log_data.source,
            trace_id=log_data.trace_id,
            user_id=log_data.user_id,
            metadata=log_data.metadata
        )
        self.db.add(log_entry)
        self.db.commit()
        self.db.refresh(log_entry)
        logger.info(f"Created log entry: {log_entry.id} for service {log_data.service_id}")
        return log_entry

    async def get_log_entries(
        self,
        service_id: Optional[str] = None,
        level: Optional[str] = None,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        search: Optional[str] = None,
        limit: int = 100
    ) -> List[LogEntry]:
        """获取日志条目"""
        query = self.db.query(LogEntry)
        
        if service_id:
            query = query.filter(LogEntry.service_id == service_id)
        if level:
            query = query.filter(LogEntry.level == level)
        if start_time:
            query = query.filter(LogEntry.timestamp >= start_time)
        if end_time:
            query = query.filter(LogEntry.timestamp <= end_time)
        if search:
            query = query.filter(LogEntry.message.contains(search))
            
        return query.order_by(desc(LogEntry.timestamp)).limit(limit).all()

    # 服务健康相关方法
    async def update_service_health(self, service_id: str, service_name: str, health_data: ServiceHealthUpdate) -> ServiceHealth:
        """更新服务健康状态"""
        service_health = self.db.query(ServiceHealth).filter(ServiceHealth.service_id == service_id).first()
        
        if not service_health:
            service_health = ServiceHealth(
                service_id=service_id,
                service_name=service_name,
                status=health_data.status,
                response_time=health_data.response_time,
                error_message=health_data.error_message,
                metadata=health_data.metadata
            )
            self.db.add(service_health)
        else:
            service_health.status = health_data.status
            service_health.response_time = health_data.response_time
            service_health.error_message = health_data.error_message
            service_health.metadata = health_data.metadata
            service_health.last_check = datetime.utcnow()
            
        self.db.commit()
        self.db.refresh(service_health)
        logger.info(f"Updated service health: {service_id} - {health_data.status}")
        return service_health

    async def get_service_health(self, service_id: Optional[str] = None) -> List[ServiceHealth]:
        """获取服务健康状态"""
        query = self.db.query(ServiceHealth)
        
        if service_id:
            query = query.filter(ServiceHealth.service_id == service_id)
            
        return query.order_by(desc(ServiceHealth.last_check)).all()

    async def get_all_services_health(self) -> List[ServiceHealth]:
        """获取所有服务健康状态"""
        return self.db.query(ServiceHealth).order_by(desc(ServiceHealth.last_check)).all()
