package config

import (
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/spf13/viper"
)

// ServerConfig 服务器配置
type ServerConfig struct {
	Port  int    `yaml:"port"`
	Debug bool   `yaml:"debug"`
	Name  string `yaml:"name"`
}

// DatabaseConfig 数据库配置
type DatabaseConfig struct {
	Host            string        `yaml:"host"`
	Port            int           `yaml:"port"`
	User            string        `yaml:"user"`
	Password        string        `yaml:"password"`
	DBName          string        `yaml:"dbname"`
	SSLMode         string        `yaml:"sslmode"`
	MaxOpenConns    int           `yaml:"max_open_conns"`
	MaxIdleConns    int           `yaml:"max_idle_conns"`
	ConnMaxLifetime time.Duration `yaml:"conn_max_lifetime"`
	ConnMaxIdleTime time.Duration `yaml:"conn_max_idle_time"`
}

// RedisConfig Redis配置
type RedisConfig struct {
	Addr     string `yaml:"addr"`
	Password string `yaml:"password"`
	DB       int    `yaml:"db"`
}

// JWTConfig JWT配置
type JWTConfig struct {
	Secret        string        `yaml:"secret"`
	TokenExpiry   time.Duration `yaml:"token_expiry"`
	RefreshExpiry time.Duration `yaml:"refresh_expiry"`
}

// LogConfig 日志配置
type LogConfig struct {
	Level      string `yaml:"level"`
	Format     string `yaml:"format"`
	Output     string `yaml:"output"`
	FilePath   string `yaml:"file_path"`
	MaxSize    int    `yaml:"max_size"`
	MaxBackups int    `yaml:"max_backups"`
	MaxAge     int    `yaml:"max_age"`
}

// ConsulConfig Consul配置
type ConsulConfig struct {
	Host          string        `yaml:"host"`
	Port          int           `yaml:"port"`
	ServiceName   string        `yaml:"service_name"`
	ServiceID     string        `yaml:"service_id"`
	ServiceTags   []string      `yaml:"service_tags"`
	CheckInterval time.Duration `yaml:"check_interval"`
	CheckTimeout  time.Duration `yaml:"check_timeout"`
}

// Config 主配置结构
type Config struct {
	Server   ServerConfig   `yaml:"server"`
	Database DatabaseConfig `yaml:"database"`
	Redis    RedisConfig    `yaml:"redis"`
	JWT      JWTConfig      `yaml:"jwt"`
	Log      LogConfig      `yaml:"log"`
	Consul   ConsulConfig   `yaml:"consul"`
}

