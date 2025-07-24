<template>
  <div class="douban-section">
    <!-- 豆瓣推荐头部 -->
    <div class="douban-header">
      <h2 class="section-title">
        豆瓣推荐
        <span class="current-category">{{ currentCategoryText }}</span>
      </h2>
    </div>
    
    <!-- 豆瓣推荐内容网格 -->
    <div class="douban-grid" :class="{ 'tag-switching': isTagSwitching }">
      <transition-group 
        name="card-fade" 
        tag="div" 
        class="video-cards-container"
      >
        <VideoCard 
          v-for="video in filteredVideos" 
          :key="video.id || video.vod_id"
          :video="video"
          :source="'豆瓣推荐'"
          @click="onVideoClick"
        />
      </transition-group>
      
      <!-- 加载状态 -->
      <div v-if="loading && videos.length === 0" class="loading-card">
        <div class="loading-spinner"></div>
        <div class="loading-text">正在获取豆瓣推荐...</div>
      </div>
    </div>
    
    <!-- 无限滚动加载指示器 -->
    <div v-if="loading && videos.length > 0" class="infinite-loading">
      <div class="infinite-loading-spinner"></div>
      <div class="infinite-loading-text">正在加载更多内容...</div>
    </div>
    
    <!-- 加载更多按钮 (备用选项) -->
    <div v-if="!loading && !noMore && videos.length > 0" class="load-more">
      <button class="load-more-btn" @click="loadMore" :disabled="loading">
        手动加载更多
      </button>
      <div class="auto-load-tip">💡 向下滚动可自动加载</div>
    </div>
    
    <!-- 结束提示 -->
    <div v-if="noMore && videos.length > 0" class="end-message">
      <div class="end-icon">🎬</div>
      <div class="end-text">已加载全部内容</div>
    </div>
    
    <!-- 空状态 -->
    <div v-if="!loading && videos.length === 0" class="no-results">
      <div class="no-results-icon">🎬</div>
      <div class="no-results-text">暂无豆瓣推荐内容</div>
      <div class="no-results-sub">请稍后重试或切换分类</div>
    </div>

    <div v-if="loading" class="loading-tip">
      正在加载数据，请稍候...
    </div>
  </div>
</template>

<script>
import { defineComponent, ref, computed, watch, onMounted, onUnmounted } from 'vue'
import VideoCard from './VideoCard.vue'
import { useToast } from '@/composables/useToast'
import api from '@/services/api.js'

