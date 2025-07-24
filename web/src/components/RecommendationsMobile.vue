<template>
  <div v-if="visible" class="mobile-recommendations-sidebar">
    <div class="sidebar-header">
      <span class="sidebar-title">相关推荐</span>
      <button class="sidebar-searchall-btn" :disabled="relatedVideosLoading" @click="$emit('search-all-sources')">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="10" stroke="#fff" stroke-width="2"/><path d="M16 16l-3-3" stroke="#fff" stroke-width="2"/><circle cx="11" cy="11" r="4" stroke="#fff" stroke-width="2"/></svg>
        <span>全部源搜索</span>
      </button>
      <button class="sidebar-close-btn" @click="$emit('close')">
        <svg width="24" height="24" viewBox="0 0 24 24"><path d="M6 6l12 12M6 18L18 6" stroke="#fff" stroke-width="2"/></svg>
      </button>
    </div>
    <!-- 搜索进度提示 -->
    <div v-if="relatedVideosLoading" class="search-progress-tip">
      <div class="search-progress-animated">
        <span class="dot dot1"></span>
        <span class="dot dot2"></span>
        <span class="dot dot3"></span>
      </div>
      <span class="search-progress-main">
        正在为你智能聚合搜索相关视频…
        <span class="search-progress-count">({{ searchProgress.completed }}/{{ searchProgress.total }})</span>
      </span>
      <div class="search-progress-desc">
        多源并发，极速为你查找精彩内容
      </div>
    </div>
    <div class="sidebar-content">
      <div v-if="relatedVideosLoading" class="loading-container">
        <div class="modern-loading-spinner">
          <span class="modern-dot"></span>
          <span class="modern-dot"></span>
          <span class="modern-dot"></span>
        </div>
        <div class="loading-text">请稍候，正在为你查找最优视频资源…</div>
      </div>
      <template v-else-if="displayedVideos.length > 0">
        <div class="recommendation-mobile-list">
          <VideoCard
            v-for="(video, index) in displayedVideos"
            :key="`video-${index}-${video.vod_name || video.title || index}-${video.source_page || 1}`"
            :video="video"
            :source="getVideoSource(video)"
            @click="$emit('video-select', video)"
            :class="{ active: isCurrentVideo(video) }"
          />
        </div>
        <div v-if="hasMoreData" class="mobile-load-more">
          <button class="mobile-load-more-btn" @click="$emit('load-more')">
            加载更多
          </button>
        </div>
      </template>
      <div v-else class="no-results">
        <div class="no-results-icon">🔍</div>
        <div class="no-results-text">暂无相关推荐</div>
      </div>
    </div>
  </div>
  <div v-if="visible" class="sidebar-mask" @click="$emit('close')"></div>
</template>

<script>
import { defineComponent } from 'vue'
import VideoCard from './VideoCard.vue'
export default defineComponent({
  name: 'RecommendationsMobile',
  components: { VideoCard },
  props: {
    visible: Boolean,
    relatedVideosLoading: Boolean,
    displayedVideos: Array,
    hasMoreData: Boolean,
    getVideoTitle: Function,
    getVideoThumbnail: Function,
    getVideoYear: Function,
    getVideoType: Function,
    getVideoRating: Function,
    getVideoSource: Function,
    isCurrentVideo: Function,
    searchStage: String,
    searchProgress: Object
    // 移除 isFirstOpen
  }
})
</script>

