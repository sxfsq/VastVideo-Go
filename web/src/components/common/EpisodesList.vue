<template>
  <div class="episodes-section" v-if="streamEpisodes.length > 0 || pageEpisodes.length > 0">
    <div class="episodes-header">
      <h3 class="section-title">选集播放</h3>
      <div class="episodes-count">
        <span v-if="streamEpisodes.length > 0">视频流: {{ streamEpisodes.length }}集</span>
        <span v-if="streamEpisodes.length > 0 && pageEpisodes.length > 0"> | </span>
        <span v-if="pageEpisodes.length > 0">视频页: {{ pageEpisodes.length }}集</span>
      </div>
    </div>
    
    <!-- 视频流选集 -->
    <div v-if="streamEpisodes.length > 0" class="episode-category">
      <div class="category-title">
        <span class="category-icon">🎬</span>
        视频流
      </div>
      
      <!-- PC端网格布局 -->
      <div class="episodes-grid desktop-layout">
        <div 
          v-for="(episode, index) in streamEpisodes" 
          :key="`stream-${index}`" 
          class="episode-item stream-episode" 
          :class="{ active: index === 0 }"
          @click="selectEpisode(episode)"
        >
          {{ episode.name }}
        </div>
      </div>

      <!-- 移动端水平滚动布局 -->
      <div class="episodes-scroll mobile-layout">
        <div class="episodes-horizontal">
          <div 
            v-for="(episode, index) in streamEpisodes" 
            :key="`stream-${index}`" 
            class="episode-chip stream-chip" 
            :class="{ active: index === 0 }"
            @click="selectEpisode(episode)"
          >
            {{ episode.name }}
          </div>
        </div>
      </div>
    </div>

    <!-- 视频页选集 -->
    <div v-if="pageEpisodes.length > 0" class="episode-category">
      <div class="category-title">
        <span class="category-icon">🌐</span>
        视频页
      </div>
      
      <!-- PC端网格布局 -->
      <div class="episodes-grid desktop-layout">
        <div 
          v-for="(episode, index) in pageEpisodes" 
          :key="`page-${index}`" 
          class="episode-item page-episode" 
          :class="{ active: index === 0 }"
          @click="selectEpisode(episode)"
        >
          {{ episode.name }}
        </div>
      </div>

      <!-- 移动端水平滚动布局 -->
      <div class="episodes-scroll mobile-layout">
        <div class="episodes-horizontal">
          <div 
            v-for="(episode, index) in pageEpisodes" 
            :key="`page-${index}`" 
            class="episode-chip page-chip" 
            :class="{ active: index === 0 }"
            @click="selectEpisode(episode)"
          >
            {{ episode.name }}
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- 单集信息显示（移动端） -->
  <div v-else-if="videoData.vod_play_url" class="episodes-section single-episode-section">
    <div class="episodes-header">
      <h3 class="section-title">播放信息</h3>
      <span class="episodes-count">{{ videoData.vod_remarks || 'HD' }}</span>
    </div>
    <div class="single-episode-info">
      <div class="episode-quality">{{ videoData.vod_remarks || 'HD' }}</div>
      <div class="episode-size">{{ getVideoSize() }}</div>
    </div>
  </div>
</template>

<script>
import { defineComponent, computed } from 'vue'

export default defineComponent({
  name: 'EpisodesList',
  props: {
    videoData: { 
      type: Object, 
      default: () => ({}) 
    }
  },
  emits: ['episode-select'],
  setup(props, { emit }) {
    // 判断是否为视频流地址
    const isStreamUrl = (url) => {
      if (!url) return false
      
      // 视频流地址的特征
      const streamPatterns = [
        /\.(mp4|m3u8|flv|avi|mkv|mov|wmv|webm)$/i,  // 视频文件扩展名
        /\.m3u8(\?|$)/i,  // m3u8流媒体
        /\.mp4(\?|$)/i,   // mp4文件
        /\/play\//i,      // 包含play路径
        /\/stream\//i,    // 包含stream路径
        /\/video\//i,     // 包含video路径
        /^https?:\/\/[^\/]+\/api\//i,  // API接口
        /^https?:\/\/[^\/]+\/videos?\//i,  // 视频API
      ]
      
      return streamPatterns.some(pattern => pattern.test(url))
    }

    // 判断是否为视频页面地址
    const isPageUrl = (url) => {
      if (!url) return false
      
      // 视频页面地址的特征
      const pagePatterns = [
        /\.html?(\?|$)/i,  // HTML页面
        /\.php(\?|$)/i,    // PHP页面
        /\.asp(\?|$)/i,    // ASP页面
        /\.jsp(\?|$)/i,    // JSP页面
        /\/detail\//i,     // 详情页面
        /\/play\?/i,       // 播放页面参数
        /\/vod\//i,        // 视频页面
        /\/movie\//i,      // 电影页面
        /\/tv\//i,         // 电视剧页面
      ]
      
      return pagePatterns.some(pattern => pattern.test(url))
    }

    // 分类后的剧集列表
    const streamEpisodes = computed(() => {
      if (!props.videoData?.vod_play_url) return []
      
      try {
        const playData = props.videoData.vod_play_url
        const episodes = playData.split('$$$').map((episode, index) => {
          const parts = episode.split('$')
          if (parts.length >= 2) {
            return {
              name: parts[0] || `第${index + 1}集`,
              url: parts[1],
              type: 'stream'
            }
          }
          return null
        }).filter(ep => ep && isStreamUrl(ep.url))
        
        return episodes
      } catch (error) {
        console.warn('解析视频流剧集信息失败:', error)
        return []
      }
    })

    const pageEpisodes = computed(() => {
      if (!props.videoData?.vod_play_url) return []
      
      try {
        const playData = props.videoData.vod_play_url
        const episodes = playData.split('$$$').map((episode, index) => {
          const parts = episode.split('$')
          if (parts.length >= 2) {
            return {
              name: parts[0] || `第${index + 1}集`,
              url: parts[1],
              type: 'page'
            }
          }
          return null
        }).filter(ep => ep && isPageUrl(ep.url))
        
        return episodes
      } catch (error) {
        console.warn('解析视频页剧集信息失败:', error)
        return []
      }
    })

    // 兼容旧版本的完整剧集列表
    const episodesList = computed(() => {
      return [...streamEpisodes.value, ...pageEpisodes.value]
    })

    const getVideoSize = () => {
      return props.videoData?.vod_remarks?.includes('HD') ? '高清' : '标清'
    }

    const selectEpisode = (episode) => {
      console.log('选择剧集:', episode)
      emit('episode-select', episode)
    }
    
    return {
      streamEpisodes,
      pageEpisodes,
      episodesList,
      getVideoSize,
      selectEpisode
    }
  }
})
</script>

