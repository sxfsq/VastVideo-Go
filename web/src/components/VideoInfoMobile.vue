<template>
  <div class="video-info-mobile">
    <div class="video-info-section">
      <div class="video-title">{{ videoData?.title || videoData?.vod_name || '加载中...' }}</div>
      <div class="video-meta">
        <div class="meta-stats">
          <span v-if="videoData?.rate || videoData?.vod_score" class="rating">{{ videoData.rate || videoData.vod_score }}分</span>
          <span v-if="videoData?.year || videoData?.vod_year" class="year">{{ videoData.year || videoData.vod_year }}年</span>
          <span class="views">1.2万观看</span>
        </div>
        <div class="video-tags">
          <span v-if="videoData?.type_name" class="tag">{{ videoData.type_name }}</span>
          <span class="tag source">{{ hasSearchResults ? getVideoSource(videoData) : '豆瓣推荐' }}</span>
        </div>
      </div>
      
      <div class="action-bar">
        <button class="action-item" :disabled="!hasSearchResults">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
            <path d="M8 5v14l11-7z"/>
          </svg>
          <span>播放</span>
        </button>
        <button class="action-item" :disabled="!hasSearchResults">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.29 1.51 4.04 3 5.5l7 7z"/>
          </svg>
          <span>收藏</span>
        </button>
        <button class="action-item" :disabled="!hasSearchResults">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/>
            <polyline points="16,6 12,2 8,6"/>
            <line x1="12" y1="2" x2="12" y2="15"/>
          </svg>
          <span>分享</span>
        </button>
        <button class="action-item" :disabled="!hasSearchResults">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
            <polyline points="7,10 12,15 17,10"/>
            <line x1="12" y1="15" x2="12" y2="3"/>
          </svg>
          <span>下载</span>
        </button>
      </div>
    </div>

    <div class="description-section">
      <div class="description-content" :class="{ expanded: showFullDescription }">
        <p>{{ videoData?.description || videoData?.vod_content || '这是一部优秀的影视作品，讲述了一个引人入胜的故事，具有深刻的内涵和精彩的表演，值得观看和品味。' }}</p>
      </div>
      <button class="show-more-btn" @click="toggleDescription">
        {{ showFullDescription ? '收起' : '展开' }}
        <svg class="expand-arrow" :class="{ expanded: showFullDescription }" viewBox="0 0 24 24" width="16" height="16">
          <path d="M6 9l6 6 6-6" stroke="currentColor" stroke-width="2" fill="none"/>
        </svg>
      </button>
    </div>
  </div>
</template>

<script>
import { defineComponent, ref } from 'vue'

export default defineComponent({
  name: 'VideoInfoMobile',
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
    const showFullDescription = ref(false)
    
    const toggleDescription = () => {
      showFullDescription.value = !showFullDescription.value
    }
    
    const getVideoSource = (video) => {
      if (video.search_source) {
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
    
    return {
      showFullDescription,
      toggleDescription,
      getVideoSource
    }
  }
})
</script>

<style scoped>
.video-info-mobile {
  width: 100%;
}

.video-info-section {
  padding: 12px 16px;
  border-bottom: 1px solid #272727;
}

.video-title {
  font-size: 18px;
  font-weight: 600;
  line-height: 1.3;
  margin-bottom: 8px;
  color: #ffffff;
}

.video-meta {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 16px;
}

.meta-stats {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  color: #aaaaaa;
}

.rating {
  color: #ff6b35;
  font-weight: 500;
}

.video-tags {
  display: flex;
  gap: 6px;
}

.tag {
  background: #272727;
  color: #cccccc;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 12px;
}

.tag.source {
  background: #065f46;
  color: #10b981;
}

.action-bar {
  display: flex;
  justify-content: space-around;
  padding: 8px 0;
}

.action-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  background: none;
  border: none;
  color: #ffffff;
  cursor: pointer;
  padding: 8px;
  border-radius: 8px;
  transition: background 0.2s;
  min-width: 60px;
}

.action-item:hover:not(:disabled) {
  background: #272727;
}

.action-item:disabled {
  color: #666666;
  cursor: not-allowed;
  opacity: 0.5;
}

.action-item span {
  font-size: 12px;
  font-weight: 500;
}

.description-section {
  padding: 12px 16px;
  border-bottom: 1px solid #272727;
}

.description-content {
  max-height: 40px;
  overflow: hidden;
  transition: max-height 0.3s ease;
}

.description-content.expanded {
  max-height: 200px;
}

.description-content p {
  font-size: 14px;
  line-height: 1.5;
  color: #cccccc;
  margin: 0;
}

.show-more-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  background: none;
  border: none;
  color: #3ea6ff;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  margin-top: 8px;
  padding: 4px 0;
}

.expand-arrow {
  transition: transform 0.2s;
}

.expand-arrow.expanded {
  transform: rotate(180deg);
}
</style>
