"""
模型部署管理API路由
"""
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse
import structlog

from app.schemas.model import (
    ModelDeploymentCreate, ModelDeploymentUpdate, ModelDeploymentResponse, 
    ModelDeploymentListResponse, ModelDeployRequest, ModelScaleRequest
)
from app.services.model_service import ModelService
from app.core.dependencies import get_model_service, get_current_user

logger = structlog.get_logger(__name__)
router = APIRouter()


@router.post("/", response_model=ModelDeploymentResponse, status_code=201)
async def create_model_deployment(
    model_id: uuid.UUID,
    deployment_data: ModelDeployRequest,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """部署模型"""
    try:
        deployment = await model_service.deploy_model(
            model_id=model_id,
            deployment_data=deployment_data,
            tenant_id=current_user["tenant_id"]
        )
        logger.info("Model deployed", model_id=str(model_id), deployment_id=str(deployment.id))
        return deployment
    except Exception as e:
        logger.error("Failed to deploy model", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to deploy model")


@router.get("/", response_model=ModelDeploymentListResponse)
async def list_model_deployments(
    model_id: uuid.UUID,
    offset: int = Query(0, ge=0, description="偏移量"),
    limit: int = Query(20, ge=1, le=100, description="限制数量"),
    status: Optional[str] = Query(None, description="状态过滤"),
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """获取模型部署列表"""
    try:
        result = await model_service.list_model_deployments(
            model_id=model_id,
            tenant_id=current_user["tenant_id"],
            offset=offset,
            limit=limit,
            status=status
        )
        return result
    except Exception as e:
        logger.error("Failed to list model deployments", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list model deployments")


@router.get("/{deployment_id}", response_model=ModelDeploymentResponse)
async def get_model_deployment(
    model_id: uuid.UUID,
    deployment_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """获取模型部署详情"""
    try:
        deployment = await model_service.get_model_deployment(
            model_id=model_id,
            deployment_id=deployment_id,
            tenant_id=current_user["tenant_id"]
        )
        if not deployment:
            raise HTTPException(status_code=404, detail="Model deployment not found")
        return deployment
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get model deployment", model_id=str(model_id), deployment_id=str(deployment_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get model deployment")


@router.put("/{deployment_id}", response_model=ModelDeploymentResponse)
async def update_model_deployment(
    model_id: uuid.UUID,
    deployment_id: uuid.UUID,
    deployment_data: ModelDeploymentUpdate,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """更新模型部署"""
    try:
        deployment = await model_service.update_model_deployment(
            model_id=model_id,
            deployment_id=deployment_id,
            deployment_data=deployment_data,
            tenant_id=current_user["tenant_id"]
        )
        if not deployment:
            raise HTTPException(status_code=404, detail="Model deployment not found")
        logger.info("Model deployment updated", model_id=str(model_id), deployment_id=str(deployment_id))
        return deployment
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to update model deployment", model_id=str(model_id), deployment_id=str(deployment_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to update model deployment")


@router.delete("/{deployment_id}", status_code=204)
async def delete_model_deployment(
    model_id: uuid.UUID,
    deployment_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """删除模型部署"""
    try:
        success = await model_service.delete_model_deployment(
            model_id=model_id,
            deployment_id=deployment_id,
            tenant_id=current_user["tenant_id"]
        )
        if not success:
            raise HTTPException(status_code=404, detail="Model deployment not found")
        logger.info("Model deployment deleted", model_id=str(model_id), deployment_id=str(deployment_id))
        return JSONResponse(status_code=204, content=None)
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to delete model deployment", model_id=str(model_id), deployment_id=str(deployment_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to delete model deployment")


@router.post("/{deployment_id}/start")
async def start_model_deployment(
    model_id: uuid.UUID,
    deployment_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """启动模型部署"""
    try:
        success = await model_service.start_model_deployment(
            model_id=model_id,
            deployment_id=deployment_id,
            tenant_id=current_user["tenant_id"]
        )
        
        if not success:
            raise HTTPException(status_code=404, detail="Model deployment not found")
        
        logger.info("Model deployment started", model_id=str(model_id), deployment_id=str(deployment_id))
        return {"message": "Model deployment started successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to start model deployment", model_id=str(model_id), deployment_id=str(deployment_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to start model deployment")


@router.post("/{deployment_id}/stop")
async def stop_model_deployment(
    model_id: uuid.UUID,
    deployment_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """停止模型部署"""
    try:
        success = await model_service.stop_model_deployment(
            model_id=model_id,
            deployment_id=deployment_id,
            tenant_id=current_user["tenant_id"]
        )
        
        if not success:
            raise HTTPException(status_code=404, detail="Model deployment not found")
        
        logger.info("Model deployment stopped", model_id=str(model_id), deployment_id=str(deployment_id))
        return {"message": "Model deployment stopped successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to stop model deployment", model_id=str(model_id), deployment_id=str(deployment_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to stop model deployment")


@router.post("/{deployment_id}/scale")
async def scale_model_deployment(
    model_id: uuid.UUID,
    deployment_id: uuid.UUID,
    scale_data: ModelScaleRequest,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """扩缩容模型部署"""
    try:
        success = await model_service.scale_model_deployment(
            model_id=model_id,
            deployment_id=deployment_id,
            replicas=scale_data.replicas,
            tenant_id=current_user["tenant_id"]
        )
        
        if not success:
            raise HTTPException(status_code=404, detail="Model deployment not found")
        
        logger.info("Model deployment scaled", model_id=str(model_id), deployment_id=str(deployment_id), replicas=scale_data.replicas)
        return {"message": "Model deployment scaled successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to scale model deployment", model_id=str(model_id), deployment_id=str(deployment_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to scale model deployment")


@router.get("/{deployment_id}/status")
async def get_model_deployment_status(
    model_id: uuid.UUID,
    deployment_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """获取模型部署状态"""
    try:
        status = await model_service.get_model_deployment_status(
            model_id=model_id,
            deployment_id=deployment_id,
            tenant_id=current_user["tenant_id"]
        )
        
        if not status:
            raise HTTPException(status_code=404, detail="Model deployment not found")
        
        return status
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get model deployment status", model_id=str(model_id), deployment_id=str(deployment_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get model deployment status")


@router.get("/{deployment_id}/logs")
async def get_model_deployment_logs(
    model_id: uuid.UUID,
    deployment_id: uuid.UUID,
    lines: int = Query(100, ge=1, le=1000, description="日志行数"),
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """获取模型部署日志"""
    try:
        logs = await model_service.get_model_deployment_logs(
            model_id=model_id,
            deployment_id=deployment_id,
            lines=lines,
            tenant_id=current_user["tenant_id"]
        )
        
        if logs is None:
            raise HTTPException(status_code=404, detail="Model deployment not found")
        
        return {"logs": logs}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get model deployment logs", model_id=str(model_id), deployment_id=str(deployment_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get model deployment logs")



