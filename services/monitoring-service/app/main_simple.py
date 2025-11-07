"""
简化的监控服务主应用
"""
import logging
from datetime import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# 设置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 创建FastAPI应用
app = FastAPI(
    title="LLMOps Monitoring Service",
    version="1.0.0",
    description="LLMOps平台监控服务"
)

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 健康检查端点
@app.get("/health")
async def health_check():
    """健康检查"""
    return {
        "status": "healthy",
        "service": "monitoring-service",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/ready")
async def readiness_check():
    """就绪检查"""
    return {"status": "ready"}

@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "LLMOps Monitoring Service API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health"
    }

# 监控指标相关API
@app.get("/api/v1/metrics")
async def get_metrics():
    """获取监控指标"""
    return {
        "success": True,
        "data": {
            "metrics": [
                {
                    "id": "metric-1",
                    "service_id": "user-service",
                    "metric_name": "request_count",
                    "metric_value": 100.0,
                    "metric_unit": "count",
                    "timestamp": datetime.utcnow().isoformat()
                },
                {
                    "id": "metric-2",
                    "service_id": "model-service",
                    "metric_name": "response_time",
                    "metric_value": 250.5,
                    "metric_unit": "ms",
                    "timestamp": datetime.utcnow().isoformat()
                }
            ],
            "total": 2
        }
    }

@app.get("/api/v1/metrics/summary")
async def get_metrics_summary():
    """获取指标汇总"""
    return {
        "success": True,
        "data": {
            "total_metrics": 150,
            "services_count": 6,
            "alerts_count": 3,
            "active_alerts": 1,
            "last_updated": datetime.utcnow().isoformat()
        }
    }

# 告警相关API
@app.get("/api/v1/alerts")
async def get_alerts():
    """获取告警列表"""
    return {
        "success": True,
        "data": {
            "alerts": [
                {
                    "id": "alert-1",
                    "name": "High CPU Usage",
                    "description": "CPU usage is above 80%",
                    "service_id": "model-service",
                    "metric_name": "cpu_usage",
                    "threshold": 80.0,
                    "operator": ">",
                    "severity": "warning",
                    "status": "active",
                    "is_acknowledged": False,
                    "created_at": datetime.utcnow().isoformat()
                }
            ],
            "total": 1
        }
    }

@app.get("/api/v1/alerts/summary")
async def get_alert_summary():
    """获取告警汇总"""
    return {
        "success": True,
        "data": {
            "total_alerts": 5,
            "active_alerts": 1,
            "acknowledged_alerts": 2,
            "critical_alerts": 0,
            "warning_alerts": 1,
            "info_alerts": 0
        }
    }

# 仪表板相关API
@app.get("/api/v1/dashboards")
async def get_dashboards():
    """获取仪表板列表"""
    return {
        "success": True,
        "data": {
            "dashboards": [
                {
                    "id": "dashboard-1",
                    "name": "System Overview",
                    "description": "Overall system monitoring dashboard",
                    "is_public": True,
                    "created_by": "admin",
                    "created_at": datetime.utcnow().isoformat()
                }
            ],
            "total": 1
        }
    }

# 日志相关API
@app.get("/api/v1/logs")
async def get_logs():
    """获取日志条目"""
    return {
        "success": True,
        "data": {
            "logs": [
                {
                    "id": "log-1",
                    "service_id": "user-service",
                    "level": "INFO",
                    "message": "User login successful",
                    "timestamp": datetime.utcnow().isoformat()
                },
                {
                    "id": "log-2",
                    "service_id": "model-service",
                    "level": "WARN",
                    "message": "Model loading took longer than expected",
                    "timestamp": datetime.utcnow().isoformat()
                }
            ],
            "total": 2
        }
    }

# 服务健康相关API
@app.get("/api/v1/health/services")
async def get_services_health():
    """获取服务健康状态"""
    return {
        "success": True,
        "data": {
            "services": [
                {
                    "id": "service-1",
                    "service_id": "user-service",
                    "service_name": "User Service",
                    "status": "healthy",
                    "last_check": datetime.utcnow().isoformat(),
                    "response_time": 45.2
                },
                {
                    "id": "service-2",
                    "service_id": "model-service",
                    "service_name": "Model Service",
                    "status": "healthy",
                    "last_check": datetime.utcnow().isoformat(),
                    "response_time": 120.5
                }
            ],
            "total": 2
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main_simple:app",
        host="0.0.0.0",
        port=8086,
        reload=False
    )
