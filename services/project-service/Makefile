# 项目管理服务 Makefile

.PHONY: build run test clean docker-build docker-run help

# 变量
BINARY_NAME=project-service
DOCKER_IMAGE=llmops/project-service
DOCKER_TAG=latest

# 构建二进制文件
build:
	@echo "Building $(BINARY_NAME)..."
	go build -o $(BINARY_NAME) cmd/server/main.go

# 运行服务
run: build
	@echo "Running $(BINARY_NAME)..."
	./$(BINARY_NAME)

# 开发模式运行
run-dev:
	@echo "Running $(BINARY_NAME) in development mode..."
	go run cmd/server/main.go

# 运行测试
test:
	@echo "Running tests..."
	go test -v ./...

# 运行测试并生成覆盖率报告
test-coverage:
	@echo "Running tests with coverage..."
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

# 清理构建文件
clean:
	@echo "Cleaning up..."
	rm -f $(BINARY_NAME)
	rm -f coverage.out coverage.html

# 构建Docker镜像
docker-build:
	@echo "Building Docker image..."
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

# 运行Docker容器
docker-run: docker-build
	@echo "Running Docker container..."
	docker run -p 8082:8082 $(DOCKER_IMAGE):$(DOCKER_TAG)

# 启动依赖服务
docker-up:
	@echo "Starting dependencies..."
	docker-compose up -d postgres redis consul

# 停止依赖服务
docker-down:
	@echo "Stopping dependencies..."
	docker-compose down

# 查看服务状态
docker-status:
	@echo "Checking service status..."
	docker-compose ps

# 查看日志
docker-logs:
	@echo "Viewing logs..."
	docker-compose logs -f

# 格式化代码
fmt:
	@echo "Formatting code..."
	go fmt ./...

# 检查代码
lint:
	@echo "Linting code..."
	golangci-lint run

# 生成Swagger文档
swagger:
	@echo "Generating Swagger documentation..."
	swag init -g cmd/server/main.go -o ./docs

# 安装依赖
deps:
	@echo "Installing dependencies..."
	go mod download
	go mod tidy

# 帮助信息
help:
	@echo "Available commands:"
	@echo "  build          - Build the binary"
	@echo "  run            - Build and run the service"
	@echo "  run-dev        - Run in development mode"
	@echo "  test           - Run tests"
	@echo "  test-coverage  - Run tests with coverage"
	@echo "  clean          - Clean build files"
	@echo "  docker-build   - Build Docker image"
	@echo "  docker-run     - Build and run Docker container"
	@echo "  docker-up      - Start dependencies"
	@echo "  docker-down    - Stop dependencies"
	@echo "  docker-status  - Check service status"
	@echo "  docker-logs    - View logs"
	@echo "  fmt            - Format code"
	@echo "  lint           - Lint code"
	@echo "  swagger        - Generate Swagger docs"
	@echo "  deps           - Install dependencies"
	@echo "  help           - Show this help"
