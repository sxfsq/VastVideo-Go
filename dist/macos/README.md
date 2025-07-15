# VastVideo-Go

一个用Go语言开发的视频聚合搜索和代理服务工具，支持多平台运行。

> 极速多源影视聚合播放器 · 开源 · 全端适配 · 极速体验

VastVideo-Go 是一款基于 Go 后端和现代前端技术开发的多源影视聚合播放器，支持 PC 与移动端自适应，聚合主流资源站，极速搜索、高清播放，界面美观，体验流畅。适合技术爱好者、家庭用户、影视发烧友等多种场景。

## 🌟 功能特性

- 🎬 **多源聚合搜索** - 支持主流资源站一键聚合，自动切换、优选资源，内容丰富
- ⚡ **极速搜索** - 全局异步搜索，支持多源并发，结果秒级返回，体验极致流畅
- 🎥 **高清播放** - 支持4K/1080P/720P等多分辨率，自动识别，原画播放不卡顿
- 📱 **全端适配** - 移动端、PC端自适应布局，触控/鼠标操作均友好，响应式设计
- 🛡️ **成人内容过滤** - 默认过滤成人内容，支持密码保护开关，保护家庭用户使用安全
- 🌐 **HTTP代理服务** - 提供跨域请求代理，支持CORS
- 🎯 **豆瓣API代理** - 获取豆瓣电影/电视剧信息和推荐
- 🖥️ **跨平台支持** - 支持Windows、macOS、Linux
- 🔧 **智能浏览器启动** - Windows/macOS自动启动浏览器，Linux手动访问
- 📊 **健康检查** - 提供服务状态监控
- ⚙️ **开源可定制** - 完全开源，支持二次开发、私有部署，社区活跃

## 📋 支持的视频源

| 视频源 | 名称 | 状态 |
|--------|------|------|
| bfzy | 暴风资源 | ✅ 默认启用 |
| dyttzy | 电影天堂资源 | ✅ 默认启用 |
| ruyi | 如意资源 | ⚪ 可选 |
| tyyszy | 天涯资源 | ⚪ 可选 |
| heimuer | 黑木耳 | ⚪ 可选 |
| zy360 | 360资源 | ⚪ 可选 |
| wolong | 卧龙资源 | ⚪ 可选 |
| jisu | 极速资源 | ⚪ 可选 |
| dbzy | 豆瓣资源 | ⚪ 可选 |
| mozhua | 魔爪资源 | ⚪ 可选 |
| mdzy | 魔都资源 | ⚪ 可选 |
| zuid | 最大资源 | ⚪ 可选 |
| baidu | 百度云资源 | ⚪ 可选 |
| wujin | 无尽资源 | ⚪ 可选 |
| wwzy | 旺旺短剧 | ⚪ 可选 |
| ikun | iKun资源 | ⚪ 可选 |

## 🚀 快速开始

### 系统要求

- Go 1.21 或更高版本
- 支持的操作系统：Windows、macOS、Linux

### 安装方法

#### 方法一：从源码编译

```bash
# 克隆项目
git clone https://github.com/VastPools/VastVideo-Go.git
cd VastVideo-Go

# 安装依赖
go mod tidy

# 编译项目
go build -o vastvideo-go .

# 运行程序
./vastvideo-go
```

#### 方法二：使用构建脚本

```bash
# 构建所有平台版本
./build.sh -a

# 仅构建当前平台版本
./build.sh

# 查看构建选项
./build.sh -h
```

#### 方法三：使用Docker（推荐）

```bash
# x86 架构
docker run -d --name vastvideo-go -p 8228:8228 vastpools/vastvideo-go:latest

# ARM 架构（如树莓派、部分 Mac）
docker run -d --name vastvideo-go -p 8228:8228 vastpools/vastvideo-go:latest
```

### 运行程序

```bash
# 默认启动（自动打开浏览器）
./vastvideo-go

# 不自动打开浏览器
./vastvideo-go -no-open

# 指定端口
./vastvideo-go -port 8228

# 后台运行
nohup ./vastvideo-go > vastvideo-go.log 2>&1 &

# Windows 直接运行
# 双击 vastvideo-go.exe 或运行 start.bat

# macOS 直接运行
# 双击 vastvideo-go 或在终端运行 ./vastvideo-go

## 📖 使用说明

### 启动后访问地址

程序启动后，您可以通过以下地址访问：

- **主页面**: `http://localhost:8228/` 或 `http://your-ip:8228/`
- **关于页面**: `http://localhost:8228/about`
- **健康检查**: `http://localhost:8228/health`

### API接口

#### 视频源API

```bash
# 获取所有视频源
GET /api/sources

# 搜索视频
GET /api/source_search?source=bfzy&keyword=复仇者联盟&page=1

# 获取最新推荐
GET /api/source_search?source=bfzy&latest=true&page=1
```

