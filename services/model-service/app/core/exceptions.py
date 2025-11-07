"""
异常定义
"""


class ModelServiceException(Exception):
    """模型服务异常基类"""
    
    def __init__(self, error_code: str, message: str, details: str = None, status_code: int = 500):
        self.error_code = error_code
        self.message = message
        self.details = details
        self.status_code = status_code
        super().__init__(self.message)


class ModelNotFoundError(ModelServiceException):
    """模型未找到异常"""
    
    def __init__(self, model_id: str):
        super().__init__(
            error_code="MODEL_NOT_FOUND",
            message=f"Model with id {model_id} not found",
            status_code=404
        )


class ModelVersionNotFoundError(ModelServiceException):
    """模型版本未找到异常"""
    
    def __init__(self, model_id: str, version: str):
        super().__init__(
            error_code="MODEL_VERSION_NOT_FOUND",
            message=f"Model version {version} for model {model_id} not found",
            status_code=404
        )


class ModelAlreadyExistsError(ModelServiceException):
    """模型已存在异常"""
    
    def __init__(self, model_name: str):
        super().__init__(
            error_code="MODEL_ALREADY_EXISTS",
            message=f"Model with name {model_name} already exists",
            status_code=409
        )


class ModelValidationError(ModelServiceException):
    """模型验证异常"""
    
    def __init__(self, message: str, details: str = None):
        super().__init__(
            error_code="MODEL_VALIDATION_ERROR",
            message=message,
            details=details,
            status_code=400
        )


class ModelDeploymentError(ModelServiceException):
    """模型部署异常"""
    
    def __init__(self, message: str, details: str = None):
        super().__init__(
            error_code="MODEL_DEPLOYMENT_ERROR",
            message=message,
            details=details,
            status_code=500
        )
