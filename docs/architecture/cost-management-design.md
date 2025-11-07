# 成本管控系统架构设计

## 一、设计目标

构建企业级LLM成本管控体系,实现Token级细粒度计量、多维度成本归因、智能降本策略、预算预警与自动限流,帮助企业将LLM推理成本降低30-40%。

## 二、核心能力

### 2.1 细粒度成本追踪

#### 2.1.1 Token级计量系统
```yaml
计量维度:
  Input Token:
    - 用户输入文本Token数
    - 系统Prompt Token数
    - 上下文历史Token数
    - 检索文档Token数
  
  Output Token:
    - 模型生成Token数
    - 流式输出分段计量
    - 截断/错误重试Token数
  
  Model成本:
    - 不同模型Token单价
    - 实时价格更新
    - 批量折扣计算

实现架构:
  计量Agent:
    - 部署在每个推理节点
    - 实时Token计数
    - 本地缓存+批量上报
  
  成本计算引擎:
    - 实时价格查询
    - 多维度成本计算
    - 汇率转换(如需要)
  
  数据存储:
    - 实时数据: Redis(最近1小时)
    - 历史数据: ClickHouse(长期存储)
    - 聚合数据: PostgreSQL(报表查询)
```

#### 2.1.2 多维度成本归因
```python
class CostAttribution:
    """
    成本归因系统
    """
    def __init__(self):
        self.attribution_dimensions = [
            "user_id",      # 用户维度
            "project_id",   # 项目维度
            "model_id",     # 模型维度
            "api_key",      # API密钥维度
            "tenant_id",    # 租户维度
            "region",       # 地域维度
            "time_bucket"   # 时间维度(小时/天/月)
        ]
    
    def calculate_cost(self, request_data):
        """
        计算请求成本并归因
        """
        # 1. 基础Token计量
        input_tokens = self._count_tokens(request_data["input"])
        output_tokens = self._count_tokens(request_data["output"])
        
        # 2. 模型定价查询
        model_pricing = self._get_model_pricing(request_data["model_id"])
        
        # 3. 成本计算
        input_cost = input_tokens * model_pricing["input_price_per_1k"] / 1000
        output_cost = output_tokens * model_pricing["output_price_per_1k"] / 1000
        total_cost = input_cost + output_cost
        
        # 4. 多维度归因
        attribution = {
            "request_id": request_data["request_id"],
            "timestamp": request_data["timestamp"],
            "total_cost": total_cost,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "input_cost": input_cost,
            "output_cost": output_cost,
            "model_id": request_data["model_id"],
            "user_id": request_data["user_id"],
            "project_id": request_data.get("project_id"),
            "api_key": request_data.get("api_key"),
            "tenant_id": request_data.get("tenant_id"),
            "region": request_data.get("region", "default")
        }
        
        return attribution
    
    def _count_tokens(self, text):
        """Token计数 - 支持多种模型"""
        # 使用tiktoken库进行精确计数
        import tiktoken
        
        # 根据模型选择编码器
        if "gpt" in text.lower():
            encoding = tiktoken.get_encoding("cl100k_base")
        else:
            # 其他模型使用近似算法
            encoding = tiktoken.get_encoding("cl100k_base")
        
        return len(encoding.encode(text))
    
    def _get_model_pricing(self, model_id):
        """获取模型定价信息"""
        # 从配置或API获取实时价格
        pricing_config = {
            "gpt-4": {
                "input_price_per_1k": 0.03,
                "output_price_per_1k": 0.06
            },
            "gpt-3.5-turbo": {
                "input_price_per_1k": 0.0015,
                "output_price_per_1k": 0.002
            },
            "llama-70b": {
                "input_price_per_1k": 0.0008,
                "output_price_per_1k": 0.0008
            }
        }
        
        return pricing_config.get(model_id, {
            "input_price_per_1k": 0.001,
            "output_price_per_1k": 0.001
        })
```

#### 2.1.3 实时成本看板
```yaml
看板指标:
  实时指标(分钟级):
    - 当前QPS与成本/分钟
    - 各模型调用分布
    - 成本Top10用户/项目
    - 异常成本告警
  
  小时级指标:
    - 成本趋势图
    - 模型使用效率
    - 地域成本分布
    - 项目成本排行
  
  日报指标:
    - 总成本与预算对比
    - 成本优化建议
    - 异常用户分析
    - ROI分析报告

技术实现:
  前端展示:
    - React + ECharts实时图表
    - WebSocket推送实时数据
    - 多维度筛选与钻取
  
  后端API:
    - RESTful API提供历史数据
    - GraphQL支持复杂查询
    - 缓存层加速查询响应
  
  数据源:
    - Redis: 实时指标(<1小时)
    - ClickHouse: 历史数据(>1小时)
    - PostgreSQL: 聚合报表
```

### 2.2 智能降本策略

