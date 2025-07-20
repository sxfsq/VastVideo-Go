<template>
  <div class="episodes-mobile">
    <div v-if="episodesList.length > 0" class="episodes-section">
      <div class="section-header">
        <h3 class="section-title">选集播放</h3>
        <span class="episodes-count">共{{ episodesList.length }}集</span>
      </div>
      <div class="episodes-scroll">
        <div class="episodes-horizontal">
          <div 
            v-for="(episode, index) in episodesList" 
            :key="index" 
            class="episode-chip" 
            :class="{ active: index === 0 }" 
            @click="selectEpisode(episode)"
          >
            {{ episode.name }}
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="videoData.vod_play_url" class="episodes-section">
      <div class="section-header">
        <h3 class="section-title">播放信息</h3>
        <span class="episodes-count">{{ videoData.vod_remarks || 'HD' }}</span>
      </div>
      <div class="single-episode-info">
        <div class="episode-quality">{{ videoData.vod_remarks || 'HD' }}</div>
        <div class="episode-size">{{ getVideoSize() }}</div>
      </div>
    </div>
  </div>
</template>

<script>
import { defineComponent, computed } from 'vue'

export default defineComponent({
  name: 'EpisodesMobile',
  props: {
    videoData: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  emits: ['episode-select'],
  setup(props, { emit }) {
    const episodesList = computed(() => {
      if (!props.videoData?.vod_play_url) return []
      
      try {
        const playData = props.videoData.vod_play_url
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

    const getVideoSize = () => {
      return props.videoData?.vod_remarks?.includes('HD') ? '高清' : '标清'
    }

    const selectEpisode = (episode) => {
      console.log('选择剧集:', episode)
      emit('episode-select', episode)
    }
    
    return {
      episodesList,
      getVideoSize,
      selectEpisode
    }
  }
})
</script>

<style scoped>
.episodes-mobile {
  width: 100%;
}

.episodes-section {
  padding: 16px 0;
  border-bottom: 1px solid #272727;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 16px;
  margin-bottom: 12px;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #ffffff;
  margin: 0;
}

.episodes-count {
  font-size: 14px;
  color: #aaaaaa;
}

.episodes-scroll {
  overflow-x: auto;
  scrollbar-width: none;
  -ms-overflow-style: none;
}

.episodes-scroll::-webkit-scrollbar {
  display: none;
}

.episodes-horizontal {
  display: flex;
  gap: 8px;
  padding: 0 16px;
  min-width: max-content;
}

.episode-chip {
  background: #272727;
  color: #ffffff;
  padding: 8px 16px;
  border-radius: 20px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s;
  white-space: nowrap;
  min-width: 44px;
  text-align: center;
}

.episode-chip:hover {
  background: #373737;
}

.episode-chip.active {
  background: #3ea6ff;
  color: #000000;
}

.single-episode-info {
  display: flex;
  gap: 16px;
  padding: 0 16px;
}

.episode-quality {
  background: #3ea6ff;
  color: #000000;
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: 600;
}

.episode-size {
  background: #272727;
  color: #cccccc;
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 14px;
}
</style>
