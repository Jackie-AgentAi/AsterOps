# 智能路由引擎架构设计

## 一、设计目标

实现基于多维度策略的智能请求路由系统,根据Query特征、成本约束、负载状态、用户画像等因素,自动选择最优推理路径,提升服务质量与成本效益。

## 二、核心能力

### 2.1 Query分类与理解
```yaml
分类维度:
  任务类型:
    - 知识问答: 事实性查询、百科问答
    - 代码生成: 编程任务、代码补全
    - 逻辑推理: 数学推理、因果分析
    - 创意写作: 文章创作、内容生成
    - 对话交互: 闲聊、情感支持
  
  复杂度评估:
    - 简单(1-3分): 事实查询、简单问答
    - 中等(4-6分): 需要多步推理
    - 复杂(7-10分): 需要深度分析、长文本生成
  
  领域识别:
    - 通用领域
    - 垂直领域: 金融/医疗/法律/教育等
    - 专业领域: 特定行业知识

实现方案:
  方案一: 轻量级分类器(推荐)
    - 模型: DistilBERT/TinyBERT微调
    - 输入: Query前256 tokens
    - 输出: 任务类型(8类) + 复杂度分数 + 领域标签
    - 延迟: <50ms
    - 准确率目标: >90%
  
  方案二: 规则+模型混合
    - 关键词匹配: 快速识别明显特征
    - 分类器兜底: 处理模糊Query
    - 优点: 延迟更低(~20ms)
    - 缺点: 维护成本高
```

### 2.2 路由策略引擎

#### 2.2.1 成本-质量权衡路由
```python
# 路由决策算法伪代码
def select_model_by_cost_quality(query, sla_config):
    """
    基于成本-质量权衡选择模型
    """
    # 1. 提取Query特征
    task_type = classifier.predict_task(query)
    complexity = classifier.predict_complexity(query)
    
    # 2. 获取候选模型池
    candidate_models = [
        {"name": "gpt-4", "cost": 0.03, "quality": 0.95, "latency": 2.0},
        {"name": "gpt-3.5-turbo", "cost": 0.002, "quality": 0.85, "latency": 0.8},
        {"name": "llama-70b", "cost": 0.001, "quality": 0.88, "latency": 1.2},
        {"name": "llama-13b", "cost": 0.0003, "quality": 0.75, "latency": 0.5},
    ]
    
    # 3. 根据SLA要求过滤
    if sla_config.max_latency:
        candidate_models = [m for m in candidate_models 
                           if m["latency"] <= sla_config.max_latency]
    
    if sla_config.min_quality:
        candidate_models = [m for m in candidate_models 
                           if m["quality"] >= sla_config.min_quality]
    
    # 4. 成本-质量评分
    for model in candidate_models:
        # 简单Query优先低成本模型,复杂Query优先高质量模型
        complexity_weight = complexity / 10.0
        model["score"] = (
            model["quality"] * complexity_weight + 
            (1 - model["cost"] / max_cost) * (1 - complexity_weight)
        )
    
    # 5. 选择最高分模型
    return max(candidate_models, key=lambda m: m["score"])
```

#### 2.2.2 负载感知路由
```yaml
负载监控指标:
  - 模型QPS: 每秒请求数
  - 排队长度: 等待处理的请求数
  - GPU利用率: 计算资源占用
  - 平均延迟: P50/P90/P99延迟

路由策略:
  健康检查:
    - 实时监控模型服务状态
    - 故障模型自动摘除
    - 心跳超时3次标记为不可用
  
  负载均衡:
    - 加权轮询: 根据模型容量分配权重
    - 最少连接: 选择当前负载最低的实例
    - 一致性哈希: 同用户请求路由到同一实例(会话保持)
  
  过载保护:
    - 排队长度>阈值: 拒绝路由到该模型
    - GPU利用率>90%: 降低权重
    - P99延迟>SLA: 触发扩容或流量切换

实现示例:
  # 负载评分算法
  load_score = (
    0.4 * (1 - qps / max_qps) +
    0.3 * (1 - queue_length / max_queue) +
    0.3 * (1 - gpu_utilization)
  )
  # 选择负载评分最高的实例
```