#### 2.2.1 语义缓存系统
```python
import redis
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

class SemanticCache:
    """
    语义缓存系统 - 相似Query直接返回缓存结果
    """
    def __init__(self, redis_client, similarity_threshold=0.95):
        self.redis = redis_client
        self.similarity_threshold = similarity_threshold
        self.embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
        self.cache_ttl = 3600 * 24  # 24小时过期
    
    def get_cached_response(self, query, model_id, user_context=None):
        """
        查询缓存响应
        """
        # 1. 生成Query向量
        query_embedding = self.embedding_model.encode([query])[0]
        
        # 2. 构建缓存键
        cache_key = f"semantic_cache:{model_id}"
        
        # 3. 获取所有缓存条目
        cached_entries = self.redis.hgetall(cache_key)
        
        if not cached_entries:
            return None
        
        # 4. 计算相似度
        best_match = None
        best_similarity = 0
        
        for entry_key, entry_data in cached_entries.items():
            entry = json.loads(entry_data)
            cached_embedding = np.array(entry["embedding"])
            
            # 计算余弦相似度
            similarity = cosine_similarity(
                [query_embedding], 
                [cached_embedding]
            )[0][0]
            
            if similarity > best_similarity:
                best_similarity = similarity
                best_match = entry
        
        # 5. 检查是否超过阈值
        if best_similarity >= self.similarity_threshold:
            # 更新访问统计
            self._update_cache_stats(best_match["cache_id"])
            
            return {
                "response": best_match["response"],
                "similarity": best_similarity,
                "cache_hit": True,
                "cost_saved": best_match["original_cost"]
            }
        
        return None
    
    def cache_response(self, query, response, model_id, cost, user_context=None):
        """
        缓存响应结果
        """
        # 1. 生成Query向量
        query_embedding = self.embedding_model.encode([query])[0]
        
        # 2. 生成缓存ID
        cache_id = f"{model_id}_{hash(query)}_{int(time.time())}"
        
        # 3. 构建缓存条目
        cache_entry = {
            "cache_id": cache_id,
            "query": query,
            "response": response,
            "model_id": model_id,
            "embedding": query_embedding.tolist(),
            "original_cost": cost,
            "timestamp": time.time(),
            "user_context": user_context,
            "access_count": 0
        }
        
        # 4. 存储到Redis
        cache_key = f"semantic_cache:{model_id}"
        self.redis.hset(
            cache_key, 
            cache_id, 
            json.dumps(cache_entry)
        )
        self.redis.expire(cache_key, self.cache_ttl)
        
        # 5. 更新缓存统计
        self._update_cache_metrics(model_id, cost)
    
    def _update_cache_stats(self, cache_id):
        """更新缓存访问统计"""
        stats_key = f"cache_stats:{cache_id}"
        self.redis.incr(stats_key)
        self.redis.expire(stats_key, self.cache_ttl)
    
    def _update_cache_metrics(self, model_id, cost):
        """更新缓存指标"""
        metrics_key = f"cache_metrics:{model_id}"
        self.redis.hincrbyfloat(metrics_key, "total_cost_saved", cost)
        self.redis.hincrby(metrics_key, "cache_entries", 1)
        self.redis.expire(metrics_key, self.cache_ttl)
    
    def get_cache_effectiveness(self, model_id):
        """获取缓存效果统计"""
        metrics_key = f"cache_metrics:{model_id}"
        metrics = self.redis.hgetall(metrics_key)
        
        if not metrics:
            return {"hit_rate": 0, "cost_saved": 0, "entries": 0}
        
        return {
            "hit_rate": float(metrics.get(b"hit_rate", 0)),
            "cost_saved": float(metrics.get(b"total_cost_saved", 0)),
            "entries": int(metrics.get(b"cache_entries", 0))
        }
```

