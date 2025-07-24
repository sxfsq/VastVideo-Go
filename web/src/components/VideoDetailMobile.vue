<template>
  <div class="video-detail-mobile-youtube">
    <!-- 返回按钮 -->
    <div class="detail-header">
      <button class="back-btn" @click="goBack">
        <svg viewBox="0 0 24 24" width="20" height="20">
          <path d="M15 18l-6-6 6-6" stroke="currentColor" stroke-width="2" fill="none"/>
        </svg>
      </button>
    </div>

    <!-- 空状态显示 -->
    <div v-if="!videoData || Object.keys(videoData).length === 0" class="empty-state">
      <div class="empty-state-content">
        <div class="loading-spinner"></div>
        <div class="empty-state-title">正在加载视频信息...</div>
        <div class="empty-state-desc">请稍候，正在获取视频详细信息</div>
      </div>
    </div>

    <!-- 主要内容区域（受 showMainContent 控制） -->
    <div v-else-if="showMainContent" class="video-detail-content">
      <!-- 视频基础信息（标题、评分、标签） -->
              <VideoMeta
          :video-data="currentVideoData"
          :has-search-results="hasSearchResults"
          @show-description="showDescriptionFullscreen"
        />

      <!-- 播放器组件 -->
      <VideoPlayer
        :video-data="currentVideoData"
        :has-search-results="hasSearchResults"
        :final-poster-url="finalPosterUrl"
        :on-poster-error="onPosterError"
        :on-poster-load="onPosterLoad"
      />

      <!-- 操作按钮 -->
            <VideoActions
        :has-search-results="hasSearchResults"
      />

      <!-- 剧情介绍 -->
              <VideoDescription
          :video-data="currentVideoData"
          :is-fullscreen="isDescriptionFullscreen"
          @close="closeDescriptionFullscreen"
        />

      <!-- 剧集选择组件 -->
            <EpisodesList
        :video-data="currentVideoData"
        @episode-select="selectEpisode"
      />

      <!-- 演员信息组件 -->
      <CastList 
        :video-data="currentVideoData"
        @actor-select="selectActor"
      />
    </div>

    <!-- 侧边栏唤出按钮 -->
    <button
      v-if="showSidebarButton && showMainContent"
      class="sidebar-toggle-btn sidebar-toggle-btn-bottom"
      @click="showSidebar = true"
    >
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="12" fill="#6366f1"/><path d="M9 6l6 6-6 6" stroke="#fff" stroke-width="2" fill="none"/></svg>
      <span>相关推荐</span>
    </button>
    <!-- 相关推荐全屏弹窗 -->
    <RecommendationsMobile
      :visible="showSidebar"
      :related-videos-loading="relatedVideosLoading"
      :displayed-videos="displayedVideos"
      :has-more-data="hasMoreData"
      :get-video-title="getVideoTitle"
      :get-video-thumbnail="getVideoThumbnail"
      :get-video-year="getVideoYear"
      :get-video-type="getVideoType"
      :get-video-rating="getVideoRating"
      :get-video-source="getVideoSource"
      :is-current-video="isCurrentVideo"
      :search-stage="searchStage"
      :search-progress="searchProgress"
      @video-select="selectRelatedVideo"
      @load-more="loadMoreVideos"
      @image-error="onImageError"
      @search-all-sources="searchWithAllSources"
      @close="handleCloseRecommendations"
      @search="handleSidebarSearch"
    />
  </div>
</template>

<script>
import { defineComponent, ref, onMounted, onUnmounted, nextTick, watch, computed } from 'vue'
import VideoPlayer from './common/VideoPlayer.vue'
import VideoMeta from './common/VideoMeta.vue'
import VideoActions from './common/VideoActions.vue'
import VideoDescription from './common/VideoDescription.vue'
import EpisodesList from './common/EpisodesList.vue'
import CastList from './common/CastList.vue'
import RecommendationsMobile from './RecommendationsMobile.vue'
import api from '@/services/api.js'

