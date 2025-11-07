#!/usr/bin/env python3
"""
LLMOps平台性能测试框架
"""

import asyncio
import aiohttp
import time
import json
import statistics
import logging
from typing import List, Dict, Optional
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor
import matplotlib.pyplot as plt
import pandas as pd

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class PerformanceConfig:
    """性能测试配置"""
    api_gateway_url: str = "http://localhost:8080"
    concurrent_users: int = 100
    test_duration: int = 60  # 秒
    ramp_up_time: int = 10   # 秒
    target_rps: int = 100    # 每秒请求数
    timeout: int = 30

@dataclass
class TestResult:
    """测试结果"""
    response_time: float
    status_code: int
    success: bool
    error: Optional[str] = None
    timestamp: float = 0

class PerformanceTest:
    """性能测试类"""
    
    def __init__(self, config: PerformanceConfig):
        self.config = config
        self.results: List[TestResult] = []
        self.start_time = 0
        self.end_time = 0
    
    async def make_request(self, session: aiohttp.ClientSession, url: str, method: str = "GET", data: dict = None) -> TestResult:
        """发送单个请求"""
        start_time = time.time()
        try:
            if method == "GET":
                async with session.get(url, timeout=self.config.timeout) as response:
                    response_time = time.time() - start_time
                    return TestResult(
                        response_time=response_time,
                        status_code=response.status,
                        success=200 <= response.status < 300,
                        timestamp=start_time
                    )
            elif method == "POST":
                async with session.post(url, json=data, timeout=self.config.timeout) as response:
                    response_time = time.time() - start_time
                    return TestResult(
                        response_time=response_time,
                        status_code=response.status,
                        success=200 <= response.status < 300,
                        timestamp=start_time
                    )
        except Exception as e:
            response_time = time.time() - start_time
            return TestResult(
                response_time=response_time,
                status_code=0,
                success=False,
                error=str(e),
                timestamp=start_time
            )
    
    async def run_load_test(self, url: str, method: str = "GET", data: dict = None):
        """运行负载测试"""
        logger.info(f"开始负载测试: {url}")
        logger.info(f"并发用户: {self.config.concurrent_users}")
        logger.info(f"测试时长: {self.config.test_duration}秒")
        
        self.start_time = time.time()
        self.end_time = self.start_time + self.config.test_duration
        
        # 创建HTTP会话
        connector = aiohttp.TCPConnector(limit=self.config.concurrent_users)
        timeout = aiohttp.ClientTimeout(total=self.config.timeout)
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            # 创建任务
            tasks = []
            for _ in range(self.config.concurrent_users):
                task = asyncio.create_task(
                    self._worker(session, url, method, data)
                )
                tasks.append(task)
            
            # 等待所有任务完成
            await asyncio.gather(*tasks)
        
        logger.info("负载测试完成")
    
    async def _worker(self, session: aiohttp.ClientSession, url: str, method: str, data: dict):
        """工作线程"""
        while time.time() < self.end_time:
            result = await self.make_request(session, url, method, data)
            self.results.append(result)
            
            # 控制请求频率
            await asyncio.sleep(1.0 / self.config.target_rps)
    
    def calculate_metrics(self) -> Dict:
        """计算性能指标"""
        if not self.results:
            return {}
        
        response_times = [r.response_time for r in self.results]
        success_count = sum(1 for r in self.results if r.success)
        total_count = len(self.results)
        
        metrics = {
            "total_requests": total_count,
            "successful_requests": success_count,
            "failed_requests": total_count - success_count,
            "success_rate": success_count / total_count * 100,
            "average_response_time": statistics.mean(response_times),
            "median_response_time": statistics.median(response_times),
            "p95_response_time": self._percentile(response_times, 95),
            "p99_response_time": self._percentile(response_times, 99),
            "min_response_time": min(response_times),
            "max_response_time": max(response_times),
            "requests_per_second": total_count / (self.end_time - self.start_time),
            "test_duration": self.end_time - self.start_time
        }
        
        return metrics
    
    def _percentile(self, data: List[float], percentile: int) -> float:
        """计算百分位数"""
        sorted_data = sorted(data)
        index = int(len(sorted_data) * percentile / 100)
        return sorted_data[min(index, len(sorted_data) - 1)]
    
    def generate_report(self, output_file: str = "performance_report.json"):
        """生成性能报告"""
        metrics = self.calculate_metrics()
        
        report = {
            "test_config": {
                "concurrent_users": self.config.concurrent_users,
                "test_duration": self.config.test_duration,
                "target_rps": self.config.target_rps
            },
            "metrics": metrics,
            "timestamp": time.time()
        }
        
        with open(output_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        logger.info(f"性能报告已生成: {output_file}")
        return report
    
    def plot_results(self, output_file: str = "performance_chart.png"):
        """绘制性能图表"""
        if not self.results:
            logger.warning("没有测试结果可绘制")
            return
        
        # 准备数据
        timestamps = [r.timestamp - self.start_time for r in self.results]
        response_times = [r.response_time for r in self.results]
        
        # 创建图表
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))
        
        # 响应时间趋势
        ax1.plot(timestamps, response_times, alpha=0.7)
        ax1.set_xlabel('时间 (秒)')
        ax1.set_ylabel('响应时间 (秒)')
        ax1.set_title('响应时间趋势')
        ax1.grid(True)
        
        # 响应时间分布
        ax2.hist(response_times, bins=50, alpha=0.7)
        ax2.set_xlabel('响应时间 (秒)')
        ax2.set_ylabel('频次')
        ax2.set_title('响应时间分布')
        ax2.grid(True)
        
        plt.tight_layout()
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        logger.info(f"性能图表已生成: {output_file}")

