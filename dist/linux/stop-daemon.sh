#!/bin/bash
# VastVideo-Go Linux 停止后台服务脚本

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 切换到脚本目录
cd "$SCRIPT_DIR"

PID_FILE="./vastvideo-go.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "VastVideo-Go 服务未运行"
    exit 0
fi

PID=$(cat "$PID_FILE")

if [ -z "$PID" ]; then
    echo "PID 文件为空，清理文件"
    rm -f "$PID_FILE"
    exit 0
fi

if ! kill -0 "$PID" 2>/dev/null; then
    echo "进程 $PID 不存在，清理 PID 文件"
    rm -f "$PID_FILE"
    exit 0
fi

echo "正在停止 VastVideo-Go 服务 (PID: $PID)..."
kill "$PID"

# 等待进程结束
for i in {1..10}; do
    if ! kill -0 "$PID" 2>/dev/null; then
        echo "✅ VastVideo-Go 服务已停止"
        rm -f "$PID_FILE"
        exit 0
    fi
    sleep 1
done

# 强制终止
echo "强制终止进程..."
kill -9 "$PID" 2>/dev/null
rm -f "$PID_FILE"
echo "✅ VastVideo-Go 服务已强制停止"