#### 2.2.3 用户画像路由
```yaml
用户分层:
  VIP用户:
    - 特征: 付费用户、高价值客户
    - 路由策略: 优先高性能模型,无排队
    - 成本预算: 放宽限制
  
  普通用户:
    - 特征: 免费用户、低频使用
    - 路由策略: 标准模型,正常排队
    - 成本预算: 严格控制
  
  测试用户:
    - 特征: 开发测试账号
    - 路由策略: 测试环境模型
    - 成本预算: 配额限制

历史行为分析:
  - 用户偏好模型: 统计历史满意度高的模型
  - 任务分布: 用户常见任务类型
  - 时段特征: 高峰/低峰时段习惯

动态调整:
  - 用户反馈负面: 自动升级到更好模型
  - 成本超预算: 引导使用经济模型
  - AB测试: 部分用户试用新模型
```

### 2.3 多模型协同路由

#### 2.3.1 专家混合(MoE)路由
```yaml
场景: 不同模型在不同子任务上有优势

架构:
  - Router: 识别任务类型
  - Expert Models: 专家模型池
    * 代码专家: CodeLlama
    * 数学专家: WizardMath
    * 对话专家: Vicuna
    * 通用专家: Llama2-70B
  - Aggregator: 结果聚合(如需要)

路由逻辑:
  if task_type == "code":
      return route_to("CodeLlama")
  elif task_type == "math":
      return route_to("WizardMath")
  elif task_type == "chat":
      return route_to("Vicuna")
  else:
      return route_to("Llama2-70B")

优势:
  - 质量提升: 专业模型在垂直领域表现更佳
  - 成本优化: 小模型处理简单任务
  - 灵活扩展: 新增专家模型无需改动主流程
```

#### 2.3.2 级联路由
```yaml
场景: 粗筛+精排,降低成本

两阶段架构:
  Stage 1 - 粗筛:
    - 使用小模型: Llama-13B
    - 快速判断: 能否直接回答
    - 决策:
      * 简单Query → 直接返回结果
      * 复杂Query → 进入Stage 2
  
  Stage 2 - 精排:
    - 使用大模型: GPT-4
    - 深度分析
    - 返回高质量结果

收益:
  - 50%的简单Query被小模型处理
  - 成本降低60%
  - 整体延迟降低30%

实现示例:
  # 粗筛阶段
  small_model_response = llama13b.generate(query)
  confidence = compute_confidence(small_model_response)
  
  if confidence > 0.85:
      return small_model_response  # 直接返回
  else:
      # 精排阶段
      return gpt4.generate(query)
```

#### 2.3.3 投票路由
```yaml
场景: 关键决策,需要多模型共识

架构:
  - 并行调用3-5个模型
  - 收集所有输出
  - 投票机制选择最终答案

投票策略:
  简单多数:
    - 统计相同答案出现次数
    - 选择多数派答案
  
  加权投票:
    - 根据模型质量评分加权
    - 高质量模型权重更高
  
  一致性检查:
    - 所有模型输出一致: 高信心返回
    - 分歧严重: 标记为不确定,转人工

适用场景:
  - 医疗诊断建议
  - 法律意见咨询
  - 金融风险评估
  - 安全敏感决策

成本考量:
  - 仅对高价值场景启用
  - 配置动态开关
  - 成本是单模型的3-5倍
```

## 三、系统架构

