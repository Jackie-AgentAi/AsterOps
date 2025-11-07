package repository

import (
	"context"
	"time"

	"github.com/llmops/cost-service/internal/domain/entity"
	"gorm.io/gorm"
)

// 成本记录仓储接口
type CostRepository interface {
	Create(ctx context.Context, cost *entity.CostRecord) error
	GetByID(ctx context.Context, id string) (*entity.CostRecord, error)
	GetByProjectID(ctx context.Context, projectID string, offset, limit int) ([]*entity.CostRecord, int64, error)
	GetByUserID(ctx context.Context, userID string, offset, limit int) ([]*entity.CostRecord, int64, error)
	GetByTenantID(ctx context.Context, tenantID string, offset, limit int) ([]*entity.CostRecord, int64, error)
	GetByDateRange(ctx context.Context, startDate, endDate time.Time, offset, limit int) ([]*entity.CostRecord, int64, error)
	Update(ctx context.Context, cost *entity.CostRecord) error
	Delete(ctx context.Context, id string) error
	GetTotalCostByProject(ctx context.Context, projectID string) (float64, error)
	GetTotalCostByTenant(ctx context.Context, tenantID string) (float64, error)
	GetCostByType(ctx context.Context, costType string, offset, limit int) ([]*entity.CostRecord, int64, error)
}

// 预算仓储接口
type BudgetRepository interface {
	Create(ctx context.Context, budget *entity.Budget) error
	GetByID(ctx context.Context, id string) (*entity.Budget, error)
	GetByProjectID(ctx context.Context, projectID string, offset, limit int) ([]*entity.Budget, int64, error)
	GetByTenantID(ctx context.Context, tenantID string, offset, limit int) ([]*entity.Budget, int64, error)
	GetActiveBudgets(ctx context.Context, projectID string) ([]*entity.Budget, error)
	Update(ctx context.Context, budget *entity.Budget) error
	Delete(ctx context.Context, id string) error
	CheckBudgetAlert(ctx context.Context, budgetID string) (bool, error)
}

// 成本分析仓储接口
type AnalysisRepository interface {
	Create(ctx context.Context, analysis *entity.CostAnalysis) error
	GetByID(ctx context.Context, id string) (*entity.CostAnalysis, error)
	GetByProjectID(ctx context.Context, projectID string, analysisType string, offset, limit int) ([]*entity.CostAnalysis, int64, error)
	GetByTenantID(ctx context.Context, tenantID string, analysisType string, offset, limit int) ([]*entity.CostAnalysis, int64, error)
	GetLatestAnalysis(ctx context.Context, projectID string, analysisType string) (*entity.CostAnalysis, error)
	Delete(ctx context.Context, id string) error
}

// 计费规则仓储接口
type BillingRuleRepository interface {
	Create(ctx context.Context, rule *entity.BillingRule) error
	GetByID(ctx context.Context, id string) (*entity.BillingRule, error)
	GetByProjectID(ctx context.Context, projectID string, offset, limit int) ([]*entity.BillingRule, int64, error)
	GetByTenantID(ctx context.Context, tenantID string, offset, limit int) ([]*entity.BillingRule, int64, error)
	GetActiveRules(ctx context.Context, projectID string) ([]*entity.BillingRule, error)
	Update(ctx context.Context, rule *entity.BillingRule) error
	Delete(ctx context.Context, id string) error
}

// 成本优化仓储接口
type OptimizationRepository interface {
	Create(ctx context.Context, optimization *entity.CostOptimization) error
	GetByID(ctx context.Context, id string) (*entity.CostOptimization, error)
	GetByProjectID(ctx context.Context, projectID string, offset, limit int) ([]*entity.CostOptimization, int64, error)
	GetByTenantID(ctx context.Context, tenantID string, offset, limit int) ([]*entity.CostOptimization, int64, error)
	GetByStatus(ctx context.Context, status string, offset, limit int) ([]*entity.CostOptimization, int64, error)
	GetByPriority(ctx context.Context, priority string, offset, limit int) ([]*entity.CostOptimization, int64, error)
	Update(ctx context.Context, optimization *entity.CostOptimization) error
	Delete(ctx context.Context, id string) error
}

