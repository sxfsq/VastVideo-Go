<template>
  <div class="video-detail-desktop">
    <div v-if="!videoData || Object.keys(videoData).length === 0" class="empty-state">
      <div class="empty-state-content">
        <div class="loading-spinner"></div>
        <div class="empty-state-title">正在加载视频信息...</div>
        <div class="empty-state-desc">请稍候，正在获取视频详细信息</div>
      </div>
    </div>
    <div v-else class="youtube-layout">
      <div class="main-content">
        <div class="primary-content">
          <!-- 播放器区域保留原有实现 -->
          <div class="player-section">
            <VideoPlayer
              :video-data="currentVideoData"
              :has-search-results="hasSearchResults"
              :final-poster-url="finalPosterUrl"
              :on-poster-error="onPosterError"
              :on-poster-load="onPosterLoad"
            />
          </div>
          <!-- 通用基础信息组件 -->
          <VideoMeta 
            :video-data="currentVideoData" 
            :has-search-results="hasSearchResults"
            @show-description="showDescriptionFullscreen"
          />
          <!-- 通用操作按钮组件 -->
          <VideoActions :has-search-results="hasSearchResults" />
          <!-- 通用剧情介绍组件 -->
          <VideoDescription 
            :video-data="currentVideoData" 
            :is-fullscreen="isDescriptionFullscreen"
            @close="closeDescriptionFullscreen"
          />
          <!-- 通用剧集选择组件 -->
          <EpisodesList :video-data="currentVideoData" @episode-select="selectEpisode" />
          <!-- 通用演员列表组件 -->
          <CastList :video-data="currentVideoData" @actor-select="handleActorSelect" />

        </div>
      </div>
      <!-- 右侧推荐列表等内容保留原有实现 -->
      <div class="recommendations">
        <!-- 推荐列表标题和操作按钮 -->
        <div class="recommendations-header">
          <h3 class="section-title">相关推荐</h3>
          <div class="search-actions">
            <button 
              v-if="!relatedVideosLoading && availableSources.length > 0"
              class="search-all-sources-btn"
              @click="searchWithAllSources"
              :disabled="relatedVideosLoading"
            >
              <span class="btn-icon">🔍</span>
              使用全部源搜索
            </button>
          </div>
        </div>
        <div class="recommendations-list">
          <!-- 加载状态 -->
          <template v-if="relatedVideosLoading">
            <div class="loading-container">
              <div class="loading-spinner"></div>
              <div class="loading-text">
                正在{{ searchStage === '全部源' ? '使用全部源' : '使用默认源' }}并发搜索相关视频...
              </div>
              <div v-if="searchStage === '全部源'" class="loading-subtext">
                默认源无结果，正在扩大搜索范围
              </div>
              <div class="search-progress">
                <div class="progress-bar">
                  <div 
                    class="progress-fill" 
                    :style="{ width: `${(searchProgress.completed / searchProgress.total) * 100}%` }"
                  ></div>
                </div>
                <div class="progress-text">
                  搜索进度: {{ searchProgress.completed }}/{{ searchProgress.total }} 
                  <span class="progress-detail">({{ Math.ceil(searchProgress.total / 2) }}个源 × 2页)</span>
                </div>
              </div>
            </div>
          </template>
          <!-- 相关视频列表 -->
          <template v-else-if="displayedVideos.length > 0">
            <div 
              v-for="(video, index) in displayedVideos" 
              :key="`video-${index}-${video.vod_name || video.title || index}-${video.source_page || 1}`"
              :class="['recommendation-item', { 'current-video': isCurrentVideo(video) }]" 
              @click="selectRelatedVideo(video)"
            >
              <div class="recommendation-thumbnail">
                <img 
                  v-if="getVideoThumbnail(video)" 
                  :src="getVideoThumbnail(video)" 
                  :alt="getVideoTitle(video)"
                  @error="onImageError"
                  loading="lazy"
                />
                <div v-else class="thumbnail-placeholder">
                  <div class="placeholder-icon">🎬</div>
                </div>
                <div class="thumbnail-overlay">
                  <div class="play-btn">▶</div>
                </div>
                <div class="video-source-badge">{{ getVideoSource(video) }}</div>
              </div>
              <div class="recommendation-info">
                <div class="recommendation-title">{{ getVideoTitle(video) }}</div>
                <!-- 视频基本信息 -->
                <div class="video-basic-info">
                  <div class="info-row">
                    <span class="info-label">类型:</span>
                    <span class="info-value">{{ getVideoType(video) }}</span>
                  </div>
                  <div v-if="getVideoYear(video)" class="info-row">
                    <span class="info-label">年份:</span>
                    <span class="info-value">{{ getVideoYear(video) }}</span>
                  </div>
                  <div v-if="getVideoRating(video)" class="info-row">
                    <span class="info-label">评分:</span>
                    <span class="info-value rating-value">★ {{ getVideoRating(video) }}分</span>
                  </div>
                  <div v-if="getVideoDirector(video)" class="info-row">
                    <span class="info-label">导演:</span>
                    <span class="info-value">{{ getVideoDirector(video) }}</span>
                  </div>
                  <div v-if="getVideoArea(video)" class="info-row">
                    <span class="info-label">地区:</span>
                    <span class="info-value">{{ getVideoArea(video) }}</span>
                  </div>
                </div>
                <!-- 演员信息（如果有） -->
                <div v-if="getVideoActors(video).length > 0" class="actors-info">
                  <div class="info-label">演员:</div>
                  <div class="actors-list">
                    {{ getVideoActors(video).slice(0, 3).join('、') }}
                    <span v-if="getVideoActors(video).length > 3" class="more-actors">等{{ getVideoActors(video).length }}人</span>
                  </div>
                </div>
              </div>
            </div>
          </template>
          <!-- 加载更多状态 -->
          <div v-if="displayedVideos.length > 0 && hasMoreData" class="load-more-container">
            <div v-if="isLoadingMore" class="loading-more">
              <div class="loading-spinner-small"></div>
              <span>加载更多...</span>
            </div>
            <button 
              v-else 
              class="load-more-btn" 
              @click="loadMoreVideos"
            >
              查看更多 (还有 {{ allVideosData.length - displayedVideos.length }} 个视频)
            </button>
          </div>
          <!-- 数据统计信息 -->
          <div v-if="allVideosData.length > 0" class="videos-stats">
            已显示 {{ displayedVideos.length }} / {{ allVideosData.length }} 个相关视频
          </div>
          <!-- 无结果状态 -->
          <template v-else-if="!relatedVideosLoading">
            <div class="no-results">
              <div class="no-results-icon">🔍</div>
              <div class="no-results-text">暂无相关推荐</div>
            </div>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { defineComponent, ref, onMounted, onUnmounted, nextTick, watch, computed } from 'vue'
import VideoMeta from './common/VideoMeta.vue'
import VideoActions from './common/VideoActions.vue'
import VideoDescription from './common/VideoDescription.vue'
import CastList from './common/CastList.vue'
import EpisodesList from './common/EpisodesList.vue'
import VideoPlayer from './common/VideoPlayer.vue'
import { api } from '@/services/api.js'
import Recommendations from './common/Recommendations.vue'

