"""
中间件
"""
import time
import logging
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)

class LoggingMiddleware(BaseHTTPMiddleware):
    """日志中间件"""
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        # 记录请求开始
        logger.info(f"Request started: {request.method} {request.url}")
        
        # 处理请求
        response = await call_next(request)
        
        # 计算处理时间
        process_time = time.time() - start_time
        
        # 记录请求完成
        logger.info(
            f"Request completed: {request.method} {request.url} "
            f"Status: {response.status_code} Duration: {process_time:.3f}s"
        )
        
        # 添加响应头
        response.headers["X-Process-Time"] = str(process_time)
        
        return response

class MetricsMiddleware(BaseHTTPMiddleware):
    """指标中间件"""
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        # 处理请求
        response = await call_next(request)
        
        # 计算处理时间
        process_time = time.time() - start_time
        
        # 记录指标（这里可以发送到Prometheus等监控系统）
        logger.info(
            f"Metrics: {request.method} {request.url.path} "
            f"Status: {response.status_code} Duration: {process_time:.3f}s"
        )
        
        return response
