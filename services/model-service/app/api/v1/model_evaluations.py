"""
模型评测管理API路由
"""
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse
import structlog

from app.schemas.model import (
    ModelEvaluationCreate, ModelEvaluationUpdate, ModelEvaluationResponse, 
    ModelEvaluationListResponse, ModelEvaluateRequest, ModelMetricResponse, ModelMetricListResponse
)
from app.services.model_service import ModelService
from app.core.dependencies import get_model_service, get_current_user

logger = structlog.get_logger(__name__)
router = APIRouter()


@router.post("/", response_model=ModelEvaluationResponse, status_code=201)
async def create_model_evaluation(
    model_id: uuid.UUID,
    evaluation_data: ModelEvaluateRequest,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """创建模型评测"""
    try:
        evaluation = await model_service.create_model_evaluation(
            model_id=model_id,
            evaluation_data=evaluation_data,
            tenant_id=current_user["tenant_id"]
        )
        logger.info("Model evaluation created", model_id=str(model_id), evaluation_id=str(evaluation.id))
        return evaluation
    except Exception as e:
        logger.error("Failed to create model evaluation", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to create model evaluation")


@router.get("/", response_model=ModelEvaluationListResponse)
async def list_model_evaluations(
    model_id: uuid.UUID,
    offset: int = Query(0, ge=0, description="偏移量"),
    limit: int = Query(20, ge=1, le=100, description="限制数量"),
    status: Optional[str] = Query(None, description="状态过滤"),
    evaluation_type: Optional[str] = Query(None, description="评测类型过滤"),
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """获取模型评测列表"""
    try:
        result = await model_service.list_model_evaluations(
            model_id=model_id,
            tenant_id=current_user["tenant_id"],
            offset=offset,
            limit=limit,
            status=status,
            evaluation_type=evaluation_type
        )
        return result
    except Exception as e:
        logger.error("Failed to list model evaluations", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list model evaluations")


@router.get("/{evaluation_id}", response_model=ModelEvaluationResponse)
async def get_model_evaluation(
    model_id: uuid.UUID,
    evaluation_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """获取模型评测详情"""
    try:
        evaluation = await model_service.get_model_evaluation(
            model_id=model_id,
            evaluation_id=evaluation_id,
            tenant_id=current_user["tenant_id"]
        )
        if not evaluation:
            raise HTTPException(status_code=404, detail="Model evaluation not found")
        return evaluation
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get model evaluation", model_id=str(model_id), evaluation_id=str(evaluation_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get model evaluation")


@router.put("/{evaluation_id}", response_model=ModelEvaluationResponse)
async def update_model_evaluation(
    model_id: uuid.UUID,
    evaluation_id: uuid.UUID,
    evaluation_data: ModelEvaluationUpdate,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """更新模型评测"""
    try:
        evaluation = await model_service.update_model_evaluation(
            model_id=model_id,
            evaluation_id=evaluation_id,
            evaluation_data=evaluation_data,
            tenant_id=current_user["tenant_id"]
        )
        if not evaluation:
            raise HTTPException(status_code=404, detail="Model evaluation not found")
        logger.info("Model evaluation updated", model_id=str(model_id), evaluation_id=str(evaluation_id))
        return evaluation
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to update model evaluation", model_id=str(model_id), evaluation_id=str(evaluation_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to update model evaluation")


@router.delete("/{evaluation_id}", status_code=204)
async def delete_model_evaluation(
    model_id: uuid.UUID,
    evaluation_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """删除模型评测"""
    try:
        success = await model_service.delete_model_evaluation(
            model_id=model_id,
            evaluation_id=evaluation_id,
            tenant_id=current_user["tenant_id"]
        )
        if not success:
            raise HTTPException(status_code=404, detail="Model evaluation not found")
        logger.info("Model evaluation deleted", model_id=str(model_id), evaluation_id=str(evaluation_id))
        return JSONResponse(status_code=204, content=None)
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to delete model evaluation", model_id=str(model_id), evaluation_id=str(evaluation_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to delete model evaluation")


@router.post("/{evaluation_id}/start")
async def start_model_evaluation(
    model_id: uuid.UUID,
    evaluation_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """启动模型评测"""
    try:
        success = await model_service.start_model_evaluation(
            model_id=model_id,
            evaluation_id=evaluation_id,
            tenant_id=current_user["tenant_id"]
        )
        
        if not success:
            raise HTTPException(status_code=404, detail="Model evaluation not found")
        
        logger.info("Model evaluation started", model_id=str(model_id), evaluation_id=str(evaluation_id))
        return {"message": "Model evaluation started successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to start model evaluation", model_id=str(model_id), evaluation_id=str(evaluation_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to start model evaluation")


@router.post("/{evaluation_id}/stop")
async def stop_model_evaluation(
    model_id: uuid.UUID,
    evaluation_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """停止模型评测"""
    try:
        success = await model_service.stop_model_evaluation(
            model_id=model_id,
            evaluation_id=evaluation_id,
            tenant_id=current_user["tenant_id"]
        )
        
        if not success:
            raise HTTPException(status_code=404, detail="Model evaluation not found")
        
        logger.info("Model evaluation stopped", model_id=str(model_id), evaluation_id=str(evaluation_id))
        return {"message": "Model evaluation stopped successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to stop model evaluation", model_id=str(model_id), evaluation_id=str(evaluation_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to stop model evaluation")


@router.get("/{evaluation_id}/results")
async def get_model_evaluation_results(
    model_id: uuid.UUID,
    evaluation_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """获取模型评测结果"""
    try:
        results = await model_service.get_model_evaluation_results(
            model_id=model_id,
            evaluation_id=evaluation_id,
            tenant_id=current_user["tenant_id"]
        )
        
        if results is None:
            raise HTTPException(status_code=404, detail="Model evaluation not found")
        
        return results
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get model evaluation results", model_id=str(model_id), evaluation_id=str(evaluation_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get model evaluation results")


@router.get("/{evaluation_id}/metrics")
async def get_model_evaluation_metrics(
    model_id: uuid.UUID,
    evaluation_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """获取模型评测指标"""
    try:
        metrics = await model_service.get_model_evaluation_metrics(
            model_id=model_id,
            evaluation_id=evaluation_id,
            tenant_id=current_user["tenant_id"]
        )
        
        if metrics is None:
            raise HTTPException(status_code=404, detail="Model evaluation not found")
        
        return metrics
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get model evaluation metrics", model_id=str(model_id), evaluation_id=str(evaluation_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get model evaluation metrics")


@router.get("/metrics", response_model=ModelMetricListResponse)
async def list_model_metrics(
    model_id: uuid.UUID,
    deployment_id: Optional[uuid.UUID] = Query(None, description="部署ID过滤"),
    metric_name: Optional[str] = Query(None, description="指标名称过滤"),
    start_time: Optional[str] = Query(None, description="开始时间"),
    end_time: Optional[str] = Query(None, description="结束时间"),
    offset: int = Query(0, ge=0, description="偏移量"),
    limit: int = Query(20, ge=1, le=100, description="限制数量"),
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """获取模型指标列表"""
    try:
        result = await model_service.list_model_metrics(
            model_id=model_id,
            deployment_id=deployment_id,
            metric_name=metric_name,
            start_time=start_time,
            end_time=end_time,
            offset=offset,
            limit=limit,
            tenant_id=current_user["tenant_id"]
        )
        return result
    except Exception as e:
        logger.error("Failed to list model metrics", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list model metrics")



