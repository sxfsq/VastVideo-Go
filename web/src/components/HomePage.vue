<template>
  <main class="main-content">
    <!-- 豆瓣推荐区 -->
    <div 
      v-if="!showSearchResults" 
      class="recommend-section"
    >
      <DouBan 
        ref="doubanRef"
        :current-type="currentType"
        :current-tag="currentTag"
        :showing-detail="showingDetail"
        @video-click="onVideoClick"
      />
    </div>
    
    <!-- 搜索结果区 -->
    <div 
      v-show="showSearchResults" 
      class="search-results-section"
    >
      <header class="search-header">
        <h2 class="section-title">{{ searchResultTitle }}</h2>
        <button class="back-to-recommend-btn" @click="backToRecommend">
          返回推荐
        </button>
      </header>
      <div class="video-grid">
        <VideoCard 
          v-for="video in filteredSearchResults" 
          :key="video.id || video.vod_id"
          :video="video"
          :source="'搜索结果'"
          @click="onVideoClick"
        />
        <div v-if="searchLoading" class="loading-card">
          <div class="loading-spinner"></div>
          <div class="loading-text">搜索中...</div>
        </div>
      </div>
      <div v-if="!searchLoading && searchResults.length === 0 && hasSearched" class="no-results">
        <div class="no-results-icon">🔍</div>
        未找到相关视频
      </div>
    </div>
  </main>
</template>

<script>
import { defineComponent, ref, computed, watch, onMounted } from 'vue'
import VideoCard from './VideoCard.vue'
import DouBan from './DouBan.vue'
import { useToast } from '@/composables/useToast'
import api from '@/services/api.js'

export default defineComponent({
  name: 'HomePage',
  components: {
    VideoCard,
    DouBan
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
    
    // 组件引用
    const doubanRef = ref(null)
    
    // 搜索状态
    const showSearchResults = ref(false)
    const searchResults = ref([])
    const searchLoading = ref(false)
    const searchResultTitle = ref('')
    const hasSearched = ref(false)
    let searchController = null
    
    // 计算属性
    const filteredSearchResults = computed(() => {
      return filterVideoContent(searchResults.value)
    })
    
    // 方法
    const backToRecommend = () => {
      showSearchResults.value = false
      hasSearched.value = false
      searchResults.value = []
      searchResultTitle.value = ''
      
      // 如果搜索控制器存在，取消搜索
      if (searchController) {
        searchController.abort()
        searchController = null
      }
    }
    
    const performSearch = async (keyword) => {
      console.log('执行搜索:', keyword)
      
      // 取消之前的搜索
      if (searchController) {
        searchController.abort()
      }
      
      searchController = new AbortController()
      searchLoading.value = true
      hasSearched.value = true
      showSearchResults.value = true
      
      if (!keyword.trim()) {
        searchResultTitle.value = '最新推荐'
        // 空搜索，获取最新视频
        await searchLatestVideos()
      } else {
        searchResultTitle.value = `搜索结果: ${keyword}`
        await searchVideos(keyword)
      }
    }
    
    const searchVideos = async (keyword) => {
      try {
        const data = await api.search.videos(keyword)
        if (data.success) {
          searchResults.value = data.data || []
          console.log(`搜索完成: 找到${searchResults.value.length}个结果`)
        } else {
          throw new Error(data.message || '搜索失败')
        }
      } catch (error) {
        if (error.name !== 'AbortError') {
          console.error('搜索失败:', error)
          showToast('搜索失败', 'error', 2000)
          searchResults.value = []
        }
      } finally {
        searchLoading.value = false
      }
    }
    
    const searchLatestVideos = async () => {
      try {
        const data = await api.search.latest()
        if (data.success) {
          searchResults.value = data.data || []
          console.log(`获取最新视频完成: 找到${searchResults.value.length}个结果`)
        } else {
          throw new Error(data.message || '获取最新视频失败')
        }
      } catch (error) {
        if (error.name !== 'AbortError') {
          console.error('获取最新视频失败:', error)
          showToast('获取最新视频失败', 'error', 2000)
          searchResults.value = []
        }
      } finally {
        searchLoading.value = false
      }
    }
    
    const onVideoClick = (video) => {
      console.log('视频点击:', video)
      emit('video-click', video)
    }
    
    // 过滤视频内容（成人内容过滤）
    const filterVideoContent = (videoList) => {
      const filterEnabled = isFilterEnabled()
      if (filterEnabled) {
        return videoList.filter(video => {
          const typeName = video.type_name || video.type || ''
          return !(typeName === '伦理片' || typeName === '理论片')
        })
      }
      return videoList
    }
    
    const isFilterEnabled = () => {
      const stored = localStorage.getItem('vastvideo_adult_filter')
      return stored ? JSON.parse(stored) : true
    }
    
    // 监听标签变化
    watch(() => props.currentTag, (newTag, oldTag) => {
      console.log('HomePage 标签变化:', oldTag, '->', newTag)
      if (newTag !== oldTag) {
        // 标签变化时，确保显示推荐页面而不是搜索结果
        showSearchResults.value = false
        hasSearched.value = false
        searchResults.value = []
        searchResultTitle.value = ''
        
        // 如果搜索控制器存在，取消搜索
        if (searchController) {
          searchController.abort()
          searchController = null
        }
      }
    })
    
    // 暴露方法给父组件
    const exposed = {
      performSearch,
      backToRecommend
    }
    
    return {
      // 组件引用
      doubanRef,
      
      // 数据
      showSearchResults,
      searchResults,
      searchLoading,
      searchResultTitle,
      hasSearched,
      filteredSearchResults,
      
      // 方法
      performSearch,
      backToRecommend,
      onVideoClick,
      
      // 暴露给父组件的方法
      ...exposed
    }
  }
})
</script>

