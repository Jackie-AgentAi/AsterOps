package entity

import (
	"time"
)

// 成本记录实体
type CostRecord struct {
	ID          string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	ProjectID   string    `json:"project_id" gorm:"not null;index"`
	ModelID     *string   `json:"model_id,omitempty" gorm:"index"`
	UserID      string    `json:"user_id" gorm:"not null;index"`
	TenantID    string    `json:"tenant_id" gorm:"not null;index"`
	CostType    string    `json:"cost_type" gorm:"not null"` // inference, training, storage, etc.
	Amount      float64   `json:"amount" gorm:"type:decimal(15,4);not null"`
	Currency    string    `json:"currency" gorm:"default:'USD'"`
	Description string    `json:"description"`
	Metadata    string    `json:"metadata" gorm:"type:jsonb"` // JSON metadata
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 预算实体
type Budget struct {
	ID             string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	ProjectID      string    `json:"project_id" gorm:"not null;index"`
	Name           string    `json:"name" gorm:"not null"`
	Amount         float64   `json:"amount" gorm:"type:decimal(15,4);not null"`
	Currency       string    `json:"currency" gorm:"default:'USD'"`
	Period         string    `json:"period" gorm:"not null"` // monthly, quarterly, yearly
	StartDate      time.Time `json:"start_date" gorm:"not null"`
	EndDate        time.Time `json:"end_date" gorm:"not null"`
	AlertThreshold float64   `json:"alert_threshold" gorm:"type:decimal(5,2);default:80.00"`
	Status         string    `json:"status" gorm:"default:'active'"` // active, paused, expired
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

// 成本分析实体
type CostAnalysis struct {
	ID          string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	ProjectID   string    `json:"project_id" gorm:"not null;index"`
	TenantID    string    `json:"tenant_id" gorm:"not null;index"`
	AnalysisType string   `json:"analysis_type" gorm:"not null"` // summary, trend, breakdown, comparison
	Period      string    `json:"period" gorm:"not null"` // daily, weekly, monthly, yearly
	Data        string    `json:"data" gorm:"type:jsonb"` // Analysis results in JSON
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 计费规则实体
type BillingRule struct {
	ID          string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	ProjectID   string    `json:"project_id" gorm:"not null;index"`
	TenantID    string    `json:"tenant_id" gorm:"not null;index"`
	Name        string    `json:"name" gorm:"not null"`
	RuleType    string    `json:"rule_type" gorm:"not null"` // per_request, per_hour, per_gb, etc.
	Rate        float64   `json:"rate" gorm:"type:decimal(15,4);not null"`
	Currency    string    `json:"currency" gorm:"default:'USD'"`
	IsActive    bool      `json:"is_active" gorm:"default:true"`
	Metadata    string    `json:"metadata" gorm:"type:jsonb"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 成本优化建议实体
type CostOptimization struct {
	ID          string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	ProjectID   string    `json:"project_id" gorm:"not null;index"`
	TenantID    string    `json:"tenant_id" gorm:"not null;index"`
	Title       string    `json:"title" gorm:"not null"`
	Description string    `json:"description"`
	Category    string    `json:"category" gorm:"not null"` // resource, model, infrastructure
	Priority    string    `json:"priority" gorm:"not null"` // low, medium, high, critical
	PotentialSavings float64 `json:"potential_savings" gorm:"type:decimal(15,4)"`
	Currency    string    `json:"currency" gorm:"default:'USD'"`
	Status      string    `json:"status" gorm:"default:'pending'"` // pending, applied, rejected
	Metadata    string    `json:"metadata" gorm:"type:jsonb"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 成本记录创建请求
type CreateCostRecordRequest struct {
	ProjectID   string  `json:"project_id" binding:"required"`
	ModelID     *string `json:"model_id,omitempty"`
	CostType    string  `json:"cost_type" binding:"required"`
	Amount      float64 `json:"amount" binding:"required,gt=0"`
	Currency    string  `json:"currency"`
	Description string  `json:"description"`
	Metadata    string  `json:"metadata"`
}

// 预算创建请求
type CreateBudgetRequest struct {
	ProjectID      string    `json:"project_id" binding:"required"`
	Name           string    `json:"name" binding:"required"`
	Amount         float64   `json:"amount" binding:"required,gt=0"`
	Currency       string    `json:"currency"`
	Period         string    `json:"period" binding:"required"`
	StartDate      time.Time `json:"start_date" binding:"required"`
	EndDate        time.Time `json:"end_date" binding:"required"`
	AlertThreshold float64   `json:"alert_threshold"`
}

// 成本分析请求
type CostAnalysisRequest struct {
	ProjectID     string `json:"project_id" binding:"required"`
	AnalysisType  string `json:"analysis_type" binding:"required"`
	Period        string `json:"period" binding:"required"`
	StartDate     *time.Time `json:"start_date,omitempty"`
	EndDate       *time.Time `json:"end_date,omitempty"`
	GroupBy       string `json:"group_by,omitempty"` // cost_type, model_id, user_id
	Filters       string `json:"filters,omitempty"` // JSON filters
}

// 成本记录响应
type CostRecordResponse struct {
	ID          string    `json:"id"`
	ProjectID   string    `json:"project_id"`
	ModelID     *string   `json:"model_id,omitempty"`
	UserID      string    `json:"user_id"`
	TenantID    string    `json:"tenant_id"`
	CostType    string    `json:"cost_type"`
	Amount      float64   `json:"amount"`
	Currency    string    `json:"currency"`
	Description string    `json:"description"`
	Metadata    string    `json:"metadata"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 预算响应
type BudgetResponse struct {
	ID             string    `json:"id"`
	ProjectID      string    `json:"project_id"`
	Name           string    `json:"name"`
	Amount         float64   `json:"amount"`
	Currency       string    `json:"currency"`
	Period         string    `json:"period"`
	StartDate      time.Time `json:"start_date"`
	EndDate        time.Time `json:"end_date"`
	AlertThreshold float64   `json:"alert_threshold"`
	Status         string    `json:"status"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

// 成本分析响应
type CostAnalysisResponse struct {
	ID           string    `json:"id"`
	ProjectID    string    `json:"project_id"`
	TenantID     string    `json:"tenant_id"`
	AnalysisType string    `json:"analysis_type"`
	Period       string    `json:"period"`
	Data         string    `json:"data"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// 成本优化建议响应
type CostOptimizationResponse struct {
	ID               string    `json:"id"`
	ProjectID        string    `json:"project_id"`
	TenantID         string    `json:"tenant_id"`
	Title            string    `json:"title"`
	Description      string    `json:"description"`
	Category         string    `json:"category"`
	Priority         string    `json:"priority"`
	PotentialSavings float64   `json:"potential_savings"`
	Currency         string    `json:"currency"`
	Status           string    `json:"status"`
	Metadata         string    `json:"metadata"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}