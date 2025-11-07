package service

import (
	"context"
	"time"

	"github.com/llmops/cost-service/internal/domain/entity"
	"github.com/llmops/cost-service/internal/domain/repository"

	"github.com/google/uuid"
)

type BudgetService interface {
	// Budget methods
	CreateBudget(ctx context.Context, budget *entity.Budget) error
	GetBudgetByID(ctx context.Context, id uuid.UUID) (*entity.Budget, error)
	UpdateBudget(ctx context.Context, budget *entity.Budget) error
	DeleteBudget(ctx context.Context, id uuid.UUID) error
	ListBudgets(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID, offset, limit int) ([]*entity.Budget, int64, error)
	GetBudgetsByProject(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID) ([]*entity.Budget, error)
	GetActiveBudgets(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID) ([]*entity.Budget, error)
	GetBudgetsByPeriod(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID, period string) ([]*entity.Budget, error)
	GetBudgetsByDateRange(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID, startDate, endDate time.Time) ([]*entity.Budget, error)
	GetBudgetUsage(ctx context.Context, budgetID uuid.UUID) (float64, error)
	GetBudgetUsagePercentage(ctx context.Context, budgetID uuid.UUID) (float64, error)
	
	// Budget alerts
	CheckBudgetAlerts(ctx context.Context, budgetID uuid.UUID) (*BudgetAlert, error)
	GetBudgetAlerts(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID) ([]*BudgetAlert, error)
	SetBudgetAlert(ctx context.Context, budgetID uuid.UUID, threshold float64) error
}

type budgetService struct {
	budgetRepo repository.BudgetRepository
	costRepo   repository.CostRepository
}

func NewBudgetService(budgetRepo repository.BudgetRepository, costRepo repository.CostRepository) BudgetService {
	return &budgetService{
		budgetRepo: budgetRepo,
		costRepo:   costRepo,
	}
}

func (s *budgetService) CreateBudget(ctx context.Context, budget *entity.Budget) error {
	return s.budgetRepo.CreateBudget(ctx, budget)
}

func (s *budgetService) GetBudgetByID(ctx context.Context, id uuid.UUID) (*entity.Budget, error) {
	return s.budgetRepo.GetBudgetByID(ctx, id)
}

func (s *budgetService) UpdateBudget(ctx context.Context, budget *entity.Budget) error {
	return s.budgetRepo.UpdateBudget(ctx, budget)
}

func (s *budgetService) DeleteBudget(ctx context.Context, id uuid.UUID) error {
	return s.budgetRepo.DeleteBudget(ctx, id)
}

func (s *budgetService) ListBudgets(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID, offset, limit int) ([]*entity.Budget, int64, error) {
	return s.budgetRepo.ListBudgets(ctx, projectID, tenantID, offset, limit)
}

func (s *budgetService) GetBudgetsByProject(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID) ([]*entity.Budget, error) {
	return s.budgetRepo.GetBudgetsByProject(ctx, projectID, tenantID)
}

func (s *budgetService) GetActiveBudgets(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID) ([]*entity.Budget, error) {
	return s.budgetRepo.GetActiveBudgets(ctx, projectID, tenantID)
}

func (s *budgetService) GetBudgetsByPeriod(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID, period string) ([]*entity.Budget, error) {
	return s.budgetRepo.GetBudgetsByPeriod(ctx, projectID, tenantID, period)
}

func (s *budgetService) GetBudgetsByDateRange(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID, startDate, endDate time.Time) ([]*entity.Budget, error) {
	return s.budgetRepo.GetBudgetsByDateRange(ctx, projectID, tenantID, startDate, endDate)
}

func (s *budgetService) GetBudgetUsage(ctx context.Context, budgetID uuid.UUID) (float64, error) {
	return s.budgetRepo.GetBudgetUsage(ctx, budgetID)
}

func (s *budgetService) GetBudgetUsagePercentage(ctx context.Context, budgetID uuid.UUID) (float64, error) {
	return s.budgetRepo.GetBudgetUsagePercentage(ctx, budgetID)
}

func (s *budgetService) CheckBudgetAlerts(ctx context.Context, budgetID uuid.UUID) (*BudgetAlert, error) {
	// 获取预算信息
	budget, err := s.budgetRepo.GetBudgetByID(ctx, budgetID)
	if err != nil {
		return nil, err
	}

	// 获取使用百分比
	usagePercentage, err := s.budgetRepo.GetBudgetUsagePercentage(ctx, budgetID)
	if err != nil {
		return nil, err
	}

	// 检查是否超过告警阈值
	alert := &BudgetAlert{
		BudgetID:           budgetID,
		BudgetName:         budget.Name,
		ProjectID:          budget.ProjectID,
		AlertThreshold:     budget.AlertThreshold,
		UsagePercentage:    usagePercentage,
		IsAlertTriggered:   usagePercentage >= budget.AlertThreshold,
		AlertLevel:         s.getAlertLevel(usagePercentage),
		RemainingAmount:    budget.Amount - (budget.Amount * usagePercentage / 100),
		RemainingDays:      s.getRemainingDays(budget.EndDate),
		LastChecked:        time.Now(),
	}

	return alert, nil
}

func (s *budgetService) GetBudgetAlerts(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID) ([]*BudgetAlert, error) {
	// 获取活跃预算
	budgets, err := s.budgetRepo.GetActiveBudgets(ctx, projectID, tenantID)
	if err != nil {
		return nil, err
	}

	var alerts []*BudgetAlert
	for _, budget := range budgets {
		alert, err := s.CheckBudgetAlerts(ctx, budget.ID)
		if err != nil {
			continue
		}
		if alert.IsAlertTriggered {
			alerts = append(alerts, alert)
		}
	}

	return alerts, nil
}

func (s *budgetService) SetBudgetAlert(ctx context.Context, budgetID uuid.UUID, threshold float64) error {
	budget, err := s.budgetRepo.GetBudgetByID(ctx, budgetID)
	if err != nil {
		return err
	}

	budget.AlertThreshold = threshold
	return s.budgetRepo.UpdateBudget(ctx, budget)
}

func (s *budgetService) getAlertLevel(usagePercentage float64) string {
	if usagePercentage >= 100 {
		return "critical"
	} else if usagePercentage >= 90 {
		return "high"
	} else if usagePercentage >= 80 {
		return "medium"
	} else if usagePercentage >= 70 {
		return "low"
	}
	return "none"
}

func (s *budgetService) getRemainingDays(endDate time.Time) int {
	now := time.Now()
	if endDate.Before(now) {
		return 0
	}
	return int(endDate.Sub(now).Hours() / 24)
}

// 响应结构体
type BudgetAlert struct {
	BudgetID           uuid.UUID `json:"budget_id"`
	BudgetName         string    `json:"budget_name"`
	ProjectID          uuid.UUID `json:"project_id"`
	AlertThreshold     float64   `json:"alert_threshold"`
	UsagePercentage    float64   `json:"usage_percentage"`
	IsAlertTriggered   bool      `json:"is_alert_triggered"`
	AlertLevel         string    `json:"alert_level"`
	RemainingAmount    float64   `json:"remaining_amount"`
	RemainingDays      int       `json:"remaining_days"`
	LastChecked        time.Time `json:"last_checked"`
}