<style scoped>
.mobile-recommendations-sidebar {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  z-index: 10002;
  background: #18192b;
  box-shadow: 0 4px 24px rgba(0,0,0,0.18);
  border-radius: 0;
  overflow: hidden;
  transition: opacity 0.2s;
  opacity: 1;
  display: flex;
  flex-direction: column;
}
.sidebar-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 18px 8px 18px;
  background: #23244a;
  border-radius: 0;
  border-bottom: 1px solid #23244a;
}
.sidebar-title {
  font-size: 16px;
  font-weight: 600;
  color: #fff;
}
.sidebar-searchall-btn {
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  color: #fff;
  border: none;
  border-radius: 16px;
  padding: 4px 12px;
  margin-right: 8px;
  font-size: 13px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 4px;
  cursor: pointer;
  transition: background 0.2s;
}
.sidebar-searchall-btn:disabled {
  background: #4b5563;
  cursor: not-allowed;
  opacity: 0.6;
}
.sidebar-searchall-btn svg {
  flex-shrink: 0;
}
.sidebar-close-btn {
  background: none;
  border: none;
  color: #fff;
  cursor: pointer;
  padding: 4px;
  border-radius: 50%;
  transition: background 0.2s;
}
.sidebar-close-btn:hover {
  background: #23244a;
}
.sidebar-content {
  flex: 1;
  padding: 10px 8px 0 8px;
  overflow-y: auto;
}
.recommendation-mobile-list {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
.recommendation-mobile-item {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 4px;
  background: #23244a;
  border-radius: 8px;
  padding: 6px 4px;
  cursor: pointer;
  transition: background 0.2s;
  min-height: 120px;
}
.recommendation-mobile-item.active {
  background: #6366f1;
  color: #fff;
}
.recommendation-mobile-thumb {
  width: 100%;
  height: 80px;
  object-fit: cover;
  border-radius: 6px;
  background: #18192b;
  flex-shrink: 0;
}
.recommendation-mobile-info {
  width: 100%;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 2px 2px 0 2px;
}
.recommendation-mobile-title {
  font-size: 13px;
  font-weight: 600;
  color: #fff;
  line-height: 1.2;
  margin-bottom: 1px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.recommendation-mobile-meta {
  font-size: 10px;
  color: #a5a5a5;
  margin-bottom: 0;
}
.recommendation-mobile-source {
  font-size: 10px;
  color: #10b981;
}
.mobile-load-more {
  text-align: center;
  margin: 16px 0 0 0;
}
.mobile-load-more-btn {
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  color: #fff;
  border: none;
  padding: 8px 24px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(99, 102, 241, 0.12);
  transition: background 0.2s;
}
.mobile-load-more-btn:hover {
  background: #7c3aed;
}
.no-results {
  text-align: center;
  color: #aaa;
  margin-top: 40px;
}
.no-results-icon {
  font-size: 40px;
  margin-bottom: 8px;
}
.sidebar-mask {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0,0,0,0.18);
  z-index: 10001;
}
.search-progress-tip {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin: 12px 0 8px 0;
  font-size: 15px;
  color: #a5a5a5;
  font-weight: 500;
  letter-spacing: 0.02em;
}
.search-progress-animated {
  display: flex;
  gap: 3px;
  margin-bottom: 2px;
}
.dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #6366f1;
  opacity: 0.7;
  animation: dot-bounce 1.2s infinite;
}
.dot1 { animation-delay: 0s; }
.dot2 { animation-delay: 0.2s; }
.dot3 { animation-delay: 0.4s; }
@keyframes dot-bounce {
  0%, 80%, 100% { transform: scale(0.8); opacity: 0.7; }
  40% { transform: scale(1.3); opacity: 1; }
}
.search-progress-main {
  font-size: 15px;
  color: #fff;
  font-weight: 600;
}
.search-progress-desc {
  font-size: 12px;
  color: #8b8baf;
  margin-top: 2px;
}
.modern-loading-spinner {
  display: flex;
  gap: 6px;
  justify-content: center;
  align-items: center;
  margin-bottom: 10px;
}
.modern-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  opacity: 0.7;
  animation: modern-dot-bounce 1.2s infinite;
}
.modern-dot:nth-child(1) { animation-delay: 0s; }
.modern-dot:nth-child(2) { animation-delay: 0.2s; }
.modern-dot:nth-child(3) { animation-delay: 0.4s; }
@keyframes modern-dot-bounce {
  0%, 80%, 100% { transform: scale(0.8); opacity: 0.7; }
  40% { transform: scale(1.3); opacity: 1; }
}
@media (max-width: 480px) {
  .mobile-recommendations-sidebar {
    width: 100vw;
    max-width: 100vw;
    min-width: 0;
    border-radius: 0;
    padding-bottom: 0;
  }
  .sidebar-header {
    padding: 14px 10px 8px 10px;
  }
}
</style>
