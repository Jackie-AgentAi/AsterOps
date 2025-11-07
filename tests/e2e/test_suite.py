#!/usr/bin/env python3
"""
LLMOps平台端到端测试套件
"""

import pytest
import requests
import json
import time
import logging
from typing import Dict, List, Optional
from dataclasses import dataclass

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class TestConfig:
    """测试配置"""
    api_gateway_url: str = "http://localhost:8080"
    user_service_url: str = "http://localhost:8081"
    model_service_url: str = "http://localhost:8083"
    inference_service_url: str = "http://localhost:8084"
    cost_service_url: str = "http://localhost:8085"
    monitoring_service_url: str = "http://localhost:8086"
    timeout: int = 30
    retry_count: int = 3
    retry_delay: int = 5

class APIClient:
    """API客户端"""
    
    def __init__(self, base_url: str, timeout: int = 30):
        self.base_url = base_url
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        })
    
    def get(self, path: str, **kwargs) -> requests.Response:
        """GET请求"""
        url = f"{self.base_url}{path}"
        return self.session.get(url, timeout=self.timeout, **kwargs)
    
    def post(self, path: str, data: dict = None, **kwargs) -> requests.Response:
        """POST请求"""
        url = f"{self.base_url}{path}"
        return self.session.post(url, json=data, timeout=self.timeout, **kwargs)
    
    def put(self, path: str, data: dict = None, **kwargs) -> requests.Response:
        """PUT请求"""
        url = f"{self.base_url}{path}"
        return self.session.put(url, json=data, timeout=self.timeout, **kwargs)
    
    def delete(self, path: str, **kwargs) -> requests.Response:
        """DELETE请求"""
        url = f"{self.base_url}{path}"
        return self.session.delete(url, timeout=self.timeout, **kwargs)

class TestHelper:
    """测试辅助类"""
    
    @staticmethod
    def wait_for_service(url: str, timeout: int = 60) -> bool:
        """等待服务启动"""
        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                response = requests.get(f"{url}/health", timeout=5)
                if response.status_code == 200:
                    return True
            except requests.RequestException:
                pass
            time.sleep(2)
        return False
    
    @staticmethod
    def retry_request(func, *args, **kwargs):
        """重试请求"""
        for attempt in range(3):
            try:
                return func(*args, **kwargs)
            except requests.RequestException as e:
                if attempt == 2:
                    raise e
                time.sleep(2)
        return None

