"""
推理服务主应用
"""
import logging
import os
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
from prometheus_client import make_asgi_app
import structlog

from app.api.v1 import inference, models, metrics
from app.core.config import settings
from app.core.database import init_db
from app.core.logging import setup_logging
from app.core.middleware import LoggingMiddleware, MetricsMiddleware
from app.core.exceptions import InferenceServiceException
from app.services.model_manager import ModelManager


# 设置日志
setup_logging()
logger = structlog.get_logger(__name__)

# 全局模型管理器
model_manager = None


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """应用生命周期管理"""
    global model_manager
    
    # 启动时执行
    logger.info("Starting Inference Service...")
    
    # 初始化数据库
    await init_db()
    logger.info("Database initialized")
    
    # 初始化模型管理器
    model_manager = ModelManager()
    await model_manager.initialize()
    logger.info("Model manager initialized")
    
    # 初始化Redis连接
    # await init_redis()
    # logger.info("Redis initialized")
    
    # 初始化服务发现
    # await init_consul()
    # logger.info("Service discovery initialized")
    
    yield
    
    # 关闭时执行
    logger.info("Shutting down Inference Service...")
    if model_manager:
        await model_manager.cleanup()
        logger.info("Model manager cleaned up")


# 创建FastAPI应用
app = FastAPI(
    title="Inference Service",
    description="LLMOps推理服务",
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
@app.exception_handler(InferenceServiceException)
async def inference_service_exception_handler(request: Request, exc: InferenceServiceException):
    """推理服务异常处理"""
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
    # 检查模型管理器状态
    model_status = "healthy"
    if model_manager:
        model_status = await model_manager.get_health_status()
    
    return {
        "status": "healthy" if model_status == "healthy" else "degraded",
        "service": "inference-service",
        "version": "1.0.0",
        "models": model_status
    }


@app.get("/ready")
async def readiness_check():
    """就绪检查"""
    # 检查数据库连接
    # 检查Redis连接
    # 检查模型管理器状态
    if not model_manager:
        return JSONResponse(
            status_code=503,
            content={"status": "not_ready", "reason": "model_manager_not_initialized"}
        )
    
    return {
        "status": "ready",
        "service": "inference-service"
    }


# 根路径
@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "Inference Service API",
        "version": "1.0.0",
        "docs": "/docs"
    }


# 注册路由
app.include_router(
    inference.router,
    prefix="/api/v1/inference",
    tags=["inference"]
)

app.include_router(
    models.router,
    prefix="/api/v1/models",
    tags=["models"]
)

app.include_router(
    metrics.router,
    prefix="/api/v1/metrics",
    tags=["metrics"]
)


# 全局依赖注入
@app.middleware("http")
async def inject_model_manager(request: Request, call_next):
    """注入模型管理器到请求上下文"""
    request.state.model_manager = model_manager
    response = await call_next(request)
    return response


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8084,
        reload=settings.DEBUG,
        log_level="info"
    )



