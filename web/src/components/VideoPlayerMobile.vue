<template>
  <div class="video-player-mobile">
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
  </div>
</template>

<script>
import { defineComponent, ref, computed } from 'vue'

export default defineComponent({
  name: 'VideoPlayerMobile',
  props: {
    videoData: {
      type: Object,
      required: false,
      default: () => ({})
    },
    hasSearchResults: {
      type: Boolean,
      default: false
    }
  },
  setup(props) {
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
      
      const url = getPosterUrl(props.videoData)
      if (!url) {
        return getDefaultPosterSvg()
      }
      
      return url
    })
    
    const onPosterError = (event) => {
      posterImageError.value = true
    }

    const onPosterLoad = (event) => {
      posterImageError.value = false
    }
    
    return {
      finalPosterUrl,
      onPosterError,
      onPosterLoad
    }
  }
})
</script>

<style scoped>
.video-player-mobile {
  width: 100%;
}

.player-section {
  position: relative;
  width: 100%;
  aspect-ratio: 16/9;
  background: #000;
}

.video-player-container {
  width: 100%;
  height: 100%;
  position: relative;
  cursor: pointer;
}

.video-player-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #1a1a2e, #16213e);
}

.play-icon {
  font-size: 60px;
  color: white;
  opacity: 0.9;
  text-shadow: 0 2px 10px rgba(0,0,0,0.5);
  margin-bottom: 8px;
}

.player-text {
  font-size: 16px;
  color: white;
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
  padding: 20px;
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
  max-width: 300px;
}

@media (max-width: 480px) {
  .poster-image {
    max-width: calc(100% - 20px);
    max-height: calc(100% - 20px);
  }
  
  .video-poster-container {
    padding: 10px;
  }
}
</style>
