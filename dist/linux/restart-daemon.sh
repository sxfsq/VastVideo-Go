#!/bin/bash
# VastVideo-Go Linux 重启后台服务脚本

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 切换到脚本目录
cd "$SCRIPT_DIR"

echo "🔄 重启 VastVideo-Go 服务..."

# 停止服务
if [ -f "./stop-daemon.sh" ]; then
    ./stop-daemon.sh
    sleep 2
fi

# 启动服务
if [ -f "./start-daemon.sh" ]; then
    ./start-daemon.sh "$@"
else
    echo "❌ 找不到启动脚本"
    exit 1
fi
