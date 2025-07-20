// API使用示例文件
// 展示如何使用统一的API服务

import api, { ApiService } from './api.js'
import { API_CONFIG, API_ENDPOINTS } from '../config/api.js'

// ===== 使用便捷的 api 对象 =====

// 1. 获取视频源列表
export async function exampleGetSources() {
  try {
    const data = await api.sources.list()
    console.log('视频源列表:', data)
    return data
  } catch (error) {
    console.error('获取视频源失败:', error)
  }
}

// 2. 搜索视频
export async function exampleSearchVideos(keyword) {
  try {
    const data = await api.search.videos(keyword)
    console.log('搜索结果:', data)
    return data
  } catch (error) {
    console.error('搜索失败:', error)
  }
}

// 3. 获取豆瓣标签
export async function exampleGetDoubanTags(type = 'movie') {
  try {
    const data = await api.douban.tags(type)
    console.log('豆瓣标签:', data)
    return data
  } catch (error) {
    console.error('获取标签失败:', error)
  }
}

// 4. 获取豆瓣推荐内容
export async function exampleGetDoubanSubjects() {
  try {
    const params = {
      type: 'movie',
      tag: '最新',
      pageLimit: 20,
      pageStart: 0
    }
    const data = await api.douban.subjects(params)
    console.log('豆瓣推荐:', data)
    return data
  } catch (error) {
    console.error('获取推荐失败:', error)
  }
}

// ===== 使用 ApiService 类 =====

// 5. 直接使用ApiService类
export async function exampleUsingApiService() {
  try {
    // 获取健康状态
    const health = await ApiService.checkHealth()
    console.log('健康状态:', health)
    
    // 获取过滤配置
    const config = await ApiService.getFilterConfig()
    console.log('过滤配置:', config)
    
    return { health, config }
  } catch (error) {
    console.error('ApiService调用失败:', error)
  }
}

// ===== 使用通用请求方法 =====

// 6. 使用通用请求方法
export async function exampleGenericRequest() {
  try {
    // 使用通用GET请求
    const data = await api.request('/health')
    console.log('通用请求结果:', data)
    return data
  } catch (error) {
    console.error('通用请求失败:', error)
  }
}

// 7. 使用带重试的请求
export async function exampleRetryRequest() {
  try {
    const data = await api.requestWithRetry('/api/sources')
    console.log('重试请求结果:', data)
    return data
  } catch (error) {
    console.error('重试请求失败:', error)
  }
}

// ===== 在Vue组件中的使用示例 =====

// 8. Vue组件中的完整使用示例
export const VueComponentExample = {
  setup() {
    const { ref, onMounted } = Vue
    
    const sources = ref([])
    const tags = ref([])
    const videos = ref([])
    const loading = ref(false)
    
    // 获取视频源
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
    
    // 获取标签
    const fetchTags = async (type = 'movie') => {
      try {
        const data = await api.douban.tags(type)
        tags.value = data.tags || []
      } catch (error) {
        console.error('获取标签失败:', error)
      }
    }
    
    // 搜索视频
    const searchVideos = async (keyword) => {
      loading.value = true
      try {
        const data = await api.search.videos(keyword)
        if (data.success) {
          videos.value = data.data || []
        }
      } catch (error) {
        console.error('搜索失败:', error)
      } finally {
        loading.value = false
      }
    }
    
    // 组件挂载时获取数据
    onMounted(() => {
      fetchSources()
      fetchTags()
    })
    
    return {
      sources,
      tags,
      videos,
      loading,
      fetchSources,
      fetchTags,
      searchVideos
    }
  }
}

// ===== 错误处理示例 =====

// 9. 完整的错误处理示例
export async function exampleWithErrorHandling() {
  try {
    // 模拟可能失败的请求
    const data = await api.douban.subjects({
      type: 'movie',
      tag: '不存在的标签',
      pageLimit: 20,
      pageStart: 0
    })
    
    return data
  } catch (error) {
    // 根据错误类型进行不同处理
    if (error.message.includes('超时')) {
      console.error('请求超时，请稍后重试')
      // 可以显示重试按钮
    } else if (error.message.includes('网络')) {
      console.error('网络连接失败，请检查网络')
      // 可以显示网络检查提示
    } else {
      console.error('未知错误:', error.message)
      // 显示通用错误提示
    }
    
    // 返回默认值或重新抛出错误
    return { success: false, error: error.message }
  }
}

// ===== 配置修改示例 =====

// 10. 动态修改API配置
export function exampleConfigModification() {
  console.log('当前配置:', API_CONFIG)
  console.log('所有端点:', API_ENDPOINTS)
  
  // 在开发时可能需要切换不同的后端地址
  // 注意：实际使用中应该通过环境变量或配置文件来管理
  console.log('如需修改配置，请编辑 src/config/api.js 文件')
}

// ===== 批量请求示例 =====

// 11. 并发请求示例
export async function exampleConcurrentRequests() {
  try {
    // 同时发起多个请求
    const [sourcesResult, tagsResult, healthResult] = await Promise.all([
      api.sources.list(),
      api.douban.tags('movie'),
      api.health()
    ])
    
    console.log('并发请求结果:', {
      sources: sourcesResult,
      tags: tagsResult,
      health: healthResult
    })
    
    return { sourcesResult, tagsResult, healthResult }
  } catch (error) {
    console.error('并发请求失败:', error)
  }
}

// ===== 导出所有示例 =====

export const examples = {
  getSources: exampleGetSources,
  searchVideos: exampleSearchVideos,
  getDoubanTags: exampleGetDoubanTags,
  getDoubanSubjects: exampleGetDoubanSubjects,
  usingApiService: exampleUsingApiService,
  genericRequest: exampleGenericRequest,
  retryRequest: exampleRetryRequest,
  withErrorHandling: exampleWithErrorHandling,
  configModification: exampleConfigModification,
  concurrentRequests: exampleConcurrentRequests
}

// 使用说明
console.log(`
📚 API使用指南:

1. 基础使用:
   import api from '@/services/api.js'
   const data = await api.sources.list()

2. 错误处理:
   try {
     const data = await api.search.videos('关键字')
   } catch (error) {
     console.error('搜索失败:', error)
   }

3. 配置修改:
   编辑 src/config/api.js 文件

4. 查看更多示例:
   import { examples } from '@/services/examples.js'
   examples.getSources()
`)

export default examples 