<style scoped>
/* 主内容区 */
.main-content {
  margin-top: -2px;
  padding: 8px;
  padding-top: 8px;
  min-height: calc(100vh - 60px);
  z-index: 0 !important;
  width: 100%;
  box-sizing: border-box;
  overflow-x: hidden;
}

.recommend-section, .search-results-section {
  position: relative;
  z-index: 1000;
}



.search-header {
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

.back-to-recommend-btn {
  background: #6c63ff;
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.3s;
}

.back-to-recommend-btn:hover {
  background: #554eea;
}

/* 搜索结果视频网格 */
.video-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 10px;
  margin-bottom: 20px;
  width: 100%;
  box-sizing: border-box;
  padding: 0;
  margin-left: 0;
  margin-right: 0;
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

/* 加载更多 */
.load-more {
  text-align: center;
  padding: 20px;
  color: #b3b6d4;
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
}

/* 中等屏幕优化 */
@media (min-width: 481px) and (max-width: 768px) {
  .video-grid {
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
    gap: 12px;
  }
  
  .main-content {
    padding: 12px;
  }
}

/* 响应式调整 */
@media (max-width: 480px) {
  .video-grid {
    grid-template-columns: repeat(auto-fill, minmax(110px, 1fr));
    gap: 8px;
    width: 100%;
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
  
  .main-content {
    padding: 6px;
    width: 100%;
  }
}

@media (max-width: 360px) {
  .main-content {
    padding: 4px;
    width: 100%;
  }
  
  .video-grid {
    grid-template-columns: repeat(auto-fill, minmax(90px, 1fr));
    gap: 6px;
    width: 100%;
  }
}

/* PC分辨率下的样式 */
@media (min-width: 769px) {
  .video-grid {
    grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
    gap: 20px;
    max-width: none;
  }
  
  .section-title {
    font-size: 24px;
    margin-bottom: 24px;
  }
  
  .main-content {
    padding: 24px;
    margin-top: 20px;
    width: 100%;
    max-width: none;
  }
}

/* 超大屏幕优化 */
@media (min-width: 1200px) {
  .video-grid {
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 24px;
  }
  
  .main-content {
    padding: 32px;
  }
}

/* 4K屏幕优化 */
@media (min-width: 1600px) {
  .video-grid {
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
    gap: 28px;
  }
}
</style> 