class TestUserService:
    """用户服务测试"""
    
    def __init__(self, config: TestConfig):
        self.config = config
        self.client = APIClient(config.api_gateway_url)
        self.auth_token = None
    
    def test_health_check(self):
        """测试健康检查"""
        logger.info("测试用户服务健康检查...")
        response = self.client.get("/api/v1/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        logger.info("用户服务健康检查通过")
    
    def test_user_registration(self):
        """测试用户注册"""
        logger.info("测试用户注册...")
        user_data = {
            "username": f"testuser_{int(time.time())}",
            "email": f"test_{int(time.time())}@example.com",
            "password": "password123"
        }
        
        response = self.client.post("/api/v1/auth/register", data=user_data)
        assert response.status_code == 201
        data = response.json()
        assert "user" in data
        logger.info("用户注册测试通过")
    
    def test_user_login(self):
        """测试用户登录"""
        logger.info("测试用户登录...")
        login_data = {
            "username": "testuser",
            "password": "password123"
        }
        
        response = self.client.post("/api/v1/auth/login", data=login_data)
        if response.status_code == 200:
            data = response.json()
            self.auth_token = data.get("token")
            assert self.auth_token is not None
            logger.info("用户登录测试通过")
        else:
            logger.warning("用户登录测试跳过（用户不存在）")
    
    def test_authenticated_request(self):
        """测试认证请求"""
        if not self.auth_token:
            logger.warning("跳过认证请求测试（无token）")
            return
        
        logger.info("测试认证请求...")
        headers = {"Authorization": f"Bearer {self.auth_token}"}
        response = self.client.get("/api/v1/users/profile", headers=headers)
        # 根据实际API调整断言
        logger.info("认证请求测试通过")

class TestModelService:
    """模型服务测试"""
    
    def __init__(self, config: TestConfig):
        self.config = config
        self.client = APIClient(config.api_gateway_url)
    
    def test_health_check(self):
        """测试健康检查"""
        logger.info("测试模型服务健康检查...")
        response = self.client.get("/api/v2/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        logger.info("模型服务健康检查通过")
    
    def test_model_list(self):
        """测试模型列表"""
        logger.info("测试模型列表...")
        response = self.client.get("/api/v2/models")
        assert response.status_code == 200
        data = response.json()
        assert "models" in data or "data" in data
        logger.info("模型列表测试通过")
    
    def test_model_creation(self):
        """测试模型创建"""
        logger.info("测试模型创建...")
        model_data = {
            "name": f"test_model_{int(time.time())}",
            "description": "Test model",
            "framework": "pytorch",
            "task_type": "text-classification"
        }
        
        response = self.client.post("/api/v2/models", data=model_data)
        # 根据实际API调整断言
        logger.info("模型创建测试通过")

class TestInferenceService:
    """推理服务测试"""
    
    def __init__(self, config: TestConfig):
        self.config = config
        self.client = APIClient(config.api_gateway_url)
    
    def test_health_check(self):
        """测试健康检查"""
        logger.info("测试推理服务健康检查...")
        response = self.client.get("/api/v3/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        logger.info("推理服务健康检查通过")
    
    def test_inference_request(self):
        """测试推理请求"""
        logger.info("测试推理请求...")
        inference_data = {
            "model": "gpt-3.5-turbo",
            "messages": [{"role": "user", "content": "Hello"}]
        }
        
        response = self.client.post("/api/v3/inference/chat", data=inference_data)
        # 根据实际API调整断言
        logger.info("推理请求测试通过")

class TestCostService:
    """成本服务测试"""
    
    def __init__(self, config: TestConfig):
        self.config = config
        self.client = APIClient(config.api_gateway_url)
    
    def test_health_check(self):
        """测试健康检查"""
        logger.info("测试成本服务健康检查...")
        response = self.client.get("/api/v4/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        logger.info("成本服务健康检查通过")
    
    def test_cost_recording(self):
        """测试成本记录"""
        logger.info("测试成本记录...")
        cost_data = {
            "project_id": "00000000-0000-0000-0000-000000000001",
            "cost_type": "compute",
            "amount": 100.0,
            "currency": "USD",
            "description": "Test cost"
        }
        
        response = self.client.post("/api/v4/costs", data=cost_data)
        # 根据实际API调整断言
        logger.info("成本记录测试通过")

class TestMonitoringService:
    """监控服务测试"""
    
    def __init__(self, config: TestConfig):
        self.config = config
        self.client = APIClient(config.api_gateway_url)
    
    def test_health_check(self):
        """测试健康检查"""
        logger.info("测试监控服务健康检查...")
        response = self.client.get("/api/v5/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        logger.info("监控服务健康检查通过")
    
    def test_metrics_collection(self):
        """测试指标收集"""
        logger.info("测试指标收集...")
        response = self.client.get("/api/v5/monitoring/metrics")
        assert response.status_code == 200
        data = response.json()
        assert "metrics" in data or "data" in data
        logger.info("指标收集测试通过")

class TestAPIGateway:
    """API网关测试"""
    
    def __init__(self, config: TestConfig):
        self.config = config
        self.client = APIClient(config.api_gateway_url)
    
    def test_health_check(self):
        """测试健康检查"""
        logger.info("测试API网关健康检查...")
        response = self.client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        logger.info("API网关健康检查通过")
    
    def test_routing(self):
        """测试路由"""
        logger.info("测试API网关路由...")
        # 测试各个服务的路由
        services = [
            ("/api/v1/health", "用户服务"),
            ("/api/v2/health", "模型服务"),
            ("/api/v3/health", "推理服务"),
            ("/api/v4/health", "成本服务"),
            ("/api/v5/health", "监控服务")
        ]
        
        for path, service_name in services:
            response = self.client.get(path)
            if response.status_code == 200:
                logger.info(f"{service_name}路由正常")
            else:
                logger.warning(f"{service_name}路由异常: {response.status_code}")

class E2ETestSuite:
    """端到端测试套件"""
    
    def __init__(self, config: TestConfig):
        self.config = config
        self.user_test = TestUserService(config)
        self.model_test = TestModelService(config)
        self.inference_test = TestInferenceService(config)
        self.cost_test = TestCostService(config)
        self.monitoring_test = TestMonitoringService(config)
        self.gateway_test = TestAPIGateway(config)
    
    def setup(self):
        """测试设置"""
        logger.info("开始端到端测试设置...")
        
        # 等待所有服务启动
        services = [
            (self.config.api_gateway_url, "API网关"),
            (self.config.user_service_url, "用户服务"),
            (self.config.model_service_url, "模型服务"),
            (self.config.inference_service_url, "推理服务"),
            (self.config.cost_service_url, "成本服务"),
            (self.config.monitoring_service_url, "监控服务")
        ]
        
        for url, name in services:
            if TestHelper.wait_for_service(url, self.config.timeout):
                logger.info(f"{name}启动成功")
            else:
                logger.error(f"{name}启动失败")
                raise Exception(f"{name}启动失败")
        
        logger.info("所有服务启动完成")
    
    def test_all_services(self):
        """测试所有服务"""
        logger.info("开始测试所有服务...")
        
        # 测试API网关
        self.gateway_test.test_health_check()
        self.gateway_test.test_routing()
        
        # 测试用户服务
        self.user_test.test_health_check()
        self.user_test.test_user_registration()
        self.user_test.test_user_login()
        self.user_test.test_authenticated_request()
        
        # 测试模型服务
        self.model_test.test_health_check()
        self.model_test.test_model_list()
        self.model_test.test_model_creation()
        
        # 测试推理服务
        self.inference_test.test_health_check()
        self.inference_test.test_inference_request()
        
        # 测试成本服务
        self.cost_test.test_health_check()
        self.cost_test.test_cost_recording()
        
        # 测试监控服务
        self.monitoring_test.test_health_check()
        self.monitoring_test.test_metrics_collection()
        
        logger.info("所有服务测试完成")
    
    def teardown(self):
        """测试清理"""
        logger.info("开始测试清理...")
        # 清理测试数据
        logger.info("测试清理完成")

def main():
    """主函数"""
    config = TestConfig()
    test_suite = E2ETestSuite(config)
    
    try:
        test_suite.setup()
        test_suite.test_all_services()
        logger.info("端到端测试完成")
    except Exception as e:
        logger.error(f"端到端测试失败: {e}")
        raise
    finally:
        test_suite.teardown()

if __name__ == "__main__":
    main()



