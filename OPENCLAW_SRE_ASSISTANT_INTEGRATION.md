## OpenClaw 作为“超级 SRE 助理”的集成方案

- **创建日期**: 2026-03-09
- **目标读者**: 平台后端 / SRE / 架构负责人

---

## 1. 目标与边界

- **目标**: 将 OpenClaw 作为“超级聪明的 SRE 助理”集成到现有 LLMOps / 运维管理平台中，让其可以通过自然语言执行标准运维 SOP，同时不削弱 OpenClaw 在其他场景的能力。
- **硬边界**: 所有对生产环境有副作用的操作（重启、扩缩容、静默告警、修改配置等）必须经过现有 Go 运维平台的 API 网关和 RBAC / 审计，不允许 OpenClaw 直接访问数据库、Kubernetes、主机或内部消息总线。
- **软边界**: OpenClaw 可以使用其全部通用能力（多通道 IM、浏览器、Canvas、个人助手技能等），但运维相关访问只能通过一组受控的 `ops-*` API 与 Go 后端交互。

---

## 2. 现有架构简要回顾

- **基础设施**
  - PostgreSQL (`postgres` 服务)
  - Redis (`redis` 服务)
  - Consul (`consul` 服务) 作为服务发现 / 配置中心
  - MinIO (`minio` 服务) 作为对象存储
  - Prometheus + Grafana (`prometheus`、`grafana` 服务) 监控与可视化

- **业务与运维相关服务（Go）**
  - `user-service`: 用户与权限管理（`cmd/server/main.go`、`internal/...`）
  - `project-service`: 项目与资源管理
  - `cost-service`: 成本管理
  - `api-gateway`: 统一 API 网关（`auth_main.go`）
  - 共享认证模块: `shared/auth/*.go`

- **AI / 监控子系统（Python + FastAPI）**
  - `model-service`: 模型注册 / 版本管理
  - `inference-service`: 推理服务
  - `monitoring-service`: 指标聚合、异常检测、告警管理（对 Prometheus / Grafana / ES 进行抽象）

- **前端**
  - `frontend/admin-dashboard`: 管理后台
  - `frontend/user-portal`: 用户门户
  - `frontend/mobile-app`: 移动端 H5/壳

---

## 3. OpenClaw 角色与部署形态

### 3.1 角色定位

- **OpenClaw** = 多通道 AI 网关 + 插件 / Skills 平台 + 个性化助手运行时。
- **本项目运维平台** = 生产环境的权威控制平面（RBAC、审计、SOP 执行器）。
- 设计原则:
  - 将运维平台视为 OpenClaw 的一个“高价值工具集 / 应用域”；
  - 运维平台对生产资源的控制力不被 OpenClaw 削弱或绕过；
  - OpenClaw 在运维以外的能力保持完整（个人助手、其他业务场景等）。

### 3.2 部署建议

1. **OpenClaw 独立部署**
   - 在同一集群中以独立容器部署 `openclaw-gateway`，使用官方 Docker 方式。
   - 暴露内部访问地址，例如:
     - HTTP / WS: `http://openclaw-gateway:18789`
   - 通过独立配置卷管理:
     - 模型 / Providers
     - 渠道配置（Slack、Feishu、Teams 等）
     - Workspace / Profiles

2. **网络与访问控制**
   - 只允许以下服务访问 OpenClaw:
     - `api-gateway`（Go）作为主要调用方；
     - 必要时允许 `monitoring-service` 等读类服务访问。
   - 对外部世界（IM 渠道）的入站流量由 OpenClaw 自己处理，和现有 `nginx` / Web 入口解耦。

---

## 4. “双层边界”设计

### 4.1 第一层: 运维平台硬边界（Go）

- 在 `api-gateway` 或单独建立 `ops-service`，对外暴露一组 **AI 可用的运维 API**，所有生产操作必须走这些接口:
  - 示例接口（仅示意，具体路径可按现有 REST 风格设计）:
    - `GET  /ops/services/{service}/health` — 查询服务健康状态
    - `GET  /ops/services/{service}/alerts` — 查询最近告警
    - `POST /ops/services/{service}/restart` — 重启服务
    - `POST /ops/services/{service}/scale` — 扩缩容服务
    - `POST /ops/alerts/{id}/suppress` — 静默告警规则
    - `POST /ops/maintenance-windows` — 创建维护窗口
  - 这些接口内部负责:
    - **身份映射**: 将 OpenClaw 来的调用与内部 `user-service` 用户/角色绑定（通过 JWT / API Key / mTLS 等）。
    - **RBAC 控制**: 依据角色判断是否允许执行对应 SOP。
    - **审计记录**: 将操作写入审计表 / 日志（包含 operator、channel、原始自然语言指令摘要）。
    - **幂等 / 防抖**: 避免重复执行高危操作（例如 5 分钟内只能重启同一服务一次）。
    - **速率限制**: 对高危接口设置严格的 QPS / 并发限制。

