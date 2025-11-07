"""
依赖注入
"""
from typing import Generator
from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.services.model_service import ModelService


def get_model_service(db: Session = Depends(get_db)) -> ModelService:
    """获取模型服务实例"""
    return ModelService(db_session=db)


def get_current_user() -> dict:
    """获取当前用户（模拟）"""
    # 这里应该从JWT token中解析用户信息
    # 暂时返回模拟用户数据
    return {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "username": "testuser",
        "email": "test@example.com",
        "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
        "roles": ["user"]
    }
