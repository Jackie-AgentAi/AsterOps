FROM golang:1.21-alpine AS builder

# 配置Go代理使用国内镜像源
ENV GOPROXY=https://goproxy.cn,direct

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o api-gateway .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/api-gateway .

EXPOSE 8087
CMD ["./api-gateway"]