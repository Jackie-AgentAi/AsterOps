"""
FastAPI依赖注入
"""
from fastapi import Depends, HTTPException, status
from app.services.inference_service import InferenceService
from app.core.database import SessionLocal

def get_db():
    """获取数据库会话"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_inference_service(db: SessionLocal = Depends(get_db)) -> InferenceService:
    """获取推理服务实例"""
    return InferenceService(db)

def get_current_user():
    """获取当前用户（模拟）"""
    # 实际应用中会从JWT token中解析用户信息
    # 这里为了简化，直接返回一个模拟用户
    return {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "username": "testuser",
        "email": "test@example.com",
        "roles": ["admin"],
        "tenant_id": "550e8400-e29b-41d4-a716-446655440000"
    }