// LoadConfig 加载配置
func LoadConfig() (*Config, error) {
	// 设置配置文件
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./configs")
	viper.AddConfigPath(".")

	// 设置环境变量前缀
	viper.SetEnvPrefix("USER")
	viper.AutomaticEnv()

	// 设置默认值
	viper.SetDefault("server.port", 8081)
	viper.SetDefault("server.debug", false)
	viper.SetDefault("server.name", "user-service")

	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", 5432)
	viper.SetDefault("database.user", "user")
	viper.SetDefault("database.password", "password")
	viper.SetDefault("database.dbname", "user_db")
	viper.SetDefault("database.sslmode", "disable")
	viper.SetDefault("database.max_open_conns", 100)
	viper.SetDefault("database.max_idle_conns", 10)
	viper.SetDefault("database.conn_max_lifetime", "1h")
	viper.SetDefault("database.conn_max_idle_time", "10m")

	viper.SetDefault("redis.addr", "localhost:6379")
	viper.SetDefault("redis.password", "")
	viper.SetDefault("redis.db", 0)

	viper.SetDefault("jwt.secret", "your-secret-key-change-in-production")
	viper.SetDefault("jwt.token_expiry", "24h")
	viper.SetDefault("jwt.refresh_expiry", "168h")

	viper.SetDefault("log.level", "info")
	viper.SetDefault("log.format", "json")
	viper.SetDefault("log.output", "stdout")
	viper.SetDefault("log.file_path", "")
	viper.SetDefault("log.max_size", 100)
	viper.SetDefault("log.max_backups", 3)
	viper.SetDefault("log.max_age", 28)

	viper.SetDefault("consul.host", "localhost")
	viper.SetDefault("consul.port", 8500)
	viper.SetDefault("consul.service_name", "user-service")
	viper.SetDefault("consul.service_id", "user-service-1")
	viper.SetDefault("consul.service_tags", []string{"user", "auth", "api"})
	viper.SetDefault("consul.check_interval", "10s")
	viper.SetDefault("consul.check_timeout", "5s")

	// 读取配置文件
	if err := viper.ReadInConfig(); err != nil {
		// 配置文件不存在时使用默认值
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, err
		}
	}

	// 解析配置
	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, err
	}

	// 从环境变量覆盖配置
	if appName := os.Getenv("APP_NAME"); appName != "" {
		config.Server.Name = appName
	}
	if debug := os.Getenv("DEBUG"); debug != "" {
		if parsed, err := strconv.ParseBool(debug); err == nil {
			config.Server.Debug = parsed
		}
	}
	if port := os.Getenv("PORT"); port != "" {
		if parsed, err := strconv.Atoi(port); err == nil {
			config.Server.Port = parsed
		}
	}

	if databaseHost := os.Getenv("DATABASE_HOST"); databaseHost != "" {
		config.Database.Host = databaseHost
	}
	if databasePort := os.Getenv("DATABASE_PORT"); databasePort != "" {
		if parsed, err := strconv.Atoi(databasePort); err == nil {
			config.Database.Port = parsed
		}
	}
	if databaseUser := os.Getenv("DATABASE_USER"); databaseUser != "" {
		config.Database.User = databaseUser
	}
	if databasePassword := os.Getenv("DATABASE_PASSWORD"); databasePassword != "" {
		config.Database.Password = databasePassword
	}
	if databaseName := os.Getenv("DATABASE_NAME"); databaseName != "" {
		config.Database.DBName = databaseName
	}

	if redisAddr := os.Getenv("REDIS_ADDR"); redisAddr != "" {
		config.Redis.Addr = redisAddr
	}
	if redisPassword := os.Getenv("REDIS_PASSWORD"); redisPassword != "" {
		config.Redis.Password = redisPassword
	}
	if redisDB := os.Getenv("REDIS_DB"); redisDB != "" {
		if parsed, err := strconv.Atoi(redisDB); err == nil {
			config.Redis.DB = parsed
		}
	}

	if secretKey := os.Getenv("SECRET_KEY"); secretKey != "" {
		config.JWT.Secret = secretKey
	}
	if tokenExpiry := os.Getenv("TOKEN_EXPIRY"); tokenExpiry != "" {
		if parsed, err := time.ParseDuration(tokenExpiry); err == nil {
			config.JWT.TokenExpiry = parsed
		}
	}
	if refreshExpiry := os.Getenv("REFRESH_EXPIRY"); refreshExpiry != "" {
		if parsed, err := time.ParseDuration(refreshExpiry); err == nil {
			config.JWT.RefreshExpiry = parsed
		}
	}

	if logLevel := os.Getenv("LOG_LEVEL"); logLevel != "" {
		config.Log.Level = logLevel
	}
	if logFormat := os.Getenv("LOG_FORMAT"); logFormat != "" {
		config.Log.Format = logFormat
	}

	if consulHost := os.Getenv("CONSUL_HOST"); consulHost != "" {
		config.Consul.Host = consulHost
	}
	if consulPort := os.Getenv("CONSUL_PORT"); consulPort != "" {
		if parsed, err := strconv.Atoi(consulPort); err == nil {
			config.Consul.Port = parsed
		}
	}
	if serviceName := os.Getenv("SERVICE_NAME"); serviceName != "" {
		config.Consul.ServiceName = serviceName
	}
	if serviceID := os.Getenv("SERVICE_ID"); serviceID != "" {
		config.Consul.ServiceID = serviceID
	}
	if serviceTags := os.Getenv("SERVICE_TAGS"); serviceTags != "" {
		config.Consul.ServiceTags = strings.Split(serviceTags, ",")
	}

	return &config, nil
}



