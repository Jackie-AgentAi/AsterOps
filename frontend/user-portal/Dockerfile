# 多阶段构建
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 设置npm阿里源
RUN npm config set registry https://registry.npmmirror.com

# 复制package文件
COPY package*.json ./

# 清理npm缓存并安装依赖
RUN npm cache clean --force && \
    npm install --no-optional --production=false && \
    npm install @rollup/rollup-linux-x64-musl --save-dev

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 生产阶段
FROM nginx:alpine

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 暴露端口
EXPOSE 80

# 启动nginx
CMD ["nginx", "-g", "daemon off;"]
