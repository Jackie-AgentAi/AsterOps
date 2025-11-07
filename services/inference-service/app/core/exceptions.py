"""
自定义异常类
"""
from typing import Optional, Dict, Any

class InferenceServiceException(Exception):
    """推理服务通用异常"""
    def __init__(
        self,
        status_code: int,
        error_code: str,
        message: str,
        details: Optional[Dict[str, Any]] = None
    ):
        self.status_code = status_code
        self.error_code = error_code
        self.message = message
        self.details = details
        super().__init__(self.message)

class ModelNotFoundException(InferenceServiceException):
    """模型未找到异常"""
    def __init__(self, model_id: str):
        super().__init__(
            status_code=404,
            error_code="MODEL_NOT_FOUND",
            message=f"Model with ID '{model_id}' not found."
        )

class InferenceRequestNotFoundException(InferenceServiceException):
    """推理请求未找到异常"""
    def __init__(self, request_id: str):
        super().__init__(
            status_code=404,
            error_code="INFERENCE_REQUEST_NOT_FOUND",
            message=f"Inference request with ID '{request_id}' not found."
        )

class InferenceException(InferenceServiceException):
    """推理异常"""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            status_code=500,
            error_code="INFERENCE_FAILED",
            message=f"Inference failed: {message}",
            details=details
        )

class InvalidInferenceDataException(InferenceServiceException):
    """无效推理数据异常"""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            status_code=400,
            error_code="INVALID_INFERENCE_DATA",
            message=f"Invalid inference data: {message}",
            details=details
        )

class UnauthorizedException(InferenceServiceException):
    """未授权异常"""
    def __init__(self, message: str = "Unauthorized"):
        super().__init__(
            status_code=401,
            error_code="UNAUTHORIZED",
            message=message
        )

class ForbiddenException(InferenceServiceException):
    """禁止访问异常"""
    def __init__(self, message: str = "Forbidden"):
        super().__init__(
            status_code=403,
            error_code="FORBIDDEN",
            message=message
        )


