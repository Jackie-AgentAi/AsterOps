package entity

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Project 项目实体
type Project struct {
	ID          uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	Name        string    `json:"name" gorm:"size:255;not null"`
	Description string    `json:"description" gorm:"type:text"`
	Status      string    `json:"status" gorm:"size:50;default:'active'"`
	OwnerID     uuid.UUID `json:"owner_id" gorm:"type:uuid;not null"`
	TenantID    uuid.UUID `json:"tenant_id" gorm:"type:uuid;not null"`
	
	// 资源配额
	QuotaCPULimit      int64 `json:"quota_cpu_limit" gorm:"default:0"`
	QuotaMemoryLimit   int64 `json:"quota_memory_limit" gorm:"default:0"`
	QuotaGPULimit      int64 `json:"quota_gpu_limit" gorm:"default:0"`
	QuotaStorageLimit  int64 `json:"quota_storage_limit" gorm:"default:0"`
	QuotaBandwidthLimit int64 `json:"quota_bandwidth_limit" gorm:"default:0"`
	
	// 当前使用量
	CurrentCPUUsage      int64 `json:"current_cpu_usage" gorm:"default:0"`
	CurrentMemoryUsage   int64 `json:"current_memory_usage" gorm:"default:0"`
	CurrentGPUUsage      int64 `json:"current_gpu_usage" gorm:"default:0"`
	CurrentStorageUsage  int64 `json:"current_storage_usage" gorm:"default:0"`
	CurrentBandwidthUsage int64 `json:"current_bandwidth_usage" gorm:"default:0"`
	
	// 项目设置
	Settings map[string]interface{} `json:"settings" gorm:"type:jsonb;serializer:json"`
	
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"deleted_at" gorm:"index"`
	
	// 关联关系
	Members   []ProjectMember       `json:"members" gorm:"foreignKey:ProjectID"`
	Resources []ProjectResourceQuota `json:"resources" gorm:"foreignKey:ProjectID"`
	Activities []ProjectActivity     `json:"activities" gorm:"foreignKey:ProjectID"`
}

// ProjectMember 项目成员实体
type ProjectMember struct {
	ID         uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	ProjectID  uuid.UUID `json:"project_id" gorm:"type:uuid;not null"`
	UserID     uuid.UUID `json:"user_id" gorm:"type:uuid;not null"`
	Role       string    `json:"role" gorm:"size:50;not null"`
	Status     string    `json:"status" gorm:"size:50;default:'active'"`
	Permissions []string `json:"permissions" gorm:"type:text[]"`
	
	// 邀请信息
	InvitedBy   *uuid.UUID `json:"invited_by" gorm:"type:uuid"`
	InvitedAt   *time.Time `json:"invited_at"`
	AcceptedAt  *time.Time `json:"accepted_at"`
	ExpiresAt   *time.Time `json:"expires_at"`
	
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"deleted_at" gorm:"index"`
	
	// 关联关系
	Project Project `json:"project" gorm:"foreignKey:ProjectID"`
	User    User    `json:"user" gorm:"foreignKey:UserID"`
}

// ProjectResourceQuota 项目资源配额实体
type ProjectResourceQuota struct {
	ID         uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	ProjectID  uuid.UUID `json:"project_id" gorm:"type:uuid;not null"`
	ResourceType string  `json:"resource_type" gorm:"size:50;not null"`
	ResourceName string  `json:"resource_name" gorm:"size:255;not null"`
	Limit      int64     `json:"limit" gorm:"not null"`
	Used       int64     `json:"used" gorm:"default:0"`
	Unit       string    `json:"unit" gorm:"size:20"`
	
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"deleted_at" gorm:"index"`
	
	// 关联关系
	Project Project `json:"project" gorm:"foreignKey:ProjectID"`
}

// ProjectTemplate 项目模板实体
type ProjectTemplate struct {
	ID          uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	Name        string    `json:"name" gorm:"size:255;not null"`
	Description string    `json:"description" gorm:"type:text"`
	Category    string    `json:"category" gorm:"size:100"`
	Tags        []string  `json:"tags" gorm:"type:text[]"`
	IsPublic    bool      `json:"is_public" gorm:"default:false"`
	OwnerID     uuid.UUID `json:"owner_id" gorm:"type:uuid;not null"`
	TenantID    uuid.UUID `json:"tenant_id" gorm:"type:uuid;not null"`
	
	// 模板配置
	TemplateConfig map[string]interface{} `json:"template_config" gorm:"type:jsonb;serializer:json"`
	
	// 使用统计
	UsageCount int64 `json:"usage_count" gorm:"default:0"`
	
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"deleted_at" gorm:"index"`
}

// ProjectActivity 项目活动日志实体
type ProjectActivity struct {
	ID        uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	ProjectID uuid.UUID `json:"project_id" gorm:"type:uuid;not null"`
	UserID    uuid.UUID `json:"user_id" gorm:"type:uuid;not null"`
	Action    string    `json:"action" gorm:"size:100;not null"`
	Resource  string    `json:"resource" gorm:"size:100"`
	Details   string    `json:"details" gorm:"type:text"`
	IPAddress string    `json:"ip_address" gorm:"size:45"`
	UserAgent string    `json:"user_agent" gorm:"size:500"`
	
	CreatedAt time.Time `json:"created_at"`
	
	// 关联关系
	Project Project `json:"project" gorm:"foreignKey:ProjectID"`
	User    User    `json:"user" gorm:"foreignKey:UserID"`
}

// User 用户实体 (简化版，用于关联)
type User struct {
	ID       uuid.UUID `json:"id" gorm:"type:uuid;primary_key"`
	Username string    `json:"username" gorm:"size:100"`
	Email    string    `json:"email" gorm:"size:255"`
	Name     string    `json:"name" gorm:"size:255"`
}

// TableName 指定表名
func (Project) TableName() string {
	return "projects"
}

func (ProjectMember) TableName() string {
	return "project_members"
}

func (ProjectResourceQuota) TableName() string {
	return "project_resource_quotas"
}

func (ProjectTemplate) TableName() string {
	return "project_templates"
}

func (ProjectActivity) TableName() string {
	return "project_activities"
}

func (User) TableName() string {
	return "users"
}


