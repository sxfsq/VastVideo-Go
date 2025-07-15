#!/bin/bash

# VastVideo-Go 多平台构建脚本
# 支持生成 Linux、Windows、macOS 三个平台的执行程序

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="VastVideo-Go"
VERSION="2.0.0"
BUILD_DIR="build"
DIST_DIR="dist"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "VastVideo-Go 多平台构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -a, --all           构建所有平台 (Linux, Windows, macOS)"
    echo "  -l, --linux         仅构建 Linux 版本"
    echo "  -w, --windows       仅构建 Windows 版本"
    echo "  -m, --macos         仅构建 macOS 版本"
    echo "  -c, --clean         清理构建目录"
    echo "  -v, --version       显示版本信息"
    echo ""
    echo "示例:"
    echo "  $0 -a              # 构建所有平台"
    echo "  $0 -l              # 仅构建 Linux"
    echo "  $0 -w -m           # 构建 Windows 和 macOS"
    echo "  $0 -c              # 清理构建目录"
}

# 显示版本信息
show_version() {
    echo "VastVideo-Go 构建脚本 v$VERSION"
}

# 清理构建目录
clean_build() {
    print_info "清理构建目录..."
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_success "已清理 $BUILD_DIR 目录"
    fi
    if [ -d "$DIST_DIR" ]; then
        rm -rf "$DIST_DIR"
        print_success "已清理 $DIST_DIR 目录"
    fi
    print_success "清理完成"
}

# 创建构建目录
create_dirs() {
    mkdir -p "$BUILD_DIR"
    mkdir -p "$DIST_DIR"
}

# 构建 Linux 版本
build_linux() {
    print_info "构建 Linux 版本..."
    
    # 检查是否在 Linux 环境或支持交叉编译
    if [ "$(uname)" = "Linux" ] || command -v gcc >/dev/null 2>&1; then
        # 构建 AMD64 版本
        GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o "$BUILD_DIR/VastVideo-Go-linux-amd64" .
        print_success "Linux AMD64 版本构建完成: $BUILD_DIR/VastVideo-Go-linux-amd64"
        
        # 构建 386 版本 (x86)
        GOOS=linux GOARCH=386 go build -ldflags="-s -w" -o "$BUILD_DIR/VastVideo-Go-linux-386" .
        print_success "Linux 386 版本构建完成: $BUILD_DIR/VastVideo-Go-linux-386"
        
        # 构建 ARM64 版本
        GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o "$BUILD_DIR/VastVideo-Go-linux-arm64" .
        print_success "Linux ARM64 版本构建完成: $BUILD_DIR/VastVideo-Go-linux-arm64"
        
        # 创建 Linux 发布包
        mkdir -p "$DIST_DIR/linux"
        cp "$BUILD_DIR/VastVideo-Go-linux-amd64" "$DIST_DIR/linux/"
        cp "$BUILD_DIR/VastVideo-Go-linux-386" "$DIST_DIR/linux/"
        cp "$BUILD_DIR/VastVideo-Go-linux-arm64" "$DIST_DIR/linux/"
        cp config/config.ini "$DIST_DIR/linux/" 2>/dev/null || true
        cp README.md "$DIST_DIR/linux/" 2>/dev/null || true
        cp USAGE.md "$DIST_DIR/linux/" 2>/dev/null || true
        
        # 创建前台启动脚本
        cat > "$DIST_DIR/linux/start.sh" << 'EOF'
#!/bin/bash
# VastVideo-Go Linux 启动脚本

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

# 启动程序
echo "启动 VastVideo-Go (Linux $ARCH)..."
./$EXECUTABLE "$@"
EOF
        chmod +x "$DIST_DIR/linux/start.sh"
        
        # 创建后台启动脚本
        cat > "$DIST_DIR/linux/start-daemon.sh" << 'EOF'
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
EOF
        chmod +x "$DIST_DIR/linux/start-daemon.sh"
        
        # 创建停止脚本
        cat > "$DIST_DIR/linux/stop-daemon.sh" << 'EOF'
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
EOF
        chmod +x "$DIST_DIR/linux/stop-daemon.sh"
        
        # 创建状态检查脚本
        cat > "$DIST_DIR/linux/status-daemon.sh" << 'EOF'
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
EOF
        chmod +x "$DIST_DIR/linux/status-daemon.sh"
        
        # 创建重启脚本
        cat > "$DIST_DIR/linux/restart-daemon.sh" << 'EOF'
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
EOF
        chmod +x "$DIST_DIR/linux/restart-daemon.sh"
        
        # 创建压缩包
        cd "$DIST_DIR"
        tar -czf "VastVideo-Go-linux-v$VERSION.tar.gz" linux/
        cd - > /dev/null
        print_success "Linux 发布包创建完成: $DIST_DIR/VastVideo-Go-linux-v$VERSION.tar.gz"
    else
        print_warning "跳过 Linux 构建 (需要 Linux 环境或交叉编译支持)"
    fi
}