#### 2.2.2 Prompt自动压缩
```python
class PromptCompressor:
    """
    Prompt自动压缩 - 移除冗余信息,保留关键上下文
    """
    def __init__(self):
        self.compression_strategies = [
            "remove_redundant_whitespace",
            "compress_repeated_content", 
            "summarize_long_context",
            "remove_irrelevant_history"
        ]
    
    def compress_prompt(self, prompt, target_compression_ratio=0.7):
        """
        压缩Prompt,保持语义完整性
        """
        original_tokens = self._count_tokens(prompt)
        target_tokens = int(original_tokens * target_compression_ratio)
        
        if original_tokens <= target_tokens:
            return prompt, 1.0
        
        # 1. 移除冗余空白
        compressed = self._remove_redundant_whitespace(prompt)
        
        # 2. 压缩重复内容
        compressed = self._compress_repeated_content(compressed)
        
        # 3. 摘要长上下文
        if self._count_tokens(compressed) > target_tokens:
            compressed = self._summarize_long_context(compressed, target_tokens)
        
        # 4. 移除无关历史
        if self._count_tokens(compressed) > target_tokens:
            compressed = self._remove_irrelevant_history(compressed, target_tokens)
        
        compression_ratio = self._count_tokens(compressed) / original_tokens
        
        return compressed, compression_ratio
    
    def _remove_redundant_whitespace(self, text):
        """移除冗余空白字符"""
        import re
        # 移除多余空格和换行
        text = re.sub(r'\s+', ' ', text)
        # 移除首尾空白
        text = text.strip()
        return text
    
    def _compress_repeated_content(self, text):
        """压缩重复内容"""
        # 识别重复的句子或段落
        sentences = text.split('. ')
        unique_sentences = []
        seen = set()
        
        for sentence in sentences:
            # 简单的重复检测(可以改进为语义相似度)
            sentence_hash = hash(sentence.lower().strip())
            if sentence_hash not in seen:
                unique_sentences.append(sentence)
                seen.add(sentence_hash)
        
        return '. '.join(unique_sentences)
    
    def _summarize_long_context(self, text, target_tokens):
        """摘要长上下文"""
        # 使用轻量级摘要模型
        from transformers import pipeline
        
        summarizer = pipeline("summarization", 
                            model="facebook/bart-large-cnn",
                            max_length=target_tokens * 2,  # 估算
                            min_length=target_tokens // 2)
        
        # 分段摘要(避免超长输入)
        chunks = self._split_text(text, 1000)  # 1000字符一段
        summaries = []
        
        for chunk in chunks:
            if len(chunk) > 100:  # 只摘要足够长的段落
                summary = summarizer(chunk, max_length=100, min_length=20)
                summaries.append(summary[0]['summary_text'])
            else:
                summaries.append(chunk)
        
        return ' '.join(summaries)
    
    def _remove_irrelevant_history(self, text, target_tokens):
        """移除无关历史对话"""
        # 解析对话历史
        conversation_parts = self._parse_conversation(text)
        
        # 保留最近的对话和关键信息
        relevant_parts = []
        current_tokens = 0
        
        # 从最新开始保留
        for part in reversed(conversation_parts):
            part_tokens = self._count_tokens(part)
            if current_tokens + part_tokens <= target_tokens:
                relevant_parts.insert(0, part)
                current_tokens += part_tokens
            else:
                break
        
        return ' '.join(relevant_parts)
    
    def _split_text(self, text, chunk_size):
        """分割文本为块"""
        words = text.split()
        chunks = []
        current_chunk = []
        current_size = 0
        
        for word in words:
            if current_size + len(word) > chunk_size and current_chunk:
                chunks.append(' '.join(current_chunk))
                current_chunk = [word]
                current_size = len(word)
            else:
                current_chunk.append(word)
                current_size += len(word) + 1
        
        if current_chunk:
            chunks.append(' '.join(current_chunk))
        
        return chunks
```

#### 2.2.3 模型自动降级
```python
class ModelDowngradeManager:
    """
    模型自动降级 - 非关键场景使用小模型
    """
    def __init__(self):
        self.downgrade_rules = {
            "simple_qa": {
                "condition": lambda query: self._is_simple_question(query),
                "target_model": "llama-13b",
                "cost_reduction": 0.7
            },
            "low_priority_user": {
                "condition": lambda user: user.get("tier") == "free",
                "target_model": "llama-7b", 
                "cost_reduction": 0.8
            },
            "high_load_period": {
                "condition": lambda: self._is_high_load_period(),
                "target_model": "gpt-3.5-turbo",
                "cost_reduction": 0.5
            }
        }
    
    def should_downgrade(self, query, user_profile, current_model):
        """
        判断是否应该降级模型
        """
        for rule_name, rule in self.downgrade_rules.items():
            if rule["condition"](query, user_profile):
                return {
                    "should_downgrade": True,
                    "target_model": rule["target_model"],
                    "cost_reduction": rule["cost_reduction"],
                    "reason": rule_name
                }
        
        return {"should_downgrade": False}
    
    def _is_simple_question(self, query):
        """判断是否为简单问题"""
        simple_indicators = [
            "what is", "who is", "when is", "where is",
            "how many", "how much", "yes or no"
        ]
        
        query_lower = query.lower()
        return any(indicator in query_lower for indicator in simple_indicators)
    
    def _is_high_load_period(self):
        """判断是否为高负载时段"""
        import datetime
        current_hour = datetime.datetime.now().hour
        
        # 工作时间(9-18点)为高负载
        return 9 <= current_hour <= 18
```

#### 2.2.4 批处理优化
```python
class BatchOptimizer:
    """
    批处理优化 - 离线任务合并批次降低成本
    """
    def __init__(self):
        self.batch_queue = []
        self.batch_size = 10
        self.batch_timeout = 30  # 30秒超时
    
    def add_to_batch(self, request):
        """
        添加请求到批处理队列
        """
        self.batch_queue.append({
            "request": request,
            "timestamp": time.time(),
            "processed": False
        })
        
        # 检查是否可以处理批次
        if len(self.batch_queue) >= self.batch_size:
            self._process_batch()
        elif self._should_timeout_batch():
            self._process_batch()
    
    def _process_batch(self):
        """
        处理批次请求
        """
        if not self.batch_queue:
            return
        
        # 按模型分组
        model_groups = {}
        for item in self.batch_queue:
            model_id = item["request"]["model_id"]
            if model_id not in model_groups:
                model_groups[model_id] = []
            model_groups[model_id].append(item)
        
        # 并行处理各模型批次
        for model_id, items in model_groups.items():
            self._process_model_batch(model_id, items)
        
        # 清空队列
        self.batch_queue = []
    
    def _process_model_batch(self, model_id, items):
        """
        处理单个模型的批次
        """
        # 构建批量请求
        batch_inputs = [item["request"]["input"] for item in items]
        
        # 调用模型API(支持批处理的模型)
        batch_response = self._call_model_batch(model_id, batch_inputs)
        
        # 分发结果
        for i, item in enumerate(items):
            item["response"] = batch_response[i]
            item["processed"] = True
            item["cost"] = self._calculate_batch_cost(model_id, len(batch_inputs))
    
    def _call_model_batch(self, model_id, inputs):
        """
        调用模型批处理API
        """
        # 这里调用实际的模型API
        # 不同模型有不同的批处理接口
        pass
    
    def _calculate_batch_cost(self, model_id, batch_size):
        """
        计算批处理成本(通常有折扣)
        """
        base_cost = self._get_model_cost(model_id)
        batch_discount = min(0.3, batch_size * 0.02)  # 最多30%折扣
        return base_cost * (1 - batch_discount)
```