export default defineComponent({
  name: 'VideoDetailDesktop',
  components: {
    VideoMeta,
    VideoActions,
    VideoDescription,
    CastList,
    EpisodesList,
    VideoPlayer,
    Recommendations
  },
  props: {
    videoData: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  emits: ['video-select', 'search'],
  setup(props, { emit }) {
    const showFullDescription = ref(false)
    const isDescriptionFullscreen = ref(false)
    const relatedVideos = ref([])
    const relatedVideosLoading = ref(false)
    const availableSources = ref([])
    const selectedSources = ref([])
    const skipNextSearch = ref(false) // 控制是否跳过下次搜索
    
    // 当前显示的视频数据（本地管理，立即响应点击）
    const currentVideoData = ref(props.videoData ? { ...props.videoData } : {})
    
    // 控制信息显示状态
    const isShowingPlaceholder = ref(false) // 是否显示占位内容
    const hasSearchResults = ref(false) // 是否有搜索结果，默认为false显示海报
    const searchStage = ref('默认源') // 跟踪当前搜索阶段
    const searchProgress = ref({ current: 0, total: 0, completed: 0 }) // 搜索进度跟踪
    
    // 分页和无限滚动相关状态
    const currentPage = ref(1)
    const hasMoreData = ref(true)
    const isLoadingMore = ref(false)
    const displayedVideos = ref([]) // 当前显示的视频列表
    const allVideosData = ref([]) // 所有搜索到的视频数据
    const videosPerPage = 8 // 每页显示的视频数量

    // 解析演员列表
    const actorsList = computed(() => {
      if (!currentVideoData.value?.vod_actor) return []
      return currentVideoData.value.vod_actor
        .split(',')
        .map(actor => actor.trim())
        .filter(actor => actor)
        .slice(0, 12) // 最多显示12个演员
    })

    // 解析剧集列表
    const episodesList = computed(() => {
      if (!currentVideoData.value?.vod_play_url) return []
      
      try {
        // 解析播放链接格式: "HD$url$$$HD2$url2"
        const playData = currentVideoData.value.vod_play_url
        const episodes = playData.split('$$$').map((episode, index) => {
          const parts = episode.split('$')
          if (parts.length >= 2) {
            return {
              name: parts[0] || `第${index + 1}集`,
              url: parts[1]
            }
          }
          return null
        }).filter(ep => ep)
        
        return episodes
      } catch (error) {
        console.warn('解析剧集信息失败:', error)
        return []
      }
    })

    // 获取视频文件大小信息
    const getVideoSize = () => {
      // 这里可以根据实际需求添加文件大小检测逻辑
      return currentVideoData.value?.vod_remarks?.includes('HD') ? '高清' : '标清'
    }
    

    
    const showDescriptionFullscreen = () => {
      isDescriptionFullscreen.value = true
    }

    const closeDescriptionFullscreen = () => {
      isDescriptionFullscreen.value = false
    }

    const toggleDescription = () => {
      showFullDescription.value = !showFullDescription.value
      // 描述展开后重新调整推荐列表高度
      nextTick(() => {
        adjustRecommendationsHeight()
      })
    }

    const selectEpisode = (episode) => {
      console.log('选择剧集:', episode)
      // 这里可以添加切换剧集的逻辑
      // 例如：更新播放URL、标记当前选中集等
    }

    const handleActorSelect = (actor) => {
      console.log('选择演员:', actor)
      // 这里可以添加演员选择的逻辑，比如搜索该演员的其他作品
    }

    const selectRelatedVideo = (video) => {
      console.log('选择相关视频:', video)
      
      // 使用优化的视频切换函数
      switchToVideo(video)
    }
    
    // 当前选中的视频索引
    const currentVideoIndex = ref(-1)
    
    // 检查是否为当前播放的视频
    const isCurrentVideo = (video) => {
      if (!props.videoData) return false
      
      const currentTitle = getVideoTitle(props.videoData)
      const videoTitle = getVideoTitle(video)
      const currentSource = getVideoSource(props.videoData)
      const videoSource = getVideoSource(video)
      
      return currentTitle === videoTitle && currentSource === videoSource
    }
    
    // 更新当前选中视频的高亮标识（用于搜索完成后）
    const updateCurrentVideoHighlight = (selectedVideo, shouldScroll = true) => {
      if (allVideosData.value.length === 0) return
      
      // 找到被点击视频在完整列表中的索引
      const videoIndex = allVideosData.value.findIndex(video => {
        const selectedTitle = getVideoTitle(selectedVideo)
        const videoTitle = getVideoTitle(video)
        const selectedSource = getVideoSource(selectedVideo)
        const videoSource = getVideoSource(video)
        
        // 找到相同的视频（标题和来源都相同）
        return selectedTitle === videoTitle && selectedSource === videoSource
      })
      
      // 更新当前选中的视频索引（用于视觉标识）
      currentVideoIndex.value = videoIndex
      
      if (videoIndex !== -1) {
        console.log(`✅ 已标识当前视频 "${getVideoTitle(selectedVideo)}" (索引: ${videoIndex})`)
        // 只在需要时滚动到当前视频位置（避免视频切换时的滚动冲突）
        if (shouldScroll) {
          scrollToCurrentVideoInList(videoIndex)
        }
      } else {
        console.log(`ℹ️ 当前视频 "${getVideoTitle(selectedVideo)}" 不在相关推荐列表中`)
      }
    }
    
    // 页面滚动到顶部，展示完整播放器
    const scrollToPageTop = () => {
      // 平滑滚动到页面顶部
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      })
      
      console.log('📺 页面已滚动到顶部，展示播放器区域')
    }
    
    // 优化的视频切换函数（防止滚动冲突）
    let switchVideoTimeout = null
    const switchToVideo = (video) => {
      // 清除之前的定时器，避免快速点击造成的冲突
      if (switchVideoTimeout) {
        clearTimeout(switchVideoTimeout)
      }
      
      // 立即更新当前显示的视频数据
      currentVideoData.value = { ...video }
      isShowingPlaceholder.value = false // 确保关闭占位状态
      hasSearchResults.value = true // 切换到相关视频时确保有结果状态
      console.log(`🎬 视频信息已切换到: "${getVideoTitle(video)}"`)
      
      // 设置标志，避免下次视频数据变化时触发搜索
      skipNextSearch.value = true
      
      // 通知父组件更新视频数据
      emit('video-select', video)
      
      // 分阶段执行滚动，避免冲突
      executeScrollSequence(video)
    }
    
    // 分阶段执行滚动序列，避免颤动
    const executeScrollSequence = (video) => {
      // 第一阶段：立即更新视觉标识（不滚动）
      updateCurrentVideoHighlightOnly(video)
      
      // 第二阶段：页面滚动到顶部
      scrollToPageTop()
      
      // 第三阶段：等待页面滚动完成后，再滚动列表
      switchVideoTimeout = setTimeout(() => {
        scrollToCurrentVideoInListDelayed(video)
      }, 800) // 等待页面滚动动画完成
    }
    
    // 只更新视觉标识，不触发列表滚动
    const updateCurrentVideoHighlightOnly = (selectedVideo) => {
      if (allVideosData.value.length === 0) return
      
      // 找到被点击视频在完整列表中的索引
      const videoIndex = allVideosData.value.findIndex(video => {
        const selectedTitle = getVideoTitle(selectedVideo)
        const videoTitle = getVideoTitle(video)
        const selectedSource = getVideoSource(selectedVideo)
        const videoSource = getVideoSource(video)
        
        return selectedTitle === videoTitle && selectedSource === videoSource
      })
      
      // 更新当前选中的视频索引（用于视觉标识）
      currentVideoIndex.value = videoIndex
      
      if (videoIndex !== -1) {
        console.log(`✅ 已标识当前视频 "${getVideoTitle(selectedVideo)}" (索引: ${videoIndex})`)
      } else {
        console.log(`ℹ️ 当前视频 "${getVideoTitle(selectedVideo)}" 不在相关推荐列表中`)
      }
    }
    
    // 延迟执行列表滚动
    const scrollToCurrentVideoInListDelayed = (selectedVideo) => {
      const videoIndex = allVideosData.value.findIndex(video => {
        const selectedTitle = getVideoTitle(selectedVideo)
        const videoTitle = getVideoTitle(video)
        const selectedSource = getVideoSource(selectedVideo)
        const videoSource = getVideoSource(video)
        
        return selectedTitle === videoTitle && selectedSource === videoSource
      })
      
      if (videoIndex !== -1) {
        console.log(`🎯 页面滚动完成，开始列表滚动`)
        scrollToCurrentVideoInList(videoIndex)
      }
    }

    // 动态设置推荐列表高度，与左侧主要内容区域对齐
    const adjustRecommendationsHeight = () => {
      nextTick(() => {
        const primaryContent = document.querySelector('.primary-content')
        const recommendationsList = document.querySelector('.recommendations-list')
        
        if (primaryContent && recommendationsList) {
          // 获取左侧主要内容区域的高度
          const primaryHeight = primaryContent.offsetHeight
          
          // 设置右侧推荐列表的高度与左侧对齐
          recommendationsList.style.height = `${primaryHeight}px`
          
          console.log(`📐 推荐列表高度已调整为: ${primaryHeight}px`)
        }
      })
    }

    // 监听窗口大小变化，重新调整高度
    const handleResize = () => {
      adjustRecommendationsHeight()
    }

    // ResizeObserver 监听左侧内容高度变化
    let resizeObserver = null
    const setupResizeObserver = () => {
      nextTick(() => {
        const primaryContent = document.querySelector('.primary-content')
        
        if (primaryContent && window.ResizeObserver) {
          resizeObserver = new ResizeObserver((entries) => {
            for (const entry of entries) {
              // 当左侧内容高度变化时，同步调整右侧列表高度
              adjustRecommendationsHeight()
            }
          })
          
          resizeObserver.observe(primaryContent)
          console.log('📏 已启动左侧内容高度监听')
        }
      })
    }

    // 清理ResizeObserver
    const cleanupResizeObserver = () => {
      if (resizeObserver) {
        resizeObserver.disconnect()
        resizeObserver = null
        console.log('🧹 已清理高度监听器')
      }
    }
    
    // 检查当前播放的视频是否在相关推荐列表中
    const checkCurrentVideoInList = () => {
      if (!props.videoData || allVideosData.value.length === 0) {
        currentVideoIndex.value = -1
        return
      }
      
      // 找到当前播放视频在相关推荐列表中的索引
      const currentTitle = getVideoTitle(props.videoData)
      const currentSource = getVideoSource(props.videoData)
      
      const videoIndex = allVideosData.value.findIndex(video => {
        const videoTitle = getVideoTitle(video)
        const videoSource = getVideoSource(video)
        return currentTitle === videoTitle && currentSource === videoSource
      })
      
      currentVideoIndex.value = videoIndex
      
      if (videoIndex !== -1) {
        console.log(`✅ 当前视频在相关推荐列表中的位置: ${videoIndex}`)
        // 直接滚动到当前视频位置（搜索完成后允许滚动）
        setTimeout(() => {
          scrollToCurrentVideoInList(videoIndex)
          // 同时调整高度，确保布局一致
          adjustRecommendationsHeight()
        }, 300) // 稍微延迟，让DOM完全渲染
      } else {
        console.log('ℹ️ 当前视频不在相关推荐列表中')
      }
    }
    
    // 滚动到当前视频在列表中的位置
    const scrollToCurrentVideoInList = (videoIndex) => {
      nextTick(() => {
        // 检查视频是否在当前显示的列表中
        const isInDisplayedList = videoIndex < displayedVideos.value.length
        
        if (!isInDisplayedList) {
          // 如果当前视频不在显示列表中，扩展显示列表到包含该视频
          const pagesNeeded = Math.ceil((videoIndex + 1) / videosPerPage)
          currentPage.value = pagesNeeded
          updateDisplayedVideos()
          
          console.log(`📺 扩展显示列表到第 ${pagesNeeded} 页以包含当前视频`)
        }
        
        // 等待DOM更新后滚动
        nextTick(() => {
          // 找到当前视频在显示列表中的实际位置
          const currentVideo = allVideosData.value[videoIndex]
          const displayedIndex = displayedVideos.value.findIndex(video => {
            const currentTitle = getVideoTitle(currentVideo)
            const videoTitle = getVideoTitle(video)
            const currentSource = getVideoSource(currentVideo)
            const videoSource = getVideoSource(video)
            return currentTitle === videoTitle && currentSource === videoSource
          })
          
          if (displayedIndex !== -1) {
            const recommendationsList = document.querySelector('.recommendations-list')
            const videoElement = document.querySelector(`.recommendation-item:nth-child(${displayedIndex + 1})`)
            
            if (videoElement && recommendationsList) {
              // 使用容器滚动而不是元素滚动，避免与页面滚动冲突
              const elementTop = videoElement.offsetTop
              recommendationsList.scrollTo({
                top: elementTop,
                behavior: 'smooth'
              })
              console.log(`📍 已滚动列表到当前视频位置 (显示索引: ${displayedIndex + 1})`)
            }
          }
        })
      })
    }
    
    // 无限滚动监听器
    const setupInfiniteScroll = () => {
      nextTick(() => {
        const recommendationsList = document.querySelector('.recommendations-list')
        if (!recommendationsList) return
        
        const handleScroll = () => {
          const { scrollTop, scrollHeight, clientHeight } = recommendationsList
          const threshold = 100 // 距离底部100px时触发加载
          
          if (scrollTop + clientHeight >= scrollHeight - threshold) {
            loadMoreVideos()
          }
        }
        
        recommendationsList.addEventListener('scroll', handleScroll)
        
        // 返回清理函数
        return () => {
          recommendationsList.removeEventListener('scroll', handleScroll)
        }
      })
    }

    // 获取视频信息的辅助方法
    const getVideoTitle = (video) => {
      return video.title || video.vod_name || video.name || '未知标题'
    }

    const getVideoThumbnail = (video) => {
      const thumbnail = video.cover || video.vod_pic || video.pic || video.poster
      // 过滤掉无效的图片URL
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
      // 优先显示搜索来源，然后是原始来源信息
      if (video.search_source) {
        // 尝试从可用源列表中获取名称
        const sourceInfo = availableSources.value.find(s => s.code === video.search_source)
        if (sourceInfo) {
          return sourceInfo.name
        }
        
        // 备用源名称映射
        const sourceMap = {
          'dbzy': '豆瓣资源',
          'bfzy': '暴风资源',
          'hnzy': '红牛资源', 
          'ffzy': '非凡资源',
          'lzzy': '量子资源',
          'dyttzy': '电影天堂',
          'subzyapi': '速播资源',
          'wolongzyw': '卧龙资源'
        }
        return sourceMap[video.search_source] || video.search_source
      }
      return video.source_name || video.source || '视频源'
    }

    // 新增的辅助函数
    const getVideoDirector = (video) => {
      return video.vod_director || video.director || ''
    }

    const getVideoArea = (video) => {
      return video.vod_area || video.area || ''
    }

    const getVideoLang = (video) => {
      return video.vod_lang || video.lang || video.language || ''
    }

    const getVideoRemarks = (video) => {
      return video.vod_remarks || video.remarks || ''
    }

    const getVideoActors = (video) => {
      const actors = video.vod_actor || video.actor || video.actors || ''
      if (!actors) return []
      return actors.split(',').map(actor => actor.trim()).filter(actor => actor)
    }

    const onImageError = (event) => {
      // 图片加载失败时隐藏图片，显示占位符
      event.target.style.display = 'none'
      // 占位符会自动显示，因为使用了v-else
    }

    // 海报图片状态管理
    const posterImageError = ref(false)
    
    // 获取海报图片URL（参考VideoCard.vue的逻辑）
    const getPosterUrl = (videoData) => {
      // 尝试多个可能的图片字段
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
    
    // 获取默认SVG占位图（与VideoCard.vue相同）
    const getDefaultPosterSvg = () => {
      return 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTQwIiBoZWlnaHQ9IjIxMCIgdmlld0JveD0iMCAwIDE0MCAyMTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIxNDAiIGhlaWdodD0iMjEwIiBmaWxsPSIjMjMyNDRhIi8+CjxyZWN0IHg9IjEwIiB5PSIxMCIgd2lkdGg9IjEyMCIgaGVpZ2h0PSIxNjAiIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzNjM2M1YSIgc3Ryb2tlLXdpZHRoPSIxIi8+CjxwYXRoIGQ9Ik0zMCA2MGg4MHY0MEgzMHoiIGZpbGw9IiMzYzNjNWEiIGZpbGwtb3BhY2l0eT0iMC4zIi8+Cjx0ZXh0IHg9IjcwIiB5PSIxODAiIGZvbnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSIxMiIgZmlsbD0iI2I5YmJkNCIgdGV4dC1hbmNob3I9Im1pZGRsZSI+6K+36L6T5YWl5Y2a5L2N5L2N5Y2aPC90ZXh0Pgo8L3N2Zz4K'
    }
    
    // 计算最终的海报URL
    const finalPosterUrl = computed(() => {
      if (posterImageError.value) {
        return getDefaultPosterSvg()
      }
      
      const url = getPosterUrl(props.videoData)
      if (!url) {
        return getDefaultPosterSvg()
      }
      
      return url
    })
    
    const onPosterError = (event) => {
      posterImageError.value = true
      // 自动切换到默认SVG图片
    }

    const onPosterLoad = (event) => {
      posterImageError.value = false
      // 图片加载成功
    }

    // 获取可用视频源列表
    const fetchAvailableSources = async () => {
      try {
        const response = await api.sources.list()
        
        if (response && response.success && Array.isArray(response.data)) {
          availableSources.value = response.data
          console.log(`✅ 视频源列表获取成功: ${availableSources.value.length} 个源`)
          
          // 初始化选择的源
          initializeSelectedSources()
        } else {
          throw new Error('API返回数据格式错误')
        }
      } catch (error) {
        console.error('❌ 获取视频源列表失败:', error)
        
        // 使用默认源列表作为备用
        availableSources.value = [
          { code: 'dbzy', name: '豆瓣资源', url: '', is_default: true },
          { code: 'bfzy', name: '暴风资源', url: '', is_default: true },
          { code: 'hnzy', name: '红牛资源', url: '', is_default: false },
          { code: 'ffzy', name: '非凡资源', url: '', is_default: false }
        ]
        console.log('📋 使用备用默认源列表')
        initializeSelectedSources()
      }
    }

    // 初始化选择的源
    const initializeSelectedSources = () => {
      try {
        // 从本地存储获取用户选择的源
        const storageKey = 'vastvideo_sources_web' // 为web端使用不同的key
        const storedSources = JSON.parse(localStorage.getItem(storageKey) || '[]')
        
        if (storedSources.length > 0) {
          // 验证已选择的源是否仍然存在
          const validSources = storedSources.filter(code => 
            availableSources.value.some(src => src.code === code)
          )
          
          if (validSources.length > 0) {
            selectedSources.value = validSources
            return
          }
        }
        
        // 如果没有有效的本地存储，使用后端配置的默认源
        const defaultSources = availableSources.value
          .filter(src => src.is_default)
          .map(src => src.code)
        
        if (defaultSources.length > 0) {
          selectedSources.value = defaultSources
        } else {
          // 如果没有配置默认源，使用前两个源作为备用
          selectedSources.value = availableSources.value
            .slice(0, 2)
            .map(src => src.code)

        }
        
        // 保存到本地存储
        localStorage.setItem(storageKey, JSON.stringify(selectedSources.value))
        
      } catch (error) {
        console.error('❌ 初始化选择源失败:', error)
        selectedSources.value = ['dbzy', 'bfzy'] // 最后备用
      }
    }

    // 使用指定源列表并发搜索视频的辅助函数（支持多页）
    const searchWithSources = async (sourceCodes, keyword, maxPagesPerSource = 2) => {
      const startTime = Date.now()
      console.log(`🚀 开始并发搜索: ${sourceCodes.length}个源，关键词: "${keyword}"`)
      
      // 初始化搜索进度
      const totalTasks = sourceCodes.length * maxPagesPerSource
      searchProgress.value = { current: 0, total: totalTasks, completed: 0 }
      
      // 并发控制：限制同时进行的请求数量
      const maxConcurrentRequests = 6 // 最多同时6个请求
      const requestQueue = []
      let activeRequests = 0
      
      // 请求控制函数
      const executeRequest = async (requestFn) => {
        if (activeRequests >= maxConcurrentRequests) {
          // 等待有空闲的请求槽
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
      
      // 为每个源创建搜索任务
      const searchTasks = sourceCodes.map(async (sourceCode) => {
        const sourceName = availableSources.value.find(s => s.code === sourceCode)?.name || sourceCode
        let sourceResults = []
        
        try {
          // 并发搜索该源的多页数据
          const pagePromises = []
          for (let page = 1; page <= maxPagesPerSource; page++) {
            pagePromises.push(
              executeRequest(async () => {
                try {
                  const response = await api.search.videosBySource(sourceCode, keyword, page)
                  
                  // 更新搜索进度
                  searchProgress.value.completed++
                  searchProgress.value.current = Math.min(searchProgress.value.completed, searchProgress.value.total)
                  
                  if (response && response.success && Array.isArray(response.data)) {
                    if (response.data.length === 0) {
                      return null // 标记为空页
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
                  // 更新搜索进度（即使失败也要计数）
                  searchProgress.value.completed++
                  searchProgress.value.current = Math.min(searchProgress.value.completed, searchProgress.value.total)
                  
                  console.warn(`❌ 源 ${sourceName} 第${page}页搜索异常:`, error.message)
                  return null
                }
              })
            )
          }
          
          // 等待该源的所有页面搜索完成
          const pageResults = await Promise.allSettled(pagePromises)
          
          // 收集成功的结果
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
      
      // 并发执行所有源的搜索任务
      const allSourceResults = await Promise.allSettled(searchTasks)
      
      // 收集所有成功的结果
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
      console.log(`⚡ 搜索性能: 平均每个源 ${duration / sourceCodes.length}ms，成功率 ${(successCount / sourceCodes.length * 100).toFixed(1)}%`)
      
      return results
    }
    
    // 更新显示的视频列表（分页逻辑）
    const updateDisplayedVideos = () => {
      const startIndex = 0
      const endIndex = currentPage.value * videosPerPage
      const newDisplayedVideos = allVideosData.value.slice(startIndex, endIndex)
      
      displayedVideos.value = newDisplayedVideos
      hasMoreData.value = endIndex < allVideosData.value.length
      
      console.log(`📺 当前显示 ${displayedVideos.value.length} 个视频，总计 ${allVideosData.value.length} 个，${hasMoreData.value ? '还有更多' : '已全部显示'}`)
      
      // 更新显示后调整推荐列表高度
      nextTick(() => {
        adjustRecommendationsHeight()
      })
    }
    
    // 加载更多视频（无限滚动）
    const loadMoreVideos = () => {
      if (isLoadingMore.value || !hasMoreData.value) return
      
      isLoadingMore.value = true
      console.log('📥 加载更多视频...')
      
      // 模拟异步加载延迟
      setTimeout(() => {
        currentPage.value += 1
        updateDisplayedVideos()
        isLoadingMore.value = false
        console.log(`✅ 已加载到第 ${currentPage.value} 页`)
        
        // 加载更多后重新调整高度
        nextTick(() => {
          adjustRecommendationsHeight()
        })
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
      
      // 优化搜索关键词：移除多余的标点符号和空格，提取主要关键词
      searchKeyword = searchKeyword
        .replace(/[\[\]()（）【】\-_\s]+/g, ' ') // 移除括号和特殊符号
        .trim()
        .split(' ')[0] // 取第一个主要词汇
      
      if (!searchKeyword) {
        console.log('⚠️ 搜索关键词为空')
        return
      }

      console.log(`🔍 手动触发全部源搜索: "${searchKeyword}"`)
      
      relatedVideosLoading.value = true
      isShowingPlaceholder.value = true
      searchStage.value = '全部源'
      
      try {
        // 使用所有可用源进行搜索
        const allSourceCodes = availableSources.value.map(s => s.code)
        console.log(`🔍 手动搜索: 使用全部源搜索 "${searchKeyword}" (${allSourceCodes.length}个源，每源最多2页，总计${allSourceCodes.length * 2}个任务)`)
        
        const allResults = await searchWithSources(allSourceCodes, searchKeyword, 2)
        console.log(`📊 手动搜索完成: 找到 ${allResults.length} 个视频`)
        
        if (allResults.length > 0) {
          // 过滤掉当前视频本身，去重
          const currentTitle = getVideoTitle(props.videoData).toLowerCase()
          const uniqueVideos = new Map()
          
          const filteredResults = allResults.filter(video => {
            const videoTitle = getVideoTitle(video).toLowerCase()
            const videoSource = getVideoSource(video)
            const currentSource = getVideoSource(props.videoData)
            
            // 只过滤掉完全相同的视频（标题相同且来源相同）
            const isSameVideo = videoTitle === currentTitle && videoSource === currentSource
            return !isSameVideo
          })
          
          filteredResults.forEach(video => {
            const title = getVideoTitle(video)
            if (!uniqueVideos.has(title)) {
              uniqueVideos.set(title, video)
            }
          })
          
          // 存储所有搜索结果
          allVideosData.value = Array.from(uniqueVideos.values())
          
          // 重置分页状态
          currentPage.value = 1
          hasMoreData.value = allVideosData.value.length > videosPerPage
          
          // 更新显示的视频列表
          updateDisplayedVideos()
          
          console.log(`✅ 手动搜索成功: 找到 ${allVideosData.value.length} 个相关视频，首页显示 ${displayedVideos.value.length} 个`)
          
          // 如果有搜索结果，自动显示第一个视频的信息
          if (allVideosData.value.length > 0) {
            hasSearchResults.value = true
            const firstVideo = allVideosData.value[0]
            currentVideoData.value = { ...firstVideo }
            currentVideoIndex.value = 0
            console.log(`🎬 手动搜索成功，切换到播放器模式，显示第一个相关视频: "${getVideoTitle(firstVideo)}"`)
          }
          
          // 检查当前播放的视频是否在相关推荐列表中
          checkCurrentVideoInList()
        } else {
          allVideosData.value = []
          displayedVideos.value = []
          currentVideoIndex.value = -1
          currentPage.value = 1
          hasMoreData.value = false
          hasSearchResults.value = false
          
          // 没有搜索结果时，恢复原始视频信息，继续显示海报
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
        
        // 恢复原始视频信息
        if (props.videoData && Object.keys(props.videoData).length > 0) {
          currentVideoData.value = { ...props.videoData }
        }
      } finally {
        relatedVideosLoading.value = false
        isShowingPlaceholder.value = false
        
        // 搜索完成后重新调整推荐列表高度
        nextTick(() => {
          adjustRecommendationsHeight()
        })
        
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
      
      // 优化搜索关键词：移除多余的标点符号和空格，提取主要关键词
      searchKeyword = searchKeyword
        .replace(/[\[\]()（）【】\-_\s]+/g, ' ') // 移除括号和特殊符号
        .trim()
        .split(' ')[0] // 取第一个主要词汇
      
      if (!searchKeyword) return

      relatedVideosLoading.value = true
      isShowingPlaceholder.value = true // 开始显示占位内容
      // 搜索开始时保持海报显示，等搜索结果出来后再决定是否显示播放器
      
      // 创建占位视频数据
      const placeholderData = {
        title: '正在搜索相关视频内容...',
        vod_name: '正在搜索相关视频内容...',
        type_name: '搜索中',
        year: '2024',
        vod_year: '2024',
        rate: '9.0',
        vod_score: '9.0',
        description: '我们正在为您搜索最相关的视频内容，这可能需要几秒钟时间。请稍候，我们会为您呈现最佳的观看推荐...',
        vod_content: '我们正在为您搜索最相关的视频内容，这可能需要几秒钟时间。请稍候，我们会为您呈现最佳的观看推荐...',
        vod_director: '导演姓名加载中',
        vod_area: '地区信息加载中',
        vod_lang: '语言信息加载中',
        vod_actor: '演员姓名,演员姓名,演员姓名,演员姓名,演员姓名,演员姓名',
        search_source: '智能搜索',
        source_name: '智能搜索'
      }
      
      // 搜索开始时不修改海报相关数据，继续显示原始海报
      console.log('🔄 开始搜索，保持原始海报显示')
      
      try {
        let allResults = []
        searchStage.value = '默认源'
        let usedAllSources = false
        
        // 第一阶段：使用选择的默认源搜索
        if (selectedSources.value.length > 0) {
          const defaultSources = selectedSources.value.slice(0, 3) // 使用前3个默认源
          console.log(`🔍 阶段1: 使用${searchStage.value}搜索 "${searchKeyword}" (${defaultSources.length}个源，每源最多3页，总计${defaultSources.length * 3}个任务)`)
          
          allResults = await searchWithSources(defaultSources, searchKeyword, 3)
          console.log(`📊 ${searchStage}搜索结果: ${allResults.length} 个视频`)
        }
        
        // 第二阶段：如果默认源没有结果，自动使用全部源重新搜索
        if (allResults.length === 0) {
          searchStage.value = '全部源'
          usedAllSources = true
          console.log(`⚠️ 默认源搜索无结果，自动启用${searchStage.value}搜索`)
          
          // 使用所有可用源进行搜索
          const allSourceCodes = availableSources.value.map(s => s.code)
          console.log(`🔍 阶段2: 使用${searchStage.value}搜索 "${searchKeyword}" (${allSourceCodes.length}个源，每源最多2页，总计${allSourceCodes.length * 2}个任务)`)
          
          allResults = await searchWithSources(allSourceCodes, searchKeyword, 2)
          console.log(`📊 ${searchStage.value}搜索结果: ${allResults.length} 个视频`)
        }
        

        
        if (allResults.length > 0) {
          // 过滤掉当前视频本身，去重，最多取15个相关视频
          const currentTitle = getVideoTitle(props.videoData).toLowerCase()
          const uniqueVideos = new Map()
          
          const filteredResults = allResults.filter(video => {
            const videoTitle = getVideoTitle(video).toLowerCase()
            const videoSource = getVideoSource(video)
            const currentSource = getVideoSource(props.videoData)
            
            // 只过滤掉完全相同的视频（标题相同且来源相同）
            const isSameVideo = videoTitle === currentTitle && videoSource === currentSource
            return !isSameVideo
          })
          
          filteredResults.forEach(video => {
            const title = getVideoTitle(video)
            if (!uniqueVideos.has(title)) {
              uniqueVideos.set(title, video)
            }
          })
          
          // 存储所有搜索结果
          allVideosData.value = Array.from(uniqueVideos.values())
          
          // 重置分页状态
          currentPage.value = 1
          hasMoreData.value = allVideosData.value.length > videosPerPage
          
          // 更新显示的视频列表
          updateDisplayedVideos()
          
          console.log(`✅ 最终结果: 找到 ${allVideosData.value.length} 个相关视频，首页显示 ${displayedVideos.value.length} 个`)
          
          // 如果有搜索结果，自动显示第一个视频的信息
          if (allVideosData.value.length > 0) {
            hasSearchResults.value = true
            const firstVideo = allVideosData.value[0]
            currentVideoData.value = { ...firstVideo }
            currentVideoIndex.value = 0
            console.log(`🎬 搜索成功，切换到播放器模式，显示第一个相关视频: "${getVideoTitle(firstVideo)}"`)
          }
          
          // 检查当前播放的视频是否在相关推荐列表中
          checkCurrentVideoInList()
        } else {
          allVideosData.value = []
          displayedVideos.value = []
          currentVideoIndex.value = -1
          currentPage.value = 1
          hasMoreData.value = false
          hasSearchResults.value = false
          
          // 没有搜索结果时，恢复原始视频信息，继续显示海报
          if (props.videoData && Object.keys(props.videoData).length > 0) {
            currentVideoData.value = { ...props.videoData }
          }
          console.log('⚠️ 搜索无结果，保持海报模式，恢复原始视频信息')
        }
        
        // 搜索完成的总结日志
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
        relatedVideos.value = []
      } finally {
        relatedVideosLoading.value = false
        isShowingPlaceholder.value = false // 搜索完成，关闭占位状态
        
        // 搜索完成后重新调整推荐列表高度
        nextTick(() => {
          adjustRecommendationsHeight()
        })
        
        console.log('🏁 搜索完成，占位内容已关闭')
      }
    }



    // 监听视频数据变化，同步更新当前显示数据
    watch(() => props.videoData, (newVideo) => {
      if (newVideo && Object.keys(newVideo).length > 0) {
        // 同步更新当前显示的视频数据
        currentVideoData.value = { ...newVideo }
        isShowingPlaceholder.value = false // 数据更新后关闭占位状态
        hasSearchResults.value = false // 外部视频数据更新时重置为海报模式，等搜索结果决定
        console.log(`📺 同步视频数据: "${getVideoTitle(newVideo)}"`)
      } else {
        console.log('⚠️ 接收到空或无效的视频数据')
        currentVideoData.value = {}
        hasSearchResults.value = false
      }
      
      if (skipNextSearch.value) {
        // 跳过这次搜索，重置标志
        skipNextSearch.value = false
        console.log('🔄 跳过搜索，视频数据已更新为相关推荐中的视频')
        return
      }
      
      if (newVideo && selectedSources.value.length > 0) {
        console.log('🔍 视频数据变化，开始新搜索')
        searchRelatedVideos()
      }
    }, { immediate: false })
    
    // 监听源列表变化，当源列表初始化完成时搜索相关视频
    watch(selectedSources, (newSources) => {
      if (newSources.length > 0 && props.videoData && Object.keys(props.videoData).length > 0) {
        searchRelatedVideos()
      }
    }, { immediate: false })

    onMounted(async () => {
      // 初始化当前视频数据
      if (props.videoData && Object.keys(props.videoData).length > 0) {
        currentVideoData.value = { ...props.videoData }
        isShowingPlaceholder.value = false
        hasSearchResults.value = false // 初始状态显示海报，只有搜索到结果后才显示播放器
        console.log(`📺 初始化视频数据: "${getVideoTitle(props.videoData)}"`)
        // 调试信息已简化
      } else {
        console.log('⚠️ 无视频数据传入，等待数据加载')
        hasSearchResults.value = false
        currentVideoData.value = {}
      }
      
      // 设置无限滚动
      setupInfiniteScroll()
      
      // 初始化源列表
      await fetchAvailableSources()
      
      // 如果有视频数据且有可用源，立即搜索相关视频
      if (props.videoData && Object.keys(props.videoData).length > 0 && selectedSources.value.length > 0) {
        await searchRelatedVideos()
      }
      
      // 检查当前视频是否在推荐列表中
      nextTick(checkCurrentVideoInList)
      
      // 初始化高度调整和监听
      setupResizeObserver()
      adjustRecommendationsHeight()
      
      // 监听窗口大小变化
      window.addEventListener('resize', handleResize)
    })

    // 组件卸载时清理监听器
    onUnmounted(() => {
      cleanupResizeObserver()
      window.removeEventListener('resize', handleResize)
    })

    onUnmounted(() => {
      // 清理事件监听器
      window.removeEventListener('resize', adjustRecommendationsHeight)
      
      // 清理定时器
      if (switchVideoTimeout) {
        clearTimeout(switchVideoTimeout)
        switchVideoTimeout = null
      }
    })

    // 侧边栏搜索事件处理
    const handleSidebarSearch = (keyword) => {
      emit('search', keyword)
    }

    return {
      // Props 暴露
      videoData: computed(() => props.videoData),
      
      // 状态
      showFullDescription,
      relatedVideos,
      relatedVideosLoading,
      availableSources,
      selectedSources,
      skipNextSearch,
      currentVideoData,
      isShowingPlaceholder,
      hasSearchResults,
      searchStage,
      searchProgress,
      posterImageError,
      finalPosterUrl,
      // 新的分页相关状态
      currentPage,
      hasMoreData,
      isLoadingMore,
      displayedVideos,
      allVideosData,
      videosPerPage,
      // 原有状态
      actorsList,
      episodesList,
      currentVideoIndex,
      isDescriptionFullscreen,
      // 方法
      showDescriptionFullscreen,
      closeDescriptionFullscreen,
      toggleDescription,
      selectEpisode,
      handleActorSelect,
      selectRelatedVideo,
      switchToVideo,
      executeScrollSequence,
      updateCurrentVideoHighlight,
      updateCurrentVideoHighlightOnly,
      scrollToCurrentVideoInListDelayed,
      scrollToPageTop,
      checkCurrentVideoInList,
      scrollToCurrentVideoInList,
      searchWithSources,
      searchWithAllSources,
      updateDisplayedVideos,
      loadMoreVideos,
      setupInfiniteScroll,
      isCurrentVideo,
      adjustRecommendationsHeight,
      handleResize,
      setupResizeObserver,
      cleanupResizeObserver,
      getVideoTitle,
      getVideoThumbnail,
      getVideoYear,
      getVideoType,
      getVideoRating,
      getVideoSource,
      getVideoDirector,
      getVideoArea,
      getVideoLang,
      getVideoRemarks,
      getVideoActors,
      getVideoSize,
      onImageError,
      onPosterError,
      onPosterLoad,
      getPosterUrl,
      getDefaultPosterSvg,
      toggleDescription,
      handleSidebarSearch
    }
  }
})
</script>

<style scoped>
.video-detail-desktop {
  background: #1a1b2e;
  color: #e0e0e0;
  min-height: 100vh;
  padding: 20px 40px 40px;
  max-width: 1400px;
  margin: 0 auto;
  width: 100%;
}



/* 空状态样式 */
.empty-state {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 60vh;
  padding: 40px;
}

.empty-state-content {
  text-align: center;
  color: #e0e0e0;
  max-width: 400px;
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
  font-size: 20px;
  font-weight: 600;
  margin-bottom: 12px;
  color: #ffffff;
}

.empty-state-desc {
  font-size: 14px;
  color: #a5a5a5;
  line-height: 1.5;
}

/* YouTube风格主布局 */
.youtube-layout {
  display: grid;
  grid-template-columns: 1fr 400px;
  gap: 24px;
  margin-bottom: 30px;
  align-items: start;
  position: relative;
}



/* 左侧主内容区 */
.main-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* 主要内容区域（到剧集选择为止） */
.primary-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* 播放器区域 */
.player-section {
  width: 100%;
}

.video-player-container {
  background: #000;
  border-radius: 12px;
  overflow: hidden;
  aspect-ratio: 16/9;
  position: relative;
  cursor: pointer;
  transition: transform 0.2s;
  width: 100%;
}

.video-player-container:hover {
  transform: scale(1.002);
}

.video-player-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #1e3a8a, #3730a3);
  color: white;
}

.play-icon {
  font-size: 48px;
  margin-bottom: 12px;
  opacity: 0.9;
}

.player-text {
  font-size: 16px;
  opacity: 0.8;
}

/* 海报容器样式 */
.video-poster-container {
  width: 100%;
  height: 100%;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #0f172a, #1e293b);
  border-radius: 12px;
  overflow: hidden;
  padding: 20px; /* 给海报留出边距 */
  min-height: 400px; /* 确保容器有足够的高度 */
}

/* 响应式设计 */
@media (max-width: 768px) {
  .video-poster-container {
    min-height: 300px;
    padding: 15px;
  }
}

.poster-image {
  max-width: calc(100% - 40px); /* 减去container的padding */
  max-height: calc(100% - 40px);
  width: auto;
  height: auto;
  object-fit: contain; /* 保持比例，完整显示海报 */
  transition: all 0.3s ease;
  border-radius: 8px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
  /* 确保海报居中显示 */
  display: block;
  margin: auto;
  /* 设置最大尺寸限制，确保海报不会过大 */
  max-width: 350px;
}

/* 响应式海报尺寸 */
@media (max-width: 768px) {
  .poster-image {
    max-width: calc(100% - 30px);
    max-height: calc(100% - 30px);
  }
}

/* 海报图片保持原始亮度，无任何滤镜 */

/* .poster-placeholder 样式已移除，使用SVG默认图片 */

/* 覆盖层样式已移除，海报显示为纯净模式 */



/* 视频信息区域 */
.video-info {
  background: #23244a;
  padding: 20px;
  border-radius: 12px;
}

.video-title {
  font-size: 20px;
  font-weight: 600;
  color: #ffffff;
  margin-bottom: 16px;
  line-height: 1.4;
}

.video-meta-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
}

.video-meta-left {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.meta-tag {
  background: #3a3b5a;
  color: #e0e0e0;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  white-space: nowrap;
}

.meta-tag.rating {
  background: #f59e0b;
  color: #1a1b2e;
  font-weight: 500;
}

.meta-tag.source {
  background: #10b981;
  color: #1a1b2e;
  font-weight: 500;
}

.video-actions {
  display: flex;
  gap: 8px;
}

.action-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s;
  background: #3a3b5a;
  color: #e0e0e0;
}

.action-btn:hover {
  background: #4a4b6a;
}

.action-btn.primary {
  background: #6366f1;
  color: white;
}

.action-btn.primary:hover {
  background: #5b5fef;
}

/* 按钮禁用状态 */
.action-btn:disabled {
  background: #2a2b4a;
  color: #6b7280;
  cursor: not-allowed;
  opacity: 0.6;
}

.action-btn.primary:disabled {
  background: #4b5563;
  color: #9ca3af;
  cursor: not-allowed;
}

.action-btn:disabled:hover {
  background: #2a2b4a;
  transform: none;
}

.action-btn.primary:disabled:hover {
  background: #4b5563;
  transform: none;
}

.action-btn:disabled svg {
  opacity: 0.5;
}



/* 描述信息 */
.video-description {
  background: #23244a;
  padding: 20px;
  border-radius: 12px;
}

.description-content {
  max-height: 60px;
  overflow: hidden;
  transition: max-height 0.3s ease;
  position: relative;
}

.description-content.expanded {
  max-height: 300px;
}

.description-content p {
  color: #d1d1d1;
  line-height: 1.6;
  font-size: 14px;
  margin: 0;
}

.show-more-btn {
  background: none;
  border: none;
  color: #6366f1;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  margin-top: 8px;
  padding: 4px 0;
}

.show-more-btn:hover {
  color: #5b5fef;
}

/* 剧集选择 */
.episodes-section {
  background: #23244a;
  padding: 20px;
  border-radius: 12px;
}

.episodes-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.section-title {
  font-size: 18px;
  font-weight: 600;
  color: #ffffff;
  margin: 0;
}

.episodes-count {
  font-size: 14px;
  color: #a5a5a5;
}

.episodes-container {
  max-height: 200px;
  overflow-y: auto;
}

.episodes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
  gap: 8px;
}

.episode-item {
  background: #3a3b5a;
  color: #e0e0e0;
  padding: 10px 8px;
  border-radius: 6px;
  text-align: center;
  cursor: pointer;
  font-size: 13px;
  font-weight: 500;
  transition: all 0.2s;
  min-height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.episode-item:hover {
  background: #4a4b6a;
  transform: translateY(-1px);
}

.episode-item.active {
  background: #6366f1;
  color: white;
}



/* 演员信息 */
.cast-section {
  background: #23244a;
  padding: 20px;
  border-radius: 12px;
}

.cast-container {
  margin-top: 16px;
}

.cast-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.cast-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: #2a2b4a;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.cast-item:hover {
  background: #3a3b5a;
  transform: translateY(-1px);
}

.cast-avatar {
  width: 50px;
  height: 50px;
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  border-radius: 50%;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
  font-size: 18px;
  text-transform: uppercase;
}

.cast-info {
  flex: 1;
  min-width: 0;
}

.cast-name {
  font-size: 14px;
  font-weight: 500;
  color: #ffffff;
  margin-bottom: 2px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.cast-role {
  font-size: 12px;
  color: #a5a5a5;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}



/* 单集信息 */
.single-episode-info {
  display: flex;
  gap: 16px;
  margin-top: 16px;
}

.episode-quality {
  background: #6366f1;
  color: white;
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
}

.episode-size {
  background: #374151;
  color: #d1d1d1;
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 14px;
}

/* 右侧推荐列表 */
.recommendations {
  display: flex;
  flex-direction: column;
  align-self: start;
  position: sticky;
  top: 20px;
  height: fit-content;
}

/* 推荐列表标题和操作按钮 */
.recommendations-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding: 0 4px;
}

.recommendations-header .section-title {
  font-size: 18px;
  font-weight: 600;
  color: #ffffff;
  margin: 0;
}

.search-actions {
  display: flex;
  gap: 8px;
}

.search-all-sources-btn {
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  color: white;
  border: none;
  padding: 8px 12px;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 500;
  transition: all 0.2s ease;
  box-shadow: 0 2px 4px rgba(99, 102, 241, 0.2);
}

.search-all-sources-btn:hover {
  background: linear-gradient(135deg, #5b5fef, #7c3aed);
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(99, 102, 241, 0.3);
}

.search-all-sources-btn:active {
  transform: translateY(0);
  box-shadow: 0 2px 4px rgba(99, 102, 241, 0.2);
}

.search-all-sources-btn:disabled {
  background: #4b5563;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
  opacity: 0.6;
}

.btn-icon {
  font-size: 14px;
}

/* 旧的推荐列表标题样式已移除，使用新的recommendations-header样式 */

.recommendations-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  /* 高度通过JavaScript动态设置，与左侧主要内容区域对齐 */
  overflow-y: auto;
  border-radius: 12px;
  background: rgba(35, 36, 74, 0.3);
  padding: 8px;
  
  /* 自定义滚动条样式 */
  scrollbar-width: thin;
  scrollbar-color: #6366f1 transparent;
}

.recommendations-list::-webkit-scrollbar {
  width: 6px;
}

.recommendations-list::-webkit-scrollbar-track {
  background: transparent;
}

.recommendations-list::-webkit-scrollbar-thumb {
  background: #6366f1;
  border-radius: 3px;
}

.recommendations-list::-webkit-scrollbar-thumb:hover {
  background: #5b5fef;
}

/* 占位模糊效果 */
.placeholder-blur {
  position: relative;
  overflow: hidden;
  transition: all 0.3s ease;
}

.placeholder-blur::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(
    90deg,
    transparent,
    rgba(255, 255, 255, 0.1),
    transparent
  );
  animation: shimmer 1.5s infinite;
  z-index: 1;
}

.placeholder-blur * {
  filter: blur(0.5px);
  opacity: 0.7;
  transition: all 0.3s ease;
}

@keyframes shimmer {
  0% {
    left: -100%;
  }
  100% {
    left: 100%;
  }
}

/* 加载状态样式增强 */
.placeholder-blur .meta-tag,
.placeholder-blur .info-value,
.placeholder-blur .cast-name {
  background: linear-gradient(90deg, #374151, #4b5563, #374151);
  background-size: 200% 100%;
  animation: loading-pulse 1.5s ease-in-out infinite;
  border-radius: 4px;
  color: transparent !important;
}

@keyframes loading-pulse {
  0%, 100% {
    background-position: 200% 0;
  }
  50% {
    background-position: -200% 0;
  }
}

.recommendation-item {
  display: flex;
  gap: 12px;
  padding: 12px;
  background: #23244a;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
  align-items: flex-start;
}

.recommendation-item:hover {
  background: #2a2b4a;
  transform: translateY(-1px);
}

.recommendation-item:hover .recommendation-thumbnail {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
  transform: scale(1.02);
}

.recommendation-item.current-video {
  border: 2px solid #6366f1;
  background: linear-gradient(135deg, #2a2d5a, #3a3d6a);
  position: relative;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
}

.recommendation-item.current-video::before {
  content: "正在播放";
  position: absolute;
  top: 8px;
  right: 8px;
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  color: white;
  font-size: 10px;
  font-weight: 600;
  padding: 3px 8px;
  border-radius: 6px;
  z-index: 2;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.recommendation-item.current-video:hover {
  background: linear-gradient(135deg, #30406a, #40508a);
  border-color: #5b5fef;
  box-shadow: 0 6px 16px rgba(99, 102, 241, 0.4);
}

.recommendation-item.current-video .recommendation-thumbnail::after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  border: 2px solid #6366f1;
  border-radius: 8px;
  pointer-events: none;
}

.recommendation-thumbnail {
  position: relative;
  width: 126px;
  height: 189px;
  background: #18192b;
  border-radius: 8px;
  flex-shrink: 0;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
  transition: all 0.3s ease;
}

.recommendation-thumbnail img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  background: #18192b;
  transition: opacity 0.3s ease;
}

.thumbnail-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #374151, #4b5563);
}

.placeholder-icon {
  font-size: 32px;
  opacity: 0.6;
  color: #6b7280;
}

.thumbnail-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.3);
  opacity: 0;
  transition: opacity 0.2s;
}

.recommendation-item:hover .thumbnail-overlay {
  opacity: 1;
}

.play-btn {
  color: white;
  font-size: 24px;
  opacity: 0.9;
}

.video-source-badge {
  position: absolute;
  top: 4px;
  right: 4px;
  background: rgba(0, 0, 0, 0.8);
  color: white;
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 500;
  max-width: 80px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.recommendation-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding-top: 4px;
  min-height: 189px; /* 与海报高度保持一致 */
}

.recommendation-title {
  font-size: 14px;
  font-weight: 600;
  color: #ffffff;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin-bottom: 6px;
  min-height: 42px; /* 确保标题有足够的高度 */
}

/* 视频基本信息 */
.video-basic-info {
  display: flex;
  flex-direction: column;
  gap: 3px;
  margin-bottom: 6px;
}

.info-row {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  line-height: 1.2;
}

.info-label {
  color: #9ca3af;
  font-weight: 500;
  min-width: 32px;
  flex-shrink: 0;
}

.info-value {
  color: #e5e7eb;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.rating-value {
  color: #fbbf24;
  font-weight: 600;
}

/* 演员信息 */
.actors-info {
  margin-top: auto;
  padding-top: 6px;
  border-top: 1px solid #374151;
}

.actors-info .info-label {
  color: #9ca3af;
  font-weight: 500;
  font-size: 11px;
  margin-bottom: 3px;
  display: block;
}

.actors-list {
  font-size: 10px;
  color: #d1d5db;
  line-height: 1.2;
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.more-actors {
  color: #6b7280;
  font-style: italic;
}

/* 滚动条样式 */
.episodes-container::-webkit-scrollbar,
.recommendations-list::-webkit-scrollbar {
  width: 4px;
}

.episodes-container::-webkit-scrollbar-track,
.recommendations-list::-webkit-scrollbar-track {
  background: #2a2b4a;
  border-radius: 2px;
}

.episodes-container::-webkit-scrollbar-thumb,
.recommendations-list::-webkit-scrollbar-thumb {
  background: #4a4b6a;
  border-radius: 2px;
}

.episodes-container::-webkit-scrollbar-thumb:hover,
.recommendations-list::-webkit-scrollbar-thumb:hover {
  background: #5a5b7a;
}

/* 响应式调整 */
@media (max-width: 1200px) {
  .youtube-layout {
    grid-template-columns: 1fr 350px;
    gap: 20px;
  }
  
  .recommendation-thumbnail {
    width: 105px;
    height: 157px;
  }
  
  .recommendation-thumbnail img {
    object-fit: cover;
  }
  
  .video-source-badge {
    font-size: 9px;
    max-width: 70px;
  }
  
  .recommendation-info {
    min-height: 157px; /* 与海报高度保持一致 */
  }
  
  .cast-grid {
    grid-template-columns: repeat(3, 1fr);
  }
  
  .episodes-grid {
    grid-template-columns: repeat(auto-fill, minmax(80px, 1fr));
  }
}

@media (max-width: 1000px) {
  .video-detail-desktop {
    padding: 20px 20px 20px;
  }
  
  .youtube-layout {
    grid-template-columns: 1fr;
    gap: 20px;
  }
  
  .recommendations {
    order: -1;
    position: static;
    top: auto;
  }
  
  .recommendations-list {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 16px;
  }
  
  .recommendation-item {
    flex-direction: column;
  }
  
  .recommendation-thumbnail {
    width: 100%;
    aspect-ratio: 2/3;
    height: auto;
  }
  
  .recommendation-thumbnail img {
    object-fit: cover;
  }
  
  .video-source-badge {
    font-size: 8px;
    max-width: 60px;
  }
  
  .recommendation-info {
    min-height: auto; /* 小屏幕下自适应高度 */
  }
  
  .video-basic-info {
    gap: 2px;
  }
  
  .info-row {
    font-size: 10px;
  }
  
  .actors-info .info-label {
    font-size: 10px;
  }
  
  .actors-list {
    font-size: 9px;
    -webkit-line-clamp: 1;
  }
  
  .video-basic-info {
    gap: 2px;
  }
  
  .info-row {
    font-size: 9px;
  }
  
  .actors-info .info-label {
    font-size: 9px;
  }
  
  .actors-list {
    font-size: 8px;
  }
  
  .cast-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .episodes-grid {
    grid-template-columns: repeat(auto-fill, minmax(70px, 1fr));
  }
  
  .video-actions {
    flex-wrap: wrap;
  }
}

/* 加载状态 */
.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
  color: #aaaaaa;
}

.loading-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #3a3b5a;
  border-top: 3px solid #6366f1;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 12px;
}

.loading-text {
  font-size: 14px;
  text-align: center;
  margin-bottom: 4px;
}

.loading-subtext {
  font-size: 12px;
  text-align: center;
  color: #888888;
  font-style: italic;
}

.search-progress {
  margin-top: 16px;
  width: 100%;
  max-width: 300px;
}

.progress-bar {
  width: 100%;
  height: 6px;
  background: #374151;
  border-radius: 3px;
  overflow: hidden;
  margin-bottom: 8px;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #6366f1, #8b5cf6);
  border-radius: 3px;
  transition: width 0.3s ease;
}

.progress-text {
  font-size: 12px;
  color: #9ca3af;
  text-align: center;
}

.progress-detail {
  color: #6b7280;
  font-size: 11px;
  opacity: 0.8;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* 无结果状态 */
.no-results {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
  color: #888888;
  text-align: center;
}

.no-results-icon {
  font-size: 48px;
  margin-bottom: 12px;
  opacity: 0.6;
}

.no-results-text {
  font-size: 14px;
  color: #aaaaaa;
}

/* 加载更多样式 */
.load-more-container {
  padding: 16px 4px;
  text-align: center;
}

.load-more-btn {
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 2px 8px rgba(99, 102, 241, 0.2);
}

.load-more-btn:hover {
  background: linear-gradient(135deg, #5b5fef, #7c3aed);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
}

.loading-more {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  color: #a5a5a5;
  font-size: 14px;
}

.loading-spinner-small {
  width: 16px;
  height: 16px;
  border: 2px solid #374151;
  border-top: 2px solid #6366f1;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

.videos-stats {
  padding: 8px 4px;
  text-align: center;
  font-size: 12px;
  color: #6b7280;
  border-top: 1px solid #374151;
  margin-top: 8px;
}

/* 优化推荐列表滚动和分页 */
.recommendations-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-height: 700px; /* 增加最大高度，适应更高的海报 */
  overflow-y: auto;
  padding-right: 4px; /* 为滚动条留出空间 */
  /* 高度通过JavaScript动态设置，与左侧主要内容对齐 */
}

/* 自定义滚动条样式 */
.recommendations-list::-webkit-scrollbar {
  width: 6px;
}

.recommendations-list::-webkit-scrollbar-track {
  background: #23244a;
  border-radius: 3px;
}

.recommendations-list::-webkit-scrollbar-thumb {
  background: #6366f1;
  border-radius: 3px;
}

.recommendations-list::-webkit-scrollbar-thumb:hover {
  background: #5b5fef;
}
</style>
