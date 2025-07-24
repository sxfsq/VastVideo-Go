<template>
  <div class="player-section">
    <div class="video-player-container">
      <div v-if="hasSearchResults" class="video-player-placeholder">
        <div class="play-icon">▶</div>
        <div class="player-text">点击播放</div>
      </div>
      <div v-else class="video-poster-container">
        <img 
          :src="finalPosterUrl"
          :alt="videoData?.title || videoData?.vod_name || '视频海报'"
          class="poster-image"
          loading="lazy"
          referrerpolicy="no-referrer"
          @error="onPosterError"
          @load="onPosterLoad"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { defineComponent } from 'vue'
export default defineComponent({
  name: 'VideoPlayer',
  props: {
    videoData: { type: Object, default: () => ({}) },
    hasSearchResults: { type: Boolean, default: false },
    finalPosterUrl: { type: String, default: '' },
    onPosterError: { type: Function, default: () => {} },
    onPosterLoad: { type: Function, default: () => {} }
  }
})
</script>

<style scoped>
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
  padding: 20px;
  min-height: 400px;
}

@media (max-width: 768px) {
  .video-poster-container {
    min-height: 300px;
    padding: 15px;
  }
}

.poster-image {
  max-width: calc(100% - 40px);
  max-height: calc(100% - 40px);
  width: auto;
  height: auto;
  object-fit: contain;
  transition: all 0.3s ease;
  border-radius: 8px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
  display: block;
  margin: auto;
  max-width: 350px;
}

@media (max-width: 768px) {
  .poster-image {
    max-width: calc(100% - 30px);
    max-height: calc(100% - 30px);
  }
}
</style> 