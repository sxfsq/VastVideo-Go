<template>
  <div class="source-recommendations-page">
    <div class="page-header">
      <h2 class="page-title">全部源最新推荐</h2>
    </div>
    <div v-if="loading" class="loading-container">
      <div class="loading-spinner"></div>
      <div class="loading-text">正在加载最新推荐...</div>
    </div>
    <div v-else>
      <div v-if="videos.length > 0" class="video-list">
        <VideoCard
          v-for="(video, idx) in videos"
          :key="video.id || video.vod_id || video.url || idx"
          :video="video"
          :source="video.source_name || video.source || '推荐源'"
          @click="$emit('video-click', video)"
        />
      </div>
      <div v-else class="no-results">
        <div class="no-results-icon">📭</div>
        <div class="no-results-text">暂无最新推荐</div>
      </div>
    </div>
  </div>
</template>

<script>
import { defineComponent } from 'vue'
import VideoCard from './VideoCard.vue'
export default defineComponent({
  name: 'SourceRecommendations',
  components: { VideoCard },
  props: {
    videos: { type: Array, default: () => [] },
    loading: { type: Boolean, default: false }
  },
  emits: ['video-click']
})
</script>

<style scoped>
.source-recommendations-page {
  width: 100%;
  padding: 0 0 24px 0;
}
.page-header {
  padding: 18px 18px 8px 18px;
  background: #23244a;
  border-bottom: 1px solid #23244a;
}
.page-title {
  font-size: 20px;
  font-weight: 700;
  color: #fff;
  margin: 0;
}
.video-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 16px;
  padding: 18px;
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
@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
.loading-text {
  font-size: 14px;
  text-align: center;
  margin-bottom: 4px;
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
.no-results-text {
  font-size: 15px;
}
</style> 