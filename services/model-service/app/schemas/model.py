"""
模型相关Pydantic模式
"""
import uuid
from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, validator


class ModelBase(BaseModel):
    """模型基础模式"""
    name: str = Field(..., min_length=3, max_length=255, description="模型名称")
    description: Optional[str] = Field(None, description="模型描述")
    framework: str = Field(..., min_length=1, max_length=100, description="模型框架")
    task_type: str = Field(..., min_length=1, max_length=100, description="任务类型")
    is_public: bool = Field(False, description="是否公开")
    tags: List[str] = Field(default_factory=list, description="标签")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="元数据")


class ModelCreate(ModelBase):
    """创建模型请求"""
    pass


class ModelUpdate(BaseModel):
    """更新模型请求"""
    name: Optional[str] = Field(None, min_length=3, max_length=255)
    description: Optional[str] = None
    framework: Optional[str] = Field(None, min_length=1, max_length=100)
    task_type: Optional[str] = Field(None, min_length=1, max_length=100)
    is_public: Optional[bool] = None
    tags: Optional[List[str]] = None
    metadata: Optional[Dict[str, Any]] = None


class ModelResponse(ModelBase):
    """模型响应"""
    id: uuid.UUID
    status: str
    owner_id: uuid.UUID
    tenant_id: uuid.UUID
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ModelListResponse(BaseModel):
    """模型列表响应"""
    models: List[ModelResponse]
    total: int
    offset: int
    limit: int


class ModelVersionBase(BaseModel):
    """模型版本基础模式"""
    version: str = Field(..., min_length=1, max_length=50, description="版本号")
    description: Optional[str] = Field(None, description="版本描述")
    file_path: Optional[str] = Field(None, max_length=500, description="文件路径")
    file_size: Optional[int] = Field(None, ge=0, description="文件大小")
    checksum: Optional[str] = Field(None, max_length=64, description="文件校验和")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="元数据")


class ModelVersionCreate(ModelVersionBase):
    """创建模型版本请求"""
    pass


class ModelVersionUpdate(BaseModel):
    """更新模型版本请求"""
    description: Optional[str] = None
    file_path: Optional[str] = Field(None, max_length=500)
    file_size: Optional[int] = Field(None, ge=0)
    checksum: Optional[str] = Field(None, max_length=64)
    metadata: Optional[Dict[str, Any]] = None


class ModelVersionResponse(ModelVersionBase):
    """模型版本响应"""
    id: uuid.UUID
    model_id: uuid.UUID
    status: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ModelVersionListResponse(BaseModel):
    """模型版本列表响应"""
    versions: List[ModelVersionResponse]
    total: int
    offset: int
    limit: int


class ModelDeploymentBase(BaseModel):
    """模型部署基础模式"""
    name: str = Field(..., min_length=3, max_length=255, description="部署名称")
    description: Optional[str] = Field(None, description="部署描述")
    deployment_type: str = Field(..., description="部署类型")
    endpoint: Optional[str] = Field(None, max_length=500, description="端点")
    replicas: int = Field(1, ge=1, description="副本数")
    cpu_limit: Optional[str] = Field(None, description="CPU限制")
    memory_limit: Optional[str] = Field(None, description="内存限制")
    gpu_limit: Optional[str] = Field(None, description="GPU限制")
    config: Dict[str, Any] = Field(default_factory=dict, description="配置")


class ModelDeploymentCreate(ModelDeploymentBase):
    """创建模型部署请求"""
    model_version_id: uuid.UUID = Field(..., description="模型版本ID")


class ModelDeploymentUpdate(BaseModel):
    """更新模型部署请求"""
    name: Optional[str] = Field(None, min_length=3, max_length=255)
    description: Optional[str] = None
    replicas: Optional[int] = Field(None, ge=1)
    cpu_limit: Optional[str] = None
    memory_limit: Optional[str] = None
    gpu_limit: Optional[str] = None
    config: Optional[Dict[str, Any]] = None


class ModelDeploymentResponse(ModelDeploymentBase):
    """模型部署响应"""
    id: uuid.UUID
    model_id: uuid.UUID
    model_version_id: uuid.UUID
    status: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ModelDeploymentListResponse(BaseModel):
    """模型部署列表响应"""
    deployments: List[ModelDeploymentResponse]
    total: int
    offset: int
    limit: int


