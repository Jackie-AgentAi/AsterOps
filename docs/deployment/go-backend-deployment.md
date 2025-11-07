# LLMOps平台Go后端部署方案

> **文档版本**: v1.0  
> **更新日期**: 2025-01-17  
> **技术栈**: Go + Docker + Kubernetes

## 一、部署架构概述

### 1.1 部署目标
- 高可用性: 99.9%+ 服务可用性
- 高性能: 支持高并发请求处理
- 可扩展: 支持水平扩展和自动扩缩容
- 安全性: 容器隔离和网络安全
- 可观测: 完整的监控和日志体系

### 1.2 部署环境
```yaml
环境划分:
  开发环境 (dev):
    - 用途: 日常开发调试
    - 资源: 最小配置
    - 数据: 测试数据
    
  测试环境 (test):
    - 用途: 功能测试和集成测试
    - 资源: 中等配置
    - 数据: 完整测试数据集
    
  预生产环境 (staging):
    - 用途: 生产前验证
    - 资源: 与生产环境一致
    - 数据: 生产数据镜像
    
  生产环境 (production):
    - 用途: 正式服务
    - 资源: 完整配置
    - 数据: 真实生产数据
```

## 二、容器化部署

### 2.1 Docker镜像构建

#### 2.1.1 多阶段构建Dockerfile
```dockerfile
# 构建阶段
FROM golang:1.21-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装必要的包
RUN apk add --no-cache git ca-certificates tzdata

# 复制go mod文件
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main cmd/user-service/main.go

# 运行阶段
FROM alpine:latest

# 安装ca证书和时区数据
RUN apk --no-cache add ca-certificates tzdata

# 设置时区
ENV TZ=Asia/Shanghai

# 创建非root用户
RUN adduser -D -s /bin/sh appuser

# 设置工作目录
WORKDIR /app

# 从构建阶段复制二进制文件
COPY --from=builder /app/main .

# 复制配置文件
COPY --from=builder /app/configs ./configs

# 复制迁移脚本
COPY --from=builder /app/migrations ./migrations

# 更改文件所有者
RUN chown -R appuser:appuser /app

# 切换到非root用户
USER appuser

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# 启动应用
CMD ["./main"]
```

#### 2.1.2 构建脚本
```bash
#!/bin/bash
# build.sh

set -e

# 配置变量
SERVICE_NAME="user-service"
VERSION=${1:-latest}
REGISTRY="harbor.llmops.com"
NAMESPACE="llmops"

# 构建镜像
echo "Building Docker image for $SERVICE_NAME:$VERSION"
docker build -t $SERVICE_NAME:$VERSION .

# 标记镜像
docker tag $SERVICE_NAME:$VERSION $REGISTRY/$NAMESPACE/$SERVICE_NAME:$VERSION
docker tag $SERVICE_NAME:$VERSION $REGISTRY/$NAMESPACE/$SERVICE_NAME:latest

# 推送到镜像仓库
echo "Pushing image to registry"
docker push $REGISTRY/$NAMESPACE/$SERVICE_NAME:$VERSION
docker push $REGISTRY/$NAMESPACE/$SERVICE_NAME:latest

echo "Build completed successfully"
```

### 2.2 镜像优化

#### 2.2.1 镜像大小优化
```dockerfile
# 使用Alpine Linux基础镜像
FROM alpine:3.18

# 使用多阶段构建减少镜像大小
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o main cmd/user-service/main.go

# 最终镜像
FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/main /main
COPY --from=builder /app/configs /configs
EXPOSE 8080
CMD ["/main"]
```

#### 2.2.2 安全扫描
```bash
#!/bin/bash
# security-scan.sh

# 使用Trivy进行安全扫描
trivy image --severity HIGH,CRITICAL user-service:latest

# 使用Docker Scout进行安全扫描
docker scout cves user-service:latest
```

## 三、Kubernetes部署

### 3.1 命名空间配置

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: llmops-backend
  labels:
    name: llmops-backend
    environment: production
