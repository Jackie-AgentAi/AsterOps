package logger

import (
	"log"
	"os"
)

// Logger 日志记录器
type Logger struct {
	infoLogger  *log.Logger
	errorLogger *log.Logger
	warnLogger  *log.Logger
}

// NewLogger 创建新的日志记录器
func NewLogger() *Logger {
	return &Logger{
		infoLogger:  log.New(os.Stdout, "INFO: ", log.LstdFlags|log.Lshortfile),
		errorLogger: log.New(os.Stderr, "ERROR: ", log.LstdFlags|log.Lshortfile),
		warnLogger:  log.New(os.Stdout, "WARN: ", log.LstdFlags|log.Lshortfile),
	}
}

// Info 记录信息日志
func (l *Logger) Info(v ...interface{}) {
	l.infoLogger.Println(v...)
}

// Error 记录错误日志
func (l *Logger) Error(v ...interface{}) {
	l.errorLogger.Println(v...)
}

// Warn 记录警告日志
func (l *Logger) Warn(v ...interface{}) {
	l.warnLogger.Println(v...)
}

// Infof 记录格式化信息日志
func (l *Logger) Infof(format string, v ...interface{}) {
	l.infoLogger.Printf(format, v...)
}

// Errorf 记录格式化错误日志
func (l *Logger) Errorf(format string, v ...interface{}) {
	l.errorLogger.Printf(format, v...)
}

// Warnf 记录格式化警告日志
func (l *Logger) Warnf(format string, v ...interface{}) {
	l.warnLogger.Printf(format, v...)
}

// Fatal 记录致命错误日志并退出
func (l *Logger) Fatal(v ...interface{}) {
	l.errorLogger.Fatal(v...)
}

// Fatalf 记录格式化致命错误日志并退出
func (l *Logger) Fatalf(format string, v ...interface{}) {
	l.errorLogger.Fatalf(format, v...)
}

// 全局日志记录器
var GlobalLogger = NewLogger()

