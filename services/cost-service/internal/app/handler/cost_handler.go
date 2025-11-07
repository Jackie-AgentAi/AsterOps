package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/llmops/cost-service/internal/domain/entity"
	"github.com/llmops/cost-service/internal/domain/service"
	"github.com/sirupsen/logrus"
)

// 成本处理器
type CostHandler struct {
	costService *service.CostService
	logger      *logrus.Logger
}

// 创建成本处理器
func NewCostHandler(costService *service.CostService, logger *logrus.Logger) *CostHandler {
	return &CostHandler{
		costService: costService,
		logger:      logger,
	}
}

// 创建成本记录
func (h *CostHandler) CreateCostRecord(c *gin.Context) {
	var req entity.CreateCostRecordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": err.Error(),
		})
		return
	}

	// 从上下文获取用户信息
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "unauthorized",
			"message": "User not authenticated",
		})
		return
	}

	tenantID, exists := c.Get("tenant_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "unauthorized",
			"message": "Tenant not identified",
		})
		return
	}

	response, err := h.costService.CreateCostRecord(c.Request.Context(), &req, userID.(string), tenantID.(string))
	if err != nil {
		h.logger.WithError(err).Error("Failed to create cost record")
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "internal_error",
			"message": "Failed to create cost record",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    response,
	})
}

// 获取成本记录
func (h *CostHandler) GetCostRecord(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "Cost record ID is required",
		})
		return
	}

	response, err := h.costService.GetCostRecord(c.Request.Context(), id)
	if err != nil {
		h.logger.WithError(err).WithField("cost_id", id).Error("Failed to get cost record")
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "not_found",
			"message": "Cost record not found",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}

// 获取成本记录列表
func (h *CostHandler) GetCostRecords(c *gin.Context) {
	// 获取查询参数
	projectID := c.Query("project_id")
	userID := c.Query("user_id")
	tenantID := c.Query("tenant_id")
	
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	// 验证参数
	if projectID == "" && userID == "" && tenantID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "project_id, user_id, or tenant_id must be provided",
		})
		return
	}

	// 从上下文获取用户信息（如果未提供）
	if userID == "" {
		if uid, exists := c.Get("user_id"); exists {
			userID = uid.(string)
		}
	}
	if tenantID == "" {
		if tid, exists := c.Get("tenant_id"); exists {
			tenantID = tid.(string)
		}
	}

	responses, total, err := h.costService.GetCostRecords(c.Request.Context(), projectID, userID, tenantID, offset, limit)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get cost records")
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "internal_error",
			"message": "Failed to get cost records",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"costs":  responses,
			"total":  total,
			"offset": offset,
			"limit":  limit,
		},
	})
}

// 更新成本记录
func (h *CostHandler) UpdateCostRecord(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "Cost record ID is required",
		})
		return
	}

	var req entity.CreateCostRecordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": err.Error(),
		})
		return
	}

	response, err := h.costService.UpdateCostRecord(c.Request.Context(), id, &req)
	if err != nil {
		h.logger.WithError(err).WithField("cost_id", id).Error("Failed to update cost record")
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "internal_error",
			"message": "Failed to update cost record",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}

// 删除成本记录
func (h *CostHandler) DeleteCostRecord(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "Cost record ID is required",
		})
		return
	}

	err := h.costService.DeleteCostRecord(c.Request.Context(), id)
	if err != nil {
		h.logger.WithError(err).WithField("cost_id", id).Error("Failed to delete cost record")
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "internal_error",
			"message": "Failed to delete cost record",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Cost record deleted successfully",
	})
}

// 获取成本汇总
func (h *CostHandler) GetCostSummary(c *gin.Context) {
	projectID := c.Query("project_id")
	tenantID := c.Query("tenant_id")

	if projectID == "" && tenantID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "project_id or tenant_id must be provided",
		})
		return
	}

	// 从上下文获取租户信息（如果未提供）
	if tenantID == "" {
		if tid, exists := c.Get("tenant_id"); exists {
			tenantID = tid.(string)
		}
	}

	summary, err := h.costService.GetCostSummary(c.Request.Context(), projectID, tenantID)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get cost summary")
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "internal_error",
			"message": "Failed to get cost summary",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    summary,
	})
}

// 生成成本分析
func (h *CostHandler) GenerateCostAnalysis(c *gin.Context) {
	var req entity.CostAnalysisRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": err.Error(),
		})
		return
	}

	response, err := h.costService.GenerateCostAnalysis(c.Request.Context(), &req)
	if err != nil {
		h.logger.WithError(err).Error("Failed to generate cost analysis")
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "internal_error",
			"message": "Failed to generate cost analysis",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}

// 获取成本分析
func (h *CostHandler) GetCostAnalysis(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "Analysis ID is required",
		})
		return
	}

	// 这里应该调用分析服务获取分析结果
	// 为了简化，直接返回模拟数据
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"id":           id,
			"analysis_type": "summary",
			"period":       "monthly",
			"data": gin.H{
				"total_cost":    1000.0,
				"cost_by_type":  gin.H{"inference": 500, "training": 300, "storage": 200},
				"currency":      "USD",
				"generated_at":  "2024-01-01T00:00:00Z",
			},
		},
	})
}