### 2.3 成本预测与优化建议

#### 2.3.1 成本预测模型
```python
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
import numpy as np

class CostPredictor:
    """
    成本预测模型 - 基于历史数据预测未来成本
    """
    def __init__(self):
        self.models = {
            "hourly": RandomForestRegressor(n_estimators=100),
            "daily": RandomForestRegressor(n_estimators=100),
            "weekly": RandomForestRegressor(n_estimators=100)
        }
        self.scalers = {
            "hourly": StandardScaler(),
            "daily": StandardScaler(),
            "weekly": StandardScaler()
        }
        self.feature_columns = [
            "hour", "day_of_week", "month", "qps", "avg_tokens_per_request",
            "model_distribution_gpt4", "model_distribution_gpt35", 
            "model_distribution_llama", "user_tier_vip_ratio"
        ]
    
    def train_models(self, historical_data):
        """
        训练预测模型
        """
        for period in ["hourly", "daily", "weekly"]:
            # 准备训练数据
            X, y = self._prepare_training_data(historical_data, period)
            
            if len(X) < 100:  # 数据不足
                continue
            
            # 特征标准化
            X_scaled = self.scalers[period].fit_transform(X)
            
            # 训练模型
            self.models[period].fit(X_scaled, y)
    
    def predict_cost(self, period="daily", days_ahead=7):
        """
        预测未来成本
        """
        if period not in self.models:
            raise ValueError(f"Unsupported period: {period}")
        
        predictions = []
        current_time = datetime.datetime.now()
        
        for i in range(days_ahead):
            # 构建特征向量
            features = self._build_features(current_time + timedelta(days=i))
            features_scaled = self.scalers[period].transform([features])
            
            # 预测
            prediction = self.models[period].predict(features_scaled)[0]
            predictions.append({
                "date": current_time + timedelta(days=i),
                "predicted_cost": max(0, prediction),  # 确保非负
                "confidence": self._calculate_confidence(period, features)
            })
        
        return predictions
    
    def _prepare_training_data(self, data, period):
        """
        准备训练数据
        """
        # 按周期聚合数据
        if period == "hourly":
            grouped = data.groupby(data['timestamp'].dt.floor('H'))
        elif period == "daily":
            grouped = data.groupby(data['timestamp'].dt.date)
        else:  # weekly
            grouped = data.groupby(data['timestamp'].dt.to_period('W'))
        
        X = []
        y = []
        
        for period_key, group in grouped:
            # 提取特征
            features = self._extract_period_features(group, period_key)
            X.append(features)
            
            # 目标变量(总成本)
            y.append(group['cost'].sum())
        
        return np.array(X), np.array(y)
    
    def _extract_period_features(self, group, period_key):
        """
        提取周期特征
        """
        features = []
        
        # 时间特征
        if isinstance(period_key, datetime.datetime):
            features.extend([
                period_key.hour,
                period_key.weekday(),
                period_key.month
            ])
        else:
            features.extend([0, 0, 0])  # 占位符
        
        # 请求特征
        features.extend([
            len(group),  # QPS
            group['input_tokens'].mean(),  # 平均Token数
        ])
        
        # 模型分布特征
        model_counts = group['model_id'].value_counts()
        total_requests = len(group)
        
        features.extend([
            model_counts.get('gpt-4', 0) / total_requests,
            model_counts.get('gpt-3.5-turbo', 0) / total_requests,
            model_counts.get('llama-70b', 0) / total_requests,
        ])
        
        # 用户特征
        vip_users = group[group['user_tier'] == 'vip']['user_id'].nunique()
        total_users = group['user_id'].nunique()
        features.append(vip_users / max(total_users, 1))
        
        return features
    
    def _build_features(self, target_time):
        """
        构建预测特征
        """
        # 时间特征
        features = [
            target_time.hour,
            target_time.weekday(),
            target_time.month
        ]
        
        # 历史统计特征(需要从数据库获取)
        historical_stats = self._get_historical_stats(target_time)
        features.extend([
            historical_stats.get('avg_qps', 100),
            historical_stats.get('avg_tokens', 500),
            historical_stats.get('gpt4_ratio', 0.2),
            historical_stats.get('gpt35_ratio', 0.5),
            historical_stats.get('llama_ratio', 0.3),
            historical_stats.get('vip_ratio', 0.1)
        ])
        
        return features
    
    def _calculate_confidence(self, period, features):
        """
        计算预测置信度
        """
        # 基于历史数据相似度和模型性能
        # 简化实现
        return 0.8  # 固定置信度
```

