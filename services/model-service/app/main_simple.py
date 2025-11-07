"""
简化的模型管理服务主应用（跳过数据库初始化）
"""
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# 设置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 创建FastAPI应用
app = FastAPI(
    title="Model Service",
    description="LLMOps模型管理服务",
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
    return {
        "status": "ready",
        "service": "model-service"
    }

@app.get("/metrics")
async def metrics():
    """Prometheus指标端点"""
    return """# HELP model_service_requests_total Total number of requests
# TYPE model_service_requests_total counter
model_service_requests_total{service="model-service"} 0

# HELP model_service_health_status Service health status
# TYPE model_service_health_status gauge
model_service_health_status{service="model-service"} 1

# HELP model_service_info Service information
# TYPE model_service_info gauge
model_service_info{service="model-service",version="1.0.0"} 1
"""

# 根路径
@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "Model Service API",
        "version": "1.0.0",
        "docs": "/docs"
    }

# 模型管理API（简化版本）
@app.get("/api/v1/models")
async def list_models():
    """获取模型列表"""
    return {
        "models": [
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "name": "Test Model 1",
                "description": "A test model",
                "framework": "pytorch",
                "task_type": "text_classification",
                "status": "active",
                "is_public": False,
                "tags": ["test", "demo"],
                "created_at": "2024-01-01T00:00:00Z"
            },
            {
                "id": "550e8400-e29b-41d4-a716-446655440001",
                "name": "Test Model 2",
                "description": "Another test model",
                "framework": "tensorflow",
                "task_type": "image_classification",
                "status": "active",
                "is_public": True,
                "tags": ["test", "image"],
                "created_at": "2024-01-01T00:00:00Z"
            }
        ],
        "total": 2
    }

@app.get("/api/v1/models/{model_id}")
async def get_model(model_id: str):
    """获取模型详情"""
    return {
        "id": model_id,
        "name": "Test Model",
        "description": "A test model",
        "framework": "pytorch",
        "task_type": "text_classification",
        "status": "active",
        "is_public": False,
        "tags": ["test", "demo"],
        "created_at": "2024-01-01T00:00:00Z"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main_simple:app",
        host="0.0.0.0",
        port=8083,
        reload=False,
        log_level="info"
    )
