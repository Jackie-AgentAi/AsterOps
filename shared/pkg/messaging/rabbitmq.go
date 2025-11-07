package messaging

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/streadway/amqp"
)

// RabbitMQ消息队列管理器
type RabbitMQManager struct {
	conn    *amqp.Connection
	channel *amqp.Channel
	config  RabbitMQConfig
}

// RabbitMQ配置
type RabbitMQConfig struct {
	URL      string
	Exchange string
	Queue    string
}

// 消息结构
type Message struct {
	ID        string                 `json:"id"`
	Type      string                 `json:"type"`
	Source    string                 `json:"source"`
	Data      map[string]interface{} `json:"data"`
	Timestamp time.Time              `json:"timestamp"`
	TenantID  string                 `json:"tenant_id"`
	UserID    string                 `json:"user_id"`
}

// 创建RabbitMQ管理器
func NewRabbitMQManager(config RabbitMQConfig) (*RabbitMQManager, error) {
	conn, err := amqp.Dial(config.URL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to RabbitMQ: %w", err)
	}

	channel, err := conn.Channel()
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("failed to open channel: %w", err)
	}

	// 声明交换机
	err = channel.ExchangeDeclare(
		config.Exchange, // name
		"topic",         // type
		true,            // durable
		false,           // auto-deleted
		false,           // internal
		false,           // no-wait
		nil,             // arguments
	)
	if err != nil {
		channel.Close()
		conn.Close()
		return nil, fmt.Errorf("failed to declare exchange: %w", err)
	}

	return &RabbitMQManager{
		conn:    conn,
		channel: channel,
		config:  config,
	}, nil
}

// 发布消息
func (r *RabbitMQManager) PublishMessage(ctx context.Context, routingKey string, message Message) error {
	body, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	err = r.channel.Publish(
		r.config.Exchange, // exchange
		routingKey,        // routing key
		false,             // mandatory
		false,             // immediate
		amqp.Publishing{
			ContentType:  "application/json",
			Body:         body,
			Timestamp:    time.Now(),
			MessageId:    message.ID,
			Headers: amqp.Table{
				"type":     message.Type,
				"source":   message.Source,
				"tenant_id": message.TenantID,
				"user_id":  message.UserID,
			},
		},
	)

	if err != nil {
		return fmt.Errorf("failed to publish message: %w", err)
	}

	log.Printf("Message published: %s -> %s", message.Type, routingKey)
	return nil
}

// 订阅消息
func (r *RabbitMQManager) SubscribeMessages(ctx context.Context, queueName, routingKey string, handler func(Message) error) error {
	// 声明队列
	queue, err := r.channel.QueueDeclare(
		queueName, // name
		true,      // durable
		false,     // delete when unused
		false,     // exclusive
		false,     // no-wait
		nil,       // arguments
	)
	if err != nil {
		return fmt.Errorf("failed to declare queue: %w", err)
	}

	// 绑定队列到交换机
	err = r.channel.QueueBind(
		queue.Name,       // queue name
		routingKey,       // routing key
		r.config.Exchange, // exchange
		false,            // no-wait
		nil,              // arguments
	)
	if err != nil {
		return fmt.Errorf("failed to bind queue: %w", err)
	}

	// 设置QoS
	err = r.channel.Qos(
		1,     // prefetch count
		0,     // prefetch size
		false, // global
	)
	if err != nil {
		return fmt.Errorf("failed to set QoS: %w", err)
	}

	// 开始消费消息
	msgs, err := r.channel.Consume(
		queue.Name, // queue
		"",         // consumer
		false,      // auto-ack
		false,      // exclusive
		false,      // no-local
		false,      // no-wait
		nil,        // args
	)
	if err != nil {
		return fmt.Errorf("failed to register consumer: %w", err)
	}

	// 处理消息
	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			case msg := <-msgs:
				var message Message
				if err := json.Unmarshal(msg.Body, &message); err != nil {
					log.Printf("Failed to unmarshal message: %v", err)
					msg.Nack(false, false)
					continue
				}

				// 处理消息
				if err := handler(message); err != nil {
					log.Printf("Failed to handle message: %v", err)
					msg.Nack(false, true) // 重新入队
					continue
				}

				// 确认消息
				msg.Ack(false)
			}
		}
	}()

	return nil
}

// 关闭连接
func (r *RabbitMQManager) Close() error {
	if r.channel != nil {
		r.channel.Close()
	}
	if r.conn != nil {
		return r.conn.Close()
	}
	return nil
}

// 事件发布器
type EventPublisher struct {
	rabbitmq *RabbitMQManager
}

func NewEventPublisher(rabbitmq *RabbitMQManager) *EventPublisher {
	return &EventPublisher{
		rabbitmq: rabbitmq,
	}
}

// 发布用户事件
func (p *EventPublisher) PublishUserEvent(ctx context.Context, eventType string, userID, tenantID string, data map[string]interface{}) error {
	message := Message{
		ID:        generateMessageID(),
		Type:      eventType,
		Source:    "user-service",
		Data:      data,
		Timestamp: time.Now(),
		TenantID:  tenantID,
		UserID:    userID,
	}

	routingKey := fmt.Sprintf("user.%s", eventType)
	return p.rabbitmq.PublishMessage(ctx, routingKey, message)
}

// 发布模型事件
func (p *EventPublisher) PublishModelEvent(ctx context.Context, eventType string, modelID, tenantID string, data map[string]interface{}) error {
	message := Message{
		ID:        generateMessageID(),
		Type:      eventType,
		Source:    "model-service",
		Data:      data,
		Timestamp: time.Now(),
		TenantID:  tenantID,
		UserID:    data["user_id"].(string),
	}

	routingKey := fmt.Sprintf("model.%s", eventType)
	return p.rabbitmq.PublishMessage(ctx, routingKey, message)
}

// 发布推理事件
func (p *EventPublisher) PublishInferenceEvent(ctx context.Context, eventType string, inferenceID, tenantID string, data map[string]interface{}) error {
	message := Message{
		ID:        generateMessageID(),
		Type:      eventType,
		Source:    "inference-service",
		Data:      data,
		Timestamp: time.Now(),
		TenantID:  tenantID,
		UserID:    data["user_id"].(string),
	}

	routingKey := fmt.Sprintf("inference.%s", eventType)
	return p.rabbitmq.PublishMessage(ctx, routingKey, message)
}

// 发布成本事件
func (p *EventPublisher) PublishCostEvent(ctx context.Context, eventType string, costID, tenantID string, data map[string]interface{}) error {
	message := Message{
		ID:        generateMessageID(),
		Type:      eventType,
		Source:    "cost-service",
		Data:      data,
		Timestamp: time.Now(),
		TenantID:  tenantID,
		UserID:    data["user_id"].(string),
	}

	routingKey := fmt.Sprintf("cost.%s", eventType)
	return p.rabbitmq.PublishMessage(ctx, routingKey, message)
}

// 生成消息ID
func generateMessageID() string {
	return fmt.Sprintf("msg_%d", time.Now().UnixNano())
}