class ModelEvaluationBase(BaseModel):
    """模型评测基础模式"""
    name: str = Field(..., min_length=3, max_length=255, description="评测名称")
    description: Optional[str] = Field(None, description="评测描述")
    dataset_id: Optional[str] = Field(None, max_length=255, description="数据集ID")
    evaluation_type: str = Field(..., description="评测类型")
    results: Dict[str, Any] = Field(default_factory=dict, description="评测结果")
    metrics: Dict[str, Any] = Field(default_factory=dict, description="评测指标")


class ModelEvaluationCreate(ModelEvaluationBase):
    """创建模型评测请求"""
    model_version_id: uuid.UUID = Field(..., description="模型版本ID")


class ModelEvaluationUpdate(BaseModel):
    """更新模型评测请求"""
    name: Optional[str] = Field(None, min_length=3, max_length=255)
    description: Optional[str] = None
    dataset_id: Optional[str] = Field(None, max_length=255)
    evaluation_type: Optional[str] = None
    results: Optional[Dict[str, Any]] = None
    metrics: Optional[Dict[str, Any]] = None


class ModelEvaluationResponse(ModelEvaluationBase):
    """模型评测响应"""
    id: uuid.UUID
    model_id: uuid.UUID
    model_version_id: uuid.UUID
    status: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ModelEvaluationListResponse(BaseModel):
    """模型评测列表响应"""
    evaluations: List[ModelEvaluationResponse]
    total: int
    offset: int
    limit: int


class ModelMetricResponse(BaseModel):
    """模型指标响应"""
    id: uuid.UUID
    deployment_id: uuid.UUID
    metric_name: str
    metric_value: str
    metric_unit: Optional[str]
    timestamp: datetime
    labels: Dict[str, Any]
    
    class Config:
        from_attributes = True


class ModelMetricListResponse(BaseModel):
    """模型指标列表响应"""
    metrics: List[ModelMetricResponse]
    total: int
    offset: int
    limit: int


class ModelSearchRequest(BaseModel):
    """模型搜索请求"""
    keyword: str = Field(..., min_length=1, description="搜索关键词")
    framework: Optional[str] = Field(None, description="框架过滤")
    task_type: Optional[str] = Field(None, description="任务类型过滤")
    tags: Optional[List[str]] = Field(None, description="标签过滤")
    is_public: Optional[bool] = Field(None, description="是否公开过滤")
    offset: int = Field(0, ge=0, description="偏移量")
    limit: int = Field(20, ge=1, le=100, description="限制数量")


class ModelUploadRequest(BaseModel):
    """模型上传请求"""
    version: str = Field(..., min_length=1, max_length=50, description="版本号")
    description: Optional[str] = Field(None, description="版本描述")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="元数据")


class ModelDeployRequest(BaseModel):
    """模型部署请求"""
    model_version_id: uuid.UUID = Field(..., description="模型版本ID")
    name: str = Field(..., min_length=3, max_length=255, description="部署名称")
    description: Optional[str] = Field(None, description="部署描述")
    deployment_type: str = Field(..., description="部署类型")
    replicas: int = Field(1, ge=1, description="副本数")
    cpu_limit: Optional[str] = Field(None, description="CPU限制")
    memory_limit: Optional[str] = Field(None, description="内存限制")
    gpu_limit: Optional[str] = Field(None, description="GPU限制")
    config: Dict[str, Any] = Field(default_factory=dict, description="配置")


class ModelScaleRequest(BaseModel):
    """模型扩缩容请求"""
    replicas: int = Field(..., ge=1, description="副本数")


class ModelEvaluateRequest(BaseModel):
    """模型评测请求"""
    model_version_id: uuid.UUID = Field(..., description="模型版本ID")
    name: str = Field(..., min_length=3, max_length=255, description="评测名称")
    description: Optional[str] = Field(None, description="评测描述")
    dataset_id: Optional[str] = Field(None, max_length=255, description="数据集ID")
    evaluation_type: str = Field(..., description="评测类型")
    config: Dict[str, Any] = Field(default_factory=dict, description="评测配置")



