#!/bin/bash

# VastVideo-Go Docker 多平台构建脚本
# 支持构建 AMD64 和 ARM64 版本的 Docker 镜像并推送到 Docker Hub

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="VastVideo-Go"
VERSION=""  # 版本号将通过参数提供
DOCKER_IMAGE_NAME="vastvideo-go"
DOCKER_NAMESPACE="vastpools"  # 请修改为您的 Docker Hub 用户名
BUILD_DIR="build"
DIST_DIR="dist"
DOCKER_DIR="docker"
# 新增：源码目录
SRC_DIR="./GitHub/VastVideo-Go"

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
    echo "VastVideo-Go Docker 多平台构建脚本"
    echo ""
    echo "用法: $0 --version VERSION [选项]"
    echo ""
    echo "必需参数:"
    echo "  --version VERSION   指定版本号 (必需)"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -b, --build         构建所有平台并创建 Docker 镜像 (使用本地代码)"
    echo "  -p, --push          构建并推送到 Docker Hub (使用本地代码)"
    echo "  -l, --local         使用本地代码构建 (与 -b 相同)"
    echo "  -d, --docker-only   仅构建 Docker 镜像 (使用已编译的结果)"
    echo "  -c, --clean         清理构建目录和 Docker 镜像"
    echo "  --image-name NAME   指定 Docker 镜像名称 (默认: vastvideo-go)"
    echo "  --namespace NAME    指定 Docker Hub 命名空间 (默认: vastpools)"
    echo ""
    echo "工作流程:"
    echo "  1. 先运行 build.sh 进行编译: ./build.sh -a"
    echo "  2. 然后运行 Docker 构建: $0 --version 2.0.0 -d"
    echo "  或者使用一键构建: $0 --version 2.0.0 -b"
    echo ""
    echo "示例:"
    echo "  $0 --version 2.0.0 -b                    # 构建所有平台和 Docker 镜像"
    echo "  $0 --version 2.0.0 -p                    # 构建并推送到 Docker Hub"
    echo "  $0 --version 2.0.0 -l                    # 使用本地代码构建"
    echo "  $0 --version 2.0.0 -d                    # 仅构建 Docker 镜像"
    echo "  $0 --version 2.0.0 -c                    # 清理所有构建文件"
    echo "  $0 --version 2.0.0 --image-name myapp --namespace myuser -p  # 自定义镜像名称和命名空间"
}

# 显示版本信息
show_version() {
    echo "VastVideo-Go Docker 构建脚本 v$VERSION"
}

# 检查依赖
check_dependencies() {
    print_info "检查依赖..."
    
    # 检查 Go
    if ! command -v go >/dev/null 2>&1; then
        print_error "错误: 未找到 Go 环境，请先安装 Go"
        exit 1
    fi
    
    # 检查 Docker
    if ! command -v docker >/dev/null 2>&1; then
        print_error "错误: 未找到 Docker，请先安装 Docker"
        exit 1
    fi
    
    # 检查 Docker 是否运行
    if ! docker info >/dev/null 2>&1; then
        print_error "错误: Docker 未运行，请启动 Docker 服务"
        exit 1
    fi
    
    # 检查 Docker Buildx
    if ! docker buildx version >/dev/null 2>&1; then
        print_warning "警告: Docker Buildx 不可用，将使用传统构建方式"
    fi
    
    print_success "依赖检查完成"
    print_info "Go 版本: $(go version)"
    print_info "Docker 版本: $(docker --version)"
}

# 检查 Docker Hub 登录状态
check_docker_login() {
    print_info "检查 Docker Hub 登录状态..."
    
    if docker info | grep -q "Username"; then
        print_success "Docker Hub 已登录"
        return 0
    else
        print_warning "Docker Hub 未登录"
        return 1
    fi
}

# Docker Hub 登录
docker_login() {
    print_info "请登录 Docker Hub..."
    print_info "请输入您的 Docker Hub 用户名和密码"
    
    if docker login; then
        print_success "Docker Hub 登录成功"
        return 0
    else
        print_error "Docker Hub 登录失败"
        return 1
    fi
}

