<template>
  <div class="recommendations">
    <!-- 推荐列表标题和操作按钮 -->
    <div class="recommendations-header">
      <h3 class="section-title">相关推荐</h3>
      <div class="search-actions">
        <button 
          v-if="!relatedVideosLoading && availableSources.length > 0"
          class="search-all-sources-btn"
          @click="$emit('search-all-sources')"
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
          @click="$emit('video-select', video)"
        >
          <div class="recommendation-thumbnail">
            <img 
              v-if="getVideoThumbnail(video)" 
              :src="getVideoThumbnail(video)" 
              :alt="getVideoTitle(video)"
              @error="$emit('image-error', $event)"
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
          @click="$emit('load-more')"
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
</template>

<script>
import { defineComponent } from 'vue'
export default defineComponent({
  name: 'Recommendations',
  props: {
    relatedVideosLoading: Boolean,
    availableSources: Array,
    searchStage: String,
    searchProgress: Object,
    displayedVideos: Array,
    allVideosData: Array,
    hasMoreData: Boolean,
    isLoadingMore: Boolean,
    getVideoTitle: Function,
    getVideoThumbnail: Function,
    getVideoYear: Function,
    getVideoType: Function,
    getVideoRating: Function,
    getVideoSource: Function,
    getVideoDirector: Function,
    getVideoArea: Function,
    getVideoActors: Function,
    isCurrentVideo: Function
  }
})
</script>

<style scoped>
</style> 