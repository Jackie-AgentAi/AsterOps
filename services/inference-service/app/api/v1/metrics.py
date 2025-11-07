"""
指标API路由
"""
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
import structlog

from app.schemas.inference import (
    InferenceMetricResponse, MetricsResponse, HealthCheckResponse
)
from app.services.inference_service import InferenceService
from app.core.dependencies import get_inference_service, get_current_user

logger = structlog.get_logger(__name__)
router = APIRouter()


@router.get("/", response_model=MetricsResponse)
async def get_metrics(
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取推理指标"""
    try:
        metrics = await inference_service.get_metrics(
            tenant_id=current_user["tenant_id"]
        )
        return metrics
    except Exception as e:
        logger.error("Failed to get metrics", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get metrics")


@router.get("/{model_id}", response_model=List[InferenceMetricResponse])
async def get_model_metrics(
    model_id: uuid.UUID,
    offset: int = Query(0, ge=0, description="偏移量"),
    limit: int = Query(20, ge=1, le=100, description="限制数量"),
    metric_name: Optional[str] = Query(None, description="指标名称过滤"),
    start_time: Optional[str] = Query(None, description="开始时间"),
    end_time: Optional[str] = Query(None, description="结束时间"),
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取模型指标"""
    try:
        metrics = await inference_service.get_model_metrics(
            model_id=model_id,
            tenant_id=current_user["tenant_id"],
            offset=offset,
            limit=limit,
            metric_name=metric_name,
            start_time=start_time,
            end_time=end_time
        )
        return metrics
    except Exception as e:
        logger.error("Failed to get model metrics", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get model metrics")


@router.get("/health", response_model=HealthCheckResponse)
async def get_health_metrics(
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取健康检查指标"""
    try:
        health = await inference_service.get_health_metrics(
            tenant_id=current_user["tenant_id"]
        )
        return health
    except Exception as e:
        logger.error("Failed to get health metrics", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get health metrics")


@router.get("/performance")
async def get_performance_metrics(
    model_id: Optional[uuid.UUID] = Query(None, description="模型ID过滤"),
    start_time: Optional[str] = Query(None, description="开始时间"),
    end_time: Optional[str] = Query(None, description="结束时间"),
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取性能指标"""
    try:
        metrics = await inference_service.get_performance_metrics(
            model_id=model_id,
            tenant_id=current_user["tenant_id"],
            start_time=start_time,
            end_time=end_time
        )
        return metrics
    except Exception as e:
        logger.error("Failed to get performance metrics", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get performance metrics")


@router.get("/usage")
async def get_usage_metrics(
    model_id: Optional[uuid.UUID] = Query(None, description="模型ID过滤"),
    start_time: Optional[str] = Query(None, description="开始时间"),
    end_time: Optional[str] = Query(None, description="结束时间"),
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取使用量指标"""
    try:
        metrics = await inference_service.get_usage_metrics(
            model_id=model_id,
            tenant_id=current_user["tenant_id"],
            start_time=start_time,
            end_time=end_time
        )
        return metrics
    except Exception as e:
        logger.error("Failed to get usage metrics", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get usage metrics")


@router.get("/cost")
async def get_cost_metrics(
    model_id: Optional[uuid.UUID] = Query(None, description="模型ID过滤"),
    start_time: Optional[str] = Query(None, description="开始时间"),
    end_time: Optional[str] = Query(None, description="结束时间"),
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取成本指标"""
    try:
        metrics = await inference_service.get_cost_metrics(
            model_id=model_id,
            tenant_id=current_user["tenant_id"],
            start_time=start_time,
            end_time=end_time
        )
        return metrics
    except Exception as e:
        logger.error("Failed to get cost metrics", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get cost metrics")


@router.get("/gpu")
async def get_gpu_metrics(
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取GPU指标"""
    try:
        metrics = await inference_service.get_gpu_metrics(
            tenant_id=current_user["tenant_id"]
        )
        return metrics
    except Exception as e:
        logger.error("Failed to get GPU metrics", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get GPU metrics")


@router.get("/memory")
async def get_memory_metrics(
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取内存指标"""
    try:
        metrics = await inference_service.get_memory_metrics(
            tenant_id=current_user["tenant_id"]
        )
        return metrics
    except Exception as e:
        logger.error("Failed to get memory metrics", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get memory metrics")


@router.get("/requests")
async def get_request_metrics(
    model_id: Optional[uuid.UUID] = Query(None, description="模型ID过滤"),
    start_time: Optional[str] = Query(None, description="开始时间"),
    end_time: Optional[str] = Query(None, description="结束时间"),
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取请求指标"""
    try:
        metrics = await inference_service.get_request_metrics(
            model_id=model_id,
            tenant_id=current_user["tenant_id"],
            start_time=start_time,
            end_time=end_time
        )
        return metrics
    except Exception as e:
        logger.error("Failed to get request metrics", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get request metrics")


@router.get("/errors")
async def get_error_metrics(
    model_id: Optional[uuid.UUID] = Query(None, description="模型ID过滤"),
    start_time: Optional[str] = Query(None, description="开始时间"),
    end_time: Optional[str] = Query(None, description="结束时间"),
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取错误指标"""
    try:
        metrics = await inference_service.get_error_metrics(
            model_id=model_id,
            tenant_id=current_user["tenant_id"],
            start_time=start_time,
            end_time=end_time
        )
        return metrics
    except Exception as e:
        logger.error("Failed to get error metrics", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get error metrics")