# 构建 Windows 版本
build_windows() {
    print_info "构建 Windows 版本..."
    
    # 检查是否支持交叉编译
    if command -v gcc >/dev/null 2>&1; then
        # 构建 AMD64 版本
        GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o "$BUILD_DIR/VastVideo-Go-windows-amd64.exe" .
        print_success "Windows AMD64 版本构建完成: $BUILD_DIR/VastVideo-Go-windows-amd64.exe"
        
        # 构建 386 版本 (x86)
        GOOS=windows GOARCH=386 go build -ldflags="-s -w" -o "$BUILD_DIR/VastVideo-Go-windows-386.exe" .
        print_success "Windows 386 版本构建完成: $BUILD_DIR/VastVideo-Go-windows-386.exe"
        
        # 创建 Windows 发布包
        mkdir -p "$DIST_DIR/windows"
        cp "$BUILD_DIR/VastVideo-Go-windows-amd64.exe" "$DIST_DIR/windows/"
        cp "$BUILD_DIR/VastVideo-Go-windows-386.exe" "$DIST_DIR/windows/"
        cp config/config.ini "$DIST_DIR/windows/" 2>/dev/null || true
        cp README.md "$DIST_DIR/windows/" 2>/dev/null || true
        cp USAGE.md "$DIST_DIR/windows/" 2>/dev/null || true
        
        # 创建智能启动批处理文件
        cat > "$DIST_DIR/windows/start.bat" << 'EOF'
@echo off
chcp 65001 >nul
REM VastVideo-Go Windows 智能启动脚本

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0

REM 切换到脚本目录
cd /d "%SCRIPT_DIR%"

REM 检测系统架构
for /f "tokens=*" %%i in ('wmic os get osarchitecture /value ^| find "="') do set %%i
set ARCH=%osarchitecture%

REM 根据架构选择可执行文件
if "%ARCH%"=="32-bit" (
    set EXECUTABLE=VastVideo-Go-windows-386.exe
    echo 检测到 32 位系统，使用 386 版本
) else (
    set EXECUTABLE=VastVideo-Go-windows-amd64.exe
    echo 检测到 64 位系统，使用 AMD64 版本
)

REM 检查可执行文件是否存在
if not exist "%EXECUTABLE%" (
    echo 错误: 找不到 %EXECUTABLE% 可执行文件
    echo.
    echo 可用的可执行文件:
    if exist "VastVideo-Go-windows-amd64.exe" echo - VastVideo-Go-windows-amd64.exe
    if exist "VastVideo-Go-windows-386.exe" echo - VastVideo-Go-windows-386.exe
    echo.
    pause
    exit /b 1
)

REM 启动程序
echo 启动 VastVideo-Go (Windows %ARCH%)...
echo 使用可执行文件: %EXECUTABLE%
echo.
%EXECUTABLE% %*
pause
EOF
        
        # 创建 AMD64 专用启动脚本
        cat > "$DIST_DIR/windows/start-amd64.bat" << 'EOF'
@echo off
chcp 65001 >nul
REM VastVideo-Go Windows AMD64 专用启动脚本

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0

REM 切换到脚本目录
cd /d "%SCRIPT_DIR%"

REM 检查可执行文件是否存在
if not exist "VastVideo-Go-windows-amd64.exe" (
    echo 错误: 找不到 VastVideo-Go-windows-amd64.exe 可执行文件
    pause
    exit /b 1
)

REM 启动程序
echo 启动 VastVideo-Go (Windows AMD64)...
VastVideo-Go-windows-amd64.exe %*
pause
EOF
        
        # 创建 386 专用启动脚本
        cat > "$DIST_DIR/windows/start-386.bat" << 'EOF'
@echo off
chcp 65001 >nul
REM VastVideo-Go Windows 386 专用启动脚本

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0

REM 切换到脚本目录
cd /d "%SCRIPT_DIR%"

REM 检查可执行文件是否存在
if not exist "VastVideo-Go-windows-386.exe" (
    echo 错误: 找不到 VastVideo-Go-windows-386.exe 可执行文件
    pause
    exit /b 1
)

REM 启动程序
echo 启动 VastVideo-Go (Windows 386)...
VastVideo-Go-windows-386.exe %*
pause
EOF
        
        # 创建压缩包
        cd "$DIST_DIR"
        zip -r "VastVideo-Go-windows-v$VERSION.zip" windows/
        cd - > /dev/null
        print_success "Windows 发布包创建完成: $DIST_DIR/VastVideo-Go-windows-v$VERSION.zip"
    else
        print_warning "跳过 Windows 构建 (需要交叉编译支持)"
    fi
}