# 清理构建目录和 Docker 镜像
clean_build() {
    print_info "清理构建目录和 Docker 镜像..."
    
    # 清理构建目录
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_success "已清理 $BUILD_DIR 目录"
    fi
    
    if [ -d "$DIST_DIR" ]; then
        rm -rf "$DIST_DIR"
        print_success "已清理 $DIST_DIR 目录"
    fi
    
    if [ -d "$DOCKER_DIR" ]; then
        rm -rf "$DOCKER_DIR"
        print_success "已清理 $DOCKER_DIR 目录"
    fi
    
    # 清理 Docker 镜像
    print_info "清理 Docker 镜像..."
    docker rmi "$DOCKER_NAMESPACE/$DOCKER_IMAGE_NAME:latest" 2>/dev/null || true
    docker rmi "$DOCKER_NAMESPACE/$DOCKER_IMAGE_NAME:$VERSION" 2>/dev/null || true
    docker rmi "$DOCKER_NAMESPACE/$DOCKER_IMAGE_NAME:amd64" 2>/dev/null || true
    docker rmi "$DOCKER_NAMESPACE/$DOCKER_IMAGE_NAME:arm64" 2>/dev/null || true
    
    print_success "清理完成"
}

# 拉取最新代码
pull_latest_code() {
    print_info "拉取最新代码..."
    
    # 检查 pull-code.sh 脚本是否存在
    if [ ! -f "./pull-code.sh" ]; then
        print_error "错误: 找不到 pull-code.sh 脚本"
        exit 1
    fi
    
    # 强制删除本地代码目录（如果存在）
    if [ -d "$SRC_DIR" ]; then
        print_info "删除本地代码目录: $SRC_DIR"
        rm -rf "$SRC_DIR"
        print_success "本地代码目录已删除"
    fi
    
    # 执行 pull-code.sh 脚本
    print_info "执行 pull-code.sh 拉取最新代码..."
    chmod +x "./pull-code.sh"
    ./pull-code.sh
    
    if [ $? -ne 0 ]; then
        print_error "拉取代码失败，尝试使用本地代码..."
        # 如果拉取失败，使用本地代码
        if [ -d ".git" ] && [ -f "main.go" ]; then
            print_info "使用当前目录作为源码目录"
            SRC_DIR="."
            return 0
        else
            print_error "无法获取源码"
            exit 1
        fi
    fi
    
    print_success "代码拉取完成"
}

# 执行全平台编译
build_all_platforms() {
    print_info "执行全平台编译..."
    
    # 检查编译脚本是否存在
    if [ ! -f "$SRC_DIR/build.sh" ]; then
        print_error "错误: 找不到 $SRC_DIR/build.sh 脚本"
        exit 1
    fi
    
    # 执行编译脚本
    chmod +x "$SRC_DIR/build.sh"
    (cd "$SRC_DIR" && ./build.sh -a)
    
    if [ $? -ne 0 ]; then
        print_error "编译失败"
        exit 1
    fi
    
    print_success "全平台编译完成"
}

# 使用本地代码构建
build_with_local_code() {
    print_info "使用本地代码构建..."
    
    # 检查当前目录是否有 Go 项目文件
    if [ ! -f "main.go" ] || [ ! -f "go.mod" ]; then
        print_error "错误: 当前目录不是有效的 Go 项目"
        print_info "请确保在项目根目录下运行此脚本"
        exit 1
    fi
    
    # 设置源码目录为当前目录
    SRC_DIR="."
    
    print_info "使用当前目录作为源码目录: $SRC_DIR"
    
    # 检查编译脚本是否存在
    if [ ! -f "$SRC_DIR/build.sh" ]; then
        print_error "错误: 找不到 $SRC_DIR/build.sh 脚本"
        exit 1
    fi
    
    # 执行编译脚本
    chmod +x "$SRC_DIR/build.sh"
    (cd "$SRC_DIR" && ./build.sh -a)
    
    if [ $? -ne 0 ]; then
        print_error "编译失败"
        exit 1
    fi
    
    print_success "本地代码编译完成"
}

