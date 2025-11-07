#!/bin/bash

# LLMOps前端测试运行脚本
# 支持单元测试、集成测试和端到端测试

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${2}${1}${NC}"
}

# 打印标题
print_title() {
    echo ""
    print_message "===============================================" $BLUE
    print_message "$1" $BLUE
    print_message "===============================================" $BLUE
    echo ""
}

# 检查依赖
check_dependencies() {
    print_title "检查依赖"
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        print_message "错误: Node.js 未安装" $RED
        exit 1
    fi
    
    # 检查npm
    if ! command -v npm &> /dev/null; then
        print_message "错误: npm 未安装" $RED
        exit 1
    fi
    
    print_message "✓ Node.js 版本: $(node --version)" $GREEN
    print_message "✓ npm 版本: $(npm --version)" $GREEN
}

# 安装依赖
install_dependencies() {
    print_title "安装依赖"
    
    if [ ! -d "node_modules" ]; then
        print_message "安装项目依赖..." $YELLOW
        npm install
    else
        print_message "依赖已安装，跳过安装步骤" $GREEN
    fi
}

# 运行单元测试
run_unit_tests() {
    print_title "运行单元测试"
    
    print_message "运行 Vitest 单元测试..." $YELLOW
    npm run test:run
    
    if [ $? -eq 0 ]; then
        print_message "✓ 单元测试通过" $GREEN
    else
        print_message "✗ 单元测试失败" $RED
        return 1
    fi
}

# 运行单元测试并生成覆盖率报告
run_unit_tests_with_coverage() {
    print_title "运行单元测试 (含覆盖率)"
    
    print_message "运行 Vitest 单元测试并生成覆盖率报告..." $YELLOW
    npm run test:coverage
    
    if [ $? -eq 0 ]; then
        print_message "✓ 单元测试通过，覆盖率报告已生成" $GREEN
        print_message "覆盖率报告位置: coverage/index.html" $BLUE
    else
        print_message "✗ 单元测试失败" $RED
        return 1
    fi
}

# 运行集成测试
run_integration_tests() {
    print_title "运行集成测试"
    
    print_message "运行集成测试..." $YELLOW
    npm run test:run -- tests/integration
    
    if [ $? -eq 0 ]; then
        print_message "✓ 集成测试通过" $GREEN
    else
        print_message "✗ 集成测试失败" $RED
        return 1
    fi
}

# 运行端到端测试
run_e2e_tests() {
    print_title "运行端到端测试"
    
    print_message "安装 Playwright 浏览器..." $YELLOW
    npx playwright install
    
    print_message "运行 Playwright 端到端测试..." $YELLOW
    npm run test:e2e
    
    if [ $? -eq 0 ]; then
        print_message "✓ 端到端测试通过" $GREEN
    else
        print_message "✗ 端到端测试失败" $RED
        return 1
    fi
}

# 运行所有测试
run_all_tests() {
    print_title "运行所有测试"
    
    local failed=0
    
    # 运行单元测试
    if ! run_unit_tests; then
        failed=1
    fi
    
    # 运行集成测试
    if ! run_integration_tests; then
        failed=1
    fi
    
    # 运行端到端测试
    if ! run_e2e_tests; then
        failed=1
    fi
    
    if [ $failed -eq 0 ]; then
        print_title "所有测试通过！"
        print_message "🎉 恭喜！所有测试都通过了" $GREEN
    else
        print_title "部分测试失败"
        print_message "❌ 有测试失败，请检查上面的错误信息" $RED
        exit 1
    fi
}

# 清理测试文件
cleanup() {
    print_title "清理测试文件"
    
    print_message "清理测试结果和覆盖率文件..." $YELLOW
    
    # 删除覆盖率报告
    if [ -d "coverage" ]; then
        rm -rf coverage
        print_message "✓ 删除覆盖率报告" $GREEN
    fi
    
    # 删除测试结果
    if [ -d "test-results" ]; then
        rm -rf test-results
        print_message "✓ 删除测试结果" $GREEN
    fi
    
    # 删除Playwright报告
    if [ -d "playwright-report" ]; then
        rm -rf playwright-report
        print_message "✓ 删除Playwright报告" $GREEN
    fi
}

# 显示帮助信息
show_help() {
    echo "LLMOps前端测试运行脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  unit                运行单元测试"
    echo "  unit-coverage       运行单元测试并生成覆盖率报告"
    echo "  integration         运行集成测试"
    echo "  e2e                 运行端到端测试"
    echo "  all                 运行所有测试"
    echo "  clean               清理测试文件"
    echo "  help                显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 unit             运行单元测试"
    echo "  $0 unit-coverage    运行单元测试并生成覆盖率报告"
    echo "  $0 all              运行所有测试"
    echo "  $0 clean            清理测试文件"
}

# 主函数
main() {
    case "${1:-all}" in
        "unit")
            check_dependencies
            install_dependencies
            run_unit_tests
            ;;
        "unit-coverage")
            check_dependencies
            install_dependencies
            run_unit_tests_with_coverage
            ;;
        "integration")
            check_dependencies
            install_dependencies
            run_integration_tests
            ;;
        "e2e")
            check_dependencies
            install_dependencies
            run_e2e_tests
            ;;
        "all")
            check_dependencies
            install_dependencies
            run_all_tests
            ;;
        "clean")
            cleanup
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_message "未知选项: $1" $RED
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"