# 构建 macOS 版本
build_macos() {
    print_info "构建 macOS 版本..."
    
    # 检查是否在 macOS 环境或支持交叉编译
    if [ "$(uname)" = "Darwin" ] || command -v clang >/dev/null 2>&1; then
        GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o "$BUILD_DIR/VastVideo-Go-darwin-amd64" .
        
        # 如果支持 ARM64，也构建 ARM64 版本
        if [ "$(uname -m)" = "arm64" ] || command -v clang >/dev/null 2>&1; then
            GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o "$BUILD_DIR/VastVideo-Go-darwin-arm64" .
            print_success "macOS ARM64 版本构建完成: $BUILD_DIR/VastVideo-Go-darwin-arm64"
        fi
        
        print_success "macOS 版本构建完成: $BUILD_DIR/VastVideo-Go-darwin-amd64"
        
        # 创建 macOS 发布包
        mkdir -p "$DIST_DIR/macos"
        cp "$BUILD_DIR/VastVideo-Go-darwin-amd64" "$DIST_DIR/macos/"
        if [ -f "$BUILD_DIR/VastVideo-Go-darwin-arm64" ]; then
            cp "$BUILD_DIR/VastVideo-Go-darwin-arm64" "$DIST_DIR/macos/"
        fi
        cp config/config.ini "$DIST_DIR/macos/" 2>/dev/null || true
        cp README.md "$DIST_DIR/macos/" 2>/dev/null || true
        cp USAGE.md "$DIST_DIR/macos/" 2>/dev/null || true
        
        # 创建启动脚本
        cat > "$DIST_DIR/macos/start.sh" << 'EOF'
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
EOF
        chmod +x "$DIST_DIR/macos/start.sh"
        
        # 创建压缩包
        cd "$DIST_DIR"
        tar -czf "VastVideo-Go-macos-v$VERSION.tar.gz" macos/
        cd - > /dev/null
        print_success "macOS 发布包创建完成: $DIST_DIR/VastVideo-Go-macos-v$VERSION.tar.gz"
    else
        print_warning "跳过 macOS 构建 (需要 macOS 环境或交叉编译支持)"
    fi
}

# 构建所有平台
build_all() {
    print_info "开始构建所有平台版本..."
    create_dirs
    build_linux
    build_windows
    build_macos
    print_success "所有平台构建完成！"
}

# 主函数
main() {
    # 检查参数
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -c|--clean)
                clean_build
                exit 0
                ;;
            -a|--all)
                build_all
                exit 0
                ;;
            -l|--linux)
                create_dirs
                build_linux
                exit 0
                ;;
            -w|--windows)
                create_dirs
                build_windows
                exit 0
                ;;
            -m|--macos)
                create_dirs
                build_macos
                exit 0
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# 检查 Go 环境
check_go() {
    if ! command -v go >/dev/null 2>&1; then
        print_error "错误: 未找到 Go 环境，请先安装 Go"
        exit 1
    fi
    
    print_info "Go 版本: $(go version)"
}

# 执行主函数
check_go
main "$@" 