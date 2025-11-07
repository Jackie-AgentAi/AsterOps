package service

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/llmops/cost-service/internal/domain/entity"
	"github.com/llmops/cost-service/internal/domain/repository"
	"github.com/sirupsen/logrus"
)

// 成本服务
type CostService struct {
	costRepo         repository.CostRepository
	budgetRepo       repository.BudgetRepository
	analysisRepo     repository.AnalysisRepository
	billingRepo      repository.BillingRuleRepository
	optimizationRepo repository.OptimizationRepository
	logger           *logrus.Logger
}

// 创建成本服务
func NewCostService(
	costRepo repository.CostRepository,
	budgetRepo repository.BudgetRepository,
	analysisRepo repository.AnalysisRepository,
	billingRepo repository.BillingRuleRepository,
	optimizationRepo repository.OptimizationRepository,
	logger *logrus.Logger,
) *CostService {
	return &CostService{
		costRepo:         costRepo,
		budgetRepo:       budgetRepo,
		analysisRepo:     analysisRepo,
		billingRepo:      billingRepo,
		optimizationRepo: optimizationRepo,
		logger:           logger,
	}
}

// 创建成本记录
func (s *CostService) CreateCostRecord(ctx context.Context, req *entity.CreateCostRecordRequest, userID, tenantID string) (*entity.CostRecordResponse, error) {
	cost := &entity.CostRecord{
		ProjectID:   req.ProjectID,
		ModelID:     req.ModelID,
		UserID:      userID,
		TenantID:    tenantID,
		CostType:    req.CostType,
		Amount:      req.Amount,
		Currency:    req.Currency,
		Description: req.Description,
		Metadata:    req.Metadata,
	}

	if cost.Currency == "" {
		cost.Currency = "USD"
	}

	if err := s.costRepo.Create(ctx, cost); err != nil {
		s.logger.WithError(err).Error("Failed to create cost record")
		return nil, fmt.Errorf("failed to create cost record: %w", err)
	}

	response := &entity.CostRecordResponse{
		ID:          cost.ID,
		ProjectID:   cost.ProjectID,
		ModelID:     cost.ModelID,
		UserID:      cost.UserID,
		TenantID:    cost.TenantID,
		CostType:    cost.CostType,
		Amount:      cost.Amount,
		Currency:    cost.Currency,
		Description: cost.Description,
		Metadata:    cost.Metadata,
		CreatedAt:   cost.CreatedAt,
		UpdatedAt:   cost.UpdatedAt,
	}

	s.logger.WithFields(logrus.Fields{
		"cost_id":   cost.ID,
		"project_id": cost.ProjectID,
		"amount":    cost.Amount,
		"cost_type": cost.CostType,
	}).Info("Cost record created")

	return response, nil
}

// 获取成本记录
func (s *CostService) GetCostRecord(ctx context.Context, id string) (*entity.CostRecordResponse, error) {
	cost, err := s.costRepo.GetByID(ctx, id)
	if err != nil {
		s.logger.WithError(err).WithField("cost_id", id).Error("Failed to get cost record")
		return nil, fmt.Errorf("failed to get cost record: %w", err)
	}

	response := &entity.CostRecordResponse{
		ID:          cost.ID,
		ProjectID:   cost.ProjectID,
		ModelID:     cost.ModelID,
		UserID:      cost.UserID,
		TenantID:    cost.TenantID,
		CostType:    cost.CostType,
		Amount:      cost.Amount,
		Currency:    cost.Currency,
		Description: cost.Description,
		Metadata:    cost.Metadata,
		CreatedAt:   cost.CreatedAt,
		UpdatedAt:   cost.UpdatedAt,
	}

	return response, nil
}

// 获取成本记录列表
func (s *CostService) GetCostRecords(ctx context.Context, projectID, userID, tenantID string, offset, limit int) ([]*entity.CostRecordResponse, int64, error) {
	var costs []*entity.CostRecord
	var total int64
	var err error

	if projectID != "" {
		costs, total, err = s.costRepo.GetByProjectID(ctx, projectID, offset, limit)
	} else if userID != "" {
		costs, total, err = s.costRepo.GetByUserID(ctx, userID, offset, limit)
	} else if tenantID != "" {
		costs, total, err = s.costRepo.GetByTenantID(ctx, tenantID, offset, limit)
	} else {
		return nil, 0, fmt.Errorf("project_id, user_id, or tenant_id must be provided")
	}

	if err != nil {
		s.logger.WithError(err).Error("Failed to get cost records")
		return nil, 0, fmt.Errorf("failed to get cost records: %w", err)
	}

	responses := make([]*entity.CostRecordResponse, len(costs))
	for i, cost := range costs {
		responses[i] = &entity.CostRecordResponse{
			ID:          cost.ID,
			ProjectID:   cost.ProjectID,
			ModelID:     cost.ModelID,
			UserID:      cost.UserID,
			TenantID:    cost.TenantID,
			CostType:    cost.CostType,
			Amount:      cost.Amount,
			Currency:    cost.Currency,
			Description: cost.Description,
			Metadata:    cost.Metadata,
			CreatedAt:   cost.CreatedAt,
			UpdatedAt:   cost.UpdatedAt,
		}
	}

	return responses, total, nil
}

