#!/bin/bash
# VastVideo-Go Linux 后台启动脚本

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 切换到脚本目录
cd "$SCRIPT_DIR"

# 检测系统架构
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    EXECUTABLE="VastVideo-Go-linux-amd64"
elif [ "$ARCH" = "i386" ] || [ "$ARCH" = "i686" ]; then
    EXECUTABLE="VastVideo-Go-linux-386"
else
    echo "警告: 未知架构 $ARCH，尝试使用 AMD64 版本"
    EXECUTABLE="VastVideo-Go-linux-amd64"
fi

# 检查可执行文件是否存在
if [ ! -f "./$EXECUTABLE" ]; then
    echo "错误: 找不到 $EXECUTABLE 可执行文件"
    exit 1
fi

# 设置执行权限
chmod +x "./$EXECUTABLE"

# 检查是否已经在运行
PID_FILE="./vastvideo-go.pid"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "VastVideo-Go 已经在运行 (PID: $PID)"
        echo "如需重启，请先运行: ./stop-daemon.sh"
        exit 1
    else
        echo "清理过期的 PID 文件"
        rm -f "$PID_FILE"
    fi
fi

# 启动程序到后台
echo "启动 VastVideo-Go 后台服务 (Linux $ARCH)..."
nohup ./$EXECUTABLE "$@" > vastvideo-go.log 2>&1 &
PID=$!

# 保存 PID
echo $PID > "$PID_FILE"

# 等待一下确保程序启动
sleep 2

# 检查程序是否成功启动
if kill -0 "$PID" 2>/dev/null; then
    echo "✅ VastVideo-Go 后台服务启动成功 (PID: $PID)"
    echo "📝 日志文件: $SCRIPT_DIR/vastvideo-go.log"
    echo "🛑 停止服务: ./stop-daemon.sh"
    echo "📊 查看状态: ./status-daemon.sh"
else
    echo "❌ VastVideo-Go 后台服务启动失败"
    rm -f "$PID_FILE"
    exit 1
fi