#### 豆瓣API

```bash
# 获取电影标签
GET /douban?action=tags&type=movie

# 获取电视剧标签
GET /douban?action=tags&type=tv

# 获取推荐内容
GET /douban?action=subjects&type=movie&tag=热门&page_limit=16&page_start=0
```

#### 代理服务

```bash
# HTTP代理
GET /proxy?url=https://example.com/api/data
```

### 成人内容过滤

VastVideo-Go 提供了成人内容过滤功能，保护家庭用户的使用安全：

#### 功能特点

- **默认过滤**: 系统默认过滤成人部分内容，确保家庭环境安全
- **密码保护**: 支持通过密码验证来开启或关闭过滤功能
- **密码管理**: 默认密码为 `8228`，支持用户自定义修改密码
- **密码恢复**: 如忘记密码，清空本地缓存信息即可恢复默认密码

#### 使用方法

1. **默认状态**: 程序启动时默认启用成人内容过滤
2. **关闭过滤**: 在设置页面输入密码后可关闭过滤功能
3. **开启过滤**: 同样通过密码验证可重新开启过滤功能
4. **修改密码**: 在设置页面可以修改默认密码
5. **密码恢复**: 清空浏览器本地缓存即可恢复默认密码 `8228`

### 浏览器自动启动

- **Windows/macOS**: 程序启动后会自动打开默认浏览器
- **Linux**: 需要手动访问提供的URL
- **禁用自动启动**: 使用 `-no-open` 参数

## ⚙️ 配置说明

### 配置文件位置

程序使用 `config/config.ini` 作为配置文件。

### 主要配置项

```ini
[server]
port = 8228                    # 服务端口
host = 0.0.0.0                # 监听地址

[browser]
auto_open = true              # 是否自动打开浏览器

[features]
health_check = true           # 启用健康检查
info_page = true             # 启用信息页面
proxy_service = true         # 启用代理服务
douban_api = true            # 启用豆瓣API

[logging]
console_output = true        # 控制台输出
file_output = false          # 文件输出
log_file = vastvideo-go.log  # 日志文件路径
```

### 视频源配置

在 `[sources]` 部分配置视频源：

```ini
[sources]
# 格式: code.name = 名称, code.url = URL, code.is_default = 是否默认(1/0)
bfzy.name = 暴风资源
bfzy.url = https://bfzyapi.com/api.php/provide/vod
bfzy.is_default = 1
```

## 🔧 开发说明

### 项目结构

```
VastVideo-Go/
├── main.go              # 程序入口
├── components/          # 核心组件
│   ├── browser.go      # 浏览器控制
│   ├── douban.go       # 豆瓣API
│   ├── proxy.go        # 代理服务
│   └── sources.go      # 视频源管理
├── utils/              # 工具模块
│   ├── config.go       # 配置管理
│   └── ip.go          # IP工具
├── config/             # 配置文件
│   └── config.ini     # 主配置文件
├── html/              # 前端文件
│   ├── index_mobile.html
│   └── about.html
├── build.sh           # 构建脚本
└── README.md          # 说明文档
```

### 构建多平台版本

```bash
# 构建所有平台
./build.sh -a

# 构建特定平台
./build.sh -l    # Linux
./build.sh -w    # Windows
./build.sh -m    # macOS
```

## 🐛 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 程序会自动尝试释放端口，如果失败请手动检查
   lsof -i :8228  # Linux/macOS
   netstat -ano | findstr :8228  # Windows
   ```

2. **浏览器无法启动**
   - 检查系统默认浏览器设置
   - 使用 `-no-open` 参数手动访问

3. **视频源无法访问**
   - 检查网络连接
   - 确认视频源API是否可用
   - 查看日志文件获取详细错误信息

### 日志文件

程序运行日志保存在 `vastvideo-go.log` 文件中，包含详细的运行信息和错误日志。

## 📄 许可证

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进项目。

## 🌟 开源与社区

VastVideo-Go 遵循 MIT 协议，完全开源，欢迎 Star、Fork、提 Issue 与 PR。社区交流群、文档与教程请见项目主页。

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 Issue: [GitHub Issues](https://github.com/VastPools/VastVideo-Go/issues)
- 邮箱: vastpools@hotmail.com
- GitHub: [https://github.com/VastPools/VastVideo-Go](https://github.com/VastPools/VastVideo-Go)

如有合作、定制、技术支持等需求，欢迎邮件联系。

---

**注意**: 本项目仅供学习和研究使用，请遵守相关法律法规和网站使用条款。

---

**VastVideo-Go** - 极速多源影视聚合播放器 · 开源 · 全端适配 · 极速体验 