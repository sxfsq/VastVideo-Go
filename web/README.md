# VastVideo-Go Vue 前端

这是VastVideo-Go项目的Vue.js前端部分，基于原有的移动端HTML页面重新设计并组件化。

## 功能特性

- 🎬 **聚合搜索**: 整合多个视频源，提供丰富的影视内容
- 📱 **响应式设计**: 完美适配移动端和桌面端
- 🔍 **智能搜索**: 支持关键字搜索和筛选功能
- 🎯 **豆瓣推荐**: 集成豆瓣API，提供高质量推荐内容
- ⚙️ **个性化设置**: 视频源选择、内容过滤等功能
- 🎨 **现代UI**: 基于原设计的Vue组件化重构

## 组件结构

### 核心组件

- **HeaderMenu.vue**: 顶部菜单栏
  - 菜单按钮（汉堡包菜单）
  - 应用标题
  - 关于按钮
  - 返回按钮

- **SideBar.vue**: 侧边栏
  - 搜索功能
  - 内容类型切换（电影/电视剧）
  - 标签筛选
  - 视频源选择
  - 过滤设置

- **HomePage.vue**: 主页内容
  - 推荐内容展示
  - 搜索结果展示
  - 分页加载

- **VideoCard.vue**: 视频卡片
  - 视频封面
  - 基本信息
  - 元数据标签

- **AboutDialog.vue**: 关于对话框

### Composables

- **useToast.js**: Toast提示功能
- **useVideoSources.js**: 视频源管理

## 技术栈

- **Vue 3**: 使用Composition API
- **Vite**: 现代化构建工具
- **CSS3**: 原生CSS，保持原设计风格
- **ES6+**: 现代JavaScript特性

## 开发环境搭建

### 前置要求

- Node.js >= 16.x
- npm 或 yarn

### 安装依赖

```bash
cd web
npm install
```

### 开发模式

```bash
npm run dev
```

访问 http://localhost:3000

### 构建生产版本

```bash
npm run build
```

构建结果将生成到 `dist/` 目录。

### 预览生产构建

```bash
npm run preview
```

## 项目配置

### 代理设置

开发环境下，Vite会自动代理API请求到后端服务：

```javascript
// vite.config.js
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:8228',
      changeOrigin: true
    },
    '/douban': {
      target: 'http://localhost:8228',
      changeOrigin: true
    }
  }
}
```

### 环境变量

支持以下环境变量：

- `VITE_API_BASE_URL`: API基础URL
- `VITE_APP_TITLE`: 应用标题

## API接口

### 豆瓣相关

- `GET /douban?action=tags&type={movie|tv}`: 获取标签列表
- `GET /douban?action=subjects&type={type}&tag={tag}&page_limit={limit}&page_start={start}`: 获取推荐内容

### 搜索相关

- `POST /api/search`: 搜索视频
- `GET /api/latest`: 获取最新视频

### 视频源管理

- `GET /api/sources`: 获取视频源列表

## 目录结构

```
web/
├── public/                 # 静态资源
├── src/
│   ├── components/         # Vue组件
│   │   ├── HeaderMenu.vue
│   │   ├── SideBar.vue
│   │   ├── HomePage.vue
│   │   ├── VideoCard.vue
│   │   └── AboutDialog.vue
│   ├── composables/        # 组合式函数
│   │   ├── useToast.js
│   │   └── useVideoSources.js
│   ├── App.vue            # 主应用组件
│   └── main.js            # 入口文件
├── index.html             # HTML模板
├── package.json           # 项目配置
├── vite.config.js         # Vite配置
└── README.md             # 说明文档
```

## 功能说明

### 搜索功能

1. **关键字搜索**: 在侧边栏输入关键字进行搜索
2. **空搜索**: 不输入关键字直接搜索将返回最新内容
3. **类型筛选**: 可选择电影或电视剧类型
4. **标签筛选**: 根据豆瓣标签进行内容筛选

### 视频源管理

1. 在侧边栏点击"视频源选择"
2. 选择要使用的视频源
3. 支持全选、反选操作
4. 设置保存到本地存储

### 内容过滤

1. 在侧边栏点击"过滤设置"
2. 输入管理员密码（默认: 8228）
3. 开启/关闭成人内容过滤
4. 可修改管理员密码

### 响应式设计

- **移动端**: 优化的触控体验，适配小屏幕
- **平板端**: 中等屏幕的良好显示
- **桌面端**: 大屏幕下的网格布局

## 样式说明

项目保持了原HTML页面的设计风格：

- **主色调**: 深蓝色主题 (#18192b, #23244a)
- **强调色**: 紫色渐变 (#6c63ff)
- **圆角设计**: 现代化的圆角卡片
- **动画效果**: 流畅的过渡动画
- **玻璃拟态**: 模糊背景效果

## 部署说明

### 开发环境

确保Go后端服务运行在8228端口，前端开发服务器会自动代理API请求。

**推荐使用根目录的 `start.sh` 脚本同时启动前后端：**

```bash
# 在项目根目录运行
./start.sh
```

该脚本会：
- 自动编译Go后端
- 检查并安装前端依赖
- 同时启动前端(3000端口)和后端(8228端口)
- macOS系统自动打开浏览器

### 生产环境

1. 构建前端：`npm run build`
2. 将`dist/`目录内容部署到Web服务器
3. 配置Web服务器代理API请求到Go后端

### Docker部署

可以使用Dockerfile构建容器镜像：

```dockerfile
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf
```

## 注意事项

1. **API兼容性**: 确保后端API接口与前端预期一致
2. **CORS设置**: 生产环境需要正确配置CORS
3. **代理配置**: 生产环境需要配置Web服务器代理
4. **移动端优化**: 已针对iOS设备进行特殊优化

## 开发指南

### 添加新组件

1. 在`src/components/`目录创建Vue文件
2. 使用Composition API
3. 遵循现有的样式约定

### 添加新功能

1. 考虑是否需要新的composable
2. 更新相关组件的props和emits
3. 确保响应式设计兼容

### 样式开发

1. 使用scoped CSS避免样式冲突
2. 遵循现有的色彩方案
3. 确保移动端和桌面端的兼容性

## 许可证

本项目仅供学习交流使用。 