```

### 3.2 配置管理

#### 3.2.1 ConfigMap
```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-service-config
  namespace: llmops-backend
data:
  config.yaml: |
    server:
      port: 8080
      host: "0.0.0.0"
      read_timeout: 30
      write_timeout: 30
    
    database:
      host: "postgresql-service"
      port: 5432
      user: "llmops_user"
      dbname: "llmops_db"
      sslmode: "require"
    
    redis:
      host: "redis-service"
      port: 6379
      password: ""
      db: 0
    
    jwt:
      secret_key: "your-secret-key"
      access_token_ttl: "1h"
      refresh_token_ttl: "7d"
    
    log:
      level: "info"
      format: "json"
```

#### 3.2.2 Secret
```yaml
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: user-service-secret
  namespace: llmops-backend
type: Opaque
data:
  database-password: <base64-encoded-password>
  jwt-secret: <base64-encoded-jwt-secret>
  redis-password: <base64-encoded-redis-password>
```

### 3.3 服务部署

#### 3.3.1 Deployment
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: llmops-backend
  labels:
    app: user-service
    version: v1.0.0
spec:
  replicas: 3
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
        version: v1.0.0
    spec:
      containers:
      - name: user-service
        image: harbor.llmops.com/llmops/user-service:latest
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: CONFIG_PATH
          value: "/app/configs/config.yaml"
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: user-service-secret
              key: database-password
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: user-service-secret
              key: jwt-secret
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        volumeMounts:
        - name: config-volume
          mountPath: /app/configs
          readOnly: true
      volumes:
      - name: config-volume
        configMap:
          name: user-service-config
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
```

#### 3.3.2 Service
```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: llmops-backend
  labels:
    app: user-service
spec:
  selector:
    app: user-service
  ports:
  - name: http
    port: 8080
    targetPort: 8080
    protocol: TCP
  type: ClusterIP
```

#### 3.3.3 Ingress
```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: user-service-ingress
  namespace: llmops-backend
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
spec:
  tls:
  - hosts:
    - api.llmops.com
    secretName: llmops-tls
  rules:
  - host: api.llmops.com
    http:
      paths:
      - path: /api/v1/users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 8080
```

### 3.4 自动扩缩容

#### 3.4.1 HPA配置
```yaml
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: user-service-hpa
  namespace: llmops-backend
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
```

#### 3.4.2 VPA配置
```yaml
# vpa.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: user-service-vpa
  namespace: llmops-backend
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: user-service
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 1000m
        memory: 1Gi
```

## 四、CI/CD流水线

### 4.1 GitLab CI配置

