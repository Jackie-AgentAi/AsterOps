"""
模型管理API路由
"""
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from fastapi.responses import JSONResponse
import structlog

from app.schemas.model import (
    ModelCreate, ModelUpdate, ModelResponse, ModelListResponse,
    ModelSearchRequest, ModelUploadRequest
)
from app.services.model_service import ModelService
from app.core.dependencies import get_model_service, get_current_user

logger = structlog.get_logger(__name__)
router = APIRouter()


@router.post("/", response_model=ModelResponse, status_code=201)
async def create_model(
    model_data: ModelCreate,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """创建模型"""
    try:
        model = await model_service.create_model(
            model_data=model_data,
            owner_id=current_user["id"],
            tenant_id=current_user["tenant_id"]
        )
        logger.info("Model created", model_id=str(model.id), owner_id=str(model.owner_id))
        return model
    except Exception as e:
        logger.error("Failed to create model", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to create model")


@router.get("/{model_id}", response_model=ModelResponse)
async def get_model(
    model_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """获取模型详情"""
    try:
        model = await model_service.get_model(
            model_id=model_id,
            tenant_id=current_user["tenant_id"]
        )
        if not model:
            raise HTTPException(status_code=404, detail="Model not found")
        return model
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get model", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get model")


@router.put("/{model_id}", response_model=ModelResponse)
async def update_model(
    model_id: uuid.UUID,
    model_data: ModelUpdate,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """更新模型"""
    try:
        model = await model_service.update_model(
            model_id=model_id,
            model_data=model_data,
            tenant_id=current_user["tenant_id"]
        )
        if not model:
            raise HTTPException(status_code=404, detail="Model not found")
        logger.info("Model updated", model_id=str(model.id))
        return model
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to update model", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to update model")


@router.delete("/{model_id}", status_code=204)
async def delete_model(
    model_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """删除模型"""
    try:
        success = await model_service.delete_model(
            model_id=model_id,
            tenant_id=current_user["tenant_id"]
        )
        if not success:
            raise HTTPException(status_code=404, detail="Model not found")
        logger.info("Model deleted", model_id=str(model_id))
        return JSONResponse(status_code=204, content=None)
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to delete model", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to delete model")


@router.get("/", response_model=ModelListResponse)
async def list_models(
    offset: int = Query(0, ge=0, description="偏移量"),
    limit: int = Query(20, ge=1, le=100, description="限制数量"),
    framework: Optional[str] = Query(None, description="框架过滤"),
    task_type: Optional[str] = Query(None, description="任务类型过滤"),
    is_public: Optional[bool] = Query(None, description="是否公开过滤"),
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """获取模型列表"""
    try:
        result = await model_service.list_models(
            tenant_id=current_user["tenant_id"],
            offset=offset,
            limit=limit,
            framework=framework,
            task_type=task_type,
            is_public=is_public
        )
        return result
    except Exception as e:
        logger.error("Failed to list models", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list models")


@router.get("/search", response_model=ModelListResponse)
async def search_models(
    keyword: str = Query(..., min_length=1, description="搜索关键词"),
    offset: int = Query(0, ge=0, description="偏移量"),
    limit: int = Query(20, ge=1, le=100, description="限制数量"),
    framework: Optional[str] = Query(None, description="框架过滤"),
    task_type: Optional[str] = Query(None, description="任务类型过滤"),
    is_public: Optional[bool] = Query(None, description="是否公开过滤"),
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """搜索模型"""
    try:
        result = await model_service.search_models(
            keyword=keyword,
            tenant_id=current_user["tenant_id"],
            offset=offset,
            limit=limit,
            framework=framework,
            task_type=task_type,
            is_public=is_public
        )
        return result
    except Exception as e:
        logger.error("Failed to search models", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to search models")


@router.post("/{model_id}/upload", response_model=dict)
async def upload_model_file(
    model_id: uuid.UUID,
    version: str = Query(..., min_length=1, max_length=50, description="版本号"),
    description: Optional[str] = Query(None, description="版本描述"),
    file: UploadFile = File(..., description="模型文件"),
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """上传模型文件"""
    try:
        # 验证文件类型
        if not file.filename:
            raise HTTPException(status_code=400, detail="No file provided")
        
        # 检查文件扩展名
        allowed_extensions = [".pt", ".pth", ".onnx", ".h5", ".pb", ".tflite"]
        if not any(file.filename.lower().endswith(ext) for ext in allowed_extensions):
            raise HTTPException(
                status_code=400, 
                detail=f"File type not allowed. Allowed types: {allowed_extensions}"
            )
        
        result = await model_service.upload_model_file(
            model_id=model_id,
            version=version,
            description=description,
            file=file,
            tenant_id=current_user["tenant_id"]
        )
        
        logger.info("Model file uploaded", model_id=str(model_id), version=version)
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to upload model file", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to upload model file")


@router.get("/{model_id}/download/{version}")
async def download_model_file(
    model_id: uuid.UUID,
    version: str,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """下载模型文件"""
    try:
        file_path = await model_service.get_model_file_path(
            model_id=model_id,
            version=version,
            tenant_id=current_user["tenant_id"]
        )
        
        if not file_path:
            raise HTTPException(status_code=404, detail="Model file not found")
        
        # 这里应该返回文件流，简化处理
        return {"file_path": file_path}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to download model file", model_id=str(model_id), version=version, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to download model file")


@router.post("/{model_id}/publish")
async def publish_model(
    model_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """发布模型到公共库"""
    try:
        success = await model_service.publish_model(
            model_id=model_id,
            tenant_id=current_user["tenant_id"]
        )
        
        if not success:
            raise HTTPException(status_code=404, detail="Model not found")
        
        logger.info("Model published", model_id=str(model_id))
        return {"message": "Model published successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to publish model", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to publish model")


@router.post("/{model_id}/unpublish")
async def unpublish_model(
    model_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    model_service: ModelService = Depends(get_model_service)
):
    """从公共库取消发布模型"""
    try:
        success = await model_service.unpublish_model(
            model_id=model_id,
            tenant_id=current_user["tenant_id"]
        )
        
        if not success:
            raise HTTPException(status_code=404, detail="Model not found")
        
        logger.info("Model unpublished", model_id=str(model_id))
        return {"message": "Model unpublished successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to unpublish model", model_id=str(model_id), error=str(e))
        raise HTTPException(status_code=500, detail="Failed to unpublish model")



