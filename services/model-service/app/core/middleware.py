"""
中间件
"""
import time
import uuid
from typing import Callable
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import structlog

logger = structlog.get_logger(__name__)


class LoggingMiddleware(BaseHTTPMiddleware):
    """日志中间件"""
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # 生成请求ID
        request_id = str(uuid.uuid4())
        
        # 记录请求开始
        start_time = time.time()
        
        # 记录请求信息
        logger.info(
            "Request started",
            request_id=request_id,
            method=request.method,
            url=str(request.url),
            client_ip=request.client.host if request.client else None,
        )
        
        # 处理请求
        response = await call_next(request)
        
        # 计算处理时间
        process_time = time.time() - start_time
        
        # 记录响应信息
        logger.info(
            "Request completed",
            request_id=request_id,
            status_code=response.status_code,
            process_time=process_time,
        )
        
        return response


class MetricsMiddleware(BaseHTTPMiddleware):
    """指标中间件"""
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # 处理请求
        response = await call_next(request)
        
        # 这里可以添加Prometheus指标收集
        # 例如：请求计数、响应时间等
        
        return response