#### 2.3.2 预算预警系统
```python
class BudgetAlertSystem:
    """
    预算预警系统 - 预算超支预警与自动限流
    """
    def __init__(self):
        self.alert_thresholds = {
            "warning": 0.8,    # 80%预算时警告
            "critical": 0.95,  # 95%预算时严重警告
            "limit": 1.0       # 100%预算时限流
        }
    
    def check_budget_status(self, user_id, project_id, period="monthly"):
        """
        检查预算状态
        """
        # 1. 获取预算配置
        budget_config = self._get_budget_config(user_id, project_id, period)
        if not budget_config:
            return {"status": "no_budget", "message": "未设置预算"}
        
        # 2. 获取当前消费
        current_spend = self._get_current_spend(user_id, project_id, period)
        
        # 3. 计算使用率
        usage_ratio = current_spend / budget_config["amount"]
        
        # 4. 判断状态
        if usage_ratio >= self.alert_thresholds["limit"]:
            status = "limit_exceeded"
            action = "block_requests"
        elif usage_ratio >= self.alert_thresholds["critical"]:
            status = "critical"
            action = "throttle_requests"
        elif usage_ratio >= self.alert_thresholds["warning"]:
            status = "warning"
            action = "send_alert"
        else:
            status = "normal"
            action = "none"
        
        return {
            "status": status,
            "usage_ratio": usage_ratio,
            "current_spend": current_spend,
            "budget_amount": budget_config["amount"],
            "remaining_budget": budget_config["amount"] - current_spend,
            "action": action,
            "alert_level": self._get_alert_level(usage_ratio)
        }
    
    def _get_alert_level(self, usage_ratio):
        """获取告警级别"""
        if usage_ratio >= 1.0:
            return "CRITICAL"
        elif usage_ratio >= 0.95:
            return "HIGH"
        elif usage_ratio >= 0.8:
            return "MEDIUM"
        else:
            return "LOW"
    
    def execute_budget_action(self, user_id, project_id, action):
        """
        执行预算动作
        """
        if action == "block_requests":
            # 完全阻止请求
            self._block_user_requests(user_id, project_id)
            self._send_budget_alert(user_id, project_id, "预算已用完,请求被阻止")
            
        elif action == "throttle_requests":
            # 限流请求
            self._throttle_user_requests(user_id, project_id, rate_limit=10)  # 10 QPS
            self._send_budget_alert(user_id, project_id, "预算即将用完,请求被限流")
            
        elif action == "send_alert":
            # 发送告警
            self._send_budget_alert(user_id, project_id, "预算使用率超过80%")
    
    def _block_user_requests(self, user_id, project_id):
        """阻止用户请求"""
        # 在Redis中设置阻止标记
        redis_client.setex(
            f"budget_block:{user_id}:{project_id}",
            3600,  # 1小时过期
            "blocked"
        )
    
    def _throttle_user_requests(self, user_id, project_id, rate_limit):
        """限流用户请求"""
        # 设置限流配置
        redis_client.setex(
            f"budget_throttle:{user_id}:{project_id}",
            3600,  # 1小时过期
            rate_limit
        )
    
    def _send_budget_alert(self, user_id, project_id, message):
        """发送预算告警"""
        # 发送邮件/短信/钉钉通知
        alert_data = {
            "user_id": user_id,
            "project_id": project_id,
            "message": message,
            "timestamp": datetime.datetime.now().isoformat()
        }
        
        # 发送到消息队列
        kafka_producer.send("budget_alerts", alert_data)
```