#### 4.1.1 .gitlab-ci.yml
```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - security-scan
  - deploy-dev
  - deploy-test
  - deploy-staging
  - deploy-prod

variables:
  DOCKER_REGISTRY: "harbor.llmops.com"
  DOCKER_NAMESPACE: "llmops"
  SERVICE_NAME: "user-service"

# 测试阶段
test:
  stage: test
  image: golang:1.21-alpine
  before_script:
    - apk add --no-cache git
    - go mod download
  script:
    - go test -v ./...
    - go test -race -coverprofile=coverage.out ./...
    - go tool cover -html=coverage.out -o coverage.html
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    paths:
      - coverage.html
    expire_in: 1 week
  coverage: '/coverage: \d+\.\d+%/'

# 构建阶段
build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $DOCKER_REGISTRY
  script:
    - docker build -t $DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:$CI_COMMIT_SHA .
    - docker build -t $DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:latest .
    - docker push $DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:$CI_COMMIT_SHA
    - docker push $DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:latest
  only:
    - main
    - develop

# 安全扫描
security-scan:
  stage: security-scan
  image: aquasec/trivy:latest
  script:
    - trivy image --severity HIGH,CRITICAL --exit-code 1 $DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:$CI_COMMIT_SHA
  allow_failure: true

# 部署到开发环境
deploy-dev:
  stage: deploy-dev
  image: bitnami/kubectl:latest
  script:
    - kubectl config use-context dev-cluster
    - kubectl set image deployment/user-service user-service=$DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:$CI_COMMIT_SHA -n llmops-backend
    - kubectl rollout status deployment/user-service -n llmops-backend
  environment:
    name: development
    url: https://api-dev.llmops.com
  only:
    - develop

# 部署到测试环境
deploy-test:
  stage: deploy-test
  image: bitnami/kubectl:latest
  script:
    - kubectl config use-context test-cluster
    - kubectl set image deployment/user-service user-service=$DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:$CI_COMMIT_SHA -n llmops-backend
    - kubectl rollout status deployment/user-service -n llmops-backend
  environment:
    name: testing
    url: https://api-test.llmops.com
  only:
    - develop
  when: manual

# 部署到预生产环境
deploy-staging:
  stage: deploy-staging
  image: bitnami/kubectl:latest
  script:
    - kubectl config use-context staging-cluster
    - kubectl set image deployment/user-service user-service=$DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:$CI_COMMIT_SHA -n llmops-backend
    - kubectl rollout status deployment/user-service -n llmops-backend
  environment:
    name: staging
    url: https://api-staging.llmops.com
  only:
    - main
  when: manual

# 部署到生产环境
deploy-prod:
  stage: deploy-prod
  image: bitnami/kubectl:latest
  script:
    - kubectl config use-context prod-cluster
    - kubectl set image deployment/user-service user-service=$DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:$CI_COMMIT_SHA -n llmops-backend
    - kubectl rollout status deployment/user-service -n llmops-backend
  environment:
    name: production
    url: https://api.llmops.com
  only:
    - main
  when: manual
```

### 4.2 ArgoCD配置

#### 4.2.1 Application配置
```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: user-service
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://gitlab.llmops.com/llmops/user-service.git
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: llmops-backend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
```

## 五、监控和日志

### 5.1 Prometheus监控

#### 5.1.1 ServiceMonitor
```yaml
# servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: user-service-monitor
  namespace: llmops-backend
  labels:
    app: user-service
spec:
  selector:
    matchLabels:
      app: user-service
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
    scrapeTimeout: 10s
```

#### 5.1.2 告警规则
```yaml
# alert-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: user-service-alerts
  namespace: llmops-backend
spec:
  groups:
  - name: user-service
    rules:
    - alert: UserServiceDown
      expr: up{job="user-service"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "User service is down"
        description: "User service has been down for more than 1 minute"
    
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "High error rate detected"
        description: "Error rate is above 10% for 2 minutes"
    
    - alert: HighResponseTime
      expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High response time"
        description: "95th percentile response time is above 1 second"
```

### 5.2 日志收集

#### 5.2.1 Fluentd配置
```yaml
# fluentd-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: llmops-backend
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*user-service*.log
      pos_file /var/log/fluentd-user-service.log.pos
      tag user-service.*
      format json
      time_key time
      time_format %Y-%m-%dT%H:%M:%S.%NZ
    </source>
    
    <filter user-service.**>
      @type parser
      key_name log
      reserve_data true
      <parse>
        @type json
      </parse>
    </filter>
    
    <match user-service.**>
      @type elasticsearch
      host elasticsearch-service
      port 9200
      index_name user-service
      type_name _doc
      <buffer>
        @type file
        path /var/log/fluentd-buffers/user-service.buffer
        flush_mode interval
        retry_type exponential_backoff
        flush_thread_count 2
        flush_interval 5s
        retry_forever
        retry_max_interval 30
        chunk_limit_size 2M
        queue_limit_length 8
        overflow_action block
      </buffer>
    </match>
```

## 六、数据库迁移

### 6.1 迁移脚本

#### 6.1.1 数据库迁移Job
```yaml
# migration-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: user-service-migration
  namespace: llmops-backend
spec:
  template:
    spec:
      containers:
      - name: migration
        image: harbor.llmops.com/llmops/user-service:latest
        command: ["./main", "migrate", "up"]
        env:
        - name: CONFIG_PATH
          value: "/app/configs/config.yaml"
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: user-service-secret
              key: database-password
        volumeMounts:
        - name: config-volume
          mountPath: /app/configs
          readOnly: true
      volumes:
      - name: config-volume
        configMap:
          name: user-service-config
      restartPolicy: Never
  backoffLimit: 3
```