### 4.2 第二层: OpenClaw 能力边界（软边界）

- 在 OpenClaw 内部，所有“运维相关”的功能，都通过一组受控的 **SRE Skills** 实现:
  - Skill 不直接访问数据库、Kubernetes、主机或消息总线。
  - Skill 只调用运维平台暴露的 `ops-*` HTTP API。
  - Skill 可以执行复杂的推理 / 决策逻辑（例如分析多个服务的指标并建议操作），但最终执行权仍由 Go 运维平台控制。

---

## 5. SRE Skill 设计（逻辑层）

### 5.1 Skill 列表（初始建议）

- **只读类（ReadOnly）**
  - `ops_get_service_health`
    - 入参: `service_name`, `env`, `time_range`
    - 行为: 调用 `/ops/services/{service}/health`，聚合 Prometheus / monitoring-service 返回，输出面向人类的总结 + 关键指标。
  - `ops_list_recent_alerts`
    - 入参: `service_name`, `env`, `severity`, `since`
    - 行为: 调用 `/ops/services/{service}/alerts`，按严重程度和频率聚合。
  - `ops_get_model_status`
    - 入参: `project_id`, `model_id`, `env`
    - 行为: 调用 `model-service` via `api-gateway`，返回模型版本、部署状态、最近失败率等。
  - `ops_get_inference_load`
    - 入参: `env`, `model_id` (可选)
    - 行为: 查询 `inference-service` + Prometheus，给出当前 QPS、延迟、错误率。

- **变更类（Change）**
  - `ops_restart_service`
    - 入参: `service_name`, `env`, `reason`, `operator_id`, `ticket_id` (可选)
    - 行为: 调用 `POST /ops/services/{service}/restart`，返回操作结果与追踪 ID。
  - `ops_scale_service`
    - 入参: `service_name`, `env`, `target_replicas` 或 `scale_delta`, `reason`, `operator_id`
    - 行为: 调用 `POST /ops/services/{service}/scale`。
  - `ops_suppress_alert_rule`
    - 入参: `rule_id`, `env`, `duration`, `reason`, `operator_id`
    - 行为: 调用 `POST /ops/alerts/{id}/suppress`。
  - `ops_create_maintenance_window`
    - 入参: `services`, `env`, `start_at`, `end_at`, `reason`, `operator_id`
    - 行为: 调用 `POST /ops/maintenance-windows`，用于大规模变更前创建窗口。

### 5.2 Skill 安全分级

- 所有 Skills 带上统一元数据:
  - `operator_id`: 绑定至 `user-service` 中的用户 ID。
  - `channel`: 如 `slack`, `feishu`, `web_admin`, `web_user_portal`。
  - `risk_level`: `read_only` / `low` / `medium` / `high`。
- 在 Go 侧根据 `risk_level` 决定是否:
  - 直接执行；
  - 需要二次确认（例如给 SRE 团队发一个 approve 链接）；
  - 需要已有工单 / 变更单号（`ticket_id`）。

---

## 6. 前端与用户体验集成

### 6.1 管理后台（admin-dashboard）

- 在 `admin-dashboard` 中增加“智能 SRE 助理”入口:
  - 嵌入一个 Chat 面板，与现有 UI 风格一致。
  - Chat 前端只与 `api-gateway` 通信，不直接连 OpenClaw。
- `api-gateway` 提供新的后端接口，例如:
  - `POST /ai/ops/chat` — 创建/继续与 OpenClaw 的会话
  - `GET  /ai/ops/stream/{session_id}` — WebSocket / SSE 流式返回
- `api-gateway` 内部客户端:
  - 使用 HTTP/WS 调用 OpenClaw Gateway（例如通过其 Agent / Session API）。
  - 附带当前登录用户的 `user_id`、`roles`、`project_id`、`env` 作为上下文注入到 OpenClaw 会话中。

### 6.2 IM / 协作通道（Slack / Feishu / Teams 等）

- 在 OpenClaw 的 channel 配置中:
  - 创建专用的 “SRE/Oncall” 机器人账号。
  - 设置 DM pairing / allowlist，确保只有 SRE/运维相关群组和人员可以直接触发高危 Skills。