#### 2.3.3 成本优化建议引擎
```python
class CostOptimizationAdvisor:
    """
    成本优化建议引擎
    """
    def __init__(self):
        self.optimization_rules = [
            self._analyze_model_usage,
            self._analyze_cache_efficiency,
            self._analyze_prompt_optimization,
            self._analyze_batch_opportunities,
            self._analyze_time_distribution
        ]
    
    def generate_optimization_suggestions(self, user_id, project_id, period="monthly"):
        """
        生成优化建议
        """
        # 1. 获取用户数据
        usage_data = self._get_usage_data(user_id, project_id, period)
        cost_data = self._get_cost_data(user_id, project_id, period)
        
        # 2. 分析各维度
        suggestions = []
        for rule in self.optimization_rules:
            suggestion = rule(usage_data, cost_data)
            if suggestion:
                suggestions.append(suggestion)
        
        # 3. 计算潜在节省
        total_potential_savings = sum(s["potential_savings"] for s in suggestions)
        
        # 4. 按优先级排序
        suggestions.sort(key=lambda x: x["priority"], reverse=True)
        
        return {
            "user_id": user_id,
            "project_id": project_id,
            "period": period,
            "current_cost": cost_data["total_cost"],
            "potential_savings": total_potential_savings,
            "savings_percentage": total_potential_savings / cost_data["total_cost"] * 100,
            "suggestions": suggestions
        }
    
    def _analyze_model_usage(self, usage_data, cost_data):
        """
        分析模型使用情况
        """
        model_costs = cost_data["model_breakdown"]
        
        # 找出高成本模型使用情况
        expensive_models = [m for m in model_costs if model_costs[m] > cost_data["total_cost"] * 0.3]
        
        if expensive_models:
            # 检查是否有简单任务使用了昂贵模型
            simple_tasks_with_expensive_models = self._find_simple_tasks_with_expensive_models(usage_data)
            
            if simple_tasks_with_expensive_models:
                return {
                    "type": "model_downgrade",
                    "title": "模型降级建议",
                    "description": f"发现{len(simple_tasks_with_expensive_models)}个简单任务使用了昂贵模型",
                    "details": {
                        "expensive_models": expensive_models,
                        "simple_tasks": simple_tasks_with_expensive_models[:5]  # 显示前5个
                    },
                    "recommendation": "为简单任务配置自动降级到低成本模型",
                    "potential_savings": cost_data["total_cost"] * 0.2,  # 预估节省20%
                    "priority": 8,
                    "implementation_effort": "medium"
                }
        
        return None
    
    def _analyze_cache_efficiency(self, usage_data, cost_data):
        """
        分析缓存效率
        """
        cache_stats = usage_data.get("cache_stats", {})
        cache_hit_rate = cache_stats.get("hit_rate", 0)
        
        if cache_hit_rate < 0.3:  # 缓存命中率低于30%
            return {
                "type": "cache_optimization",
                "title": "缓存优化建议",
                "description": f"当前缓存命中率仅{cache_hit_rate:.1%},有较大优化空间",
                "details": {
                    "current_hit_rate": cache_hit_rate,
                    "recommended_hit_rate": 0.6,
                    "cache_entries": cache_stats.get("entries", 0)
                },
                "recommendation": "优化缓存策略,提高相似度阈值或增加缓存容量",
                "potential_savings": cost_data["total_cost"] * (0.6 - cache_hit_rate) * 0.8,
                "priority": 7,
                "implementation_effort": "low"
            }
        
        return None
    
    def _analyze_prompt_optimization(self, usage_data, cost_data):
        """
        分析Prompt优化机会
        """
        avg_tokens = usage_data.get("avg_tokens_per_request", 0)
        
        if avg_tokens > 2000:  # 平均Token数过高
            return {
                "type": "prompt_compression",
                "title": "Prompt压缩建议",
                "description": f"平均每次请求{avg_tokens}个Token,存在压缩空间",
                "details": {
                    "current_avg_tokens": avg_tokens,
                    "recommended_avg_tokens": 1500,
                    "compression_ratio": 0.7
                },
                "recommendation": "启用Prompt自动压缩,移除冗余信息",
                "potential_savings": cost_data["total_cost"] * 0.15,  # 预估节省15%
                "priority": 6,
                "implementation_effort": "low"
            }
        
        return None
    
    def _analyze_batch_opportunities(self, usage_data, cost_data):
        """
        分析批处理机会
        """
        batch_eligible_requests = usage_data.get("batch_eligible_requests", 0)
        total_requests = usage_data.get("total_requests", 1)
        batch_ratio = batch_eligible_requests / total_requests
        
        if batch_ratio > 0.2:  # 20%以上的请求可以批处理
            return {
                "type": "batch_processing",
                "title": "批处理优化建议",
                "description": f"{batch_ratio:.1%}的请求适合批处理,可显著降低成本",
                "details": {
                    "batch_eligible_ratio": batch_ratio,
                    "batch_eligible_count": batch_eligible_requests,
                    "estimated_batch_discount": 0.3
                },
                "recommendation": "实现批处理队列,将相似请求合并处理",
                "potential_savings": cost_data["total_cost"] * batch_ratio * 0.3,
                "priority": 5,
                "implementation_effort": "high"
            }
        
        return None
    
    def _analyze_time_distribution(self, usage_data, cost_data):
        """
        分析时间分布
        """
        peak_hour_cost = cost_data.get("peak_hour_cost", 0)
        off_peak_cost = cost_data.get("off_peak_cost", 0)
        
        if peak_hour_cost > off_peak_cost * 2:  # 高峰时段成本是低峰的2倍以上
            return {
                "type": "time_distribution",
                "title": "时间分布优化建议",
                "description": "高峰时段成本显著高于低峰时段,建议错峰使用",
                "details": {
                    "peak_hour_cost": peak_hour_cost,
                    "off_peak_cost": off_peak_cost,
                    "cost_ratio": peak_hour_cost / off_peak_cost
                },
                "recommendation": "将非紧急任务安排在低峰时段执行",
                "potential_savings": (peak_hour_cost - off_peak_cost) * 0.3,
                "priority": 4,
                "implementation_effort": "medium"
            }
        
        return None
```

## 三、系统架构