### 3.1 整体架构
```
┌─────────────────────────────────────────────────────────┐
│                    客户端请求                              │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│                  路由网关 (Router Gateway)                │
│  - 请求解析  - 用户认证  - 限流控制  - 日志记录            │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│              Query分析引擎 (Query Analyzer)               │
│  - 任务分类  - 复杂度评估  - 领域识别  - 特征提取          │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│              路由决策引擎 (Routing Engine)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  规则引擎    │  │  策略引擎    │  │  ML模型      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│              模型选择器 (Model Selector)                   │
│  - 候选模型筛选  - 负载评估  - 成本计算  - 最优选择       │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│                 推理服务池 (Inference Pool)               │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐     │
│  │GPT-4 │  │ Llama│  │Claude│  │ GLM  │  │ ...  │     │
│  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘     │
└─────────────────────────────────────────────────────────┘
```

### 3.2 数据流设计

#### 请求流程
```yaml
1. 请求接入:
   - 客户端发起请求
   - API网关接收并解析
   - 提取用户信息、SLA配置

2. Query分析:
   - 输入Query到分类模型
   - 识别任务类型、复杂度、领域
   - 耗时: <50ms

3. 路由决策:
   - 加载用户画像
   - 查询模型池状态
   - 执行路由策略
   - 输出: 目标模型 + 实例ID
   - 耗时: <20ms

4. 请求转发:
   - 转发到选定模型实例
   - 建立连接并发送
   - 等待推理结果

5. 结果返回:
   - 接收模型输出
   - 记录路由日志
   - 返回给客户端
```

#### 监控反馈流程
```yaml
1. 实时监控:
   - 采集模型服务指标(QPS/延迟/错误率)
   - 采集资源指标(GPU/CPU/内存)
   - 频率: 10秒/次

2. 状态更新:
   - 更新模型可用性状态
   - 更新负载评分
   - 更新路由权重

3. 反馈优化:
   - 收集用户满意度反馈
   - 统计路由决策准确率
   - 定期训练优化分类模型
```

### 3.3 核心组件实现

#### 3.3.1 Query分类器
```python
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch

class QueryClassifier:
    def __init__(self, model_path):
        self.tokenizer = AutoTokenizer.from_pretrained(model_path)
        self.model = AutoModelForSequenceClassification.from_pretrained(model_path)
        self.model.eval()
        
        self.task_labels = [
            "qa", "code", "reasoning", "writing", "chat", 
            "translation", "summarization", "other"
        ]
        self.domain_labels = [
            "general", "finance", "medical", "legal", "education", "tech"
        ]
    
    def classify(self, query):
        """
        分类Query
        返回: {
            "task_type": str,
            "complexity": float [0-10],
            "domain": str,
            "confidence": float
        }
        """
        # Tokenize
        inputs = self.tokenizer(
            query, 
            max_length=256, 
            truncation=True, 
            return_tensors="pt"
        )
        
        # 推理
        with torch.no_grad():
            outputs = self.model(**inputs)
            logits = outputs.logits
        
        # 解析结果
        task_probs = torch.softmax(logits[0][:8], dim=0)
        task_idx = torch.argmax(task_probs).item()
        task_conf = task_probs[task_idx].item()
        
        # 复杂度评估(基于Query长度和特征)
        complexity = self._estimate_complexity(query, logits)
        
        # 领域识别
        domain_probs = torch.softmax(logits[0][8:14], dim=0)
        domain_idx = torch.argmax(domain_probs).item()
        
        return {
            "task_type": self.task_labels[task_idx],
            "complexity": complexity,
            "domain": self.domain_labels[domain_idx],
            "confidence": task_conf
        }
    
    def _estimate_complexity(self, query, logits):
        """估算Query复杂度"""
        # 因素1: Query长度
        length_score = min(len(query.split()) / 50.0, 1.0) * 3
        
        # 因素2: 关键词检测
        complex_keywords = ["why", "how", "analyze", "compare", "explain"]
        keyword_score = sum(1 for kw in complex_keywords if kw in query.lower())
        
        # 因素3: 模型输出的复杂度特征(预训练时加入)
        model_score = torch.sigmoid(logits[0][14]).item() * 5
        
        return min(length_score + keyword_score + model_score, 10.0)
```