<style scoped>
.episodes-section { 
  background: #23244a; 
  padding: 20px; 
  border-radius: 12px; 
  margin-bottom: 16px; 
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
  color: #fff; 
  margin: 0; 
}

.episodes-count { 
  font-size: 14px; 
  color: #a5a5a5; 
  display: flex;
  gap: 8px;
  align-items: center;
}

.episode-category {
  margin-bottom: 20px;
}

.episode-category:last-child {
  margin-bottom: 0;
}

.category-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
  font-weight: 600;
  color: #ffffff;
  margin-bottom: 12px;
  padding: 8px 12px;
  background: #2a2b4a;
  border-radius: 8px;
}

.category-icon {
  font-size: 18px;
}

/* PC端网格布局 */
.desktop-layout {
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

/* 视频流剧集样式 */
.stream-episode {
  border-left: 3px solid #10b981;
}

.stream-episode:hover {
  border-left-color: #059669;
}

.stream-episode.active {
  border-left-color: #ffffff;
}

/* 视频页剧集样式 */
.page-episode {
  border-left: 3px solid #f59e0b;
}

.page-episode:hover {
  border-left-color: #d97706;
}

.page-episode.active {
  border-left-color: #ffffff;
}

/* 移动端水平滚动布局 */
.mobile-layout {
  display: none;
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
  min-width: max-content;
}

.episode-chip {
  background: #3a3b5a;
  color: #e0e0e0;
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
  background: #4a4b6a;
}

.episode-chip.active {
  background: #6366f1;
  color: white;
}

/* 移动端视频流剧集样式 */
.stream-chip {
  border: 2px solid #10b981;
}

.stream-chip:hover {
  border-color: #059669;
}

.stream-chip.active {
  border-color: #ffffff;
}

/* 移动端视频页剧集样式 */
.page-chip {
  border: 2px solid #f59e0b;
}

.page-chip:hover {
  border-color: #d97706;
}

.page-chip.active {
  border-color: #ffffff;
}

/* 单集信息样式 */
.single-episode-section {
  background: #23244a;
  padding: 16px;
  border-radius: 12px;
  margin-bottom: 16px;
}

.single-episode-info {
  display: flex;
  gap: 16px;
}

.episode-quality {
  background: #6366f1;
  color: white;
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: 600;
}

.episode-size {
  background: #3a3b5a;
  color: #e0e0e0;
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 14px;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .episodes-section {
    padding: 16px;
    margin-bottom: 12px;
  }
  
  .episodes-header {
    margin-bottom: 12px;
  }
  
  .section-title {
    font-size: 16px;
  }
  
  /* 隐藏PC端布局，显示移动端布局 */
  .desktop-layout {
    display: none;
  }
  
  .mobile-layout {
    display: block;
  }
  
  .episodes-horizontal {
    padding: 0;
  }
}

@media (max-width: 480px) {
  .episodes-section {
    padding: 12px;
  }
  
  .episodes-horizontal {
    gap: 6px;
  }
  
  .episode-chip {
    padding: 6px 12px;
    font-size: 13px;
    min-width: 40px;
  }
  
  .single-episode-info {
    gap: 12px;
  }
  
  .episode-quality,
  .episode-size {
    padding: 6px 12px;
    font-size: 13px;
  }
}
</style> 