### 3.1 整体架构
```
┌─────────────────────────────────────────────────────────┐
│                    成本管控系统                           │
├─────────────────────────────────────────────────────────┤
│  展示层  │ 成本看板 │ 预算管理 │ 优化建议 │ 告警中心    │
├─────────────────────────────────────────────────────────┤
│  服务层  │ 成本计算 │ 预测引擎 │ 优化引擎 │ 告警引擎    │
├─────────────────────────────────────────────────────────┤
│  数据层  │ Redis    │ ClickHouse │ PostgreSQL │ Kafka  │
├─────────────────────────────────────────────────────────┤
│  采集层  │ 计量Agent │ 缓存系统 │ 降本策略 │ 批处理     │
└─────────────────────────────────────────────────────────┘
```

### 3.2 数据流设计

#### 成本计量流程
```yaml
1. 请求处理:
   - 用户发起请求
   - 路由到推理服务
   - 计量Agent记录Token数

2. 成本计算:
   - 查询模型定价
   - 计算Input/Output成本
   - 多维度归因

3. 数据存储:
   - 实时数据 → Redis
   - 历史数据 → ClickHouse
   - 聚合数据 → PostgreSQL

4. 告警检查:
   - 检查预算状态
   - 触发告警/限流
   - 发送通知

5. 优化分析:
   - 定期分析使用模式
   - 生成优化建议
   - 更新降本策略
```

### 3.3 核心组件实现

#### 3.3.1 成本计量Agent
```python
import time
import json
import threading
from collections import defaultdict

class CostMeteringAgent:
    """
    部署在每个推理节点的成本计量Agent
    """
    def __init__(self, redis_client, instance_id):
        self.redis = redis_client
        self.instance_id = instance_id
        self.metrics_buffer = []
        self.buffer_lock = threading.Lock()
        
        # 启动上报线程
        self.report_thread = threading.Thread(target=self._report_loop, daemon=True)
        self.report_thread.start()
    
    def record_request(self, request_data):
        """
        记录请求成本
        """
        # 计算Token数
        input_tokens = self._count_tokens(request_data["input"])
        output_tokens = self._count_tokens(request_data["output"])
        
        # 计算成本
        model_pricing = self._get_model_pricing(request_data["model_id"])
        input_cost = input_tokens * model_pricing["input_price_per_1k"] / 1000
        output_cost = output_tokens * model_pricing["output_price_per_1k"] / 1000
        total_cost = input_cost + output_cost
        
        # 构建计量记录
        metering_record = {
            "request_id": request_data["request_id"],
            "timestamp": time.time(),
            "instance_id": self.instance_id,
            "model_id": request_data["model_id"],
            "user_id": request_data["user_id"],
            "project_id": request_data.get("project_id"),
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "input_cost": input_cost,
            "output_cost": output_cost,
            "total_cost": total_cost,
            "latency": request_data.get("latency", 0)
        }
        
        # 添加到缓冲区
        with self.buffer_lock:
            self.metrics_buffer.append(metering_record)
    
    def _report_loop(self):
        """
        定期上报数据
        """
        while True:
            time.sleep(10)  # 每10秒上报一次
            
            with self.buffer_lock:
                if self.metrics_buffer:
                    # 批量上报
                    self._batch_report(self.metrics_buffer.copy())
                    self.metrics_buffer.clear()
    
    def _batch_report(self, records):
        """
        批量上报数据
        """
        # 发送到Kafka
        for record in records:
            self.redis.lpush("cost_metering_queue", json.dumps(record))
        
        # 更新实时统计
        self._update_realtime_stats(records)
    
    def _update_realtime_stats(self, records):
        """
        更新实时统计
        """
        # 按用户聚合
        user_stats = defaultdict(lambda: {"cost": 0, "requests": 0})
        for record in records:
            user_id = record["user_id"]
            user_stats[user_id]["cost"] += record["total_cost"]
            user_stats[user_id]["requests"] += 1
        
        # 更新Redis
        for user_id, stats in user_stats.items():
            self.redis.hincrbyfloat(f"user_cost:{user_id}", "hourly_cost", stats["cost"])
            self.redis.hincrby(f"user_cost:{user_id}", "hourly_requests", stats["requests"])
            self.redis.expire(f"user_cost:{user_id}", 3600)  # 1小时过期
```

