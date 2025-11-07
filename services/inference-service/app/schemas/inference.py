"""
推理相关的数据模型
"""
import uuid
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class InferenceRequestCreate(BaseModel):
    """推理请求创建"""
    prompt: str = Field(..., description="输入提示")
    max_tokens: Optional[int] = Field(100, description="最大token数")
    temperature: Optional[float] = Field(0.7, description="温度参数")
    top_p: Optional[float] = Field(0.9, description="Top-p参数")
    stream: Optional[bool] = Field(False, description="是否流式输出")
    user_id: Optional[str] = None
    tenant_id: Optional[str] = None

class InferenceResponse(BaseModel):
    """推理响应"""
    request_id: uuid.UUID
    model_id: uuid.UUID
    status: str
    result: Dict[str, Any]
    metrics: Optional[Dict[str, Any]] = None

class BatchInferenceRequest(BaseModel):
    """批量推理请求"""
    requests: List[InferenceRequestCreate]

class BatchInferenceResponse(BaseModel):
    """批量推理响应"""
    batch_id: uuid.UUID
    model_id: uuid.UUID
    status: str
    results: List[Dict[str, Any]]
    metrics: Optional[Dict[str, Any]] = None

class StreamingInferenceRequest(BaseModel):
    """流式推理请求"""
    prompt: str = Field(..., description="输入提示")
    max_tokens: Optional[int] = Field(100, description="最大token数")
    temperature: Optional[float] = Field(0.7, description="温度参数")
    user_id: Optional[str] = None
    tenant_id: Optional[str] = None

class InferenceStatusResponse(BaseModel):
    """推理状态响应"""
    model_id: uuid.UUID
    status: str
    active_requests: int
    queue_size: int
    metrics: Optional[Dict[str, Any]] = None

class InferenceRequestResponse(BaseModel):
    """推理请求响应"""
    request_id: uuid.UUID
    model_id: uuid.UUID
    status: str
    created_at: str
    completed_at: Optional[str] = None
    result: Optional[Dict[str, Any]] = None
    metrics: Optional[Dict[str, Any]] = None

class ErrorResponse(BaseModel):
    """错误响应"""
    error: str
    message: str
    details: Optional[Dict[str, Any]] = None