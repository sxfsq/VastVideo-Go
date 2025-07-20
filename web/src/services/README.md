# API服务使用文档

本文档介绍如何使用统一的API服务来调用后端接口。

## 📁 文件结构

```
src/
├── config/
│   └── api.js          # API配置文件（基础地址、端点定义）
├── services/
│   ├── api.js          # API服务文件（HTTP客户端、接口方法）
│   ├── examples.js     # 使用示例
│   └── README.md       # 本文档
```

## 🚀 快速开始

### 1. 基础使用

```javascript
import api from '@/services/api.js'

// 获取视频源列表
const sources = await api.sources.list()

// 搜索视频
const searchResults = await api.search.videos('复仇者联盟')

// 获取豆瓣标签
const tags = await api.douban.tags('movie')

// 获取推荐内容
const recommendations = await api.douban.subjects({
  type: 'movie',
  tag: '最新',
  pageLimit: 20,
  pageStart: 0
})
```

### 2. 在Vue组件中使用

```vue
<script setup>
import { ref, onMounted } from 'vue'
import api from '@/services/api.js'

const sources = ref([])
const loading = ref(false)

const fetchSources = async () => {
  loading.value = true
  try {
    const data = await api.sources.list()
    if (data.success) {
      sources.value = data.data
    }
  } catch (error) {
    console.error('获取视频源失败:', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchSources()
})
</script>
```

## 🔧 配置管理

### API配置文件 (`src/config/api.js`)

```javascript
// 基础配置
export const API_CONFIG = {
  BASE_URL: import.meta.env.DEV ? 'http://localhost:8228' : '',
  TIMEOUT: 10000,
  RETRY_COUNT: 3,
  RETRY_DELAY: 1000
}

// API端点
export const API_ENDPOINTS = {
  SOURCES: {
    LIST: '/api/sources',
    SEARCH: '/api/source_search'
  },
  // ... 更多端点
}
```

### 环境配置

- **开发环境**: 使用 `http://localhost:8228` 作为后端地址
- **生产环境**: 使用相对路径，由前端服务器代理

## 📡 API接口列表

### 视频源相关

| 方法 | 描述 | 用法 |
|------|------|------|
| `api.sources.list()` | 获取视频源列表 | `await api.sources.list()` |
| `api.sources.search(keyword)` | 搜索视频源 | `await api.sources.search('暴风')` |

### 搜索相关

| 方法 | 描述 | 用法 |
|------|------|------|
| `api.search.videos(keyword)` | 搜索视频 | `await api.search.videos('复仇者联盟')` |
| `api.search.latest()` | 获取最新视频 | `await api.search.latest()` |

### 豆瓣相关

| 方法 | 描述 | 用法 |
|------|------|------|
| `api.douban.tags(type)` | 获取标签 | `await api.douban.tags('movie')` |
| `api.douban.subjects(params)` | 获取推荐内容 | `await api.douban.subjects({...})` |

### 配置相关

| 方法 | 描述 | 用法 |
|------|------|------|
| `api.config.filter()` | 获取过滤配置 | `await api.config.filter()` |

### 健康检查

| 方法 | 描述 | 用法 |
|------|------|------|
| `api.health()` | 健康检查 | `await api.health()` |

## 🛠 高级用法

### 1. 使用ApiService类

```javascript
import { ApiService } from '@/services/api.js'

// 直接使用类方法
const sources = await ApiService.getSources()
const health = await ApiService.checkHealth()
```

### 2. 通用请求方法

```javascript
// 通用GET请求
const data = await api.request('/custom/endpoint')

// 带重试的请求
const data = await api.requestWithRetry('/api/sources')

// 自定义请求选项
const data = await api.request('/api/search', {
  method: 'POST',
  body: JSON.stringify({ keyword: '搜索词' })
})
```

### 3. 并发请求

```javascript
// 同时发起多个请求
const [sources, tags, health] = await Promise.all([
  api.sources.list(),
  api.douban.tags('movie'),
  api.health()
])
```

## 🔄 错误处理

### 1. 基础错误处理

```javascript
try {
  const data = await api.search.videos('关键字')
  // 处理成功响应
} catch (error) {
  console.error('搜索失败:', error.message)
  // 处理错误
}
```

### 2. 错误类型

- **网络错误**: `"网络连接失败，请检查网络状态"`
- **超时错误**: `"请求超时"`
- **HTTP错误**: `"HTTP 404: Not Found"`