export default defineComponent({
  name: 'VideoDetailMobile',
  components: {
    VideoPlayer,
    VideoMeta,
    VideoActions,
    VideoDescription,
    EpisodesList,
    CastList,
    RecommendationsMobile
  },
  props: {
    videoData: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  emits: ['go-back', 'video-select', 'search'],
  setup(props, { emit }) {
    // 当前显示的视频数据（本地管理，立即响应点击）
    const currentVideoData = ref(props.videoData ? { ...props.videoData } : {})
    
    // 控制信息显示状态
    const isShowingPlaceholder = ref(false)
    const hasSearchResults = ref(false)
    const isDescriptionFullscreen = ref(false)
    const searchStage = ref('默认源')
    const searchProgress = ref({ current: 0, total: 0, completed: 0 })
    
    // 分页和无限滚动相关状态
    const currentPage = ref(1)
    const hasMoreData = ref(true)
    const isLoadingMore = ref(false)
    const displayedVideos = ref([])
    const allVideosData = ref([])
    const videosPerPage = 6 // 移动端每页显示6个视频

    // 搜索相关状态
    const relatedVideosLoading = ref(false)
    const availableSources = ref([])
    const selectedSources = ref([])
    const skipNextSearch = ref(false)
    
    // 侧边栏状态（仅用于日志记录）
    const isSidebarExpanded = ref(false)
    const showSidebar = ref(false)
    const showSidebarButton = computed(() => !showSidebar.value && hasSearchResults.value && displayedVideos.value.length > 0)
    const showMainContent = ref(false)
    // 移除 isFirstSidebarOpen 相关逻辑

    // 获取视频信息的辅助方法
    const getVideoTitle = (video) => {
      return video.title || video.vod_name || video.name || '未知标题'
    }
    const getVideoThumbnail = (video) => {
      const thumbnail = video.cover || video.vod_pic || video.pic || video.poster
      if (thumbnail && thumbnail.trim() && !thumbnail.includes('placeholder.com')) {
        return thumbnail
      }
      return null
    }
    const getVideoYear = (video) => {
      return video.year || video.vod_year || ''
    }
    const getVideoType = (video) => {
      return video.type || video.type_name || video.vod_type || '视频'
    }
    const getVideoRating = (video) => {
      const rating = video.rate || video.vod_score || video.rating || video.score
      if (rating && rating !== '0' && rating !== '0.0') {
        return rating
      }
      return null
    }
    const getVideoSource = (video) => {
      if (video.search_source) {
        // 优先从后端获取的源列表中查找
        const sourceInfo = availableSources.value.find(s => s.code === video.search_source)
        if (sourceInfo) {
          return sourceInfo.name
        }
        
        // 如果后端没有，使用本地映射
        const sourceMap = {
          'dbzy': '豆瓣资源',
          'bfzy': '暴风资源',
          'hnzy': '红牛资源', 
          'ffzy': '非凡资源',
          'lzzy': '量子资源',
          'dyttzy': '电影天堂资源',
          'subzyapi': '速播资源',
          'wolongzyw': '卧龙资源',
          'wolong': '卧龙资源',
          'mozhua': '魔爪资源',
          'zuid': '最大资源',
          'ruyi': '如意资源',
          'heimuer': '黑木耳',
          'mdzy': '魔都资源',
          'baidu': '百度云资源',
          'ikun': 'iKun资源',
          'tyyszy': '天涯资源',
          'jisu': '极速资源',
          'wujin': '无尽资源',
          'wwzy': '旺旺短剧',
          'zy360': '360资源'
        }
        return sourceMap[video.search_source] || video.search_source
      }
      return video.source_name || video.source || '视频源'
    }
    const getVideoDirector = (video) => {
      return video.vod_director || video.director || ''
    }
    const getVideoArea = (video) => {
      return video.vod_area || video.area || ''
    }
    const getVideoActors = (video) => {
      const actors = video.vod_actor || video.actor || video.actors || ''
      if (!actors) return []
      return actors.split(',').map(actor => actor.trim()).filter(actor => actor)
    }
    const onImageError = (event) => {
      event.target.style.display = 'none'
    }

    // 全屏剧情介绍相关方法
    const showDescriptionFullscreen = () => {
      isDescriptionFullscreen.value = true
    }

    const closeDescriptionFullscreen = () => {
      isDescriptionFullscreen.value = false
    }

    // 优化的视频切换函数
    let switchVideoTimeout = null
    const switchToVideo = (video) => {
      if (switchVideoTimeout) {
        clearTimeout(switchVideoTimeout)
      }
      
      currentVideoData.value = { ...video }
      isShowingPlaceholder.value = false
      hasSearchResults.value = true
      console.log(`🎬 视频信息已切换到: "${getVideoTitle(video)}"`)
      
      skipNextSearch.value = true
      emit('video-select', video)
      
      // 滚动到顶部
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      })
    }

    // 获取可用视频源列表
    const fetchAvailableSources = async () => {
      try {
        console.log('🔍 正在从后端获取可用视频源列表...')
        const response = await api.sources.list()
        
        if (response && response.success && Array.isArray(response.data)) {
          availableSources.value = response.data
          console.log(`✅ 从后端获取视频源列表成功: ${availableSources.value.length} 个源`)
          console.log('📋 可用源列表:', availableSources.value.map(s => `${s.name}(${s.code})`).join(', '))
          
          // 显示默认源信息
          const defaultSources = availableSources.value.filter(s => s.is_default)
          if (defaultSources.length > 0) {
            console.log('🎯 后端标记的默认源:', defaultSources.map(s => `${s.name}(${s.code})`).join(', '))
          }
          
          initializeSelectedSources()
        } else {
          throw new Error(`API返回数据格式错误: ${JSON.stringify(response)}`)
        }
      } catch (error) {
        console.error('❌ 从后端获取视频源列表失败:', error)
        
        // 如果后端API不可用，使用本地备用源列表
        availableSources.value = [
          { code: 'dbzy', name: '豆瓣资源', url: '', is_default: true },
          { code: 'bfzy', name: '暴风资源', url: '', is_default: true },
          { code: 'hnzy', name: '红牛资源', url: '', is_default: false },
          { code: 'ffzy', name: '非凡资源', url: '', is_default: false }
        ]
        console.log('📋 后端API不可用，使用本地备用源列表')
        initializeSelectedSources()
      }
    }

    // 初始化选择的源
    const initializeSelectedSources = () => {
      try {
        const storageKey = 'vastvideo_sources_mobile'
        const storedSources = JSON.parse(localStorage.getItem(storageKey) || '[]')
        
        console.log('🔧 初始化搜索源选择...')
        console.log('📋 可用源数量:', availableSources.value.length)
        console.log('💾 本地存储的源:', storedSources)
        
        if (storedSources.length > 0) {
          const validSources = storedSources.filter(code => 
            availableSources.value.some(src => src.code === code)
          )
          
          if (validSources.length > 0) {
            selectedSources.value = validSources
            console.log('✅ 使用本地存储的有效源:', validSources)
            return
          } else {
            console.log('⚠️ 本地存储的源已失效，重新选择默认源')
          }
        }
        
        // 优先选择标记为默认的源
        const defaultSources = availableSources.value
          .filter(src => src.is_default === true)
          .map(src => src.code)
        
        if (defaultSources.length > 0) {
          selectedSources.value = defaultSources
          console.log('✅ 使用后端标记的默认源:', defaultSources)
        } else {
          // 如果没有标记默认源，选择前几个源
          const fallbackSources = availableSources.value
            .slice(0, Math.min(3, availableSources.value.length))
            .map(src => src.code)
          selectedSources.value = fallbackSources
          console.log('✅ 使用前几个可用源作为默认源:', fallbackSources)
        }
        
        // 保存到本地存储
        localStorage.setItem(storageKey, JSON.stringify(selectedSources.value))
        console.log('💾 已保存源选择到本地存储')
        
      } catch (error) {
        console.error('❌ 初始化选择源失败:', error)
        // 使用最基本的备用源
        selectedSources.value = availableSources.value.length > 0 
          ? [availableSources.value[0].code]
          : ['dbzy']
        console.log('🆘 使用备用源:', selectedSources.value)
      }
    }

    // 使用指定源列表并发搜索视频
    const searchWithSources = async (sourceCodes, keyword, maxPagesPerSource = 2) => {
      const startTime = Date.now()
      console.log(`🚀 开始并发搜索: ${sourceCodes.length}个源，关键词: "${keyword}"`)
      
      const totalTasks = sourceCodes.length * maxPagesPerSource
      searchProgress.value = { current: 0, total: totalTasks, completed: 0 }
      
      const maxConcurrentRequests = 4 // 移动端限制并发数
      const requestQueue = []
      let activeRequests = 0
      
      const executeRequest = async (requestFn) => {
        if (activeRequests >= maxConcurrentRequests) {
          await new Promise(resolve => {
            requestQueue.push(resolve)
          })
        }
        
        activeRequests++
        try {
          const result = await requestFn()
          return result
        } finally {
          activeRequests--
          if (requestQueue.length > 0) {
            const nextRequest = requestQueue.shift()
            nextRequest()
          }
        }
      }
      
      const searchTasks = sourceCodes.map(async (sourceCode) => {
        const sourceInfo = availableSources.value.find(s => s.code === sourceCode)
        const sourceName = sourceInfo?.name || sourceCode
        const sourceUrl = sourceInfo?.url || ''
        let sourceResults = []
        
        console.log(`🔍 开始搜索源: ${sourceName} (${sourceCode})`)
        
        try {
          const pagePromises = []
          for (let page = 1; page <= maxPagesPerSource; page++) {
            pagePromises.push(
              executeRequest(async () => {
                try {
                  const response = await api.search.videosBySource(sourceCode, keyword, page)
                  
                  searchProgress.value.completed++
                  searchProgress.value.current = Math.min(searchProgress.value.completed, searchProgress.value.total)
                  
                  if (response && response.success && Array.isArray(response.data)) {
                    if (response.data.length === 0) {
                      return null
                    }
                    
                    const pageResults = response.data.map(video => ({
                      ...video,
                      search_source: sourceCode,
                      source_page: page
                    }))
                    
                    console.log(`✅ 源 ${sourceName} 第${page}页找到 ${pageResults.length} 个相关视频`)
                    return pageResults
                  } else {
                    console.warn(`⚠️ 源 ${sourceName} 第${page}页搜索失败`)
                    return null
                  }
                } catch (error) {
                  searchProgress.value.completed++
                  searchProgress.value.current = Math.min(searchProgress.value.completed, searchProgress.value.total)
                  
                  console.warn(`❌ 源 ${sourceName} 第${page}页搜索异常:`, error.message)
                  return null
                }
              })
            )
          }
          
          const pageResults = await Promise.allSettled(pagePromises)
          
          pageResults.forEach((result, index) => {
            if (result.status === 'fulfilled' && result.value) {
              sourceResults.push(...result.value)
            }
          })
          
          if (sourceResults.length > 0) {
            console.log(`📊 源 ${sourceName} 并发搜索完成，总计找到 ${sourceResults.length} 个相关视频`)
          } else {
            console.log(`ℹ️ 源 ${sourceName} 并发搜索完成，未找到相关视频`)
          }
          
          return sourceResults
        } catch (sourceError) {
          console.warn(`❌ 源 ${sourceName} 并发搜索失败:`, sourceError.message)
          return []
        }
      })
      
      const allSourceResults = await Promise.allSettled(searchTasks)
      
      const results = []
      allSourceResults.forEach((result, index) => {
        if (result.status === 'fulfilled') {
          results.push(...result.value)
        } else {
          const sourceCode = sourceCodes[index]
          const sourceName = availableSources.value.find(s => s.code === sourceCode)?.name || sourceCode
          console.warn(`❌ 源 ${sourceName} 任务执行失败:`, result.reason)
        }
      })
      
      const endTime = Date.now()
      const duration = endTime - startTime
      const successCount = allSourceResults.filter(r => r.status === 'fulfilled').length
      
      console.log(`🏁 并发搜索完成: 成功搜索 ${successCount}/${sourceCodes.length} 个源，总计找到 ${results.length} 个视频，耗时 ${duration}ms`)
      
      return results
    }
    
    // 更新显示的视频列表
    const updateDisplayedVideos = () => {
      const startIndex = 0
      const endIndex = currentPage.value * videosPerPage
      const newDisplayedVideos = allVideosData.value.slice(startIndex, endIndex)
      
      displayedVideos.value = newDisplayedVideos
      hasMoreData.value = endIndex < allVideosData.value.length
      
      console.log(`📺 当前显示 ${displayedVideos.value.length} 个视频，总计 ${allVideosData.value.length} 个，${hasMoreData.value ? '还有更多' : '已全部显示'}`)
    }
    
    // 加载更多视频
    const loadMoreVideos = () => {
      if (isLoadingMore.value || !hasMoreData.value) return
      
      isLoadingMore.value = true
      console.log('📥 加载更多视频...')
      
      setTimeout(() => {
        currentPage.value += 1
        updateDisplayedVideos()
        isLoadingMore.value = false
        console.log(`✅ 已加载到第 ${currentPage.value} 页`)
      }, 300)
    }

    // 手动使用全部源搜索
    const searchWithAllSources = async () => {
      if (!props.videoData || Object.keys(props.videoData).length === 0) {
        console.log('⚠️ 无视频数据，无法搜索')
        return
      }
      if (availableSources.value.length === 0) {
        console.log('⚠️ 无可用源，无法搜索')
        return
      }

      let searchKeyword = getVideoTitle(props.videoData)
      if (!searchKeyword || searchKeyword === '未知标题' || searchKeyword === '加载中...') {
        console.log('⚠️ 无效搜索关键词')
        return
      }
      
      searchKeyword = searchKeyword
        .replace(/[\[\]()（）【】\-_\s]+/g, ' ')
        .trim()
        .split(' ')[0]
      
      if (!searchKeyword) {
        console.log('⚠️ 搜索关键词为空')
        return
      }

      console.log(`🔍 手动触发全部源搜索: "${searchKeyword}"`)
      
      relatedVideosLoading.value = true
      isShowingPlaceholder.value = true
      searchStage.value = '全部源'
      
      try {
        const allSourceCodes = availableSources.value.map(s => s.code)
        console.log(`🔍 手动搜索: 使用全部源搜索 "${searchKeyword}" (${allSourceCodes.length}个源，每源最多2页，总计${allSourceCodes.length * 2}个任务)`)
        
        const allResults = await searchWithSources(allSourceCodes, searchKeyword, 2)
        console.log(`📊 手动搜索完成: 找到 ${allResults.length} 个视频`)
        
        if (allResults.length > 0) {
          const currentTitle = getVideoTitle(props.videoData).toLowerCase()
          const uniqueVideos = new Map()
          
          const filteredResults = allResults.filter(video => {
            const videoTitle = getVideoTitle(video).toLowerCase()
            const videoSource = getVideoSource(video)
            const currentSource = getVideoSource(props.videoData)
            
            const isSameVideo = videoTitle === currentTitle && videoSource === currentSource
            return !isSameVideo
          })
          
          filteredResults.forEach(video => {
            const title = getVideoTitle(video)
            if (!uniqueVideos.has(title)) {
              uniqueVideos.set(title, video)
            }
          })
          
          allVideosData.value = Array.from(uniqueVideos.values())
          
          currentPage.value = 1
          hasMoreData.value = allVideosData.value.length > videosPerPage
          
          updateDisplayedVideos()
          
          console.log(`✅ 手动搜索成功: 找到 ${allVideosData.value.length} 个相关视频，首页显示 ${displayedVideos.value.length} 个`)
          
          if (allVideosData.value.length > 0) {
            hasSearchResults.value = true
            const firstVideo = allVideosData.value[0]
            currentVideoData.value = { ...firstVideo }
            console.log(`🎬 手动搜索成功，切换到播放器模式，显示第一个相关视频: "${getVideoTitle(firstVideo)}"`)
          }
        } else {
          allVideosData.value = []
          displayedVideos.value = []
          currentPage.value = 1
          hasMoreData.value = false
          hasSearchResults.value = false
          
          if (props.videoData && Object.keys(props.videoData).length > 0) {
            currentVideoData.value = { ...props.videoData }
          }
          console.log('⚠️ 手动搜索无结果，保持海报模式，恢复原始视频信息')
        }
      } catch (error) {
        console.error('❌ 手动搜索失败:', error)
        allVideosData.value = []
        displayedVideos.value = []
        hasSearchResults.value = false
        
        if (props.videoData && Object.keys(props.videoData).length > 0) {
          currentVideoData.value = { ...props.videoData }
        }
      } finally {
        relatedVideosLoading.value = false
        isShowingPlaceholder.value = false
        console.log('🏁 手动搜索完成')
      }
    }

    // 搜索相关视频
    const searchRelatedVideos = async () => {
      if (!props.videoData || Object.keys(props.videoData).length === 0) {
        console.log('⚠️ 无视频数据，跳过搜索')
        return
      }
      if (availableSources.value.length === 0) {
        return
      }

      let searchKeyword = getVideoTitle(props.videoData)
      if (!searchKeyword || searchKeyword === '未知标题' || searchKeyword === '加载中...') return
      
      searchKeyword = searchKeyword
        .replace(/[\[\]()（）【】\-_\s]+/g, ' ')
        .trim()
        .split(' ')[0]
      
      if (!searchKeyword) return

      relatedVideosLoading.value = true
      isShowingPlaceholder.value = true
      
      try {
        let allResults = []
        searchStage.value = '默认源'
        let usedAllSources = false
        
        // 第一阶段：使用选择的默认源搜索
        if (selectedSources.value.length > 0) {
          const defaultSources = selectedSources.value.slice(0, 3)
          console.log(`🔍 阶段1: 使用${searchStage.value}搜索 "${searchKeyword}" (${defaultSources.length}个源，每源最多3页，总计${defaultSources.length * 3}个任务)`)
          
          allResults = await searchWithSources(defaultSources, searchKeyword, 3)
          console.log(`📊 ${searchStage.value}搜索结果: ${allResults.length} 个视频`)
        }
        
        // 第二阶段：如果默认源没有结果，自动使用全部源重新搜索
        if (allResults.length === 0) {
          searchStage.value = '全部源'
          usedAllSources = true
          console.log(`⚠️ 默认源搜索无结果，自动启用${searchStage.value}搜索`)
          
          const allSourceCodes = availableSources.value.map(s => s.code)
          console.log(`🔍 阶段2: 使用${searchStage.value}搜索 "${searchKeyword}" (${allSourceCodes.length}个源，每源最多2页，总计${allSourceCodes.length * 2}个任务)`)
          
          allResults = await searchWithSources(allSourceCodes, searchKeyword, 2)
          console.log(`📊 ${searchStage.value}搜索结果: ${allResults.length} 个视频`)
        }
        
        if (allResults.length > 0) {
          const currentTitle = getVideoTitle(props.videoData).toLowerCase()
          const uniqueVideos = new Map()
          
          const filteredResults = allResults.filter(video => {
            const videoTitle = getVideoTitle(video).toLowerCase()
            const videoSource = getVideoSource(video)
            const currentSource = getVideoSource(props.videoData)
            
            const isSameVideo = videoTitle === currentTitle && videoSource === currentSource
            return !isSameVideo
          })
          
          filteredResults.forEach(video => {
            const title = getVideoTitle(video)
            if (!uniqueVideos.has(title)) {
              uniqueVideos.set(title, video)
            }
          })
          
          allVideosData.value = Array.from(uniqueVideos.values())
          
          currentPage.value = 1
          hasMoreData.value = allVideosData.value.length > videosPerPage
          
          updateDisplayedVideos()
          
          console.log(`✅ 最终结果: 找到 ${allVideosData.value.length} 个相关视频，首页显示 ${displayedVideos.value.length} 个`)
          
          if (allVideosData.value.length > 0) {
            hasSearchResults.value = true
            const firstVideo = allVideosData.value[0]
            currentVideoData.value = { ...firstVideo }
            console.log(`🎬 搜索成功，切换到播放器模式，显示第一个相关视频: "${getVideoTitle(firstVideo)}"`)
          }
        } else {
          allVideosData.value = []
          displayedVideos.value = []
          currentPage.value = 1
          hasMoreData.value = false
          hasSearchResults.value = false
          
          if (props.videoData && Object.keys(props.videoData).length > 0) {
            currentVideoData.value = { ...props.videoData }
          }
          console.log('⚠️ 搜索无结果，保持海报模式，恢复原始视频信息')
        }
        
        const foundResults = allResults.length > 0
        
        if (foundResults) {
          if (usedAllSources) {
            console.log(`📈 搜索策略成功: 默认源无结果，全部源搜索找到 ${allResults.length} 个视频`)
          } else {
            console.log(`📈 搜索策略成功: 默认源搜索找到 ${allResults.length} 个视频`)
          }
        } else {
          console.log('📉 搜索策略: 已尝试所有可用源，未找到相关内容')
        }
      } catch (error) {
        console.error('❌ 搜索相关视频失败:', error)
        // relatedVideos.value = [] // This line was removed from the original file, so it's removed here.
      } finally {
        relatedVideosLoading.value = false
        isShowingPlaceholder.value = false
        console.log('🏁 搜索完成，占位内容已关闭')
      }
    }

    // 事件处理函数
    const goBack = () => {
      emit('go-back')
    }

    const selectEpisode = (episode) => {
      console.log('选择剧集:', episode)
    }

    const selectActor = (actor) => {
      console.log('选择演员:', actor)
    }

    const hasSelectedRecommendation = ref(false)
    // 监听showSidebar，弹窗打开时重置hasSelectedRecommendation
    watch(showSidebar, (val) => {
      if (val) {
        hasSelectedRecommendation.value = false
      }
    })

    // 监听showMainContent，控制主内容区域的显示
    watch(showMainContent, (val) => {
      if (val) {
        // 当showMainContent变为true时，确保视频数据已加载
        if (props.videoData && Object.keys(props.videoData).length > 0) {
          currentVideoData.value = { ...props.videoData }
          isShowingPlaceholder.value = false
          hasSearchResults.value = false
          console.log(`📺 主内容显示，同步视频数据: "${getVideoTitle(props.videoData)}"`)
        } else {
          console.log('⚠️ 主内容显示，但视频数据为空')
          currentVideoData.value = {}
          hasSearchResults.value = false
        }
      }
    })

    const selectRelatedVideo = (video) => {
      console.log('选择相关视频:', video)
      switchToVideo(video)
      hasSelectedRecommendation.value = true
      showSidebar.value = false // 用户点击后关闭相关推荐
      showMainContent.value = true // 用户点击后显示主内容
    }

    const handleCloseRecommendations = () => {
      showSidebar.value = false
      if (!hasSelectedRecommendation.value) {
        // 回到豆瓣推荐页（无论当前currentVideoData是否已变）
        if (props.videoData && Object.keys(props.videoData).length > 0) {
          currentVideoData.value = { ...props.videoData }
        }
        showMainContent.value = false // 未选推荐时不显示主内容
        // 新增：未选推荐时，通知父组件 goBack
        emit('go-back')
      }
    }

    const handleSidebarSearch = (keyword) => {
      emit('search', keyword)
    }

    const handleSidebarToggle = (isExpanded) => {
      isSidebarExpanded.value = isExpanded
      console.log('侧边栏状态:', isExpanded ? '展开' : '收起')
      // 侧边栏完全悬浮，不影响主内容布局
    }

    // 监听视频数据变化
    watch(() => props.videoData, (newVideo) => {
      if (newVideo && Object.keys(newVideo).length > 0) {
        currentVideoData.value = { ...newVideo }
        isShowingPlaceholder.value = false
        hasSearchResults.value = false
        console.log(`📺 同步视频数据: "${getVideoTitle(newVideo)}"`)
      } else {
        console.log('⚠️ 接收到空或无效的视频数据')
        currentVideoData.value = {}
        hasSearchResults.value = false
      }
      
      if (skipNextSearch.value) {
        skipNextSearch.value = false
        console.log('🔄 跳过搜索，视频数据已更新为相关推荐中的视频')
        return
      }
      
      if (newVideo && selectedSources.value.length > 0) {
        console.log('🔍 视频数据变化，开始新搜索')
        searchRelatedVideos()
      }
    }, { immediate: false })
    
    // 监听源列表变化
    watch(selectedSources, (newSources) => {
      if (newSources.length > 0 && props.videoData && Object.keys(props.videoData).length > 0) {
        searchRelatedVideos()
      }
    }, { immediate: false })

    // 监听hasSearchResults和displayedVideos，自动弹出侧边栏（不再自动关闭）
    watch([
      () => hasSearchResults.value,
      () => displayedVideos.value.length
    ], ([hasResults, videoCount]) => {
      if (hasResults && videoCount > 0) {
        showSidebar.value = true
      }
    })

    onMounted(async () => {
      if (props.videoData && Object.keys(props.videoData).length > 0) {
        currentVideoData.value = { ...props.videoData }
        isShowingPlaceholder.value = false
        hasSearchResults.value = false
        console.log(`📺 初始化视频数据: "${getVideoTitle(props.videoData)}"`)
      } else {
        console.log('⚠️ 无视频数据传入，等待数据加载')
        hasSearchResults.value = false
        currentVideoData.value = {}
      }
      
      await fetchAvailableSources()
      
      if (props.videoData && Object.keys(props.videoData).length > 0 && selectedSources.value.length > 0) {
        await searchRelatedVideos()
      }
      showSidebar.value = true // 进入页面立即显示相关推荐
      showMainContent.value = false // 初始不显示主内容
    })

    onUnmounted(() => {
      if (switchVideoTimeout) {
        clearTimeout(switchVideoTimeout)
        switchVideoTimeout = null
      }
    })

    const posterImageError = ref(false)
    const getPosterUrl = (videoData) => {
      const possibleUrls = [
        videoData?.poster,
        videoData?.vod_pic, 
        videoData?.pic,
        videoData?.cover
      ]
      for (const url of possibleUrls) {
        if (url && typeof url === 'string' && url.trim() !== '' && !url.includes('placeholder.com')) {
          return url.trim()
        }
      }
      return null
    }
    const getDefaultPosterSvg = () => {
      return 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTQwIiBoZWlnaHQ9IjIxMCIgdmlld0JveD0iMCAwIDE0MCAyMTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIxNDAiIGhlaWdodD0iMjEwIiBmaWxsPSIjMjMyNDRhIi8+CjxyZWN0IHg9IjEwIiB5PSIxMCIgd2lkdGg9IjEyMCIgaGVpZ2h0PSIxNjAiIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzNjM2M1YSIgc3Ryb2tlLXdpZHRoPSIxIi8+CjxwYXRoIGQ9Ik0zMCA2MGg4MHY0MEgzMHoiIGZpbGw9IiMzYzNjNWEiIGZpbGwtb3BhY2l0eT0iMC4zIi8+Cjx0ZXh0IHg9IjcwIiB5PSIxODAiIGZvbnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSIxMiIgZmlsbD0iI2I5YmJkNCIgdGV4dC1hbmNob3I9Im1pZGRsZSI+6K+36L6T5YWl5Y2a5L2N5L2N5Y2aPC90ZXh0Pgo8L3N2Zz4K'
    }
    const finalPosterUrl = computed(() => {
      if (posterImageError.value) {
        return getDefaultPosterSvg()
      }
      const url = getPosterUrl(currentVideoData.value)
      if (!url) {
        return getDefaultPosterSvg()
      }
      return url
    })
    const onPosterError = () => { posterImageError.value = true }
    const onPosterLoad = () => { posterImageError.value = false }

    const isCurrentVideo = (video) => {
      if (!currentVideoData.value) return false
      const currentTitle = currentVideoData.value.title || currentVideoData.value.vod_name || ''
      const videoTitle = video.title || video.vod_name || ''
      const currentSource = currentVideoData.value.search_source || currentVideoData.value.source || ''
      const videoSource = video.search_source || video.source || ''
      return currentTitle === videoTitle && currentSource === videoSource
    }

    return {
      currentVideoData,
      isShowingPlaceholder,
      hasSearchResults,
      isDescriptionFullscreen,
      searchStage,
      searchProgress,
      currentPage,
      hasMoreData,
      isLoadingMore,
      displayedVideos,
      allVideosData,
      videosPerPage,
      relatedVideosLoading,
      availableSources,
      selectedSources,
      skipNextSearch,
      goBack,
      selectEpisode,
      selectActor,
      selectRelatedVideo,
      showDescriptionFullscreen,
      closeDescriptionFullscreen,
      searchWithAllSources,
      loadMoreVideos,
      handleSidebarToggle,
      isSidebarExpanded,
      showSidebar,
      showSidebarButton,
      showMainContent,
      finalPosterUrl,
      onPosterError,
      onPosterLoad,
      isCurrentVideo,
      getVideoTitle,
      getVideoThumbnail,
      getVideoYear,
      getVideoType,
      getVideoRating,
      getVideoSource,
      getVideoDirector,
      getVideoArea,
      getVideoActors,
      onImageError,
      hasSelectedRecommendation,
      handleCloseRecommendations,
      handleSidebarSearch
    }
  }
})
</script>