- 在 Skills 内部:
  - 根据 `channel` 和 `peer` 识别是哪个团队 / 哪种场景（生产值班 / 测试环境）。
  - 为高危操作自动回发 “确认卡片”（例如包含变更摘要、影响面和确认按钮），但最终按钮点击仍回到 Go 平台对应的审批 / 提交流程。

---

## 7. 分阶段落地计划

### 阶段 1: PoC（只读、安全无副作用）

- 目标: 在不改变生产状态的前提下，让 SRE 可以通过 OpenClaw 获取运维洞察。
- 任务:
  1. 在 Go 侧（`api-gateway` 或新 `ops-service`）实现:
     - `GET /ops/services/{service}/health`
     - `GET /ops/services/{service}/alerts`
  2. 在 OpenClaw 内新增只读 Skills:
     - `ops_get_service_health`
     - `ops_list_recent_alerts`
  3. 在 `admin-dashboard` 中添加一个最小 Chat 面板，支持:
     - 查询服务当前状态
     - 查最近告警 / 指标
- 成功标准:
  - 对任意一个服务，SRE 能在 Chat 中用自然语言获取健康概览和近期主要告警。

### 阶段 2: 受控变更（小范围写操作）

- 目标: 支持有限的自动化变更（如单服务重启），在强审计和 RBAC 下运行。
- 任务:
  1. Go 侧实现:
     - `POST /ops/services/{service}/restart`
     - 统一的审计记录落地（数据库 / 日志）。
  2. OpenClaw 增加:
     - `ops_restart_service` Skill。
     - 内置提示词模板，确保每次尝试重启都会:
       - 解释缘由（根据当前告警/指标）
       - 计算潜在影响
       - 给出操作摘要
  3. 在 Chat / IM 场景中增加“确认步骤”:
     - OpenClaw 先生成操作计划——不直接执行；
     - 等 SRE 明确回复“确认执行”或点选按钮后，调用 `POST /ops/services/{service}/restart`。
- 成功标准:
  - 小规模服务在白天时段可通过助手完成安全重启，所有操作在审计系统中有完整链路。

### 阶段 3: 高级 SOP 与自动化

- 目标: 将复杂运维 SOP（故障排查、流量切换、灰度发布等）编码成多步骤 Skills。
- 任务:
  1. 为关键 SOP 建立结构化描述:
     - 步骤清单（检查什么、读哪些指标、哪一步可能需要人干预）
     - 风险等级和影响面
  2. 在 Go 平台扩展 `ops-*` API，以支持:
     - 维护窗口管理
     - 多服务批量操作
  3. 在 OpenClaw 中实现多步骤 SOP Skills:
     - 例如 `ops_handle_high_error_rate_incident`:
       - 先收集上下游服务状态
       - 生成 root-cause 假设
       - 提议操作步骤列表
       - 逐步执行已获确认的步骤。
- 成功标准:
  - 对于常见故障场景，助手能够按 SOP 自动跑完 70% 以上步骤，人类 SRE 只需关注关键决策点。

---

## 8. 风险与缓解措施

- **风险: OpenClaw prompt 注入导致错误操作**
  - 缓解:
    - 所有高危操作必须有明确 `operator_id` 和 `risk_level`，并在 Go 侧二次校验。
    - 对 `ops-*` API 加入防护，禁止“无 ticketId 的高危操作”。

- **风险: API 设计不当导致未来扩展困难**
  - 缓解:
    - `ops-*` API 以资源 + 动作风格设计，避免强绑定当前 OpenClaw 实现细节。
    - 将运维平台看作一个独立的“自动化执行器”，即便未来更换上层 AI/助手，这些 API 仍然通用。

- **风险: OpenClaw 出现性能问题影响运维效率**
  - 缓解:
    - 将运维相关的调用与非运维用途分离在不同 workspace / profile。
    - 为运维 workspace 配置更强的模型和更严格的超时 / 重试策略。

---

## 9. 总结

- 通过“**双层边界** + **受控 `ops-*` API** + **薄 Skills 壳**”的设计，可以在不削弱 OpenClaw 通用能力的前提下，将其作为“超级聪明的 SRE 助理”集成进当前运维平台。
- 运维平台继续作为唯一的生产控制平面，负责权限、审计和最终执行；OpenClaw 负责理解自然语言、编排 SOP、生成决策和操作计划。
- 该方案允许逐步、可回滚地推进：从只读洞察到有限变更，再到复杂 SOP 自动化，整个过程对现有架构侵入可控。

