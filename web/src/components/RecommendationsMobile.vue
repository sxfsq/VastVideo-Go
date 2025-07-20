<template>
  <div class="recommendations-mobile">
    <div class="recommendations-section">
      <div class="section-header">
        <h3 class="section-title">相关推荐</h3>
        <div class="search-actions">
          <button 
            v-if="!relatedVideosLoading && availableSources.length > 0"
            class="search-all-sources-btn"
            @click="searchWithAllSources"
            :disabled="relatedVideosLoading"
          >
            <span class="btn-icon">🔍</span>
            全部源搜索
          </button>
        </div>
      </div>
      
      <div v-if="relatedVideosLoading" class="loading-container">
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
          </div>
        </div>
      </div>
      
      <div v-else-if="displayedVideos.length > 0" class="recommendations-list">
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
            </div>
          </div>
          <button class="more-options">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
              <circle cx="12" cy="5" r="2"/>
              <circle cx="12" cy="12" r="2"/>
              <circle cx="12" cy="19" r="2"/>
            </svg>
          </button>
        </div>
        
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
        
        <div v-if="allVideosData.length > 0" class="videos-stats">
          已显示 {{ displayedVideos.length }} / {{ allVideosData.length }} 个相关视频
        </div>
      </div>
      
      <div v-else-if="!relatedVideosLoading" class="no-results">
        <div class="no-results-icon">🔍</div>
        <div class="no-results-text">暂无相关推荐</div>
      </div>
    </div>
  </div>
</template>

<script>
import { defineComponent, ref, computed } from 'vue'

export default defineComponent({
  name: 'RecommendationsMobile',
  props: {
    videoData: {
      type: Object,
      required: false,
      default: () => ({})
    },
    relatedVideosLoading: {
      type: Boolean,
      default: false
    },
    searchStage: {
      type: String,
      default: '默认源'
    },
    searchProgress: {
      type: Object,
      default: () => ({ completed: 0, total: 0 })
    },
    availableSources: {
      type: Array,
      default: () => []
    },
    displayedVideos: {
      type: Array,
      default: () => []
    },
    allVideosData: {
      type: Array,
      default: () => []
    },
    hasMoreData: {
      type: Boolean,
      default: false
    },
    isLoadingMore: {
      type: Boolean,
      default: false
    }
  },
  emits: ['video-select', 'search-all-sources', 'load-more'],
  setup(props, { emit }) {
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

    const isCurrentVideo = (video) => {
      if (!props.videoData) return false
      
      const currentTitle = getVideoTitle(props.videoData)
      const videoTitle = getVideoTitle(video)
      const currentSource = getVideoSource(props.videoData)
      const videoSource = getVideoSource(video)
      
      return currentTitle === videoTitle && currentSource === videoSource
    }

    const onImageError = (event) => {
      event.target.style.display = 'none'
    }

    const selectRelatedVideo = (video) => {
      console.log('选择相关视频:', video)
      emit('video-select', video)
    }

    const searchWithAllSources = () => {
      emit('search-all-sources')
    }

    const loadMoreVideos = () => {
      emit('load-more')
    }
    
    return {
      getVideoTitle,
      getVideoThumbnail,
      getVideoYear,
      getVideoType,
      getVideoRating,
      getVideoSource,
      isCurrentVideo,
      onImageError,
      selectRelatedVideo,
      searchWithAllSources,
      loadMoreVideos
    }
  }
})
</script>

<style scoped>
.recommendations-mobile {
  width: 100%;
}

.recommendations-section {
  padding: 16px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.section-title {
  font-size: 16px;
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
  padding: 6px 10px;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  font-weight: 500;
  transition: all 0.2s ease;
}

.search-all-sources-btn:hover:not(:disabled) {
  background: linear-gradient(135deg, #5b5fef, #7c3aed);
  transform: translateY(-1px);
}

.search-all-sources-btn:disabled {
  background: #4b5563;
  cursor: not-allowed;
  transform: none;
  opacity: 0.6;
}

.btn-icon {
  font-size: 12px;
}

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

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.recommendations-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.recommendation-item {
  display: flex;
  gap: 12px;
  cursor: pointer;
  transition: background 0.2s;
  padding: 8px;
  border-radius: 8px;
}

.recommendation-item:hover {
  background: #1a1a1a;
}

.recommendation-item.current-video {
  border: 2px solid #6366f1;
  background: linear-gradient(135deg, #2a2d5a, #3a3d6a);
  position: relative;
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
}

.recommendation-thumbnail {
  position: relative;
  width: 120px;
  height: 68px;
  background: linear-gradient(135deg, #272727, #373737);
  border-radius: 8px;
  flex-shrink: 0;
  overflow: hidden;
}

.recommendation-thumbnail img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  background: #18192b;
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
  font-size: 24px;
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
  font-size: 20px;
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
  gap: 4px;
}

.recommendation-title {
  font-size: 14px;
  font-weight: 500;
  color: #ffffff;
  line-height: 1.3;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.video-basic-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
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

.more-options {
  background: none;
  border: none;
  color: #aaaaaa;
  cursor: pointer;
  padding: 4px;
  border-radius: 50%;
  transition: background 0.2s;
  align-self: flex-start;
}

.more-options:hover {
  background: #272727;
}

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
}

.load-more-btn:hover {
  background: linear-gradient(135deg, #5b5fef, #7c3aed);
  transform: translateY(-1px);
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
</style>
