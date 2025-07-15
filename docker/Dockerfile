# 使用 Alpine Linux 作为基础镜像
FROM alpine:latest

# 定义构建参数
ARG TARGETARCH
ARG TARGETOS

# 安装必要的包
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    && rm -rf /var/cache/apk/*

# 设置时区
ENV TZ=Asia/Shanghai

# 创建应用目录
WORKDIR /app

# 根据目标架构复制对应的Linux可执行文件
COPY VastVideo-Go-linux-${TARGETARCH} /app/VastVideo-Go
COPY config/ /app/config/

# 设置执行权限
RUN chmod +x /app/VastVideo-Go

# 暴露端口 (根据实际应用需要修改)
EXPOSE 8228

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8228/health || exit 1

# 启动命令
CMD ["/app/VastVideo-Go"]
