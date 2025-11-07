package validator

import (
	"regexp"
	"strings"
)

// Validator 验证器
type Validator struct{}

// NewValidator 创建新的验证器
func NewValidator() *Validator {
	return &Validator{}
}

// ValidateEmail 验证邮箱格式
func (v *Validator) ValidateEmail(email string) bool {
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	return emailRegex.MatchString(email)
}

// ValidatePassword 验证密码强度
func (v *Validator) ValidatePassword(password string) bool {
	// 密码长度至少8位
	if len(password) < 8 {
		return false
	}
	
	// 包含至少一个大写字母
	hasUpper := regexp.MustCompile(`[A-Z]`).MatchString(password)
	// 包含至少一个小写字母
	hasLower := regexp.MustCompile(`[a-z]`).MatchString(password)
	// 包含至少一个数字
	hasNumber := regexp.MustCompile(`[0-9]`).MatchString(password)
	
	return hasUpper && hasLower && hasNumber
}

// ValidateUsername 验证用户名格式
func (v *Validator) ValidateUsername(username string) bool {
	// 用户名长度3-20位，只能包含字母、数字、下划线
	if len(username) < 3 || len(username) > 20 {
		return false
	}
	
	usernameRegex := regexp.MustCompile(`^[a-zA-Z0-9_]+$`)
	return usernameRegex.MatchString(username)
}

// ValidatePhone 验证手机号格式
func (v *Validator) ValidatePhone(phone string) bool {
	// 简单的手机号验证，11位数字
	phoneRegex := regexp.MustCompile(`^1[3-9]\d{9}$`)
	return phoneRegex.MatchString(phone)
}

// ValidateRequired 验证必填字段
func (v *Validator) ValidateRequired(value string) bool {
	return strings.TrimSpace(value) != ""
}

// ValidateLength 验证字符串长度
func (v *Validator) ValidateLength(value string, min, max int) bool {
	length := len(strings.TrimSpace(value))
	return length >= min && length <= max
}

// ValidateStruct 验证结构体（简化实现）
func (v *Validator) ValidateStruct(s interface{}) error {
	// 简化的结构体验证实现
	// 实际应该使用更复杂的验证库如go-playground/validator
	return nil
}

