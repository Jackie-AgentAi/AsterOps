"""
监控服务主应用
"""
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.core.config import settings
from app.core.logging import setup_logging
from app.core.database import init_db
from app.core.middleware import LoggingMiddleware, MetricsMiddleware
from app.core.exceptions import MonitoringServiceException, map_to_http_exception
from app.api.v1.monitoring import router as monitoring_router
from prometheus_client import make_asgi_app

# 设置日志
logger = setup_logging()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时执行
    logger.info("Starting Monitoring Service...")
    
    # 暂时跳过数据库初始化，直接启动服务
    logger.info("Monitoring Service started (database initialization skipped)")
    
    yield
    
    # 关闭时执行
    logger.info("Shutting down Monitoring Service...")

# 创建FastAPI应用
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="LLMOps平台监控服务",
    lifespan=lifespan,
    debug=settings.debug
)

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 在生产环境中应该设置具体的域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 添加自定义中间件
app.add_middleware(LoggingMiddleware)
app.add_middleware(MetricsMiddleware)

# 添加Prometheus指标
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

# 全局异常处理器
@app.exception_handler(MonitoringServiceException)
async def monitoring_exception_handler(request: Request, exc: MonitoringServiceException):
    """监控服务异常处理器"""
    logger.error(f"Monitoring service exception: {exc.message}", extra=exc.details)
    http_exc = map_to_http_exception(exc)
    return JSONResponse(
        status_code=http_exc.status_code,
        content={"detail": http_exc.detail, "details": exc.details}
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """请求验证异常处理器"""
    logger.error(f"Validation error: {exc}")
    return JSONResponse(
        status_code=422,
        content={"detail": "Validation error", "errors": exc.errors()}
    )

@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    """HTTP异常处理器"""
    logger.error(f"HTTP exception: {exc.status_code} - {exc.detail}")
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """通用异常处理器"""
    logger.error(f"Unexpected error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )

# 健康检查端点
@app.get("/health")
async def health_check():
    """健康检查"""
    return {
        "status": "healthy",
        "service": "monitoring-service",
        "version": settings.app_version,
        "timestamp": "2024-01-01T00:00:00Z"
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
        "version": settings.app_version,
        "docs": "/docs",
        "health": "/health"
    }

# 注册API路由
app.include_router(
    monitoring_router,
    prefix="/api/v1",
    tags=["monitoring"]
)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug
    )