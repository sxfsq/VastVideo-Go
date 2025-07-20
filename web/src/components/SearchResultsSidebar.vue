<template>
    <div>
      <!-- 悬浮展开按钮（收缩时显示） -->
      <transition name="fade">
        <button
          v-if="!isExpanded"
          class="sidebar-fab"
          @click="toggleSidebar(true)"
        >
          <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor">
            <circle cx="12" cy="12" r="12" fill="#6c63ff"/>
            <path d="M8 5v14l2-2l2 2V5H8z" fill="#fff"/>
            <path d="M16 5v14l-2-2l-2 2V5h4z" fill="#fff"/>
          </svg>
          <span class="fab-text">搜索结果</span>
          <span v-if="displayedVideos.length > 0" class="fab-badge">{{ displayedVideos.length }}</span>
        </button>
      </transition>
  
      <!-- 侧边栏（展开时显示） -->
      <transition name="slide-sidebar">
        <div
          v-if="isExpanded"
          class="search-results-sidebar sidebar-expanded"
        >
          <div class="sidebar-toggle" @click="toggleSidebar(false)">
            <div class="toggle-icon">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M19 6.41L17.59 5L12 10.59L6.41 5L5 6.41L10.59 12L5 17.59L6.41 19L12 13.41L17.59 19L19 17.59L13.41 12L19 6.41z"/>
              </svg>
            </div>
            <span class="toggle-text">收起</span>
          </div>
          <div class="sidebar-content">
            <!-- 搜索状态头部 -->
            <div class="sidebar-header">
              <h3 class="sidebar-title">搜索结果</h3>
              <div class="search-actions">
                <button 
                  v-if="!relatedVideosLoading && availableSources.length > 0"
                  class="search-all-sources-btn"
                  @click="searchWithAllSources"
                  :disabled="relatedVideosLoading"
                >
                  <span class="btn-icon">🔍</span>
                  全部源
                </button>
              </div>
            </div>
  
            <!-- 搜索进度 -->
            <div v-if="relatedVideosLoading" class="loading-container">
              <div class="loading-spinner"></div>
              <div class="loading-text">
                正在{{ searchStage === '全部源' ? '使用全部源' : '使用默认源' }}搜索...
              </div>
              <div v-if="searchStage === '全部源'" class="loading-subtext">
                默认源无结果，扩大搜索范围
              </div>
              <div class="search-progress">
                <div class="progress-bar">
                  <div 
                    class="progress-fill" 
                    :style="{ width: `${(searchProgress.completed / searchProgress.total) * 100}%` }"
                  ></div>
                </div>
                <div class="progress-text">
                  {{ searchProgress.completed }}/{{ searchProgress.total }}
                </div>
              </div>
            </div>
  
            <!-- 搜索结果列表 -->
            <div v-else-if="displayedVideos.length > 0" class="search-results-list">
              <div 
                v-for="(video, index) in displayedVideos" 
                :key="`video-${index}-${video.vod_name || video.title || index}-${video.source_page || 1}`"
                :class="['search-result-item', { 'current-video': isCurrentVideo(video) }]" 
                @click="selectRelatedVideo(video)"
              >
                <div class="result-thumbnail">
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
                <div class="result-info">
                  <div class="result-title">{{ getVideoTitle(video) }}</div>
                  <div class="result-meta">
                    <span v-if="getVideoYear(video)" class="meta-year">{{ getVideoYear(video) }}</span>
                    <span v-if="getVideoRating(video)" class="meta-rating">★ {{ getVideoRating(video) }}</span>
                    <span class="meta-type">{{ getVideoType(video) }}</span>
                  </div>
                </div>
              </div>
  
              <!-- 加载更多 -->
              <div v-if="displayedVideos.length > 0 && hasMoreData" class="load-more-container">
                <div v-if="isLoadingMore" class="loading-more">
                  <div class="loading-spinner-small"></div>
                  <span>加载中...</span>
                </div>
                <button 
                  v-else 
                  class="load-more-btn" 
                  @click="loadMoreVideos"
                >
                  更多 ({{ allVideosData.length - displayedVideos.length }})
                </button>
              </div>
  
              <!-- 统计信息 -->
              <div v-if="allVideosData.length > 0" class="videos-stats">
                {{ displayedVideos.length }}/{{ allVideosData.length }} 个结果
              </div>
            </div>
  
            <!-- 无结果状态 -->
            <div v-else-if="!relatedVideosLoading" class="no-results">
              <div class="no-results-icon">🔍</div>
              <div class="no-results-text">暂无相关视频</div>
              <div class="no-results-desc">尝试使用全部源搜索</div>
            </div>
          </div>
        </div>
      </transition>
    </div>
  </template>
  
  <script>
  import { defineComponent, ref, watch } from 'vue'
  
  export default defineComponent({
    name: 'SearchResultsSidebar',
    props: {
      relatedVideosLoading: Boolean,
      searchStage: String,
      searchProgress: Object,
      availableSources: Array,
      displayedVideos: Array,
      allVideosData: Array,
      hasMoreData: Boolean,
      isLoadingMore: Boolean,
      currentVideoData: Object
    },
    emits: ['video-select', 'search-all-sources', 'load-more', 'toggle-sidebar'],
    setup(props, { emit, expose }) {
      const isExpanded = ref(false)
      let autoCollapseTimer = null
  
      // 展开/收起
      const openSidebar = () => {
        isExpanded.value = true
        emit('toggle-sidebar', true)
      }
      const closeSidebar = () => {
        isExpanded.value = false
        emit('toggle-sidebar', false)
      }
      const toggleSidebar = (expand) => {
        if (expand === true) {
          openSidebar()
        } else if (expand === false) {
          closeSidebar()
        } else {
          isExpanded.value = !isExpanded.value
          emit('toggle-sidebar', isExpanded.value)
        }
      }
      // 监听搜索状态，自动展开/收缩
      watch(() => props.relatedVideosLoading, (loading) => {
        if (loading) {
          openSidebar()
          if (autoCollapseTimer) clearTimeout(autoCollapseTimer)
        } else {
          if (autoCollapseTimer) clearTimeout(autoCollapseTimer)
          autoCollapseTimer = setTimeout(() => {
            closeSidebar()
          }, 1000)
        }
      })
  
      // 其余工具函数同前
      const getVideoTitle = (video) => video.title || video.vod_name || video.name || '未知标题'
      const getVideoThumbnail = (video) => {
        const thumbnail = video.cover || video.vod_pic || video.pic || video.poster
        if (thumbnail && thumbnail.trim() && !thumbnail.includes('placeholder.com')) return thumbnail
        return null
      }
      const getVideoYear = (video) => video.year || video.vod_year || ''
      const getVideoType = (video) => video.type || video.type_name || video.vod_type || '视频'
      const getVideoRating = (video) => {
        const rating = video.rate || video.vod_score || video.rating || video.score
        if (rating && rating !== '0' && rating !== '0.0') return rating
        return null
      }
      const getVideoSource = (video) => {
        if (video.search_source) {
          const sourceInfo = props.availableSources.find(s => s.code === video.search_source)
          if (sourceInfo) return sourceInfo.name
          const sourceMap = {
            'dbzy': '豆瓣资源','bfzy': '暴风资源','hnzy': '红牛资源','ffzy': '非凡资源','lzzy': '量子资源','dyttzy': '电影天堂资源','subzyapi': '速播资源','wolongzyw': '卧龙资源','wolong': '卧龙资源','mozhua': '魔爪资源','zuid': '最大资源','ruyi': '如意资源','heimuer': '黑木耳','mdzy': '魔都资源','baidu': '百度云资源','ikun': 'iKun资源','tyyszy': '天涯资源','jisu': '极速资源','wujin': '无尽资源','wwzy': '旺旺短剧','zy360': '360资源'
          }
          return sourceMap[video.search_source] || video.search_source
        }
        return video.source_name || video.source || '视频源'
      }
      const isCurrentVideo = (video) => {
        const currentTitle = props.currentVideoData.title || props.currentVideoData.vod_name || props.currentVideoData.name
        const videoTitle = video.title || video.vod_name || video.name
        return currentTitle === videoTitle
      }
      const selectRelatedVideo = (video) => emit('video-select', video)
      const searchWithAllSources = () => emit('search-all-sources')
      const loadMoreVideos = () => emit('load-more')
      const onImageError = (event) => {
        event.target.style.display = 'none'
        const placeholder = event.target.parentElement.querySelector('.thumbnail-placeholder')
        if (placeholder) placeholder.style.display = 'flex'
      }
  
      // 暴露方法给父组件
      expose({ openSidebar, closeSidebar })
  
      return {
        isExpanded,
        toggleSidebar,
        getVideoTitle,
        getVideoThumbnail,
        getVideoYear,
        getVideoType,
        getVideoRating,
        getVideoSource,
        isCurrentVideo,
        selectRelatedVideo,
        searchWithAllSources,
        loadMoreVideos,
        onImageError
      }
    }
  })
  </script>
  
  <style scoped>
  .search-results-sidebar {
    position: fixed;
    top: 0;
    right: 0;
    height: 100vh;
    z-index: 1000;
    display: flex;
    flex-direction: column;
    background: rgba(15, 15, 15, 0.95);
    backdrop-filter: blur(20px);
    border-left: 1px solid rgba(255, 255, 255, 0.1);
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    width: 320px;
    box-shadow: -2px 0 16px 0 rgba(0,0,0,0.12);
  }
  
  .sidebar-toggle {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 16px 8px;
    cursor: pointer;
    background: rgba(108, 99, 255, 0.1);
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    min-height: 80px;
    position: relative;
    transition: background 0.2s;
  }
  .sidebar-toggle:hover {
    background: rgba(108, 99, 255, 0.2);
  }
  .toggle-icon {
    color: #6c63ff;
    margin-bottom: 8px;
  }
  .toggle-text {
    font-size: 12px;
    color: #ffffff;
    text-align: center;
    writing-mode: vertical-rl;
    text-orientation: mixed;
    transform: rotate(180deg);
    white-space: nowrap;
  }
  
  /* 悬浮展开按钮 */
  .sidebar-fab {
    position: fixed;
    right: 18px;
    bottom: 24px;
    z-index: 1100;
    background: #fff;
    border: none;
    border-radius: 50px;
    box-shadow: 0 4px 16px rgba(108,99,255,0.18);
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 16px 8px 8px;
    cursor: pointer;
    transition: box-shadow 0.2s;
  }
  .sidebar-fab:hover {
    box-shadow: 0 8px 24px rgba(108,99,255,0.28);
  }
  .fab-text {
    color: #6c63ff;
    font-size: 14px;
    font-weight: 600;
  }
  .fab-badge {
    background: #ff4757;
    color: #fff;
    border-radius: 50%;
    width: 20px;
    height: 20px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    font-weight: bold;
    margin-left: 4px;
  }
  
  /* 动画 */
  .slide-sidebar-enter-active, .slide-sidebar-leave-active {
    transition: transform 0.3s cubic-bezier(0.4,0,0.2,1), opacity 0.3s;
  }
  .slide-sidebar-enter-from, .slide-sidebar-leave-to {
    transform: translateX(100%);
    opacity: 0;
  }
  .slide-sidebar-enter-to, .slide-sidebar-leave-from {
    transform: translateX(0);
    opacity: 1;
  }
  .fade-enter-active, .fade-leave-active {
    transition: opacity 0.3s;
  }
  .fade-enter-from, .fade-leave-to {
    opacity: 0;
  }
  .fade-enter-to, .fade-leave-from {
    opacity: 1;
  }
  
  .sidebar-content { flex: 1; overflow: hidden; display: flex; flex-direction: column; padding: 16px; position: relative; }
  @media (max-width: 480px) {
    .search-results-sidebar {
      width: 100vw;
      max-width: 100vw;
    }
    .sidebar-fab {
      right: 10px;
      bottom: 12px;
      padding: 8px 12px 8px 8px;
    }
  }
  </style>
  