// 更新成本记录
func (s *CostService) UpdateCostRecord(ctx context.Context, id string, req *entity.CreateCostRecordRequest) (*entity.CostRecordResponse, error) {
	cost, err := s.costRepo.GetByID(ctx, id)
	if err != nil {
		s.logger.WithError(err).WithField("cost_id", id).Error("Failed to get cost record for update")
		return nil, fmt.Errorf("failed to get cost record: %w", err)
	}

	// 更新字段
	cost.ProjectID = req.ProjectID
	cost.ModelID = req.ModelID
	cost.CostType = req.CostType
	cost.Amount = req.Amount
	cost.Currency = req.Currency
	cost.Description = req.Description
	cost.Metadata = req.Metadata

	if cost.Currency == "" {
		cost.Currency = "USD"
	}

	if err := s.costRepo.Update(ctx, cost); err != nil {
		s.logger.WithError(err).WithField("cost_id", id).Error("Failed to update cost record")
		return nil, fmt.Errorf("failed to update cost record: %w", err)
	}

	response := &entity.CostRecordResponse{
		ID:          cost.ID,
		ProjectID:   cost.ProjectID,
		ModelID:     cost.ModelID,
		UserID:      cost.UserID,
		TenantID:    cost.TenantID,
		CostType:    cost.CostType,
		Amount:      cost.Amount,
		Currency:    cost.Currency,
		Description: cost.Description,
		Metadata:    cost.Metadata,
		CreatedAt:   cost.CreatedAt,
		UpdatedAt:   cost.UpdatedAt,
	}

	s.logger.WithField("cost_id", id).Info("Cost record updated")

	return response, nil
}

// 删除成本记录
func (s *CostService) DeleteCostRecord(ctx context.Context, id string) error {
	if err := s.costRepo.Delete(ctx, id); err != nil {
		s.logger.WithError(err).WithField("cost_id", id).Error("Failed to delete cost record")
		return fmt.Errorf("failed to delete cost record: %w", err)
	}

	s.logger.WithField("cost_id", id).Info("Cost record deleted")
	return nil
}

// 获取成本汇总
func (s *CostService) GetCostSummary(ctx context.Context, projectID, tenantID string) (map[string]interface{}, error) {
	var totalCost float64
	var err error

	if projectID != "" {
		totalCost, err = s.costRepo.GetTotalCostByProject(ctx, projectID)
	} else if tenantID != "" {
		totalCost, err = s.costRepo.GetTotalCostByTenant(ctx, tenantID)
	} else {
		return nil, fmt.Errorf("project_id or tenant_id must be provided")
	}

	if err != nil {
		s.logger.WithError(err).Error("Failed to get cost summary")
		return nil, fmt.Errorf("failed to get cost summary: %w", err)
	}

	// 获取按类型分组的成本
	costByType := make(map[string]float64)
	costTypes := []string{"inference", "training", "storage", "compute", "data"}
	
	for _, costType := range costTypes {
		costs, _, err := s.costRepo.GetCostByType(ctx, costType, 0, 1000)
		if err != nil {
			s.logger.WithError(err).WithField("cost_type", costType).Warn("Failed to get cost by type")
			continue
		}
		
		var typeTotal float64
		for _, cost := range costs {
			typeTotal += cost.Amount
		}
		costByType[costType] = typeTotal
	}

	summary := map[string]interface{}{
		"total_cost":    totalCost,
		"cost_by_type":  costByType,
		"currency":      "USD",
		"generated_at":  time.Now().UTC(),
	}

	return summary, nil
}

