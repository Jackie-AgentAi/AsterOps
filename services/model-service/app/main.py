"""
模型管理服务主应用
"""
import logging
import os
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from prometheus_client import make_asgi_app
import structlog

from app.api.v1 import models, model_versions, model_deployments, model_evaluations
from app.core.config import settings
from app.core.database import init_db
from app.core.logging import setup_logging
from app.core.middleware import LoggingMiddleware, MetricsMiddleware
from app.core.exceptions import ModelServiceException


# 设置日志
setup_logging()
logger = structlog.get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """应用生命周期管理"""
    # 启动时执行
    logger.info("Starting Model Service...")
    
    # 初始化数据库
    await init_db()
    logger.info("Database initialized")
    
    # 初始化Redis连接
    # await init_redis()
    # logger.info("Redis initialized")
    
    # 初始化服务发现
    # await init_consul()
    # logger.info("Service discovery initialized")
    
    yield
    
    # 关闭时执行
    logger.info("Shutting down Model Service...")


# 创建FastAPI应用
app = FastAPI(
    title="Model Service",
    description="LLMOps模型管理服务",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan
)

# 添加中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_HOSTS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=settings.ALLOWED_HOSTS
)

app.add_middleware(LoggingMiddleware)
app.add_middleware(MetricsMiddleware)

# 添加Prometheus指标
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


# 全局异常处理
@app.exception_handler(ModelServiceException)
async def model_service_exception_handler(request: Request, exc: ModelServiceException):
    """模型服务异常处理"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.error_code,
            "message": exc.message,
            "details": exc.details
        }
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """通用异常处理"""
    logger.error("Unhandled exception", exc_info=exc)
    return JSONResponse(
        status_code=500,
        content={
            "error": "INTERNAL_SERVER_ERROR",
            "message": "Internal server error",
            "details": str(exc) if settings.DEBUG else None
        }
    )


# 健康检查端点
@app.get("/health")
async def health_check():
    """健康检查"""
    return {
        "status": "healthy",
        "service": "model-service",
        "version": "1.0.0"
    }


@app.get("/ready")
async def readiness_check():
    """就绪检查"""
    # 检查数据库连接
    # 检查Redis连接
    # 检查其他依赖服务
    return {
        "status": "ready",
        "service": "model-service"
    }


# 根路径
@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "Model Service API",
        "version": "1.0.0",
        "docs": "/docs"
    }


# 注册路由
app.include_router(
    models.router,
    prefix="/api/v1/models",
    tags=["models"]
)

app.include_router(
    model_versions.router,
    prefix="/api/v1/models/{model_id}/versions",
    tags=["model-versions"]
)

app.include_router(
    model_deployments.router,
    prefix="/api/v1/models/{model_id}/deployments",
    tags=["model-deployments"]
)

app.include_router(
    model_evaluations.router,
    prefix="/api/v1/models/{model_id}/evaluations",
    tags=["model-evaluations"]
)


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8083,
        reload=settings.DEBUG,
        log_level="info"
    )



