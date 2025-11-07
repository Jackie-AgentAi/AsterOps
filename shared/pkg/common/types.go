package common

import (
	"time"
	"github.com/google/uuid"
)

// 通用响应结构
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

// 分页结构
type Pagination struct {
	Offset int `json:"offset"`
	Limit  int `json:"limit"`
	Total  int `json:"total"`
}

// 分页响应
type PaginatedResponse struct {
	Data       interface{} `json:"data"`
	Pagination Pagination  `json:"pagination"`
}

// 用户信息
type User struct {
	ID       uuid.UUID `json:"id"`
	Username string    `json:"username"`
	Email    string    `json:"email"`
	TenantID uuid.UUID `json:"tenant_id"`
	IsActive bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// 租户信息
type Tenant struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	Domain    string    `json:"domain"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// 项目信息
type Project struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	OwnerID     uuid.UUID `json:"owner_id"`
	TenantID    uuid.UUID `json:"tenant_id"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 模型信息
type Model struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Framework   string    `json:"framework"`
	TaskType    string    `json:"task_type"`
	OwnerID     uuid.UUID `json:"owner_id"`
	TenantID    uuid.UUID `json:"tenant_id"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 成本信息
type Cost struct {
	ID          uuid.UUID `json:"id"`
	ProjectID   uuid.UUID `json:"project_id"`
	ModelID     uuid.UUID `json:"model_id"`
	UserID      uuid.UUID `json:"user_id"`
	TenantID    uuid.UUID `json:"tenant_id"`
	CostType    string    `json:"cost_type"`
	Amount      float64   `json:"amount"`
	Currency    string    `json:"currency"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 监控指标
type Metric struct {
	ID          uuid.UUID              `json:"id"`
	ServiceID   string                 `json:"service_id"`
	MetricName  string                 `json:"metric_name"`
	MetricValue float64                `json:"metric_value"`
	MetricUnit  string                 `json:"metric_unit"`
	Labels      map[string]interface{} `json:"labels"`
	Timestamp   time.Time              `json:"timestamp"`
}

// 告警信息
type Alert struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	ServiceID   string    `json:"service_id"`
	MetricName  string    `json:"metric_name"`
	Threshold   float64   `json:"threshold"`
	Operator    string    `json:"operator"`
	Severity    string    `json:"severity"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// 服务健康状态
type ServiceHealth struct {
	ID          uuid.UUID              `json:"id"`
	ServiceID   string                 `json:"service_id"`
	ServiceName string                 `json:"service_name"`
	Status      string                 `json:"status"`
	LastCheck   time.Time              `json:"last_check"`
	ResponseTime float64               `json:"response_time"`
	ErrorMessage string                `json:"error_message"`
	Metadata    map[string]interface{} `json:"metadata"`
	CreatedAt   time.Time              `json:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at"`
}

// 错误类型
type ErrorType string

const (
	ErrorTypeValidation   ErrorType = "VALIDATION_ERROR"
	ErrorTypeNotFound     ErrorType = "NOT_FOUND"
	ErrorTypeUnauthorized ErrorType = "UNAUTHORIZED"
	ErrorTypeForbidden    ErrorType = "FORBIDDEN"
	ErrorTypeInternal     ErrorType = "INTERNAL_ERROR"
	ErrorTypeTimeout      ErrorType = "TIMEOUT"
	ErrorTypeRateLimit    ErrorType = "RATE_LIMIT"
)

// 错误响应
type ErrorResponse struct {
	Type    ErrorType `json:"type"`
	Message string    `json:"message"`
	Details string    `json:"details,omitempty"`
}

// 成功响应
func SuccessResponse(data interface{}) Response {
	return Response{
		Code:    200,
		Message: "success",
		Data:    data,
	}
}

// 错误响应
func ErrorResponse(code int, message string, err error) Response {
	response := Response{
		Code:    code,
		Message: message,
	}
	if err != nil {
		response.Error = err.Error()
	}
	return response
}

// 分页响应
func PaginatedSuccessResponse(data interface{}, pagination Pagination) PaginatedResponse {
	return PaginatedResponse{
		Data:       data,
		Pagination: pagination,
	}
}



