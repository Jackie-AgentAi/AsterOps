"""
模型版本管理API路由
"""
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse
import structlog

from app.schemas.model import (
    ModelVersionCreate, ModelVersionUpdate, ModelVersionResponse, ModelVersionListResponse
)
from app.services.model_service import ModelService
from app.core.dependencies import get_model_service, get_current_user

logger = structlog.get_logger(__name__)
router = APIRouter()


@router.post("/", response_model=ModelVersionResponse, status_code=201)
async def create_model_version(
    model_id: uuid.UUID,
    version_data: ModelVersionCreate,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """创建模型版本"""
    try:
        version = await model_service.create_model_version(
            model_id=model_id,
            version_data=version_data,
            tenant_id=current_user["tenant_id"]
        )
        logger.info("Model version created", model_id=str(model_id), version=version_data.version)
        return version
    except Exception as e:
        logger.error("Failed to create model version", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to create model version")


@router.get("/", response_model=ModelVersionListResponse)
async def list_model_versions(
    model_id: uuid.UUID,
    offset: int = Query(0, ge=0, description="偏移量"),
    limit: int = Query(20, ge=1, le=100, description="限制数量"),
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """获取模型版本列表"""
    try:
        result = await model_service.list_model_versions(
            model_id=model_id,
            tenant_id=current_user["tenant_id"],
            offset=offset,
            limit=limit
        )
        return result
    except Exception as e:
        logger.error("Failed to list model versions", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list model versions")


@router.get("/{version}", response_model=ModelVersionResponse)
async def get_model_version(
    model_id: uuid.UUID,
    version: str,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """获取模型版本详情"""
    try:
        version_obj = await model_service.get_model_version(
            model_id=model_id,
            version=version,
            tenant_id=current_user["tenant_id"]
        )
        if not version_obj:
            raise HTTPException(status_code=404, detail="Model version not found")
        return version_obj
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get model version", model_id=str(model_id), version=version, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get model version")


@router.put("/{version}", response_model=ModelVersionResponse)
async def update_model_version(
    model_id: uuid.UUID,
    version: str,
    version_data: ModelVersionUpdate,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """更新模型版本"""
    try:
        version_obj = await model_service.update_model_version(
            model_id=model_id,
            version=version,
            version_data=version_data,
            tenant_id=current_user["tenant_id"]
        )
        if not version_obj:
            raise HTTPException(status_code=404, detail="Model version not found")
        logger.info("Model version updated", model_id=str(model_id), version=version)
        return version_obj
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to update model version", model_id=str(model_id), version=version, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to update model version")


@router.delete("/{version}", status_code=204)
async def delete_model_version(
    model_id: uuid.UUID,
    version: str,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """删除模型版本"""
    try:
        success = await model_service.delete_model_version(
            model_id=model_id,
            version=version,
            tenant_id=current_user["tenant_id"]
        )
        if not success:
            raise HTTPException(status_code=404, detail="Model version not found")
        logger.info("Model version deleted", model_id=str(model_id), version=version)
        return JSONResponse(status_code=204, content=None)
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to delete model version", model_id=str(model_id), version=version, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to delete model version")


@router.post("/{version}/activate")
async def activate_model_version(
    model_id: uuid.UUID,
    version: str,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """激活模型版本"""
    try:
        success = await model_service.activate_model_version(
            model_id=model_id,
            version=version,
            tenant_id=current_user["tenant_id"]
        )
        
        if not success:
            raise HTTPException(status_code=404, detail="Model version not found")
        
        logger.info("Model version activated", model_id=str(model_id), version=version)
        return {"message": "Model version activated successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to activate model version", model_id=str(model_id), version=version, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to activate model version")


@router.post("/{version}/deactivate")
async def deactivate_model_version(
    model_id: uuid.UUID,
    version: str,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """停用模型版本"""
    try:
        success = await model_service.deactivate_model_version(
            model_id=model_id,
            version=version,
            tenant_id=current_user["tenant_id"]
        )
        
        if not success:
            raise HTTPException(status_code=404, detail="Model version not found")
        
        logger.info("Model version deactivated", model_id=str(model_id), version=version)
        return {"message": "Model version deactivated successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to deactivate model version", model_id=str(model_id), version=version, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to deactivate model version")