<style scoped>
.video-detail-mobile-youtube {
  background: #0f0f0f;
  color: #ffffff;
  min-height: 100vh;
}

/* 空状态样式 */
.empty-state {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: 40px 20px;
}

.empty-state-content {
  text-align: center;
  color: #e0e0e0;
  max-width: 300px;
}

.loading-spinner {
  width: 48px;
  height: 48px;
  border: 4px solid rgba(108, 99, 255, 0.2);
  border-top: 4px solid #6c63ff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 24px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.empty-state-title {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 12px;
  color: #ffffff;
}

.empty-state-desc {
  font-size: 14px;
  color: #a5a5a5;
  line-height: 1.5;
}

/* 返回按钮 */
.detail-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  background: linear-gradient(180deg, rgba(0,0,0,0.8) 0%, transparent 100%);
  padding: 12px 16px;
}

.back-btn {
  background: rgba(255, 255, 255, 0.1);
  color: white;
  border: none;
  padding: 8px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  backdrop-filter: blur(10px);
  transition: background 0.2s;
}

.back-btn:hover {
  background: rgba(255, 255, 255, 0.2);
}

/* 主要内容区域 */
.video-detail-content {
  width: 100%;
  /* 移除右侧边距，让侧边栏完全悬浮 */
  padding-bottom: 20px; /* 为底部留出空间 */
}