### 6.2 数据备份

#### 6.2.1 备份脚本
```bash
#!/bin/bash
# backup.sh

set -e

# 配置变量
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="llmops_db"
DB_HOST="postgresql-service"
DB_USER="llmops_user"

# 创建备份目录
mkdir -p $BACKUP_DIR

# 执行备份
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME > $BACKUP_DIR/backup_$DATE.sql

# 压缩备份文件
gzip $BACKUP_DIR/backup_$DATE.sql

# 上传到对象存储
aws s3 cp $BACKUP_DIR/backup_$DATE.sql.gz s3://llmops-backups/database/

# 清理本地备份文件
rm $BACKUP_DIR/backup_$DATE.sql.gz

echo "Backup completed: backup_$DATE.sql.gz"
```

## 七、安全配置

### 7.1 网络安全

#### 7.1.1 NetworkPolicy
```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: user-service-netpol
  namespace: llmops-backend
spec:
  podSelector:
    matchLabels:
      app: user-service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: llmops-frontend
    - namespaceSelector:
        matchLabels:
          name: llmops-backend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: llmops-backend
    ports:
    - protocol: TCP
      port: 5432  # PostgreSQL
    - protocol: TCP
      port: 6379  # Redis
```

### 7.2 Pod安全策略

#### 7.2.1 PodSecurityPolicy
```yaml
# pod-security-policy.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: user-service-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

## 八、性能优化

### 8.1 资源优化

#### 8.1.1 资源请求和限制
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

#### 8.1.2 节点亲和性
```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-type
          operator: In
          values:
          - compute-optimized
```

### 8.2 应用优化

#### 8.2.1 连接池配置
```yaml
database:
  max_idle_conns: 10
  max_open_conns: 100
  conn_max_lifetime: "1h"
```

#### 8.2.2 缓存配置
```yaml
redis:
  pool_size: 10
  min_idle_conns: 5
  max_conn_age: "1h"
  pool_timeout: "4s"
```

## 九、故障恢复

### 9.1 备份恢复

#### 9.1.1 数据恢复脚本
```bash
#!/bin/bash
# restore.sh

set -e

# 配置变量
BACKUP_FILE=$1
DB_NAME="llmops_db"
DB_HOST="postgresql-service"
DB_USER="llmops_user"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

# 下载备份文件
aws s3 cp s3://llmops-backups/database/$BACKUP_FILE /tmp/

# 解压备份文件
gunzip /tmp/$BACKUP_FILE

# 恢复数据库
psql -h $DB_HOST -U $DB_USER -d $DB_NAME < /tmp/${BACKUP_FILE%.gz}

# 清理临时文件
rm /tmp/${BACKUP_FILE%.gz}

echo "Database restored from $BACKUP_FILE"
```

### 9.2 服务恢复

#### 9.2.1 自动重启策略
```yaml
restartPolicy: Always
terminationGracePeriodSeconds: 30
```

#### 9.2.2 健康检查
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

## 十、部署检查清单

### 10.1 部署前检查
- [ ] 代码审查完成
- [ ] 单元测试通过
- [ ] 集成测试通过
- [ ] 安全扫描通过
- [ ] 性能测试通过
- [ ] 数据库迁移脚本准备
- [ ] 配置文件更新
- [ ] 监控告警配置
- [ ] 备份策略确认

### 10.2 部署后检查
- [ ] 服务启动正常
- [ ] 健康检查通过
- [ ] 数据库连接正常
- [ ] 缓存连接正常
- [ ] 监控指标正常
- [ ] 日志输出正常
- [ ] API接口测试通过
- [ ] 性能指标正常
- [ ] 告警规则生效

---

**文档维护**: 本文档应随着部署架构演进持续更新，保持与实际部署的一致性。

**版本历史**:
- v1.0 (2025-01-17): 初始版本，Go后端部署方案
