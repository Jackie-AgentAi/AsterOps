# 用户权限服务 Makefile

# 变量定义
SERVICE_NAME := user-service
VERSION := 1.0.0
DOCKER_IMAGE := llmops/$(SERVICE_NAME):$(VERSION)
GO_VERSION := 1.21

# 默认目标
.PHONY: all
all: build

# 安装依赖
.PHONY: deps
deps:
	@echo "Installing dependencies..."
	go mod download
	go mod tidy

# 格式化代码
.PHONY: fmt
fmt:
	@echo "Formatting code..."
	go fmt ./...

# 代码检查
.PHONY: lint
lint:
	@echo "Running linter..."
	golangci-lint run

# 运行测试
.PHONY: test
test:
	@echo "Running tests..."
	go test -v ./...

# 测试覆盖率
.PHONY: test-coverage
test-coverage:
	@echo "Running tests with coverage..."
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

# 构建应用
.PHONY: build
build: deps
	@echo "Building $(SERVICE_NAME)..."
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o bin/$(SERVICE_NAME) cmd/server/main.go

# 构建开发版本
.PHONY: build-dev
build-dev: deps
	@echo "Building $(SERVICE_NAME) for development..."
	go build -o bin/$(SERVICE_NAME) cmd/server/main.go

# 运行应用
.PHONY: run
run: build-dev
	@echo "Running $(SERVICE_NAME)..."
	./bin/$(SERVICE_NAME)

# 运行开发模式
.PHONY: run-dev
run-dev:
	@echo "Running $(SERVICE_NAME) in development mode..."
	go run cmd/server/main.go

# 构建Docker镜像
.PHONY: docker
docker:
	@echo "Building Docker image $(DOCKER_IMAGE)..."
	docker build -t $(DOCKER_IMAGE) .

# 推送Docker镜像
.PHONY: docker-push
docker-push: docker
	@echo "Pushing Docker image $(DOCKER_IMAGE)..."
	docker push $(DOCKER_IMAGE)

# 启动Docker Compose
.PHONY: docker-up
docker-up:
	@echo "Starting services with Docker Compose..."
	docker-compose up -d

# 停止Docker Compose
.PHONY: docker-down
docker-down:
	@echo "Stopping services with Docker Compose..."
	docker-compose down

# 查看Docker Compose日志
.PHONY: docker-logs
docker-logs:
	@echo "Viewing Docker Compose logs..."
	docker-compose logs -f

# 重启服务
.PHONY: docker-restart
docker-restart:
	@echo "Restarting $(SERVICE_NAME) service..."
	docker-compose restart $(SERVICE_NAME)

# 清理
.PHONY: clean
clean:
	@echo "Cleaning up..."
	rm -rf bin/
	rm -f coverage.out coverage.html
	docker-compose down -v
	docker system prune -f

# 数据库迁移
.PHONY: migrate-up
migrate-up:
	@echo "Running database migrations..."
	# 这里可以添加数据库迁移命令

# 数据库回滚
.PHONY: migrate-down
migrate-down:
	@echo "Rolling back database migrations..."
	# 这里可以添加数据库回滚命令

# 生成API文档
.PHONY: docs
docs:
	@echo "Generating API documentation..."
	swag init -g cmd/server/main.go -o docs/

# 安装开发工具
.PHONY: install-tools
install-tools:
	@echo "Installing development tools..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install github.com/swaggo/swag/cmd/swag@latest

# 健康检查
.PHONY: health
health:
	@echo "Checking service health..."
	curl -f http://localhost:8081/health || exit 1

# 运行测试脚本
.PHONY: test-api
test-api:
	@echo "Running API tests..."
	./scripts/test_user_api.sh

# 开发环境设置
.PHONY: dev-setup
dev-setup: install-tools deps
	@echo "Setting up development environment..."
	@echo "Development environment setup complete!"

# 生产环境构建
.PHONY: prod-build
prod-build: deps
	@echo "Building for production..."
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-w -s' -o bin/$(SERVICE_NAME) cmd/server/main.go

# 帮助信息
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  deps          - Install dependencies"
	@echo "  fmt           - Format code"
	@echo "  lint          - Run linter"
	@echo "  test          - Run tests"
	@echo "  test-coverage - Run tests with coverage"
	@echo "  build         - Build application"
	@echo "  build-dev     - Build for development"
	@echo "  run           - Run application"
	@echo "  run-dev       - Run in development mode"
	@echo "  docker        - Build Docker image"
	@echo "  docker-up     - Start with Docker Compose"
	@echo "  docker-down   - Stop Docker Compose"
	@echo "  docker-logs   - View Docker Compose logs"
	@echo "  clean         - Clean up"
	@echo "  health        - Check service health"
	@echo "  test-api      - Run API tests"
	@echo "  dev-setup     - Setup development environment"
	@echo "  help          - Show this help"



