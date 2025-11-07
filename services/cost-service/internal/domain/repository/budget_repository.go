package repository

import (
	"context"
	"time"

	"github.com/llmops/cost-service/internal/domain/entity"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type BudgetRepository interface {
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
}

type budgetRepository struct {
	db *gorm.DB
}

func NewBudgetRepository(db *gorm.DB) BudgetRepository {
	return &budgetRepository{db: db}
}

func (r *budgetRepository) CreateBudget(ctx context.Context, budget *entity.Budget) error {
	return r.db.WithContext(ctx).Create(budget).Error
}

func (r *budgetRepository) GetBudgetByID(ctx context.Context, id uuid.UUID) (*entity.Budget, error) {
	var budget entity.Budget
	err := r.db.WithContext(ctx).Preload("Project").First(&budget, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &budget, nil
}

func (r *budgetRepository) UpdateBudget(ctx context.Context, budget *entity.Budget) error {
	return r.db.WithContext(ctx).Save(budget).Error
}

func (r *budgetRepository) DeleteBudget(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&entity.Budget{}, "id = ?", id).Error
}

func (r *budgetRepository) ListBudgets(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID, offset, limit int) ([]*entity.Budget, int64, error) {
	var budgets []*entity.Budget
	var total int64

	query := r.db.WithContext(ctx).Model(&entity.Budget{}).Where("tenant_id = ?", tenantID)
	if projectID != uuid.Nil {
		query = query.Where("project_id = ?", projectID)
	}

	// 获取总数
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 获取数据
	err := query.Preload("Project").
		Offset(offset).Limit(limit).
		Order("created_at DESC").
		Find(&budgets).Error

	return budgets, total, err
}

func (r *budgetRepository) GetBudgetsByProject(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID) ([]*entity.Budget, error) {
	var budgets []*entity.Budget
	err := r.db.WithContext(ctx).Where("project_id = ? AND tenant_id = ?", projectID, tenantID).
		Preload("Project").Find(&budgets).Error
	return budgets, err
}

func (r *budgetRepository) GetActiveBudgets(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID) ([]*entity.Budget, error) {
	var budgets []*entity.Budget
	now := time.Now()
	err := r.db.WithContext(ctx).Where("project_id = ? AND tenant_id = ? AND status = ? AND start_date <= ? AND end_date >= ?", 
		projectID, tenantID, "active", now, now).
		Preload("Project").Find(&budgets).Error
	return budgets, err
}

func (r *budgetRepository) GetBudgetsByPeriod(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID, period string) ([]*entity.Budget, error) {
	var budgets []*entity.Budget
	query := r.db.WithContext(ctx).Where("tenant_id = ? AND period = ?", tenantID, period)
	if projectID != uuid.Nil {
		query = query.Where("project_id = ?", projectID)
	}
	err := query.Preload("Project").Find(&budgets).Error
	return budgets, err
}

func (r *budgetRepository) GetBudgetsByDateRange(ctx context.Context, projectID uuid.UUID, tenantID uuid.UUID, startDate, endDate time.Time) ([]*entity.Budget, error) {
	var budgets []*entity.Budget
	query := r.db.WithContext(ctx).Where("tenant_id = ? AND start_date >= ? AND end_date <= ?", tenantID, startDate, endDate)
	if projectID != uuid.Nil {
		query = query.Where("project_id = ?", projectID)
	}
	err := query.Preload("Project").Find(&budgets).Error
	return budgets, err
}

func (r *budgetRepository) GetBudgetUsage(ctx context.Context, budgetID uuid.UUID) (float64, error) {
	var total float64
	err := r.db.WithContext(ctx).Model(&entity.CostRecord{}).
		Joins("JOIN budgets ON cost_records.project_id = budgets.project_id").
		Where("budgets.id = ? AND cost_records.created_at >= budgets.start_date AND cost_records.created_at <= budgets.end_date", budgetID).
		Select("COALESCE(SUM(cost_records.amount), 0)").Scan(&total).Error
	return total, err
}

func (r *budgetRepository) GetBudgetUsagePercentage(ctx context.Context, budgetID uuid.UUID) (float64, error) {
	// 获取预算金额
	var budget entity.Budget
	if err := r.db.WithContext(ctx).First(&budget, "id = ?", budgetID).Error; err != nil {
		return 0, err
	}

	// 获取使用金额
	usage, err := r.GetBudgetUsage(ctx, budgetID)
	if err != nil {
		return 0, err
	}

	// 计算使用百分比
	if budget.Amount == 0 {
		return 0, nil
	}
	return (usage / budget.Amount) * 100, nil
}