#### 3.3.2 路由决策引擎
```python
import numpy as np
from typing import List, Dict
import redis

class RoutingEngine:
    def __init__(self, redis_client, config):
        self.redis = redis_client
        self.config = config
        self.model_registry = self._load_model_registry()
    
    def route(self, query_features, user_profile, sla_config):
        """
        核心路由方法
        """
        # 1. 获取候选模型池
        candidates = self._get_candidate_models(query_features)
        
        # 2. 过滤不可用模型
        candidates = self._filter_available(candidates)
        
        # 3. 计算每个候选的路由分数
        scored_candidates = []
        for model in candidates:
            score = self._compute_routing_score(
                model, 
                query_features, 
                user_profile, 
                sla_config
            )
            scored_candidates.append((model, score))
        
        # 4. 选择最优模型
        best_model, best_score = max(scored_candidates, key=lambda x: x[1])
        
        # 5. 选择具体实例(负载均衡)
        instance = self._select_instance(best_model)
        
        # 6. 记录决策日志
        self._log_routing_decision(query_features, best_model, best_score)
        
        return {
            "model_id": best_model["id"],
            "model_name": best_model["name"],
            "instance_id": instance["id"],
            "endpoint": instance["endpoint"],
            "estimated_cost": best_model["cost_per_token"],
            "estimated_latency": instance["avg_latency"]
        }
    
    def _compute_routing_score(self, model, query_features, user_profile, sla_config):
        """
        计算路由评分
        """
        score = 0.0
        
        # 因素1: 任务匹配度 (权重40%)
        task_match = self._compute_task_match(model, query_features["task_type"])
        score += 0.4 * task_match
        
        # 因素2: 成本效益 (权重25%)
        complexity = query_features["complexity"]
        if complexity < 4:  # 简单任务优先低成本
            cost_score = 1.0 - (model["cost_per_token"] / self.config["max_cost"])
            score += 0.25 * cost_score
        else:  # 复杂任务优先质量
            quality_score = model["quality_score"]
            score += 0.25 * quality_score
        
        # 因素3: 用户优先级 (权重20%)
        if user_profile["tier"] == "vip":
            # VIP用户优先高质量模型
            score += 0.2 * model["quality_score"]
        else:
            # 普通用户平衡成本质量
            score += 0.1 * model["quality_score"]
            score += 0.1 * (1.0 - model["cost_per_token"] / self.config["max_cost"])
        
        # 因素4: 负载情况 (权重15%)
        load_score = self._get_model_load_score(model["id"])
        score += 0.15 * load_score
        
        # SLA约束检查
        if sla_config.get("max_latency"):
            if model["avg_latency"] > sla_config["max_latency"]:
                score *= 0.5  # 大幅降低分数
        
        if sla_config.get("min_quality"):
            if model["quality_score"] < sla_config["min_quality"]:
                score = 0.0  # 不符合质量要求
        
        return score
    
    def _compute_task_match(self, model, task_type):
        """计算模型与任务的匹配度"""
        # 从模型元数据获取擅长的任务类型
        model_tasks = model.get("specialized_tasks", [])
        
        if task_type in model_tasks:
            return 1.0
        elif "general" in model_tasks:
            return 0.7
        else:
            return 0.5
    
    def _get_model_load_score(self, model_id):
        """获取模型负载评分 (0-1, 越高越空闲)"""
        # 从Redis获取实时负载数据
        load_data = self.redis.hgetall(f"model:{model_id}:load")
        
        if not load_data:
            return 0.5  # 默认中等负载
        
        qps = float(load_data.get(b"qps", 0))
        max_qps = float(load_data.get(b"max_qps", 100))
        queue_len = float(load_data.get(b"queue_length", 0))
        max_queue = 100
        gpu_util = float(load_data.get(b"gpu_utilization", 0))
        
        # 综合评分
        load_score = (
            0.4 * (1 - min(qps / max_qps, 1.0)) +
            0.3 * (1 - min(queue_len / max_queue, 1.0)) +
            0.3 * (1 - gpu_util)
        )
        
        return max(load_score, 0.0)
    
    def _select_instance(self, model):
        """选择具体实例 - 最少连接算法"""
        instances = self.redis.smembers(f"model:{model['id']}:instances")
        
        best_instance = None
        min_connections = float('inf')
        
        for inst_id in instances:
            inst_data = self.redis.hgetall(f"instance:{inst_id.decode()}")
            connections = int(inst_data.get(b"active_connections", 0))
            
            if connections < min_connections:
                min_connections = connections
                best_instance = {
                    "id": inst_id.decode(),
                    "endpoint": inst_data.get(b"endpoint").decode(),
                    "avg_latency": float(inst_data.get(b"avg_latency", 1.0))
                }
        
        return best_instance
    
    def _log_routing_decision(self, query_features, model, score):
        """记录路由决策,用于后续分析优化"""
        log_entry = {
            "timestamp": time.time(),
            "task_type": query_features["task_type"],
            "complexity": query_features["complexity"],
            "selected_model": model["id"],
            "routing_score": score
        }
        # 写入时序数据库或Kafka
        pass
```