class APIGatewayPerformanceTest:
    """API网关性能测试"""
    
    def __init__(self, config: PerformanceConfig):
        self.config = config
        self.tests = []
    
    async def test_health_endpoint(self):
        """测试健康检查端点"""
        logger.info("测试API网关健康检查端点...")
        test = PerformanceTest(self.config)
        await test.run_load_test(f"{self.config.api_gateway_url}/health")
        metrics = test.calculate_metrics()
        logger.info(f"健康检查端点性能: {metrics}")
        return test
    
    async def test_user_service_routing(self):
        """测试用户服务路由"""
        logger.info("测试用户服务路由...")
        test = PerformanceTest(self.config)
        await test.run_load_test(f"{self.config.api_gateway_url}/api/v1/health")
        metrics = test.calculate_metrics()
        logger.info(f"用户服务路由性能: {metrics}")
        return test
    
    async def test_model_service_routing(self):
        """测试模型服务路由"""
        logger.info("测试模型服务路由...")
        test = PerformanceTest(self.config)
        await test.run_load_test(f"{self.config.api_gateway_url}/api/v2/health")
        metrics = test.calculate_metrics()
        logger.info(f"模型服务路由性能: {metrics}")
        return test
    
    async def test_inference_service_routing(self):
        """测试推理服务路由"""
        logger.info("测试推理服务路由...")
        test = PerformanceTest(self.config)
        await test.run_load_test(f"{self.config.api_gateway_url}/api/v3/health")
        metrics = test.calculate_metrics()
        logger.info(f"推理服务路由性能: {metrics}")
        return test
    
    async def test_cost_service_routing(self):
        """测试成本服务路由"""
        logger.info("测试成本服务路由...")
        test = PerformanceTest(self.config)
        await test.run_load_test(f"{self.config.api_gateway_url}/api/v4/health")
        metrics = test.calculate_metrics()
        logger.info(f"成本服务路由性能: {metrics}")
        return test
    
    async def test_monitoring_service_routing(self):
        """测试监控服务路由"""
        logger.info("测试监控服务路由...")
        test = PerformanceTest(self.config)
        await test.run_load_test(f"{self.config.api_gateway_url}/api/v5/health")
        metrics = test.calculate_metrics()
        logger.info(f"监控服务路由性能: {metrics}")
        return test
    
    async def run_all_tests(self):
        """运行所有测试"""
        logger.info("开始API网关性能测试...")
        
        tests = [
            self.test_health_endpoint(),
            self.test_user_service_routing(),
            self.test_model_service_routing(),
            self.test_inference_service_routing(),
            self.test_cost_service_routing(),
            self.test_monitoring_service_routing()
        ]
        
        results = await asyncio.gather(*tests)
        
        # 生成综合报告
        all_results = []
        for test in results:
            all_results.extend(test.results)
        
        # 创建综合测试结果
        combined_test = PerformanceTest(self.config)
        combined_test.results = all_results
        combined_test.start_time = min(r.timestamp for r in all_results)
        combined_test.end_time = max(r.timestamp for r in all_results)
        
        # 生成报告
        report = combined_test.generate_report("api_gateway_performance_report.json")
        combined_test.plot_results("api_gateway_performance_chart.png")
        
        logger.info("API网关性能测试完成")
        return report

class DatabasePerformanceTest:
    """数据库性能测试"""
    
    def __init__(self, config: PerformanceConfig):
        self.config = config
    
    async def test_database_connection(self):
        """测试数据库连接性能"""
        logger.info("测试数据库连接性能...")
        # 这里需要根据实际数据库实现
        pass
    
    async def test_database_queries(self):
        """测试数据库查询性能"""
        logger.info("测试数据库查询性能...")
        # 这里需要根据实际数据库实现
        pass

class CachePerformanceTest:
    """缓存性能测试"""
    
    def __init__(self, config: PerformanceConfig):
        self.config = config
    
    async def test_redis_performance(self):
        """测试Redis性能"""
        logger.info("测试Redis性能...")
        # 这里需要根据实际Redis实现
        pass

async def main():
    """主函数"""
    config = PerformanceConfig(
        concurrent_users=50,
        test_duration=30,
        target_rps=50
    )
    
    # API网关性能测试
    gateway_test = APIGatewayPerformanceTest(config)
    await gateway_test.run_all_tests()
    
    logger.info("性能测试完成")

if __name__ == "__main__":
    asyncio.run(main())



