#!/bin/bash

# VastVideo-Go 启动脚本
# 支持独立启动前端Vue、后端Go服务或全栈模式

set -e  # 遇到错误立即退出

# 进程ID变量
FRONTEND_PID=""
BACKEND_PID=""

# 启动模式变量
MODE="fullstack"  # 默认全栈模式

# 显示帮助信息
show_help() {
    echo "🚀 VastVideo-Go 启动脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  无参数         启动前端+后端 (全栈模式)"
    echo "  -f, --frontend 仅启动前端Vue服务"
    echo "  -b, --backend  仅启动后端Go服务"
    echo "  -h, --help     显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0             # 启动全栈服务"
    echo "  $0 -f          # 仅启动前端"
    echo "  $0 --backend   # 仅启动后端"
    echo ""
    echo "服务地址:"
echo "  前端本地: http://localhost:8228"
echo "  后端本地: http://localhost:8228"
echo "  (支持IP访问，启动后将显示网络地址)"
    echo ""
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--frontend)
                MODE="frontend"
                shift
                ;;
            -b|--backend)
                MODE="backend"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "❌ 未知参数: $1"
                echo "使用 $0 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
}

# 获取本机IP地址
get_local_ip() {
    # 尝试获取本机IP地址 (macOS/Linux兼容)
    local ip=""
    
    # 优先使用活跃的网络接口
    if command -v ifconfig >/dev/null 2>&1; then
        # macOS 和部分 Linux 系统
        ip=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | grep -v "inet 169.254" | head -1 | awk '{print $2}' | sed 's/addr://')
    elif command -v ip >/dev/null 2>&1; then
        # 现代 Linux 系统
        ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    fi
    
    # 备用方法：尝试连接外部服务获取本机IP
    if [ -z "$ip" ]; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    
    echo "$ip"
}

# 清理函数
cleanup() {
    echo ""
    echo "🛑 正在停止服务..."
    
    if [ ! -z "$FRONTEND_PID" ] && [[ "$MODE" == "frontend" || "$MODE" == "fullstack" ]]; then
        echo "⏹️  停止前端服务 (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID 2>/dev/null || true
        wait $FRONTEND_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$BACKEND_PID" ] && [[ "$MODE" == "backend" || "$MODE" == "fullstack" ]]; then
        echo "⏹️  停止后端服务 (PID: $BACKEND_PID)..."
        kill $BACKEND_PID 2>/dev/null || true
        wait $BACKEND_PID 2>/dev/null || true
    fi
    
    echo "✅ 服务已停止"
    echo "=================================="
}

# 设置信号处理
trap cleanup EXIT INT TERM

# 解析命令行参数
parse_args "$@"

# 显示启动信息
case $MODE in
    frontend)
        echo "🚀 VastVideo-Go 前端启动脚本开始执行..."
        ;;
    backend)
        echo "🚀 VastVideo-Go 后端启动脚本开始执行..."
        ;;
    fullstack)
        echo "🚀 VastVideo-Go 全栈启动脚本开始执行..."
        ;;
esac
echo "=================================="

echo "🔍 检查开发环境..."

# 根据启动模式检查相应环境
if [[ "$MODE" == "backend" || "$MODE" == "fullstack" ]]; then
    # 检查 Go 环境
    if ! command -v go &> /dev/null; then
        echo "❌ 错误: 未找到 Go 环境，请先安装 Go"
        exit 1
    fi
    echo "✅ Go 环境: $(go version)"
fi

if [[ "$MODE" == "frontend" || "$MODE" == "fullstack" ]]; then
    # 检查 Node.js 环境
    if ! command -v node &> /dev/null; then
        echo "❌ 错误: 未找到 Node.js 环境，请先安装 Node.js"
        exit 1
    fi
    echo "✅ Node.js 环境: $(node --version)"

    # 检查 npm 环境
    if ! command -v npm &> /dev/null; then
        echo "❌ 错误: 未找到 npm，请先安装 npm"
        exit 1
    fi
    echo "✅ npm 环境: $(npm --version)"
fi

echo "=================================="