#### 3.3.3 负载监控Agent
```python
import psutil
import threading
import time

class LoadMonitorAgent:
    """
    部署在每个推理节点的监控Agent
    """
    def __init__(self, redis_client, instance_id, model_id):
        self.redis = redis_client
        self.instance_id = instance_id
        self.model_id = model_id
        self.metrics = {
            "qps": 0,
            "active_connections": 0,
            "avg_latency": 0,
            "gpu_utilization": 0,
            "error_rate": 0
        }
        self.latency_window = []
        self.request_count = 0
        self.error_count = 0
    
    def start(self):
        """启动监控"""
        # 启动指标采集线程
        threading.Thread(target=self._collect_metrics_loop, daemon=True).start()
        # 启动数据上报线程
        threading.Thread(target=self._report_metrics_loop, daemon=True).start()
    
    def _collect_metrics_loop(self):
        """采集指标循环"""
        while True:
            self._collect_gpu_metrics()
            time.sleep(5)  # 每5秒采集一次
    
    def _report_metrics_loop(self):
        """上报指标循环"""
        while True:
            self._report_to_redis()
            time.sleep(10)  # 每10秒上报一次
    
    def _collect_gpu_metrics(self):
        """采集GPU指标"""
        try:
            import pynvml
            pynvml.nvmlInit()
            handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            util = pynvml.nvmlDeviceGetUtilizationRates(handle)
            self.metrics["gpu_utilization"] = util.gpu / 100.0
            pynvml.nvmlShutdown()
        except:
            self.metrics["gpu_utilization"] = 0
    
    def record_request(self, latency, is_error=False):
        """记录请求"""
        self.request_count += 1
        self.latency_window.append(latency)
        if len(self.latency_window) > 100:
            self.latency_window.pop(0)
        
        if is_error:
            self.error_count += 1
        
        # 更新指标
        self.metrics["avg_latency"] = sum(self.latency_window) / len(self.latency_window)
        self.metrics["error_rate"] = self.error_count / max(self.request_count, 1)
    
    def _report_to_redis(self):
        """上报到Redis"""
        # 计算QPS (最近10秒的平均)
        current_count = self.request_count
        time.sleep(10)
        qps = (self.request_count - current_count) / 10.0
        self.metrics["qps"] = qps
        
        # 上报实例指标
        self.redis.hset(
            f"instance:{self.instance_id}",
            mapping={
                "active_connections": self.metrics["active_connections"],
                "avg_latency": self.metrics["avg_latency"],
                "qps": qps,
                "error_rate": self.metrics["error_rate"]
            }
        )
        
        # 上报模型聚合指标
        self.redis.hset(
            f"model:{self.model_id}:load",
            mapping={
                "gpu_utilization": self.metrics["gpu_utilization"]
            }
        )
```