# 检查编译结果
check_build_results() {
    print_info "检查编译结果..."
    
    # 检查编译结果目录
    if [ ! -d "$SRC_DIR/build" ]; then
        print_error "错误: 找不到编译结果目录 ($SRC_DIR/build)"
        print_info "请先运行 build.sh 进行编译"
        print_info "或者使用 -b 或 -l 选项进行完整构建"
        exit 1
    fi
    
    # 检查是否有 Linux 可执行文件
    if [ ! -f "$SRC_DIR/build/VastVideo-Go-linux-amd64" ] && [ ! -f "$SRC_DIR/build/VastVideo-Go-linux-arm64" ]; then
        print_error "错误: 找不到 Linux 可执行文件"
        print_info "请确保 build.sh 已成功编译 Linux 版本"
        print_info "可用的文件:"
        ls -la "$SRC_DIR/build/" 2>/dev/null || echo "  目录为空或不存在"
        exit 1
    fi
    
    print_success "编译结果检查完成"
    print_info "找到的可执行文件:"
    ls -la "$SRC_DIR/build/" | grep "VastVideo-Go" || echo "  未找到 VastVideo-Go 可执行文件"
}

# 创建 Docker 目录结构
create_docker_structure() {
    print_info "创建 Docker 目录结构..."
    
    mkdir -p "$DOCKER_DIR"
    
    # 创建 Dockerfile
    cat > "$DOCKER_DIR/Dockerfile" << 'EOF'
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
EOF

    # 创建 .dockerignore
    cat > "$DOCKER_DIR/.dockerignore" << 'EOF'
# 忽略不必要的文件
.git
.gitignore
README.md
*.md
build/
dist/
docker/
*.sh
*.bat
*.zip
*.tar.gz
test_*
EOF

    # 创建 docker-compose.yml
    cat > "$DOCKER_DIR/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  vastvideo-go:
    image: ${DOCKER_NAMESPACE:-your-dockerhub-username}/vastvideo-go:${VERSION:-latest}
    container_name: vastvideo-go
    restart: unless-stopped
    ports:
      - "8228:8228"
    volumes:
      - ./config:/app/config
      - ./data:/app/data
    environment:
      - TZ=Asia/Shanghai
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8228/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 5s
EOF

    # 创建启动脚本
    cat > "$DOCKER_DIR/start.sh" << 'EOF'
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
EOF
    chmod +x "$DOCKER_DIR/start.sh"

    # 创建停止脚本
    cat > "$DOCKER_DIR/stop.sh" << 'EOF'
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
EOF
    chmod +x "$DOCKER_DIR/stop.sh"

    print_success "Docker 目录结构创建完成"
}

# 构建 Docker 镜像
build_docker_images() {
    print_info "构建 Docker 镜像..."
    
    # 检查编译结果目录
    if [ ! -d "$SRC_DIR/build" ]; then
        print_error "错误: 找不到编译结果目录 ($SRC_DIR/build)"
        exit 1
    fi
    
    # 复制所有架构的可执行文件到 Docker 目录
    print_info "复制多架构可执行文件..."
    cp "$SRC_DIR/build/VastVideo-Go-linux-amd64" "$DOCKER_DIR/" 2>/dev/null || print_warning "Linux AMD64 文件不存在"
    cp "$SRC_DIR/build/VastVideo-Go-linux-arm64" "$DOCKER_DIR/" 2>/dev/null || print_warning "Linux ARM64 文件不存在"
    # 只保留 Linux 平台的可执行文件用于 docker buildx
    # 复制配置文件
    cp -r "$SRC_DIR/config" "$DOCKER_DIR/" 2>/dev/null || true
    
    # 切换到 Docker 目录
    cd "$DOCKER_DIR"
    
    # 检查是否支持 buildx
    if docker buildx version >/dev/null 2>&1; then
        print_info "使用 Docker Buildx 构建多平台镜像..."
        # 创建并使用新的构建器
        docker buildx create --name vastvideo-builder --use 2>/dev/null || true
        # 构建多平台镜像
        print_info "构建多平台镜像并推送到 Docker Hub..."
        if ! docker buildx build \
            --platform linux/amd64,linux/arm64 \
            --tag "$DOCKER_NAMESPACE/$DOCKER_IMAGE_NAME:$VERSION" \
            --tag "$DOCKER_NAMESPACE/$DOCKER_IMAGE_NAME:latest" \
            --push \
            . ; then
            print_error "[FATAL] Docker Buildx 多平台镜像构建或推送失败，请检查网络和 Docker Hub 认证。"
            print_error "请确保 buildx 可用，网络畅通，并已 docker login。"
            exit 1
        fi
        print_success "多平台 Docker 镜像构建并推送完成"
    else
        print_error "[FATAL] 当前环境不支持 Docker Buildx，无法构建多平台镜像。"
        exit 1
    fi
    # 返回原目录
    cd - > /dev/null
}

