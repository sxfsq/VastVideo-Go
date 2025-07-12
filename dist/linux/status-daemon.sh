#!/bin/bash
# VastVideo-Go Linux 服务状态检查脚本

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 切换到脚本目录
cd "$SCRIPT_DIR"

PID_FILE="./vastvideo-go.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "❌ VastVideo-Go 服务未运行"
    exit 1
fi

PID=$(cat "$PID_FILE")

if [ -z "$PID" ]; then
    echo "❌ PID 文件为空"
    rm -f "$PID_FILE"
    exit 1
fi

if kill -0 "$PID" 2>/dev/null; then
    echo "✅ VastVideo-Go 服务正在运行 (PID: $PID)"
    
    # 获取进程信息
    if command -v ps >/dev/null 2>&1; then
        echo ""
        echo "进程信息:"
        ps -p "$PID" -o pid,ppid,cmd,etime,pcpu,pmem 2>/dev/null || true
    fi
    
    # 检查端口使用情况
    echo ""
    echo "端口使用情况:"
    if command -v netstat >/dev/null 2>&1; then
        netstat -tlnp 2>/dev/null | grep "$PID" || echo "未找到端口信息"
    elif command -v ss >/dev/null 2>&1; then
        ss -tlnp 2>/dev/null | grep "$PID" || echo "未找到端口信息"
    fi
    
    # 显示日志文件大小
    if [ -f "vastvideo-go.log" ]; then
        echo ""
        echo "日志文件:"
        ls -lh vastvideo-go.log
        echo ""
        echo "最近日志 (最后 10 行):"
        tail -10 vastvideo-go.log
    fi
    
    exit 0
else
    echo "❌ VastVideo-Go 服务未运行 (PID: $PID 不存在)"
    rm -f "$PID_FILE"
    exit 1
fi
