package logger

import (
	"os"

	"github.com/sirupsen/logrus"
)

// Logger 日志接口
type Logger interface {
	Debug(args ...interface{})
	Debugf(format string, args ...interface{})
	Info(args ...interface{})
	Infof(format string, args ...interface{})
	Warn(args ...interface{})
	Warnf(format string, args ...interface{})
	Error(args ...interface{})
	Errorf(format string, args ...interface{})
	Fatal(args ...interface{})
	Fatalf(format string, args ...interface{})
}

// logger 日志实现
type logger struct {
	*logrus.Logger
}

// NewLogger 创建新的日志实例
func NewLogger() Logger {
	l := logrus.New()
	l.SetOutput(os.Stdout)
	l.SetFormatter(&logrus.JSONFormatter{})
	l.SetLevel(logrus.InfoLevel)
	
	return &logger{Logger: l}
}

// NewLoggerWithLevel 创建指定级别的日志实例
func NewLoggerWithLevel(level string) Logger {
	l := logrus.New()
	l.SetOutput(os.Stdout)
	l.SetFormatter(&logrus.JSONFormatter{})
	
	switch level {
	case "debug":
		l.SetLevel(logrus.DebugLevel)
	case "info":
		l.SetLevel(logrus.InfoLevel)
	case "warn":
		l.SetLevel(logrus.WarnLevel)
	case "error":
		l.SetLevel(logrus.ErrorLevel)
	case "fatal":
		l.SetLevel(logrus.FatalLevel)
	default:
		l.SetLevel(logrus.InfoLevel)
	}
	
	return &logger{Logger: l}
}
