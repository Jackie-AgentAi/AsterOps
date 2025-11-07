package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/llmops/cost-service/internal/domain/entity"
	"github.com/llmops/cost-service/internal/domain/service"
	"github.com/llmops/cost-service/internal/pkg/response"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type BudgetHandler struct {
	budgetService service.BudgetService
}

func NewBudgetHandler(budgetService service.BudgetService) *BudgetHandler {
	return &BudgetHandler{
		budgetService: budgetService,
	}
}

// CreateBudget creates a new budget
func (h *BudgetHandler) CreateBudget(c *gin.Context) {
	var budget entity.Budget
	if err := c.ShouldBindJSON(&budget); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	if err := h.budgetService.CreateBudget(c.Request.Context(), &budget); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to create budget", err.Error())
		return
	}

	response.Success(c, http.StatusCreated, "Budget created successfully", budget)
}

// GetBudgetByID gets a budget by ID
func (h *BudgetHandler) GetBudgetByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid budget ID", err.Error())
		return
	}

	budget, err := h.budgetService.GetBudgetByID(c.Request.Context(), id)
	if err != nil {
		response.Error(c, http.StatusNotFound, "Budget not found", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Budget retrieved successfully", budget)
}

// UpdateBudget updates a budget
func (h *BudgetHandler) UpdateBudget(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid budget ID", err.Error())
		return
	}

	var budget entity.Budget
	if err := c.ShouldBindJSON(&budget); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	budget.ID = id
	if err := h.budgetService.UpdateBudget(c.Request.Context(), &budget); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to update budget", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Budget updated successfully", budget)
}

// DeleteBudget deletes a budget
func (h *BudgetHandler) DeleteBudget(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid budget ID", err.Error())
		return
	}

	if err := h.budgetService.DeleteBudget(c.Request.Context(), id); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to delete budget", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Budget deleted successfully", nil)
}

// ListBudgets lists budgets
func (h *BudgetHandler) ListBudgets(c *gin.Context) {
	projectIDStr := c.Query("project_id")
	offsetStr := c.DefaultQuery("offset", "0")
	limitStr := c.DefaultQuery("limit", "20")

	offset, err := strconv.Atoi(offsetStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid offset", err.Error())
		return
	}

	limit, err := strconv.Atoi(limitStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid limit", err.Error())
		return
	}

	tenantID, _ := c.Get("tenant_id")
	var projectID uuid.UUID
	if projectIDStr != "" {
		projectID, err = uuid.Parse(projectIDStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid project ID", err.Error())
			return
		}
	}

	budgets, total, err := h.budgetService.ListBudgets(c.Request.Context(), projectID, tenantID.(uuid.UUID), offset, limit)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to list budgets", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Budgets retrieved successfully", gin.H{
		"budgets": budgets,
		"total":   total,
		"offset":  offset,
		"limit":   limit,
	})
}

// GetBudgetsByProject gets budgets by project
func (h *BudgetHandler) GetBudgetsByProject(c *gin.Context) {
	projectIDStr := c.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid project ID", err.Error())
		return
	}

	tenantID, _ := c.Get("tenant_id")
	budgets, err := h.budgetService.GetBudgetsByProject(c.Request.Context(), projectID, tenantID.(uuid.UUID))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to get budgets by project", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Budgets retrieved successfully", budgets)
}

// GetActiveBudgets gets active budgets
func (h *BudgetHandler) GetActiveBudgets(c *gin.Context) {
	projectIDStr := c.Query("project_id")
	tenantID, _ := c.Get("tenant_id")
	
	var projectID uuid.UUID
	if projectIDStr != "" {
		var err error
		projectID, err = uuid.Parse(projectIDStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid project ID", err.Error())
			return
		}
	}

	budgets, err := h.budgetService.GetActiveBudgets(c.Request.Context(), projectID, tenantID.(uuid.UUID))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to get active budgets", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Active budgets retrieved successfully", budgets)
}

// GetBudgetsByPeriod gets budgets by period
func (h *BudgetHandler) GetBudgetsByPeriod(c *gin.Context) {
	projectIDStr := c.Query("project_id")
	period := c.Query("period")
	
	if period == "" {
		response.Error(c, http.StatusBadRequest, "Period is required", "period parameter is missing")
		return
	}

	tenantID, _ := c.Get("tenant_id")
	var projectID uuid.UUID
	if projectIDStr != "" {
		var err error
		projectID, err = uuid.Parse(projectIDStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid project ID", err.Error())
			return
		}
	}

	budgets, err := h.budgetService.GetBudgetsByPeriod(c.Request.Context(), projectID, tenantID.(uuid.UUID), period)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to get budgets by period", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Budgets retrieved successfully", budgets)
}

// GetBudgetUsage gets budget usage
func (h *BudgetHandler) GetBudgetUsage(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid budget ID", err.Error())
		return
	}

	usage, err := h.budgetService.GetBudgetUsage(c.Request.Context(), id)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to get budget usage", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Budget usage retrieved successfully", gin.H{
		"budget_id": id,
		"usage":     usage,
	})
}

// GetBudgetUsagePercentage gets budget usage percentage
func (h *BudgetHandler) GetBudgetUsagePercentage(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid budget ID", err.Error())
		return
	}

	percentage, err := h.budgetService.GetBudgetUsagePercentage(c.Request.Context(), id)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to get budget usage percentage", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Budget usage percentage retrieved successfully", gin.H{
		"budget_id":  id,
		"percentage": percentage,
	})
}

// CheckBudgetAlerts checks budget alerts
func (h *BudgetHandler) CheckBudgetAlerts(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid budget ID", err.Error())
		return
	}

	alert, err := h.budgetService.CheckBudgetAlerts(c.Request.Context(), id)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to check budget alerts", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Budget alerts checked successfully", alert)
}

// GetBudgetAlerts gets budget alerts
func (h *BudgetHandler) GetBudgetAlerts(c *gin.Context) {
	projectIDStr := c.Query("project_id")
	tenantID, _ := c.Get("tenant_id")
	
	var projectID uuid.UUID
	if projectIDStr != "" {
		var err error
		projectID, err = uuid.Parse(projectIDStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Invalid project ID", err.Error())
			return
		}
	}

	alerts, err := h.budgetService.GetBudgetAlerts(c.Request.Context(), projectID, tenantID.(uuid.UUID))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to get budget alerts", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Budget alerts retrieved successfully", alerts)
}

// SetBudgetAlert sets budget alert threshold
func (h *BudgetHandler) SetBudgetAlert(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid budget ID", err.Error())
		return
	}

	var request struct {
		Threshold float64 `json:"threshold" binding:"required,min=0,max=100"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	if err := h.budgetService.SetBudgetAlert(c.Request.Context(), id, request.Threshold); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to set budget alert", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Budget alert set successfully", gin.H{
		"budget_id": id,
		"threshold": request.Threshold,
	})
}



