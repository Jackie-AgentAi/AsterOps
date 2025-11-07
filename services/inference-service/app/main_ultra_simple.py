"""
推理服务超简化版本
"""
import logging
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from prometheus_client import make_asgi_app

# 设置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 创建FastAPI应用
app = FastAPI(
    title="Inference Service (Ultra Simple)",
    description="LLMOps推理服务 (超简化版)",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 添加Prometheus指标
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

# 全局异常处理
@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """通用异常处理"""
    logger.error("Unhandled exception", exc_info=exc)
    return JSONResponse(
        status_code=500,
        content={
            "error": "INTERNAL_SERVER_ERROR",
            "message": "Internal server error",
            "details": str(exc)
        }
    )

# 健康检查端点
@app.get("/health")
async def health_check():
    """健康检查"""
    return {
        "status": "healthy",
        "service": "inference-service",
        "version": "1.0.0"
    }

@app.get("/ready")
async def readiness_check():
    """就绪检查"""
    return {
        "status": "ready",
        "service": "inference-service"
    }

# 根路径
@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "Inference Service API (Ultra Simple)",
        "version": "1.0.0",
        "docs": "/docs"
    }

# 简化的推理端点
@app.post("/api/v1/inference/{model_id}")
async def simple_inference(model_id: str, request_data: dict):
    """简化的推理端点"""
    return {
        "request_id": "12345678-1234-1234-1234-123456789012",
        "model_id": model_id,
        "status": "completed",
        "result": {
            "text": f"Generated response for: {request_data.get('prompt', 'Hello')}",
            "tokens": 50
        },
        "metrics": {
            "inference_time": 1.5,
            "tokens_per_second": 33.3
        }
    }

if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "app.main_ultra_simple:app",
        host="0.0.0.0",
        port=8084,
        reload=False,
        log_level="info"
    )


