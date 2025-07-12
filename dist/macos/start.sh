#!/bin/bash
# VastVideo-Go macOS 启动脚本

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 切换到脚本目录
cd "$SCRIPT_DIR"

# 检测系统架构
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    EXECUTABLE="VastVideo-Go-darwin-arm64"
else
    EXECUTABLE="VastVideo-Go-darwin-amd64"
fi

# 检查可执行文件是否存在
if [ ! -f "./$EXECUTABLE" ]; then
    echo "错误: 找不到 $EXECUTABLE 可执行文件"
    exit 1
fi

# 设置执行权限
chmod +x "./$EXECUTABLE"

# 启动程序
echo "启动 VastVideo-Go (macOS $ARCH)..."
./$EXECUTABLE "$@"
