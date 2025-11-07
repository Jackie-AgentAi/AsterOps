#!/bin/bash

# 服务验证脚本
# 用于快速检查前后端服务状态和功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== LLMOps 服务验证脚本 ===${NC}\n"

# 1. 检查后端服务
echo -e "${BLUE}[1/5]${NC} 检查后端服务 (user-service:8081)..."
if curl -s http://localhost:8081/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 后端服务运行正常${NC}"
    BACKEND_STATUS=$(curl -s http://localhost:8081/health | head -c 100)
    echo "   响应: $BACKEND_STATUS"
else
    echo -e "${RED}❌ 后端服务未运行或无法访问${NC}"
    echo "   请检查: cd services/user-service && go run cmd/server/main.go"
fi
echo ""

# 2. 检查前端服务
echo -e "${BLUE}[2/5]${NC} 检查前端服务 (admin-dashboard:3000)..."
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 前端服务运行正常${NC}"
else
    echo -e "${RED}❌ 前端服务未运行或无法访问${NC}"
    echo "   请检查: cd frontend/admin-dashboard && npm run dev"
fi
echo ""

# 3. 检查数据库连接
echo -e "${BLUE}[3/5]${NC} 检查数据库连接..."
if command -v psql > /dev/null 2>&1; then
    if PGPASSWORD=${POSTGRES_PASSWORD:-postgres} psql -h ${POSTGRES_HOST:-localhost} -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-llmops} -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 数据库连接正常${NC}"
        
        # 检查用户组表
        GROUP_COUNT=$(PGPASSWORD=${POSTGRES_PASSWORD:-postgres} psql -h ${POSTGRES_HOST:-localhost} -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-llmops} -t -c "SELECT COUNT(*) FROM user_groups;" 2>/dev/null | tr -d ' ')
        echo "   用户组数量: $GROUP_COUNT"
        
        # 检查admin组
        ADMIN_GROUP=$(PGPASSWORD=${POSTGRES_PASSWORD:-postgres} psql -h ${POSTGRES_HOST:-localhost} -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-llmops} -t -c "SELECT name FROM user_groups WHERE id = '00000000-0000-0000-0000-000000000002';" 2>/dev/null | tr -d ' ')
        if [ -n "$ADMIN_GROUP" ]; then
            echo -e "${GREEN}   ✅ Admin组存在: $ADMIN_GROUP${NC}"
        else
            echo -e "${YELLOW}   ⚠️  Admin组不存在，需要初始化${NC}"
            echo "   执行: psql -h ${POSTGRES_HOST:-localhost} -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-llmops} -f services/user-service/scripts/migrations/004_admin_user_group_assignment.sql"
        fi
        
        # 检查admin用户
        ADMIN_USER=$(PGPASSWORD=${POSTGRES_PASSWORD:-postgres} psql -h ${POSTGRES_HOST:-localhost} -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-llmops} -t -c "SELECT username FROM users WHERE id = '00000000-0000-0000-0000-000000000001';" 2>/dev/null | tr -d ' ')
        if [ -n "$ADMIN_USER" ]; then
            echo -e "${GREEN}   ✅ Admin用户存在: $ADMIN_USER${NC}"
        else
            echo -e "${YELLOW}   ⚠️  Admin用户不存在，需要初始化${NC}"
        fi
    else
        echo -e "${RED}❌ 数据库连接失败${NC}"
        echo "   请检查数据库配置和连接"
    fi
else
    echo -e "${YELLOW}⚠️  psql未安装，跳过数据库检查${NC}"
fi
echo ""

# 4. 检查API接口
echo -e "${BLUE}[4/5]${NC} 检查API接口..."
if curl -s http://localhost:8081/health > /dev/null 2>&1; then
    # 检查用户组API（需要认证，这里只检查路径是否存在）
    API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/api/v1/user-groups/ 2>/dev/null || echo "000")
    if [ "$API_RESPONSE" = "401" ] || [ "$API_RESPONSE" = "200" ]; then
        echo -e "${GREEN}✅ 用户组API路径正常 (HTTP $API_RESPONSE)${NC}"
        echo "   注意: 401表示需要认证，这是正常的"
    elif [ "$API_RESPONSE" = "404" ]; then
        echo -e "${RED}❌ 用户组API路径不存在 (HTTP 404)${NC}"
    else
        echo -e "${YELLOW}⚠️  无法访问用户组API (HTTP $API_RESPONSE)${NC}"
    fi
else
    echo -e "${RED}❌ 后端服务未运行，无法检查API${NC}"
fi
echo ""

# 5. 检查端口占用
echo -e "${BLUE}[5/5]${NC} 检查端口占用..."
if command -v lsof > /dev/null 2>&1; then
    # 检查8081端口
    if lsof -i :8081 > /dev/null 2>&1; then
        BACKEND_PID=$(lsof -ti :8081)
        echo -e "${GREEN}✅ 端口8081被占用 (PID: $BACKEND_PID)${NC}"
    else
        echo -e "${YELLOW}⚠️  端口8081未被占用${NC}"
    fi
    
    # 检查3000端口
    if lsof -i :3000 > /dev/null 2>&1; then
        FRONTEND_PID=$(lsof -ti :3000)
        echo -e "${GREEN}✅ 端口3000被占用 (PID: $FRONTEND_PID)${NC}"
    else
        echo -e "${YELLOW}⚠️  端口3000未被占用${NC}"
    fi
elif command -v netstat > /dev/null 2>&1; then
    if netstat -tlnp 2>/dev/null | grep -q ":8081"; then
        echo -e "${GREEN}✅ 端口8081被占用${NC}"
    else
        echo -e "${YELLOW}⚠️  端口8081未被占用${NC}"
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q ":3000"; then
        echo -e "${GREEN}✅ 端口3000被占用${NC}"
    else
        echo -e "${YELLOW}⚠️  端口3000未被占用${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  无法检查端口占用（需要lsof或netstat）${NC}"
fi
echo ""

# 总结
echo -e "${BLUE}=== 验证完成 ===${NC}"
echo ""
echo "下一步操作:"
echo "1. 如果后端服务未运行:"
echo "   cd services/user-service"
echo "   go run cmd/server/main.go"
echo ""
echo "2. 如果前端服务未运行:"
echo "   cd frontend/admin-dashboard"
echo "   npm run dev"
echo ""
echo "3. 如果Admin组不存在:"
echo "   psql -h localhost -U postgres -d llmops -f services/user-service/scripts/migrations/004_admin_user_group_assignment.sql"
echo ""
echo "4. 访问前端页面:"
echo "   http://localhost:3000/users/user-groups"
echo ""
echo "详细验证步骤请参考: docs/verification-guide.md"