# 推送到 Docker Hub
push_to_dockerhub() {
    print_info "推送到 Docker Hub..."
    
    # 检查是否已登录 Docker Hub
    if ! check_docker_login; then
        print_warning "Docker Hub 未登录，尝试自动登录..."
        if ! docker_login; then
            print_error "Docker Hub 登录失败，无法推送镜像"
            print_info "请手动运行: docker login"
            print_info "然后重新执行此脚本"
            exit 1
        fi
    fi
    
    # 推送镜像
    print_info "推送镜像到 Docker Hub..."
    docker push "$DOCKER_NAMESPACE/$DOCKER_IMAGE_NAME:$VERSION"
    docker push "$DOCKER_NAMESPACE/$DOCKER_IMAGE_NAME:latest"
    
    if [ $? -eq 0 ]; then
        print_success "镜像推送完成"
        print_info "镜像地址:"
        print_info "  $DOCKER_NAMESPACE/$DOCKER_IMAGE_NAME:$VERSION"
        print_info "  $DOCKER_NAMESPACE/$DOCKER_IMAGE_NAME:latest"
    else
        print_error "镜像推送失败"
        exit 1
    fi
}

# 显示构建信息
show_build_info() {
    echo ""
    print_info "构建信息:"
    echo "  项目名称: $PROJECT_NAME"
    echo "  版本: $VERSION"
    echo "  Docker 镜像: $DOCKER_NAMESPACE/$DOCKER_IMAGE_NAME"
    echo "  构建目录: $BUILD_DIR"
    echo "  发布目录: $DIST_DIR"
    echo "  Docker 目录: $DOCKER_DIR"
    echo ""
}

# 主函数
main() {
    # 检查参数
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    # 检查版本号是否提供
    VERSION_PROVIDED=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                clean_build
                exit 0
                ;;
            -b|--build)
                if [ "$VERSION_PROVIDED" = false ]; then
                    print_error "错误: 必须提供版本号参数 --version VERSION"
                    show_help
                    exit 1
                fi
                check_dependencies
                show_build_info
                build_with_local_code
                check_build_results
                create_docker_structure
                build_docker_images
                print_success "构建完成！"
                exit 0
                ;;
            -l|--local)
                if [ "$VERSION_PROVIDED" = false ]; then
                    print_error "错误: 必须提供版本号参数 --version VERSION"
                    show_help
                    exit 1
                fi
                check_dependencies
                show_build_info
                build_with_local_code
                check_build_results
                create_docker_structure
                build_docker_images
                print_success "本地构建完成！"
                exit 0
                ;;
            -d|--docker-only)
                if [ "$VERSION_PROVIDED" = false ]; then
                    print_error "错误: 必须提供版本号参数 --version VERSION"
                    show_help
                    exit 1
                fi
                check_dependencies
                show_build_info
                # 设置源码目录为当前目录
                SRC_DIR="."
                check_build_results
                create_docker_structure
                build_docker_images
                print_success "Docker 镜像构建完成！"
                exit 0
                ;;
            -p|--push)
                if [ "$VERSION_PROVIDED" = false ]; then
                    print_error "错误: 必须提供版本号参数 --version VERSION"
                    show_help
                    exit 1
                fi
                check_dependencies
                show_build_info
                build_with_local_code
                check_build_results
                create_docker_structure
                build_docker_images
                push_to_dockerhub
                print_success "构建和推送完成！"
                exit 0
                ;;
            --image-name)
                DOCKER_IMAGE_NAME="$2"
                shift 2
                ;;
            --namespace)
                DOCKER_NAMESPACE="$2"
                shift 2
                ;;
            --version)
                VERSION="$2"
                VERSION_PROVIDED=true
                shift 2
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果没有提供版本号，显示错误
    if [ "$VERSION_PROVIDED" = false ]; then
        print_error "错误: 必须提供版本号参数 --version VERSION"
        show_help
        exit 1
    fi
}

# 执行主函数
main "$@" 