export default defineComponent({
  name: 'DouBan',
  components: {
    VideoCard
  },
  props: {
    currentType: {
      type: String,
      default: 'movie'
    },
    currentTag: {
      type: String,
      default: ''
    },
    showingDetail: {
      type: Boolean,
      default: false
    }
  },
  emits: ['video-click'],
  setup(props, { emit }) {
    const { showToast } = useToast()
    
    // 豆瓣推荐状态
    const videos = ref([])
    const loading = ref(false)
    const noMore = ref(false)
    const pageStart = ref(0)
    const pageLimit = 20
    const isTagSwitching = ref(false)
    
    // 计算属性
    const currentCategoryText = computed(() => {
      const typeText = props.currentType === 'movie' ? '电影' : '电视剧'
      const tagText = props.currentTag ? ` · ${props.currentTag}` : ''
      return `${typeText}${tagText}`
    })
    
    const filteredVideos = computed(() => {
      return videos.value.filter(video => {
        if (!video) return false
        
        // 基础过滤：确保有标题
        const hasTitle = video.title || video.vod_name || video.name
        if (!hasTitle) return false
        
        // 类型过滤
        if (props.currentType && video.type && video.type !== props.currentType) {
          return false
        }
        
        return true
      })
    })
    
    // 方法
    const fetchRecommendations = async (reset = false) => {
      if (loading.value) return
      
      loading.value = true
      console.log(`正在加载豆瓣推荐: 类型=${props.currentType}, 标签=${props.currentTag}, 页码=${pageStart.value}`)
      
      try {
        const params = {
          type: props.currentType,
          tag: props.currentTag,
          pageLimit: pageLimit,
          pageStart: reset ? 0 : pageStart.value
        }
        
        const data = await api.douban.subjects(params)
        const newVideos = data.subjects || []
        console.log(`豆瓣推荐加载成功: 获取到${newVideos.length}个内容`)
        
        if (reset) {
          videos.value = newVideos
          pageStart.value = pageLimit
          noMore.value = false
        } else {
          videos.value = videos.value.concat(newVideos)
          pageStart.value += pageLimit
        }
        
        if (newVideos.length < pageLimit) {
          noMore.value = true
        }
        
      } catch (error) {
        console.error('豆瓣推荐加载失败:', error)
        showToast('豆瓣推荐加载失败', 'error', 2000)
        
        if (reset) {
          videos.value = []
        }
      } finally {
        loading.value = false
        // 清除标签切换状态
        if (isTagSwitching.value) {
          setTimeout(() => {
            isTagSwitching.value = false
          }, 100) // 让新内容显示后再清除过渡状态
        }
      }
    }
    
    const loadMore = () => {
      if (!loading.value && !noMore.value) {
        fetchRecommendations(false)
      }
    }
    
    const refreshRecommendations = (isFromTagSwitch = false) => {
      if (isFromTagSwitch) {
        isTagSwitching.value = true
        // 延迟一点开始加载，让过渡效果先执行
        setTimeout(() => {
          pageStart.value = 0
          noMore.value = false
          fetchRecommendations(true)
        }, 250)
      } else {
        pageStart.value = 0
        noMore.value = false
        fetchRecommendations(true)
      }
    }
    
    const onVideoClick = (video) => {
      console.log('豆瓣视频点击:', video)
      emit('video-click', video)
    }

    // 无限滚动功能
    const handleScroll = () => {
      if (loading.value || noMore.value) return
      
      // 获取窗口和文档的滚动信息
      const scrollTop = window.pageYOffset || document.documentElement.scrollTop
      const windowHeight = window.innerHeight
      const documentHeight = document.documentElement.scrollHeight
      
      // 当滚动到距离底部200px时，自动加载更多
      const threshold = 200
      const isNearBottom = scrollTop + windowHeight >= documentHeight - threshold
      
      if (isNearBottom) {
        console.log('检测到滚动接近底部，自动加载更多内容...')
        loadMore()
      }
    }

    // 节流处理滚动事件
    let scrollTimer = null
    const throttledScroll = () => {
      if (scrollTimer) return
      scrollTimer = setTimeout(() => {
        handleScroll()
        scrollTimer = null
      }, 100) // 100ms节流
    }

    // 滚动监听器管理
    let scrollListenerActive = false
    
    const enableScrollListener = () => {
      if (!scrollListenerActive) {
        window.addEventListener('scroll', throttledScroll)
        scrollListenerActive = true
        console.log('无限滚动监听器已启用')
      }
    }
    
    const disableScrollListener = () => {
      if (scrollListenerActive) {
        window.removeEventListener('scroll', throttledScroll)
        scrollListenerActive = false
        console.log('无限滚动监听器已禁用')
      }
    }
    
    // 监听器
    watch(() => [props.currentType, props.currentTag], ([newType, newTag], [oldType, oldTag]) => {
      console.log(`豆瓣推荐参数变化: 类型 ${oldType} → ${newType}, 标签 "${oldTag}" → "${newTag}"，重新加载...`)
      refreshRecommendations(true) // 标签切换
    }, { immediate: false })

    // 监听详情页面状态变化，控制滚动监听器
    watch(() => props.showingDetail, (newValue) => {
      if (newValue) {
        // 显示详情页面时禁用滚动监听器
        disableScrollListener()
      } else {
        // 回到列表页面时启用滚动监听器
        enableScrollListener()
      }
    })
    
    // 生命周期
    onMounted(() => {
      console.log('豆瓣组件挂载，开始加载推荐内容')
      fetchRecommendations(true)
      
      // 根据当前状态决定是否启用滚动监听器
      if (!props.showingDetail) {
        enableScrollListener()
      }
    })

    onUnmounted(() => {
      // 清理滚动监听器
      disableScrollListener()
      
      // 清理节流定时器
      if (scrollTimer) {
        clearTimeout(scrollTimer)
        scrollTimer = null
      }
      
      console.log('豆瓣组件卸载，滚动监听器已移除')
    })
    
    // 暴露给父组件的方法
    const exposed = {
      refreshRecommendations,
      loadMore
    }
    
    return {
      // 状态
      videos,
      loading,
      noMore,
      currentCategoryText,
      filteredVideos,
      isTagSwitching,
      
      // 方法
      loadMore,
      onVideoClick,
      
      // 暴露方法
      ...exposed
    }
  }
})
</script>

<style scoped>
/* 豆瓣推荐区域 */
.douban-section {
  width: 100%;
  box-sizing: border-box;
}