# 根据启动模式进行相应准备
if [[ "$MODE" == "backend" || "$MODE" == "fullstack" ]]; then
    # 清理旧的编译文件
    echo "🧹 清理旧的编译文件..."
    rm -f vastvideo-go
    rm -f *.exe

    # 编译Go后端
    echo "🔨 编译Go后端..."
    if go build -o vastvideo-go .; then
        echo "✅ Go后端编译成功!"
    else
        echo "❌ Go后端编译失败!"
        exit 1
    fi

    # 检查编译后的文件
    if [ ! -f "vastvideo-go" ]; then
        echo "❌ 错误: 编译后的文件不存在"
        exit 1
    fi

    echo "📦 Go后端编译完成，文件大小: $(du -h vastvideo-go | cut -f1)"

    # 设置执行权限
    chmod +x vastvideo-go
fi

if [[ "$MODE" == "frontend" || "$MODE" == "fullstack" ]]; then
    # 检查Vue前端依赖
    echo "=================================="
    echo "🔍 检查Vue前端..."

    if [ ! -d "web" ]; then
        echo "❌ 错误: 未找到 web 目录，请确保前端项目存在"
        exit 1
    fi

    cd web

    if [ ! -f "package.json" ]; then
        echo "❌ 错误: 未找到 package.json，请确保前端项目完整"
        exit 1
    fi

    # 检查并安装前端依赖
    if [ ! -d "node_modules" ]; then
        echo "📦 安装前端依赖..."
        npm install
    else
        echo "✅ 前端依赖已存在"
    fi

    # 返回根目录
    cd ..
fi

echo "=================================="
echo "🚀 启动服务..."

# 根据模式启动相应服务
if [[ "$MODE" == "frontend" || "$MODE" == "fullstack" ]]; then
    # 启动Vue前端开发服务器（后台运行）
    echo "🌐 启动Vue前端服务..."
    cd web
    npm run dev > ../frontend.log 2>&1 &
    FRONTEND_PID=$!
    cd ..

    # 等待前端服务启动
    echo "⏳ 等待前端服务启动..."
    sleep 3

    # 检查前端服务是否启动成功
    if ! kill -0 $FRONTEND_PID 2>/dev/null; then
        echo "❌ 前端服务启动失败，查看日志:"
        cat frontend.log
        exit 1
    fi

    echo "✅ 前端服务已启动 (PID: $FRONTEND_PID)"
fi

if [[ "$MODE" == "backend" || "$MODE" == "fullstack" ]]; then
    # 启动Go后端服务器
    echo "🔧 启动Go后端服务 (http://localhost:8228)..."
fi

echo "=================================="
echo ""

# 获取本机IP地址
LOCAL_IP=$(get_local_ip)

echo "📍 访问地址:"
case $MODE in
    frontend)
        echo "   本地访问: http://localhost:8228"
        if [ ! -z "$LOCAL_IP" ]; then
            echo "   网络访问: http://$LOCAL_IP:8228"
        fi
        ;;
    backend)
        echo "   本地访问: http://localhost:8228"
        if [ ! -z "$LOCAL_IP" ]; then
            echo "   网络访问: http://$LOCAL_IP:8228"
        fi
        ;;
    fullstack)
        echo "   前端本地: http://localhost:8228"
        echo "   后端本地: http://localhost:8228"
        if [ ! -z "$LOCAL_IP" ]; then
            echo "   前端网络: http://$LOCAL_IP:8228"
            echo "   后端网络: http://$LOCAL_IP:8228"
        fi
        ;;
esac
echo ""
echo "💡 按 Ctrl+C 停止服务"
echo "=================================="

# 根据模式启动后端服务
if [[ "$MODE" == "backend" || "$MODE" == "fullstack" ]]; then
    # 启动后端（前台运行）
    ./vastvideo-go &
    BACKEND_PID=$!
fi

