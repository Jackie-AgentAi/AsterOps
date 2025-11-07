package config

import (
	"os"
	"strconv"
	"strings"

	"github.com/spf13/viper"
)

type Config struct {
	// 应用配置
	AppName    string
	AppVersion string
	Debug      bool
	Port       string

	// 数据库配置
	DatabaseURL string

	// Redis配置
	RedisURL string

	// JWT配置
	SecretKey     string
	TokenExpire   int

	// CORS配置
	AllowedOrigins []string
	AllowedMethods []string
	AllowedHeaders []string

	// 日志配置
	LogLevel  string
	LogFormat string

	// 服务发现配置
	ConsulHost string
	ConsulPort int
	ServiceName string
	ServiceID   string
	ServiceTags []string

	// 成本配置
	DefaultCurrency string
	CostPrecision   int
	BudgetAlertThreshold float64

	// 监控配置
	MetricsEnabled bool
	MetricsPath    string
}

func Load() *Config {
	// 设置配置文件
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./configs")
	viper.AddConfigPath(".")

	// 设置环境变量前缀
	viper.SetEnvPrefix("COST")
	viper.AutomaticEnv()

	// 设置默认值
	viper.SetDefault("app.name", "Cost Service")
	viper.SetDefault("app.version", "1.0.0")
	viper.SetDefault("app.debug", false)
	viper.SetDefault("app.port", "8085")

	viper.SetDefault("database.url", "postgresql://user:password@localhost:5432/cost_db")

	viper.SetDefault("redis.url", "redis://localhost:6379/0")

	viper.SetDefault("jwt.secret_key", "your-secret-key-change-in-production")
	viper.SetDefault("jwt.token_expire", 30)

	viper.SetDefault("cors.allowed_origins", []string{"*"})
	viper.SetDefault("cors.allowed_methods", []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"})
	viper.SetDefault("cors.allowed_headers", []string{"*"})

	viper.SetDefault("log.level", "info")
	viper.SetDefault("log.format", "json")

	viper.SetDefault("consul.host", "localhost")
	viper.SetDefault("consul.port", 8500)
	viper.SetDefault("consul.service_name", "github.com/llmops/cost-service")
	viper.SetDefault("consul.service_id", "github.com/llmops/cost-service-1")
	viper.SetDefault("consul.service_tags", []string{"cost", "billing", "api"})

	viper.SetDefault("cost.default_currency", "USD")
	viper.SetDefault("cost.precision", 4)
	viper.SetDefault("cost.budget_alert_threshold", 80.0)

	viper.SetDefault("metrics.enabled", true)
	viper.SetDefault("metrics.path", "/metrics")

	// 读取配置文件
	if err := viper.ReadInConfig(); err != nil {
		// 配置文件不存在时使用默认值
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			panic(err)
		}
	}

	// 解析配置
	config := &Config{
		AppName:    viper.GetString("app.name"),
		AppVersion: viper.GetString("app.version"),
		Debug:      viper.GetBool("app.debug"),
		Port:       viper.GetString("app.port"),

		DatabaseURL: viper.GetString("database.url"),

		RedisURL: viper.GetString("redis.url"),

		SecretKey:   viper.GetString("jwt.secret_key"),
		TokenExpire: viper.GetInt("jwt.token_expire"),

		AllowedOrigins: viper.GetStringSlice("cors.allowed_origins"),
		AllowedMethods: viper.GetStringSlice("cors.allowed_methods"),
		AllowedHeaders: viper.GetStringSlice("cors.allowed_headers"),

		LogLevel:  viper.GetString("log.level"),
		LogFormat: viper.GetString("log.format"),

		ConsulHost:    viper.GetString("consul.host"),
		ConsulPort:    viper.GetInt("consul.port"),
		ServiceName:   viper.GetString("consul.service_name"),
		ServiceID:     viper.GetString("consul.service_id"),
		ServiceTags:   viper.GetStringSlice("consul.service_tags"),

		DefaultCurrency:     viper.GetString("cost.default_currency"),
		CostPrecision:       viper.GetInt("cost.precision"),
		BudgetAlertThreshold: viper.GetFloat64("cost.budget_alert_threshold"),

		MetricsEnabled: viper.GetBool("metrics.enabled"),
		MetricsPath:    viper.GetString("metrics.path"),
	}

	// 从环境变量覆盖配置
	if appName := os.Getenv("APP_NAME"); appName != "" {
		config.AppName = appName
	}
	if appVersion := os.Getenv("APP_VERSION"); appVersion != "" {
		config.AppVersion = appVersion
	}
	if debug := os.Getenv("DEBUG"); debug != "" {
		if parsed, err := strconv.ParseBool(debug); err == nil {
			config.Debug = parsed
		}
	}
	if port := os.Getenv("PORT"); port != "" {
		config.Port = port
	}

	if databaseURL := os.Getenv("DATABASE_URL"); databaseURL != "" {
		config.DatabaseURL = databaseURL
	}
	if redisURL := os.Getenv("REDIS_URL"); redisURL != "" {
		config.RedisURL = redisURL
	}

	if secretKey := os.Getenv("SECRET_KEY"); secretKey != "" {
		config.SecretKey = secretKey
	}
	if tokenExpire := os.Getenv("TOKEN_EXPIRE"); tokenExpire != "" {
		if parsed, err := strconv.Atoi(tokenExpire); err == nil {
			config.TokenExpire = parsed
		}
	}

	if allowedOrigins := os.Getenv("ALLOWED_ORIGINS"); allowedOrigins != "" {
		config.AllowedOrigins = strings.Split(allowedOrigins, ",")
	}
	if allowedMethods := os.Getenv("ALLOWED_METHODS"); allowedMethods != "" {
		config.AllowedMethods = strings.Split(allowedMethods, ",")
	}
	if allowedHeaders := os.Getenv("ALLOWED_HEADERS"); allowedHeaders != "" {
		config.AllowedHeaders = strings.Split(allowedHeaders, ",")
	}

	if logLevel := os.Getenv("LOG_LEVEL"); logLevel != "" {
		config.LogLevel = logLevel
	}
	if logFormat := os.Getenv("LOG_FORMAT"); logFormat != "" {
		config.LogFormat = logFormat
	}

	if consulHost := os.Getenv("CONSUL_HOST"); consulHost != "" {
		config.ConsulHost = consulHost
	}
	if consulPort := os.Getenv("CONSUL_PORT"); consulPort != "" {
		if parsed, err := strconv.Atoi(consulPort); err == nil {
			config.ConsulPort = parsed
		}
	}
	if serviceName := os.Getenv("SERVICE_NAME"); serviceName != "" {
		config.ServiceName = serviceName
	}
	if serviceID := os.Getenv("SERVICE_ID"); serviceID != "" {
		config.ServiceID = serviceID
	}
	if serviceTags := os.Getenv("SERVICE_TAGS"); serviceTags != "" {
		config.ServiceTags = strings.Split(serviceTags, ",")
	}

	if defaultCurrency := os.Getenv("DEFAULT_CURRENCY"); defaultCurrency != "" {
		config.DefaultCurrency = defaultCurrency
	}
	if costPrecision := os.Getenv("COST_PRECISION"); costPrecision != "" {
		if parsed, err := strconv.Atoi(costPrecision); err == nil {
			config.CostPrecision = parsed
		}
	}
	if budgetAlertThreshold := os.Getenv("BUDGET_ALERT_THRESHOLD"); budgetAlertThreshold != "" {
		if parsed, err := strconv.ParseFloat(budgetAlertThreshold, 64); err == nil {
			config.BudgetAlertThreshold = parsed
		}
	}

	if metricsEnabled := os.Getenv("METRICS_ENABLED"); metricsEnabled != "" {
		if parsed, err := strconv.ParseBool(metricsEnabled); err == nil {
			config.MetricsEnabled = parsed
		}
	}
	if metricsPath := os.Getenv("METRICS_PATH"); metricsPath != "" {
		config.MetricsPath = metricsPath
	}

	return config
}