#### 3.3.2 成本计算引擎
```python
class CostCalculationEngine:
    """
    成本计算引擎 - 处理批量成本计算和归因
    """
    def __init__(self, kafka_consumer, clickhouse_client, postgres_client):
        self.kafka_consumer = kafka_consumer
        self.clickhouse_client = clickhouse_client
        self.postgres_client = postgres_client
        self.model_pricing_cache = {}
    
    def start_processing(self):
        """
        启动成本计算处理
        """
        while True:
            # 从Kafka消费数据
            messages = self.kafka_consumer.poll(timeout_ms=1000)
            
            for topic_partition, records in messages.items():
                for record in records:
                    self._process_metering_record(record.value)
    
    def _process_metering_record(self, record_data):
        """
        处理计量记录
        """
        record = json.loads(record_data)
        
        # 1. 成本归因
        attribution = self._calculate_attribution(record)
        
        # 2. 存储到ClickHouse
        self._store_to_clickhouse(attribution)
        
        # 3. 更新实时聚合
        self._update_realtime_aggregation(attribution)
        
        # 4. 检查预算状态
        self._check_budget_status(attribution)
    
    def _calculate_attribution(self, record):
        """
        计算成本归因
        """
        # 获取用户/项目信息
        user_info = self._get_user_info(record["user_id"])
        project_info = self._get_project_info(record.get("project_id"))
        
        # 构建归因记录
        attribution = {
            **record,
            "tenant_id": user_info.get("tenant_id"),
            "user_tier": user_info.get("tier", "free"),
            "project_name": project_info.get("name"),
            "region": user_info.get("region", "default"),
            "cost_center": project_info.get("cost_center"),
            "business_unit": project_info.get("business_unit")
        }
        
        return attribution
    
    def _store_to_clickhouse(self, attribution):
        """
        存储到ClickHouse
        """
        query = """
        INSERT INTO cost_metering (
            request_id, timestamp, instance_id, model_id, user_id, project_id,
            tenant_id, user_tier, region, cost_center, business_unit,
            input_tokens, output_tokens, input_cost, output_cost, total_cost, latency
        ) VALUES (
            %(request_id)s, %(timestamp)s, %(instance_id)s, %(model_id)s, %(user_id)s, %(project_id)s,
            %(tenant_id)s, %(user_tier)s, %(region)s, %(cost_center)s, %(business_unit)s,
            %(input_tokens)s, %(output_tokens)s, %(input_cost)s, %(output_cost)s, %(total_cost)s, %(latency)s
        )
        """
        
        self.clickhouse_client.execute(query, attribution)
    
    def _update_realtime_aggregation(self, attribution):
        """
        更新实时聚合数据
        """
        # 更新用户成本
        user_key = f"user_cost:{attribution['user_id']}"
        self.redis.hincrbyfloat(user_key, "daily_cost", attribution["total_cost"])
        self.redis.hincrby(user_key, "daily_requests", 1)
        self.redis.expire(user_key, 86400)  # 24小时过期
        
        # 更新项目成本
        if attribution.get("project_id"):
            project_key = f"project_cost:{attribution['project_id']}"
            self.redis.hincrbyfloat(project_key, "daily_cost", attribution["total_cost"])
            self.redis.hincrby(project_key, "daily_requests", 1)
            self.redis.expire(project_key, 86400)
        
        # 更新模型成本
        model_key = f"model_cost:{attribution['model_id']}"
        self.redis.hincrbyfloat(model_key, "daily_cost", attribution["total_cost"])
        self.redis.hincrby(model_key, "daily_requests", 1)
        self.redis.expire(model_key, 86400)
```

## 四、关键指标与监控

### 4.1 成本管控指标
```yaml
计量准确性:
  - Token计数准确率: >99.9%
  - 成本计算准确率: >99.95%
  - 数据丢失率: <0.01%

实时性指标:
  - 成本数据延迟: <30秒
  - 告警响应时间: <1分钟
  - 看板更新频率: 1分钟

优化效果:
  - 语义缓存命中率: >60%
  - 成本降低比例: 30-40%
  - 预算超支率: <5%
```

### 4.2 告警规则
```yaml
成本异常告警:
  - 单小时成本突增: >3倍历史均值
  - 单用户成本异常: >10倍正常水平
  - 模型成本异常: 某模型成本占比>80%

预算告警:
  - 预算使用率: 80%/95%/100%
  - 预算超支: 超过预算1.1倍
  - 预算即将用完: 剩余预算<1天用量

系统告警:
  - 计量数据丢失: >1%
  - 计算引擎延迟: >5分钟
  - 存储空间不足: >90%
```

## 五、部署方案

### 5.1 组件部署
```yaml
成本计量Agent:
  - 部署: DaemonSet(每个推理节点)
  - 资源: 0.5C1G per node
  - 依赖: Redis集群

成本计算引擎:
  - 部署: Kubernetes Deployment
  - 副本数: 2-3个
  - 资源: 4C8G per pod
  - 依赖: Kafka + ClickHouse + PostgreSQL

缓存系统:
  - 部署: 独立Redis集群
  - 配置: 主从+哨兵模式
  - 存储: 100GB+ SSD

预测引擎:
  - 部署: 定时任务(CronJob)
  - 频率: 每小时执行
  - 资源: 2C4G
```

### 5.2 数据存储
```yaml
Redis集群:
  - 用途: 实时数据缓存
  - 配置: 3主3从
  - 存储: 50GB
  - TTL: 1-24小时

ClickHouse:
  - 用途: 历史成本数据
  - 配置: 3节点集群
  - 存储: 1TB+
  - 保留: 2年

PostgreSQL:
  - 用途: 聚合报表数据
  - 配置: 主从模式
  - 存储: 100GB
  - 备份: 每日备份
```

## 六、预期收益

```yaml
成本收益:
  - 推理成本降低: 35-40%
  - 资源浪费减少: 50%
  - 预算控制精度: 提升到95%

运营效率:
  - 成本透明度: 100%
  - 异常发现时间: 从小时级到分钟级
  - 优化建议自动化: 90%

用户体验:
  - 成本可视化: 实时看板
  - 预算预警: 提前7天预警
  - 优化建议: 个性化推荐
```

