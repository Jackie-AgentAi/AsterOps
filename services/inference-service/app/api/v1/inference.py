"""
推理API路由
"""
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import StreamingResponse
import structlog

from app.schemas.inference import (
    InferenceRequestCreate, InferenceRequestResponse, InferenceResponse,
    BatchInferenceRequest, BatchInferenceResponse, StreamingInferenceRequest,
    InferenceStatusResponse, ErrorResponse
)
from app.services.inference_service import InferenceService
from app.core.dependencies import get_inference_service, get_current_user

logger = structlog.get_logger(__name__)
router = APIRouter()


@router.post("/{model_id}", response_model=InferenceResponse)
async def inference(
    model_id: uuid.UUID,
    request_data: InferenceRequestCreate,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """模型推理"""
    try:
        # 设置用户信息
        request_data.user_id = current_user["id"]
        request_data.tenant_id = current_user["tenant_id"]
        
        result = await inference_service.inference(
            model_id=model_id,
            request_data=request_data
        )
        
        logger.info("Inference completed", model_id=str(model_id), request_id=str(result.request_id))
        return result
    except Exception as e:
        logger.error("Inference failed", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Inference failed")


@router.post("/{model_id}/batch", response_model=BatchInferenceResponse)
async def batch_inference(
    model_id: uuid.UUID,
    batch_request: BatchInferenceRequest,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """批量推理"""
    try:
        # 设置用户信息
        for req in batch_request.requests:
            req.user_id = current_user["id"]
            req.tenant_id = current_user["tenant_id"]
        
        result = await inference_service.batch_inference(
            model_id=model_id,
            batch_request=batch_request
        )
        
        logger.info("Batch inference completed", model_id=str(model_id), batch_id=str(result.batch_id))
        return result
    except Exception as e:
        logger.error("Batch inference failed", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Batch inference failed")


@router.post("/{model_id}/stream")
async def stream_inference(
    model_id: uuid.UUID,
    request_data: StreamingInferenceRequest,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """流式推理"""
    try:
        # 设置用户信息
        request_data.user_id = current_user["id"]
        request_data.tenant_id = current_user["tenant_id"]
        
        async def generate_stream():
            async for chunk in inference_service.stream_inference(
                model_id=model_id,
                request_data=request_data
            ):
                yield f"data: {chunk.json()}\n\n"
            yield "data: [DONE]\n\n"
        
        return StreamingResponse(
            generate_stream(),
            media_type="text/plain",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "Content-Type": "text/plain; charset=utf-8"
            }
        )
    except Exception as e:
        logger.error("Stream inference failed", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Stream inference failed")


@router.get("/{model_id}/status", response_model=InferenceStatusResponse)
async def get_inference_status(
    model_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取推理状态"""
    try:
        status = await inference_service.get_inference_status(
            model_id=model_id,
            tenant_id=current_user["tenant_id"]
        )
        return status
    except Exception as e:
        logger.error("Failed to get inference status", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get inference status")


@router.get("/{model_id}/requests", response_model=List[InferenceRequestResponse])
async def list_inference_requests(
    model_id: uuid.UUID,
    offset: int = Query(0, ge=0, description="偏移量"),
    limit: int = Query(20, ge=1, le=100, description="限制数量"),
    status: Optional[str] = Query(None, description="状态过滤"),
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取推理请求列表"""
    try:
        requests = await inference_service.list_inference_requests(
            model_id=model_id,
            tenant_id=current_user["tenant_id"],
            offset=offset,
            limit=limit,
            status=status
        )
        return requests
    except Exception as e:
        logger.error("Failed to list inference requests", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list inference requests")


@router.get("/{model_id}/requests/{request_id}", response_model=InferenceRequestResponse)
async def get_inference_request(
    model_id: uuid.UUID,
    request_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取推理请求详情"""
    try:
        request = await inference_service.get_inference_request(
            model_id=model_id,
            request_id=request_id,
            tenant_id=current_user["tenant_id"]
        )
        if not request:
            raise HTTPException(status_code=404, detail="Inference request not found")
        return request
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get inference request", model_id=str(model_id), request_id=str(request_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get inference request")


@router.delete("/{model_id}/requests/{request_id}", status_code=204)
async def cancel_inference_request(
    model_id: uuid.UUID,
    request_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """取消推理请求"""
    try:
        success = await inference_service.cancel_inference_request(
            model_id=model_id,
            request_id=request_id,
            tenant_id=current_user["tenant_id"]
        )
        if not success:
            raise HTTPException(status_code=404, detail="Inference request not found")
        logger.info("Inference request cancelled", model_id=str(model_id), request_id=str(request_id))
        return None
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to cancel inference request", model_id=str(model_id), request_id=str(request_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to cancel inference request")


@router.post("/{model_id}/sessions", response_model=dict)
async def create_inference_session(
    model_id: uuid.UUID,
    session_data: dict,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """创建推理会话"""
    try:
        session = await inference_service.create_inference_session(
            model_id=model_id,
            user_id=current_user["id"],
            tenant_id=current_user["tenant_id"],
            session_data=session_data
        )
        logger.info("Inference session created", model_id=str(model_id), session_id=str(session.id))
        return session
    except Exception as e:
        logger.error("Failed to create inference session", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to create inference session")


@router.get("/{model_id}/sessions", response_model=List[dict])
async def list_inference_sessions(
    model_id: uuid.UUID,
    offset: int = Query(0, ge=0, description="偏移量"),
    limit: int = Query(20, ge=1, le=100, description="限制数量"),
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """获取推理会话列表"""
    try:
        sessions = await inference_service.list_inference_sessions(
            model_id=model_id,
            user_id=current_user["id"],
            tenant_id=current_user["tenant_id"],
            offset=offset,
            limit=limit
        )
        return sessions
    except Exception as e:
        logger.error("Failed to list inference sessions", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list inference sessions")


@router.delete("/{model_id}/sessions/{session_id}", status_code=204)
async def delete_inference_session(
    model_id: uuid.UUID,
    session_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service)
):
    """删除推理会话"""
    try:
        success = await inference_service.delete_inference_session(
            model_id=model_id,
            session_id=session_id,
            user_id=current_user["id"],
            tenant_id=current_user["tenant_id"]
        )
        if not success:
            raise HTTPException(status_code=404, detail="Inference session not found")
        logger.info("Inference session deleted", model_id=str(model_id), session_id=str(session_id))
        return None
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to delete inference session", model_id=str(model_id), session_id=str(session_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to delete inference session")