// 生成成本分析
func (s *CostService) GenerateCostAnalysis(ctx context.Context, req *entity.CostAnalysisRequest) (*entity.CostAnalysisResponse, error) {
	// 根据分析类型生成不同的分析结果
	var analysisData map[string]interface{}
	var err error

	switch req.AnalysisType {
	case "summary":
		analysisData, err = s.generateSummaryAnalysis(ctx, req)
	case "trend":
		analysisData, err = s.generateTrendAnalysis(ctx, req)
	case "breakdown":
		analysisData, err = s.generateBreakdownAnalysis(ctx, req)
	case "comparison":
		analysisData, err = s.generateComparisonAnalysis(ctx, req)
	default:
		return nil, fmt.Errorf("unsupported analysis type: %s", req.AnalysisType)
	}

	if err != nil {
		s.logger.WithError(err).WithField("analysis_type", req.AnalysisType).Error("Failed to generate cost analysis")
		return nil, fmt.Errorf("failed to generate cost analysis: %w", err)
	}

	// 将分析结果转换为JSON
	analysisDataJSON, err := json.Marshal(analysisData)
	if err != nil {
		s.logger.WithError(err).Error("Failed to marshal analysis data")
		return nil, fmt.Errorf("failed to marshal analysis data: %w", err)
	}

	// 创建分析记录
	analysis := &entity.CostAnalysis{
		ProjectID:    req.ProjectID,
		TenantID:     "default-tenant", // 从上下文获取
		AnalysisType: req.AnalysisType,
		Period:       req.Period,
		Data:         string(analysisDataJSON),
	}

	if err := s.analysisRepo.Create(ctx, analysis); err != nil {
		s.logger.WithError(err).Error("Failed to save cost analysis")
		return nil, fmt.Errorf("failed to save cost analysis: %w", err)
	}

	response := &entity.CostAnalysisResponse{
		ID:           analysis.ID,
		ProjectID:    analysis.ProjectID,
		TenantID:     analysis.TenantID,
		AnalysisType: analysis.AnalysisType,
		Period:       analysis.Period,
		Data:         analysis.Data,
		CreatedAt:    analysis.CreatedAt,
		UpdatedAt:    analysis.UpdatedAt,
	}

	s.logger.WithFields(logrus.Fields{
		"analysis_id":   analysis.ID,
		"project_id":    analysis.ProjectID,
		"analysis_type": analysis.AnalysisType,
	}).Info("Cost analysis generated")

	return response, nil
}

// 生成汇总分析
func (s *CostService) generateSummaryAnalysis(ctx context.Context, req *entity.CostAnalysisRequest) (map[string]interface{}, error) {
	// 获取项目总成本
	totalCost, err := s.costRepo.GetTotalCostByProject(ctx, req.ProjectID)
	if err != nil {
		return nil, err
	}

	// 获取按类型分组的成本
	costByType := make(map[string]float64)
	costTypes := []string{"inference", "training", "storage", "compute", "data"}
	
	for _, costType := range costTypes {
		costs, _, err := s.costRepo.GetCostByType(ctx, costType, 0, 1000)
		if err != nil {
			continue
		}
		
		var typeTotal float64
		for _, cost := range costs {
			typeTotal += cost.Amount
		}
		costByType[costType] = typeTotal
	}

	return map[string]interface{}{
		"total_cost":    totalCost,
		"cost_by_type":  costByType,
		"currency":      "USD",
		"period":        req.Period,
		"generated_at":  time.Now().UTC(),
	}, nil
}

// 生成趋势分析
func (s *CostService) generateTrendAnalysis(ctx context.Context, req *entity.CostAnalysisRequest) (map[string]interface{}, error) {
	// 模拟趋势数据
	trendData := map[string]interface{}{
		"period":       req.Period,
		"trend_points": []map[string]interface{}{
			{"date": "2024-01-01", "cost": 100.0},
			{"date": "2024-01-02", "cost": 120.0},
			{"date": "2024-01-03", "cost": 110.0},
			{"date": "2024-01-04", "cost": 130.0},
			{"date": "2024-01-05", "cost": 125.0},
		},
		"trend_direction": "increasing",
		"growth_rate":     0.15,
		"generated_at":    time.Now().UTC(),
	}

	return trendData, nil
}

// 生成分解分析
func (s *CostService) generateBreakdownAnalysis(ctx context.Context, req *entity.CostAnalysisRequest) (map[string]interface{}, error) {
	// 模拟分解数据
	breakdownData := map[string]interface{}{
		"period": req.Period,
		"breakdown": map[string]interface{}{
			"inference": map[string]interface{}{
				"cost":      500.0,
				"percentage": 50.0,
				"details":   []string{"API calls", "Model inference"},
			},
			"training": map[string]interface{}{
				"cost":      300.0,
				"percentage": 30.0,
				"details":   []string{"GPU usage", "Data processing"},
			},
			"storage": map[string]interface{}{
				"cost":      200.0,
				"percentage": 20.0,
				"details":   []string{"Model storage", "Data storage"},
			},
		},
		"generated_at": time.Now().UTC(),
	}

	return breakdownData, nil
}

// 生成对比分析
func (s *CostService) generateComparisonAnalysis(ctx context.Context, req *entity.CostAnalysisRequest) (map[string]interface{}, error) {
	// 模拟对比数据
	comparisonData := map[string]interface{}{
		"period": req.Period,
		"comparison": map[string]interface{}{
			"current_period": map[string]interface{}{
				"cost":      1000.0,
				"breakdown": map[string]float64{"inference": 500, "training": 300, "storage": 200},
			},
			"previous_period": map[string]interface{}{
				"cost":      800.0,
				"breakdown": map[string]float64{"inference": 400, "training": 250, "storage": 150},
			},
			"change": map[string]interface{}{
				"absolute":  200.0,
				"percentage": 25.0,
				"direction": "increase",
			},
		},
		"generated_at": time.Now().UTC(),
	}

	return comparisonData, nil
}