"""
自定义FastAPI中间件
"""
import time
import structlog
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from starlette.types import ASGIApp
from prometheus_client import Histogram, Counter

logger = structlog.get_logger(__name__)

# Prometheus指标
REQUEST_LATENCY_SECONDS = Histogram(
    "http_request_duration_seconds", "HTTP request latency in seconds", ["method", "endpoint"]
)
REQUEST_COUNT = Counter(
    "http_requests_total", "Total HTTP requests", ["method", "endpoint", "status_code"]
)

class LoggingMiddleware(BaseHTTPMiddleware):
    """请求日志中间件"""
    def __init__(self, app: ASGIApp):
        super().__init__(app)

    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        response = await call_next(request)
        process_time = time.time() - start_time
        
        logger.info(
            "Request completed",
            method=request.method,
            url=str(request.url),
            status_code=response.status_code,
            process_time=f"{process_time:.4f}s",
            client_ip=request.client.host if request.client else "unknown"
        )
        return response

class MetricsMiddleware(BaseHTTPMiddleware):
    """Prometheus指标中间件"""
    def __init__(self, app: ASGIApp):
        super().__init__(app)

    async def dispatch(self, request: Request, call_next):
        method = request.method
        endpoint = request.url.path
        
        start_time = time.time()
        response = await call_next(request)
        process_time = time.time() - start_time
        
        REQUEST_LATENCY_SECONDS.labels(method=method, endpoint=endpoint).observe(process_time)
        REQUEST_COUNT.labels(method=method, endpoint=endpoint, status_code=response.status_code).inc()
        
        return response