/* 移动端优化 */
@media (max-width: 768px) {
  .video-detail-content {
    padding-bottom: 40px; /* 移动端底部留更多空间 */
  }
}

.mobile-recommendations-sidebar {
  position: fixed;
  top: 0;
  right: 0;
  width: 90vw;
  max-width: 420px;
  height: 100vh;
  z-index: 9999;
  background: rgba(20, 20, 40, 0.98);
  box-shadow: -4px 0 24px rgba(0,0,0,0.18);
  border-top-left-radius: 16px;
  border-bottom-left-radius: 16px;
  overflow-y: auto;
  transition: transform 0.3s cubic-bezier(.4,2,.6,1), opacity 0.2s;
  will-change: transform, opacity;
  padding-bottom: 32px;
}
@media (max-width: 480px) {
  .mobile-recommendations-sidebar {
    width: 100vw;
    max-width: 100vw;
    border-radius: 0;
    padding-bottom: 60px;
  }
}

.sidebar-toggle-btn {
  position: fixed;
  z-index: 10001;
  background: rgba(99,102,241,0.95);
  color: #fff;
  border: none;
  border-radius: 50px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.12);
  padding: 10px 18px 10px 12px;
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 15px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
}
.sidebar-toggle-btn-bottom {
  bottom: 18px;
  right: 18px;
}
.sidebar-toggle-btn:hover {
  background: #7c3aed;
}
.sidebar-toggle-btn svg {
  flex-shrink: 0;
}
@media (max-width: 480px) {
  .sidebar-toggle-btn {
    font-size: 13px;
    padding: 8px 14px 8px 10px;
  }
  .sidebar-toggle-btn-bottom {
    bottom: 10px;
    right: 10px;
  }
}
</style>