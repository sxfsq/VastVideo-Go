// API服务文件
// 统一管理所有HTTP请求和接口调用

import { 
  API_CONFIG, 
  API_ENDPOINTS, 
  getApiUrl, 
  getDoubanTagsUrl, 
  getDoubanSubjectsUrl,
  getCurrentEnvConfig 
} from '../config/api.js'

// HTTP请求工具类
class HttpClient {
  constructor() {
    this.config = getCurrentEnvConfig()
    this.requestCount = 0
  }

  // 基础请求方法
  async request(url, options = {}) {
    const requestId = ++this.requestCount
    console.log(`[API-${requestId}] 请求: ${options.method || 'GET'} ${url}`)

    const defaultOptions = {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      timeout: API_CONFIG.TIMEOUT,
      ...options
    }

    // 添加超时控制
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), defaultOptions.timeout)

    try {
      const response = await fetch(url, {
        ...defaultOptions,
        signal: controller.signal
      })

      clearTimeout(timeoutId)

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }

      const data = await response.json()
      console.log(`[API-${requestId}] 响应成功:`, response.status)
      return data

    } catch (error) {
      clearTimeout(timeoutId)
      console.error(`[API-${requestId}] 请求失败:`, error.message)
      throw this.handleError(error)
    }
  }

  // GET请求
  async get(url, params = {}) {
    const urlWithParams = this.buildUrlWithParams(url, params)
    return this.request(urlWithParams, { method: 'GET' })
  }

  // POST请求
  async post(url, data = {}) {
    return this.request(url, {
      method: 'POST',
      body: JSON.stringify(data)
    })
  }

  // 带重试的请求
  async requestWithRetry(url, options = {}, retryCount = API_CONFIG.RETRY_COUNT) {
    try {
      return await this.request(url, options)
    } catch (error) {
      if (retryCount > 0 && this.shouldRetry(error)) {
        console.log(`请求失败，${API_CONFIG.RETRY_DELAY}ms后重试，剩余重试次数: ${retryCount}`)
        await this.delay(API_CONFIG.RETRY_DELAY)
        return this.requestWithRetry(url, options, retryCount - 1)
      }
      throw error
    }
  }

  // 构建带参数的URL
  buildUrlWithParams(url, params) {
    if (!params || Object.keys(params).length === 0) {
      return url
    }

    const searchParams = new URLSearchParams()
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        searchParams.append(key, value.toString())
      }
    })

    const paramString = searchParams.toString()
    return paramString ? `${url}?${paramString}` : url
  }

  // 判断是否应该重试
  shouldRetry(error) {
    // 网络错误或服务器错误可以重试
    return error.name === 'TypeError' || 
           error.message.includes('fetch') ||
           error.message.includes('5')
  }

  // 延迟函数
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  // 错误处理
  handleError(error) {
    if (error.name === 'AbortError') {
      return new Error('请求超时')
    }
    if (error.message.includes('Failed to fetch')) {
      return new Error('网络连接失败，请检查网络状态')
    }
    return error
  }
}

// 创建HTTP客户端实例
const httpClient = new HttpClient()

// API服务类
export class ApiService {
  // 视频源相关API
  static async getSources() {
    const url = getApiUrl(API_ENDPOINTS.SOURCES.LIST)
    return httpClient.get(url)
  }

  static async searchSources(keyword) {
    const url = getApiUrl(API_ENDPOINTS.SOURCES.SEARCH)
    return httpClient.post(url, { keyword })
  }

  // 指定源搜索视频
  static async searchVideosBySource(source, keyword, page = 1) {
    const url = getApiUrl(API_ENDPOINTS.SOURCES.SEARCH)
    const params = new URLSearchParams({
      source: source,
      keyword: keyword,
      page: page.toString()
    })
    return httpClient.get(`${url}?${params.toString()}`)
  }

  // 搜索相关API
  static async searchVideos(keyword) {
    const url = getApiUrl(API_ENDPOINTS.SEARCH.VIDEO)
    return httpClient.post(url, { keyword })
  }

  static async getLatestVideos() {
    const url = getApiUrl(API_ENDPOINTS.SEARCH.LATEST)
    return httpClient.get(url)
  }

  // 豆瓣相关API
  static async getDoubanTags(type) {
    const url = getDoubanTagsUrl(type)
    return httpClient.get(url)
  }

  static async getDoubanSubjects(params) {
    const url = getDoubanSubjectsUrl(params)
    return httpClient.get(url)
  }

  // 配置相关API
  static async getFilterConfig() {
    const url = getApiUrl(API_ENDPOINTS.CONFIG.FILTER)
    return httpClient.get(url)
  }

  // 健康检查API
  static async checkHealth() {
    const url = getApiUrl(API_ENDPOINTS.HEALTH)
    return httpClient.get(url)
  }

  // 通用请求方法
  static async request(endpoint, options = {}) {
    const url = getApiUrl(endpoint)
    return httpClient.request(url, options)
  }

  // 带重试的请求方法
  static async requestWithRetry(endpoint, options = {}) {
    const url = getApiUrl(endpoint)
    return httpClient.requestWithRetry(url, options)
  }
}

// 便捷的API调用方法
export const api = {
  // 视频源
  sources: {
    list: () => ApiService.getSources(),
    search: (keyword) => ApiService.searchSources(keyword)
  },

  // 搜索
  search: {
    videos: (keyword) => ApiService.searchVideos(keyword),
    videosBySource: (source, keyword, page) => ApiService.searchVideosBySource(source, keyword, page),
    latest: () => ApiService.getLatestVideos()
  },

  // 豆瓣
  douban: {
    tags: (type) => ApiService.getDoubanTags(type),
    subjects: (params) => ApiService.getDoubanSubjects(params)
  },

  // 配置
  config: {
    filter: () => ApiService.getFilterConfig()
  },

  // 健康检查
  health: () => ApiService.checkHealth(),

  // 通用方法
  request: (endpoint, options) => ApiService.request(endpoint, options),
  requestWithRetry: (endpoint, options) => ApiService.requestWithRetry(endpoint, options)
}

// 默认导出API服务
export default api 