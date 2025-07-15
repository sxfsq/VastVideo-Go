#!/bin/bash
# VastVideo-Go Docker 停止脚本

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 切换到脚本目录
cd "$SCRIPT_DIR"

echo "停止 VastVideo-Go Docker 容器..."

# 使用 docker-compose 停止
docker-compose down

if [ $? -eq 0 ]; then
    echo "✅ VastVideo-Go 容器已停止"
else
    echo "❌ 停止容器时发生错误"
    exit 1
fi
