#!/bin/bash
# VastVideo-Go Docker 启动脚本

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 切换到脚本目录
cd "$SCRIPT_DIR"

# 检查 Docker 是否运行
if ! docker info >/dev/null 2>&1; then
    echo "错误: Docker 未运行，请启动 Docker 服务"
    exit 1
fi

# 设置默认值
DOCKER_NAMESPACE=${DOCKER_NAMESPACE:-your-dockerhub-username}
VERSION=${VERSION:-latest}

echo "启动 VastVideo-Go Docker 容器..."
echo "镜像: $DOCKER_NAMESPACE/vastvideo-go:$VERSION"

# 使用 docker-compose 启动
docker-compose up -d

if [ $? -eq 0 ]; then
    echo "✅ VastVideo-Go 容器启动成功"
    echo "📊 查看日志: docker-compose logs -f"
    echo "🛑 停止服务: docker-compose down"
    echo "🌐 访问地址: http://localhost:8228"
else
    echo "❌ VastVideo-Go 容器启动失败"
    exit 1
fi
