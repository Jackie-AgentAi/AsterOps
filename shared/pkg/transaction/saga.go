package transaction

import (
	"context"
	"fmt"
	"time"
)

// Saga事务管理器
type SagaManager struct {
	steps []SagaStep
}

// Saga步骤接口
type SagaStep interface {
	Execute(ctx context.Context) error
	Compensate(ctx context.Context) error
	GetName() string
}

// Saga步骤实现
type SagaStepImpl struct {
	name      string
	execute   func(ctx context.Context) error
	compensate func(ctx context.Context) error
}

func (s *SagaStepImpl) Execute(ctx context.Context) error {
	return s.execute(ctx)
}

func (s *SagaStepImpl) Compensate(ctx context.Context) error {
	return s.compensate(ctx)
}

func (s *SagaStepImpl) GetName() string {
	return s.name
}

// 创建新的Saga管理器
func NewSagaManager() *SagaManager {
	return &SagaManager{
		steps: make([]SagaStep, 0),
	}
}

// 添加步骤
func (s *SagaManager) AddStep(name string, execute, compensate func(ctx context.Context) error) {
	step := &SagaStepImpl{
		name:      name,
		execute:   execute,
		compensate: compensate,
	}
	s.steps = append(s.steps, step)
}

// 执行Saga事务
func (s *SagaManager) Execute(ctx context.Context) error {
	executedSteps := make([]SagaStep, 0)
	
	// 执行所有步骤
	for _, step := range s.steps {
		if err := step.Execute(ctx); err != nil {
			// 执行失败，开始补偿
			s.compensate(ctx, executedSteps)
			return fmt.Errorf("saga step %s failed: %w", step.GetName(), err)
		}
		executedSteps = append(executedSteps, step)
	}
	
	return nil
}

// 补偿执行
func (s *SagaManager) compensate(ctx context.Context, executedSteps []SagaStep) {
	// 逆序执行补偿
	for i := len(executedSteps) - 1; i >= 0; i-- {
		step := executedSteps[i]
		if err := step.Compensate(ctx); err != nil {
			// 记录补偿失败，但不中断其他补偿
			fmt.Printf("compensation failed for step %s: %v\n", step.GetName(), err)
		}
	}
}

// 用户创建Saga示例
func CreateUserSaga(ctx context.Context, userData map[string]interface{}) error {
	saga := NewSagaManager()
	
	// 步骤1: 创建用户
	saga.AddStep("create_user", func(ctx context.Context) error {
		// 调用用户服务创建用户
		return createUser(ctx, userData)
	}, func(ctx context.Context) error {
		// 补偿: 删除用户
		return deleteUser(ctx, userData["id"].(string))
	})
	
	// 步骤2: 分配默认角色
	saga.AddStep("assign_default_role", func(ctx context.Context) error {
		// 调用权限服务分配角色
		return assignDefaultRole(ctx, userData["id"].(string))
	}, func(ctx context.Context) error {
		// 补偿: 移除角色
		return removeRole(ctx, userData["id"].(string))
	})
	
	// 步骤3: 发送欢迎邮件
	saga.AddStep("send_welcome_email", func(ctx context.Context) error {
		// 调用通知服务发送邮件
		return sendWelcomeEmail(ctx, userData["email"].(string))
	}, func(ctx context.Context) error {
		// 补偿: 发送取消邮件
		return sendCancellationEmail(ctx, userData["email"].(string))
	})
	
	// 执行Saga
	return saga.Execute(ctx)
}

// 模型部署Saga示例
func DeployModelSaga(ctx context.Context, modelData map[string]interface{}) error {
	saga := NewSagaManager()
	
	// 步骤1: 验证模型
	saga.AddStep("validate_model", func(ctx context.Context) error {
		return validateModel(ctx, modelData)
	}, func(ctx context.Context) error {
		// 验证失败无需补偿
		return nil
	})
	
	// 步骤2: 创建模型版本
	saga.AddStep("create_model_version", func(ctx context.Context) error {
		return createModelVersion(ctx, modelData)
	}, func(ctx context.Context) error {
		return deleteModelVersion(ctx, modelData["version_id"].(string))
	})
	
	// 步骤3: 部署到推理服务
	saga.AddStep("deploy_to_inference", func(ctx context.Context) error {
		return deployToInferenceService(ctx, modelData)
	}, func(ctx context.Context) error {
		return undeployFromInferenceService(ctx, modelData["deployment_id"].(string))
	})
	
	// 步骤4: 更新监控配置
	saga.AddStep("update_monitoring", func(ctx context.Context) error {
		return updateMonitoringConfig(ctx, modelData)
	}, func(ctx context.Context) error {
		return revertMonitoringConfig(ctx, modelData["monitoring_id"].(string))
	})
	
	// 执行Saga
	return saga.Execute(ctx)
}

// 辅助函数（需要根据实际服务实现）
func createUser(ctx context.Context, data map[string]interface{}) error {
	// 实现用户创建逻辑
	return nil
}

func deleteUser(ctx context.Context, userID string) error {
	// 实现用户删除逻辑
	return nil
}

func assignDefaultRole(ctx context.Context, userID string) error {
	// 实现角色分配逻辑
	return nil
}

func removeRole(ctx context.Context, userID string) error {
	// 实现角色移除逻辑
	return nil
}

func sendWelcomeEmail(ctx context.Context, email string) error {
	// 实现邮件发送逻辑
	return nil
}

func sendCancellationEmail(ctx context.Context, email string) error {
	// 实现取消邮件逻辑
	return nil
}

func validateModel(ctx context.Context, data map[string]interface{}) error {
	// 实现模型验证逻辑
	return nil
}

func createModelVersion(ctx context.Context, data map[string]interface{}) error {
	// 实现模型版本创建逻辑
	return nil
}

func deleteModelVersion(ctx context.Context, versionID string) error {
	// 实现模型版本删除逻辑
	return nil
}

func deployToInferenceService(ctx context.Context, data map[string]interface{}) error {
	// 实现推理服务部署逻辑
	return nil
}

func undeployFromInferenceService(ctx context.Context, deploymentID string) error {
	// 实现推理服务卸载逻辑
	return nil
}

func updateMonitoringConfig(ctx context.Context, data map[string]interface{}) error {
	// 实现监控配置更新逻辑
	return nil
}

func revertMonitoringConfig(ctx context.Context, monitoringID string) error {
	// 实现监控配置回滚逻辑
	return nil
}