// 成本记录仓储实现
type costRepository struct {
	db *gorm.DB
}

func NewCostRepository(db *gorm.DB) CostRepository {
	return &costRepository{db: db}
}

func (r *costRepository) Create(ctx context.Context, cost *entity.CostRecord) error {
	return r.db.WithContext(ctx).Create(cost).Error
}

func (r *costRepository) GetByID(ctx context.Context, id string) (*entity.CostRecord, error) {
	var cost entity.CostRecord
	err := r.db.WithContext(ctx).Where("id = ?", id).First(&cost).Error
	if err != nil {
		return nil, err
	}
	return &cost, nil
}

func (r *costRepository) GetByProjectID(ctx context.Context, projectID string, offset, limit int) ([]*entity.CostRecord, int64, error) {
	var costs []*entity.CostRecord
	var total int64

	query := r.db.WithContext(ctx).Model(&entity.CostRecord{}).Where("project_id = ?", projectID)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := query.Offset(offset).Limit(limit).Order("created_at DESC").Find(&costs).Error
	return costs, total, err
}

func (r *costRepository) GetByUserID(ctx context.Context, userID string, offset, limit int) ([]*entity.CostRecord, int64, error) {
	var costs []*entity.CostRecord
	var total int64

	query := r.db.WithContext(ctx).Model(&entity.CostRecord{}).Where("user_id = ?", userID)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := query.Offset(offset).Limit(limit).Order("created_at DESC").Find(&costs).Error
	return costs, total, err
}

func (r *costRepository) GetByTenantID(ctx context.Context, tenantID string, offset, limit int) ([]*entity.CostRecord, int64, error) {
	var costs []*entity.CostRecord
	var total int64

	query := r.db.WithContext(ctx).Model(&entity.CostRecord{}).Where("tenant_id = ?", tenantID)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := query.Offset(offset).Limit(limit).Order("created_at DESC").Find(&costs).Error
	return costs, total, err
}

func (r *costRepository) GetByDateRange(ctx context.Context, startDate, endDate time.Time, offset, limit int) ([]*entity.CostRecord, int64, error) {
	var costs []*entity.CostRecord
	var total int64

	query := r.db.WithContext(ctx).Model(&entity.CostRecord{}).Where("created_at BETWEEN ? AND ?", startDate, endDate)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := query.Offset(offset).Limit(limit).Order("created_at DESC").Find(&costs).Error
	return costs, total, err
}

func (r *costRepository) Update(ctx context.Context, cost *entity.CostRecord) error {
	return r.db.WithContext(ctx).Save(cost).Error
}

func (r *costRepository) Delete(ctx context.Context, id string) error {
	return r.db.WithContext(ctx).Delete(&entity.CostRecord{}, "id = ?", id).Error
}

func (r *costRepository) GetTotalCostByProject(ctx context.Context, projectID string) (float64, error) {
	var total float64
	err := r.db.WithContext(ctx).Model(&entity.CostRecord{}).
		Where("project_id = ?", projectID).
		Select("COALESCE(SUM(amount), 0)").Scan(&total).Error
	return total, err
}

func (r *costRepository) GetTotalCostByTenant(ctx context.Context, tenantID string) (float64, error) {
	var total float64
	err := r.db.WithContext(ctx).Model(&entity.CostRecord{}).
		Where("tenant_id = ?", tenantID).
		Select("COALESCE(SUM(amount), 0)").Scan(&total).Error
	return total, err
}

func (r *costRepository) GetCostByType(ctx context.Context, costType string, offset, limit int) ([]*entity.CostRecord, int64, error) {
	var costs []*entity.CostRecord
	var total int64

	query := r.db.WithContext(ctx).Model(&entity.CostRecord{}).Where("cost_type = ?", costType)
	
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := query.Offset(offset).Limit(limit).Order("created_at DESC").Find(&costs).Error
	return costs, total, err
}