### 3. 错误处理策略

```javascript
const handleApiError = (error) => {
  if (error.message.includes('超时')) {
    // 显示重试按钮
    showRetryButton()
  } else if (error.message.includes('网络')) {
    // 显示网络检查提示
    showNetworkTip()
  } else {
    // 显示通用错误
    showErrorMessage(error.message)
  }
}
```

## 🎯 最佳实践

### 1. 统一错误处理

创建全局错误处理器：

```javascript
// utils/errorHandler.js
export const handleApiError = (error, toast) => {
  let message = '操作失败'
  
  if (error.message.includes('超时')) {
    message = '请求超时，请稍后重试'
  } else if (error.message.includes('网络')) {
    message = '网络连接失败，请检查网络'
  } else {
    message = error.message
  }
  
  toast.show(message, 'error')
}
```

### 2. 请求缓存

对于不常变化的数据，可以添加缓存：

```javascript
// composables/useApiCache.js
import { ref } from 'vue'

const cache = new Map()

export const useApiCache = (key, apiCall) => {
  const data = ref(null)
  const loading = ref(false)
  
  const fetch = async (...args) => {
    const cacheKey = key + JSON.stringify(args)
    
    if (cache.has(cacheKey)) {
      data.value = cache.get(cacheKey)
      return data.value
    }
    
    loading.value = true
    try {
      const result = await apiCall(...args)
      cache.set(cacheKey, result)
      data.value = result
      return result
    } finally {
      loading.value = false
    }
  }
  
  return { data, loading, fetch }
}
```

### 3. 请求拦截器

添加请求日志或认证：

```javascript
// 在api.js中添加
class HttpClient {
  async request(url, options = {}) {
    // 添加认证头
    if (this.authToken) {
      options.headers = {
        ...options.headers,
        'Authorization': `Bearer ${this.authToken}`
      }
    }
    
    // 记录请求日志
    console.log(`[${new Date().toISOString()}] ${options.method || 'GET'} ${url}`)
    
    // ... 执行请求
  }
}
```

## 🔧 配置修改指南

### 1. 修改后端地址

编辑 `src/config/api.js`:

```javascript
export const API_CONFIG = {
  BASE_URL: 'http://your-backend-url:port',
  // ... 其他配置
}
```

### 2. 添加新的API端点

在 `API_ENDPOINTS` 中添加：

```javascript
export const API_ENDPOINTS = {
  // ... 现有端点
  NEW_FEATURE: {
    CREATE: '/api/new-feature/create',
    UPDATE: '/api/new-feature/update'
  }
}
```

在 `api.js` 中添加对应方法：

```javascript
export const api = {
  // ... 现有API
  newFeature: {
    create: (data) => ApiService.request(API_ENDPOINTS.NEW_FEATURE.CREATE, {
      method: 'POST',
      body: JSON.stringify(data)
    }),
    update: (id, data) => ApiService.request(`${API_ENDPOINTS.NEW_FEATURE.UPDATE}/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data)
    })
  }
}
```

## 📝 使用示例

查看 `src/services/examples.js` 文件获取更多使用示例。

## 🐛 故障排除

### 1. 请求失败

- 检查网络连接
- 确认后端服务是否正常运行
- 检查API地址配置是否正确

### 2. 跨域问题

- 开发环境：配置Vite代理（已在 `vite.config.js` 中配置）
- 生产环境：确保后端正确设置CORS头

### 3. 超时问题

- 增加超时时间：修改 `API_CONFIG.TIMEOUT`
- 检查网络状况
- 优化后端响应速度

## 📊 性能优化

### 1. 请求去重

避免重复请求：

```javascript
const pendingRequests = new Map()

const request = async (url, options) => {
  const key = url + JSON.stringify(options)
  
  if (pendingRequests.has(key)) {
    return pendingRequests.get(key)
  }
  
  const promise = fetch(url, options)
  pendingRequests.set(key, promise)
  
  try {
    const result = await promise
    return result
  } finally {
    pendingRequests.delete(key)
  }
}
```

### 2. 请求批处理

将多个小请求合并：

```javascript
const batchRequests = (requests) => {
  return Promise.all(requests.map(request => 
    request.catch(error => ({ error }))
  ))
}
```

---

📞 **需要帮助？** 

查看示例文件 `src/services/examples.js` 或者在项目中搜索API的具体使用方法。 