.douban-header {
  margin-bottom: 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.section-title {
  font-size: 20px;
  font-weight: 600;
  color: #fff;
  margin: 0;
}

.current-category {
  font-size: 15px;
  font-weight: 400;
  color: #b3b6d4;
  margin-left: 12px;
}

/* 豆瓣推荐网格 */
.douban-grid {
  margin-bottom: 20px;
  width: 100%;
  box-sizing: border-box;
  padding: 0;
  margin-left: 0;
  margin-right: 0;
}

.douban-grid .video-cards-container {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 20px;
}

/* 标签切换过渡效果 */
.douban-grid {
  transition: opacity 0.5s ease, filter 0.5s ease;
}

.douban-grid.tag-switching {
  opacity: 0.3;
  filter: blur(4px);
}

/* 卡片渐入动画 */
.card-fade-enter-active {
  transition: opacity 0.3s ease, filter 0.2s ease;
}

.card-fade-enter-from {
  opacity: 0;
  filter: blur(4px);
}

.card-fade-enter-to {
  opacity: 1;
  filter: blur(0);
}

/* 加载状态 */
.loading-card {
  background: #23244a;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 280px;
  border: 2px dashed #3a3b5a;
  grid-column: 1/-1;
}

.loading-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #3a3b5a;
  border-top: 3px solid #6c63ff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 12px;
}

.loading-text {
  font-size: 14px;
  color: #b3b6d4;
  font-weight: 500;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* 无结果状态 */
.no-results {
  text-align: center;
  padding: 40px 20px;
  color: #b3b6d4;
  grid-column: 1/-1;
}

.no-results-icon {
  font-size: 48px;
  margin-bottom: 16px;
  opacity: 0.5;
}

.no-results-text {
  font-size: 16px;
  font-weight: 500;
  margin-bottom: 8px;
}

.no-results-sub {
  font-size: 14px;
  opacity: 0.7;
}

/* 无限滚动加载指示器 */
.infinite-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 16px;
  color: #b3b6d4;
}

.infinite-loading-spinner {
  width: 24px;
  height: 24px;
  border: 2px solid #3a3b5a;
  border-top: 2px solid #6c63ff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 8px;
}

.infinite-loading-text {
  font-size: 14px;
  opacity: 0.8;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* 加载更多 */
.load-more {
  text-align: center;
  padding: 20px;
  color: #b3b6d4;
}

.auto-load-tip {
  font-size: 12px;
  color: #8a8db6;
  margin-top: 8px;
  opacity: 0.7;
}

.load-more-btn {
  padding: 12px 24px;
  background: #6c63ff;
  color: #fff;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
  transition: background 0.3s;
}

.load-more-btn:hover:not(:disabled) {
  background: #554eea;
}

.load-more-btn:disabled {
  background: #3a3b5a;
  cursor: not-allowed;
}

.end-message {
  color: #b3b6d4;
  padding: 24px 0;
  text-align: center;
  width: 100%;
  grid-column: 1/-1;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.end-icon {
  font-size: 32px;
  opacity: 0.6;
  margin-bottom: 8px;
}

.end-text {
  font-size: 14px;
  opacity: 0.8;
}

/* 中等屏幕优化 */
@media (min-width: 481px) and (max-width: 768px) {
  .video-cards-container {
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
    gap: 12px;
  }
}

/* 响应式调整 */
@media (max-width: 480px) {
  .video-cards-container {
    grid-template-columns: 1fr 1fr !important;
    gap: 8px;
  }
  
  .loading-card {
    min-height: 240px;
  }
  
  .loading-spinner {
    width: 28px;
    height: 28px;
    border: 2px solid #3a3b5a;
    border-top: 2px solid #6c63ff;
    margin-bottom: 10px;
  }
  
  .loading-text {
    font-size: 13px;
  }
}

@media (max-width: 360px) {
  .video-cards-container {
    grid-template-columns: 1fr 1fr !important;
    gap: 6px;
  }
}

/* PC分辨率下的样式 */
@media (min-width: 769px) {
  .video-cards-container {
    grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
    gap: 20px;
    max-width: none;
  }
  
  .section-title {
    font-size: 24px;
    margin-bottom: 24px;
  }
}

/* 超大屏幕优化 */
@media (min-width: 1200px) {
  .video-cards-container {
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 24px;
  }
}

/* 4K屏幕优化 */
@media (min-width: 1600px) {
  .video-cards-container {
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
    gap: 28px;
  }
}

@media (max-width: 600px) {
  .douban-grid .video-cards-container {
    grid-template-columns: 1fr 1fr !important;
    gap: 8px;
  }
}

.loading-tip {
  text-align: center;
  color: #888;
  font-size: 15px;
  margin: 16px 0 0 0;
}
</style> 