# 检查操作系统，如果是macOS则启动浏览器
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 检测到 macOS 系统，等待服务器启动完成..."
    
    # 等待服务启动
    sleep 3
    
    # 根据模式启动浏览器
    case $MODE in
        frontend)
            if ! kill -0 $FRONTEND_PID 2>/dev/null; then
                echo "❌ 前端服务启动失败"
            else
                echo "🌐 自动启动浏览器..."
                open "http://localhost:8228" 2>/dev/null || {
                    echo "⚠️  无法启动默认浏览器，请手动访问"
                }
                echo "✅ 浏览器已启动"
                echo "📍 本地访问: http://localhost:8228"
                if [ ! -z "$LOCAL_IP" ]; then
                    echo "📍 网络访问: http://$LOCAL_IP:8228"
                fi
            fi
            ;;
        backend)
            if ! kill -0 $BACKEND_PID 2>/dev/null; then
                echo "❌ 后端服务启动失败"
            else
                echo "🌐 自动启动浏览器..."
                open "http://localhost:8228" 2>/dev/null || {
                    echo "⚠️  无法启动默认浏览器，请手动访问"
                }
                echo "✅ 浏览器已启动"
                echo "📍 本地访问: http://localhost:8228"
                if [ ! -z "$LOCAL_IP" ]; then
                    echo "📍 网络访问: http://$LOCAL_IP:8228"
                fi
            fi
            ;;
        fullstack)
            # 检查服务状态
            FRONTEND_OK=true
            BACKEND_OK=true
            
            if ! kill -0 $FRONTEND_PID 2>/dev/null; then
                echo "❌ 前端服务启动失败"
                FRONTEND_OK=false
            fi
            
            if ! kill -0 $BACKEND_PID 2>/dev/null; then
                echo "❌ 后端服务启动失败"
                BACKEND_OK=false
            fi
            
            if $FRONTEND_OK; then
                echo "🌐 自动启动浏览器..."
                # 启动浏览器访问前端页面
                open "http://localhost:8228" 2>/dev/null || {
                    echo "⚠️  无法启动默认浏览器，请手动访问"
                }
                
                echo "✅ 浏览器已启动"
                echo "📍 前端本地: http://localhost:8228"
                echo "📍 后端本地: http://localhost:8228"
                if [ ! -z "$LOCAL_IP" ]; then
                    echo "📍 前端网络: http://$LOCAL_IP:8228"
                    echo "📍 后端网络: http://$LOCAL_IP:8228"
                fi
            fi
            ;;
    esac
else
    echo "🐧 检测到非 macOS 系统，不自动启动浏览器"
    case $MODE in
        frontend)
            echo "📱 请手动访问:"
            echo "   本地: http://localhost:8228"
            if [ ! -z "$LOCAL_IP" ]; then
                echo "   网络: http://$LOCAL_IP:8228"
            fi
            ;;
        backend)
            echo "📱 请手动访问:"
            echo "   本地: http://localhost:8228"
            if [ ! -z "$LOCAL_IP" ]; then
                echo "   网络: http://$LOCAL_IP:8228"
            fi
            ;;
        fullstack)
            echo "📱 请手动访问:"
            echo "   前端本地: http://localhost:8228"
            echo "   后端本地: http://localhost:8228"
            if [ ! -z "$LOCAL_IP" ]; then
                echo "   前端网络: http://$LOCAL_IP:8228"
                echo "   后端网络: http://$LOCAL_IP:8228"
            fi
            ;;
    esac
fi

# 根据模式等待相应进程
case $MODE in
    frontend)
        if [ ! -z "$FRONTEND_PID" ]; then
            echo "⏳ 前端服务运行中..."
            wait $FRONTEND_PID
        fi
        ;;
    backend)
        if [ ! -z "$BACKEND_PID" ]; then
            echo "⏳ 后端服务运行中..."
            wait $BACKEND_PID
        fi
        ;;
    fullstack)
        echo "⏳ 全栈服务运行中..."
        # 如果有后端进程，等待后端进程（前台）
        if [ ! -z "$BACKEND_PID" ]; then
            wait $BACKEND_PID
        # 如果只有前端进程，等待前端进程
        elif [ ! -z "$FRONTEND_PID" ]; then
            wait $FRONTEND_PID
        fi
        ;;
esac

echo "=================================="
echo "👋 VastVideo-Go 服务已退出"
echo "==================================" 