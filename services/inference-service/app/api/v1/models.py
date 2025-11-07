"""
模型管理API路由
"""
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse
import structlog

from app.schemas.inference import (
    ModelLoadRequest, ModelLoadResponse, ModelUnloadRequest, ModelUnloadResponse,
    ModelInfoResponse, ModelListResponse
)
from app.services.inference_service import InferenceService
from app.core.dependencies import get_inference_service, get_current_user

logger = structlog.get_logger(__name__)
router = APIRouter()


@router.post("/{model_id}/load", response_model=ModelLoadResponse)
async def load_model(
    model_id: uuid.UUID,
    load_request: ModelLoadRequest,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """加载模型"""
    try:
        result = await inference_service.load_model(
            model_id=model_id,
            load_request=load_request,
            tenant_id=current_user["tenant_id"]
        )
        logger.info("Model loaded", model_id=str(model_id), instance_id=result.instance_id)
        return result
    except Exception as e:
        logger.error("Failed to load model", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to load model")


@router.post("/{model_id}/unload", response_model=ModelUnloadResponse)
async def unload_model(
    model_id: uuid.UUID,
    unload_request: ModelUnloadRequest,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """卸载模型"""
    try:
        result = await inference_service.unload_model(
            model_id=model_id,
            unload_request=unload_request,
            tenant_id=current_user["tenant_id"]
        )
        logger.info("Model unloaded", model_id=str(model_id), instance_id=result.instance_id)
        return result
    except Exception as e:
        logger.error("Failed to unload model", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to unload model")


@router.get("/{model_id}/info", response_model=ModelInfoResponse)
async def get_model_info(
    model_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取模型信息"""
    try:
        info = await inference_service.get_model_info(
            model_id=model_id,
            tenant_id=current_user["tenant_id"]
        )
        if not info:
            raise HTTPException(status_code=404, detail="Model not found")
        return info
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get model info", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get model info")


@router.get("/", response_model=ModelListResponse)
async def list_models(
    offset: int = Query(0, ge=0, description="偏移量"),
    limit: int = Query(20, ge=1, le=100, description="限制数量"),
    status: Optional[str] = Query(None, description="状态过滤"),
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取可用模型列表"""
    try:
        models = await inference_service.list_models(
            tenant_id=current_user["tenant_id"],
            offset=offset,
            limit=limit,
            status=status
        )
        return models
    except Exception as e:
        logger.error("Failed to list models", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list models")


@router.get("/{model_id}/instances", response_model=List[dict])
async def list_model_instances(
    model_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取模型实例列表"""
    try:
        instances = await inference_service.list_model_instances(
            model_id=model_id,
            tenant_id=current_user["tenant_id"]
        )
        return instances
    except Exception as e:
        logger.error("Failed to list model instances", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list model instances")


@router.get("/{model_id}/instances/{instance_id}", response_model=dict)
async def get_model_instance(
    model_id: uuid.UUID,
    instance_id: str,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取模型实例详情"""
    try:
        instance = await inference_service.get_model_instance(
            model_id=model_id,
            instance_id=instance_id,
            tenant_id=current_user["tenant_id"]
        )
        if not instance:
            raise HTTPException(status_code=404, detail="Model instance not found")
        return instance
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get model instance", model_id=str(model_id), instance_id=instance_id, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get model instance")


@router.post("/{model_id}/instances/{instance_id}/restart")
async def restart_model_instance(
    model_id: uuid.UUID,
    instance_id: str,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """重启模型实例"""
    try:
        success = await inference_service.restart_model_instance(
            model_id=model_id,
            instance_id=instance_id,
            tenant_id=current_user["tenant_id"]
        )
        if not success:
            raise HTTPException(status_code=404, detail="Model instance not found")
        logger.info("Model instance restarted", model_id=str(model_id), instance_id=instance_id)
        return {"message": "Model instance restarted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to restart model instance", model_id=str(model_id), instance_id=instance_id, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to restart model instance")


@router.post("/{model_id}/instances/{instance_id}/scale")
async def scale_model_instance(
    model_id: uuid.UUID,
    instance_id: str,
    replicas: int = Query(..., ge=1, description="副本数"),
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """扩缩容模型实例"""
    try:
        success = await inference_service.scale_model_instance(
            model_id=model_id,
            instance_id=instance_id,
            replicas=replicas,
            tenant_id=current_user["tenant_id"]
        )
        if not success:
            raise HTTPException(status_code=404, detail="Model instance not found")
        logger.info("Model instance scaled", model_id=str(model_id), instance_id=instance_id, replicas=replicas)
        return {"message": "Model instance scaled successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to scale model instance", model_id=str(model_id), instance_id=instance_id, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to scale model instance")


@router.get("/{model_id}/instances/{instance_id}/logs")
async def get_model_instance_logs(
    model_id: uuid.UUID,
    instance_id: str,
    lines: int = Query(100, ge=1, le=1000, description="日志行数"),
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取模型实例日志"""
    try:
        logs = await inference_service.get_model_instance_logs(
            model_id=model_id,
            instance_id=instance_id,
            lines=lines,
            tenant_id=current_user["tenant_id"]
        )
        if logs is None:
            raise HTTPException(status_code=404, detail="Model instance not found")
        return {"logs": logs}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get model instance logs", model_id=str(model_id), instance_id=instance_id, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get model instance logs")


@router.get("/{model_id}/instances/{instance_id}/metrics")
async def get_model_instance_metrics(
    model_id: uuid.UUID,
    instance_id: str,
    start_time: Optional[str] = Query(None, description="开始时间"),
    end_time: Optional[str] = Query(None, description="结束时间"),
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取模型实例指标"""
    try:
        metrics = await inference_service.get_model_instance_metrics(
            model_id=model_id,
            instance_id=instance_id,
            start_time=start_time,
            end_time=end_time,
            tenant_id=current_user["tenant_id"]
        )
        if metrics is None:
            raise HTTPException(status_code=404, detail="Model instance not found")
        return metrics
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get model instance metrics", model_id=str(model_id), instance_id=instance_id, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get model instance metrics")