## 四、关键指标与监控

### 4.1 路由质量指标
```yaml
准确率指标:
  - 任务分类准确率: >90%
  - 最优模型选择准确率: >85% (通过后验对比)
  - 用户满意度: >4.2/5.0

性能指标:
  - 路由决策延迟: P99 < 50ms
  - Query分类延迟: P99 < 30ms
  - 端到端延迟增加: <5%

成本指标:
  - 成本降低: 30-40% (相比固定路由)
  - 高成本模型调用比例: <20%
  - 低成本模型覆盖率: >60%
```

### 4.2 监控告警
```yaml
告警规则:
  路由失败率:
    - Warning: >1%
    - Critical: >5%
    - 动作: 切换备用路由策略
  
  分类器延迟:
    - Warning: P99 > 100ms
    - Critical: P99 > 200ms
    - 动作: 增加分类器实例
  
  路由偏差:
    - 检测: 某模型调用比例异常(>50%)
    - 动作: 检查路由策略配置
  
  成本异常:
    - 检测: 单小时成本超预算1.5倍
    - 动作: 触发成本保护,限制高成本模型调用
```

## 五、优化与演进

### 5.1 在线学习优化
```yaml
数据收集:
  - 路由决策: Query特征 + 选择的模型
  - 用户反馈: 满意度评分(1-5分)
  - 实际效果: 模型输出质量、延迟、成本

模型优化:
  - 每周重训练分类模型
  - 使用真实数据微调
  - A/B测试新版本分类器

策略优化:
  - 根据统计数据调整权重
  - 发现新的路由规则
  - 淘汰低效策略
```

### 5.2 个性化路由
```yaml
用户画像构建:
  - 历史任务分布
  - 模型偏好统计
  - 成本敏感度
  - 质量要求

个性化策略:
  - 为每个用户/项目定制路由权重
  - 学习用户满意度模式
  - 推荐最适合的模型
```

### 5.3 多目标优化
```yaml
当前挑战:
  - 成本、质量、延迟三者权衡
  - 不同用户有不同偏好

解决方案:
  - 帕累托最优: 多目标优化算法
  - 动态权重: 根据场景自动调整
  - 强化学习: 长期收益最大化
```

## 六、部署方案

### 6.1 组件部署
```yaml
路由网关:
  - 部署: Kubernetes Deployment
  - 副本数: 3-5个(根据流量)
  - 资源: 2C4G per pod
  - 暴露: Service + Ingress

Query分类器:
  - 部署: 独立服务(FastAPI)
  - 副本数: 2-3个
  - 资源: 4C8G + GPU(可选)
  - 模型加载: 启动时加载到内存

路由引擎:
  - 部署: 与网关同进程(低延迟)
  - 依赖: Redis集群(存储状态)

监控Agent:
  - 部署: DaemonSet(每个推理节点)
  - 资源: 0.5C1G per node
```

### 6.2 灰度发布
```yaml
步骤1: 小流量验证(1%)
  - 验证路由正确性
  - 监控错误率、延迟

步骤2: 扩大流量(10%)
  - 对比路由效果
  - 验证成本降低

步骤3: 全量发布(100%)
  - 逐步提升流量
  - 保留回滚能力

回滚策略:
  - 1分钟内可一键回滚到旧版本
  - 自动触发条件: 错误率>5% or 延迟>2x
```

## 七、预期收益

```yaml
性能收益:
  - 端到端延迟: 降低20%(通过智能负载均衡)
  - 请求成功率: 提升到99.9%(故障自动切换)

成本收益:
  - 推理成本: 降低35-40%(小模型处理简单任务)
  - 资源利用率: 提升25%(负载均衡优化)

用户体验:
  - VIP用户延迟: 降低30%(优先路由)
  - 用户满意度: 提升15%

运维效率:
  - 手动干预: 减少80%(自动路由优化)
  - 故障恢复: 从分钟级到秒级
```

