// API配置文件
// 统一管理所有后端接口地址和配置

// 基础配置
export const API_CONFIG = {
  // 基础地址 - 根据环境自动切换
  BASE_URL: import.meta.env.DEV ? 'http://127.0.0.1:8228' : '',
  
  // 请求超时时间
  TIMEOUT: 10000,
  
  // 重试次数
  RETRY_COUNT: 3,
  
  // 重试延迟(毫秒)
  RETRY_DELAY: 1000
}

// API端点路径
export const API_ENDPOINTS = {
  // 视频源相关
  SOURCES: {
    LIST: '/api/sources',                    // 获取视频源列表
    SEARCH: '/api/source_search'             // 视频源搜索
  },
  
  // 搜索相关
  SEARCH: {
    VIDEO: '/api/search',                    // 搜索视频
    LATEST: '/api/latest'                    // 获取最新视频
  },
  
  // 豆瓣相关
  DOUBAN: {
    BASE: '/douban',                         // 豆瓣API基础路径
    TAGS: '/douban?action=tags',             // 获取标签
    SUBJECTS: '/douban?action=subjects'      // 获取推荐内容
  },
  
  // 配置相关
  CONFIG: {
    FILTER: '/api/filter_config'             // 过滤配置
  },
  
  // 健康检查
  HEALTH: '/health'
}

// 生成完整的API URL
export const getApiUrl = (endpoint) => {
  return `${API_CONFIG.BASE_URL}${endpoint}`
}

// 生成豆瓣标签URL
export const getDoubanTagsUrl = (type) => {
  return `${API_CONFIG.BASE_URL}${API_ENDPOINTS.DOUBAN.TAGS}&type=${encodeURIComponent(type)}`
}

// 生成豆瓣推荐内容URL
export const getDoubanSubjectsUrl = (params) => {
  const { type, tag = '', pageLimit = 20, pageStart = 0 } = params
  const queryParams = new URLSearchParams({
    action: 'subjects',
    type: type,
    tag: tag,
    page_limit: pageLimit.toString(),
    page_start: pageStart.toString()
  })
  return `${API_CONFIG.BASE_URL}${API_ENDPOINTS.DOUBAN.BASE}?${queryParams.toString()}`
}

// 环境配置
export const ENV_CONFIG = {
  // 开发环境
  development: {
    BASE_URL: 'http://127.0.0.1:8228',
    LOG_LEVEL: 'debug'
  },
  
  // 生产环境
  production: {
    BASE_URL: '',  // 生产环境使用相对路径
    LOG_LEVEL: 'error'
  }
}

// 获取当前环境配置
export const getCurrentEnvConfig = () => {
  const env = import.meta.env.MODE || 'development'
  return ENV_CONFIG[env] || ENV_CONFIG.development
} 

// 获取所有视频源
export function getAllSources() {
  return fetch('/api/sources').then(res => res.json());
}

// 获取某个源的最新推荐
export function getSourceLatest(sourceCode) {
  return fetch(`/api/source_search?source=${encodeURIComponent(sourceCode)}&latest=true`)
    .then(res => res.json());
}

// 某个源关键词搜索
export function searchSourceVideos(sourceCode, keyword, page = 1) {
  return fetch(`/api/source_search?source=${encodeURIComponent(sourceCode)}&keyword=${encodeURIComponent(keyword)}&page=${page}`)
    .then(res => res.json());
}

// 并发获取所有源的最新推荐，合并结果（部分失败不影响）
export async function getAllSourcesLatest() {
  const sourcesRes = await getAllSources();
  if (!sourcesRes.success) return [];
  const sources = sourcesRes.data;
  const allResults = await Promise.allSettled(
    sources.map(src => getSourceLatest(src.code).then(res => res.data || []))
  );
  // 只取fulfilled的结果
  return allResults
    .filter(r => r.status === 'fulfilled')
    .map(r => r.value)
    .flat();
}

// 并发所有源关键词搜索，合并结果（部分失败不影响）
export async function getAllSourcesSearch(keyword, page = 1) {
  const sourcesRes = await getAllSources();
  if (!sourcesRes.success) return [];
  const sources = sourcesRes.data;
  const allResults = await Promise.allSettled(
    sources.map(src => searchSourceVideos(src.code, keyword, page).then(res => res.data || []))
  );
  return allResults
    .filter(r => r.status === 'fulfilled')
    .map(r => r.value)
    .flat();
} 