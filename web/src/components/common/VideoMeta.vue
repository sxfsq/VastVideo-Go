<template>
  <div class="video-meta">
    <div class="video-title">{{ videoData?.title || videoData?.vod_name || '加载中...' }}</div>
    <div class="video-meta-bar">
      <div class="meta-tags">
        <span v-if="videoData?.type_name" class="meta-tag type">{{ videoData.type_name }}</span>
        <span v-if="videoData?.year || videoData?.vod_year" class="meta-tag year">{{ videoData.year || videoData.vod_year }}年</span>
        <span v-if="videoData?.rate || videoData?.vod_score" class="meta-tag rating">{{ videoData.rate || videoData.vod_score }}分</span>
        <span class="meta-tag source">{{ getVideoSource(videoData) }}</span>
        <span class="meta-tag views">1.2万观看</span>
      </div>
      <button class="fullscreen-description-btn" @click="showFullscreenDescription">
        <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
          <path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/>
        </svg>
        剧情介绍
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'VideoMeta',
  props: {
    videoData: { type: Object, default: () => ({}) },
    hasSearchResults: { type: Boolean, default: false }
  },
  emits: ['show-description'],
  setup(props, { emit }) {
    const getVideoSource = (video) => {
      if (video.search_source) {
        const sourceMap = {
          'dbzy': '豆瓣资源', 'bfzy': '暴风资源', 'hnzy': '红牛资源', 'ffzy': '非凡资源',
          'lzzy': '量子资源', 'dyttzy': '电影天堂', 'subzyapi': '速播资源', 'wolongzyw': '卧龙资源'
        }
        return sourceMap[video.search_source] || video.search_source
      }
      return video.source_name || video.source || '视频源'
    }
    
    const showFullscreenDescription = () => {
      emit('show-description')
    }
    
    return { getVideoSource, showFullscreenDescription }
  }
}
</script>

<style scoped>
.video-meta {
  width: 100%;
  padding: 20px;
  background: #23244a;
  border-radius: 12px;
  margin-bottom: 16px;
}

.video-title {
  font-size: 20px;
  font-weight: 600;
  color: #fff;
  margin-bottom: 16px;
  line-height: 1.3;
}

.video-meta-bar {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.meta-tags {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  flex: 1;
}

.fullscreen-description-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  color: white;
  border: none;
  padding: 5px 10px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 500;
  transition: all 0.2s ease;
  box-shadow: 0 2px 4px rgba(99, 102, 241, 0.2);
  white-space: nowrap;
  flex-shrink: 0;
}

.fullscreen-description-btn:hover {
  background: linear-gradient(135deg, #5b5fef, #7c3aed);
  transform: translateY(-1px);
  box-shadow: 0 3px 6px rgba(99, 102, 241, 0.3);
}

.fullscreen-description-btn:active {
  transform: translateY(0);
  box-shadow: 0 2px 4px rgba(99, 102, 241, 0.2);
}

.meta-tag {
  background: #3a3b5a;
  color: #e0e0e0;
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 13px;
  white-space: nowrap;
  font-weight: 500;
}

.meta-tag.rating {
  background: #f59e0b;
  color: #1a1b2e;
  font-weight: 600;
}

.meta-tag.year {
  background: #6366f1;
  color: #ffffff;
}

.meta-tag.views {
  background: #6b7280;
  color: #e5e7eb;
}

.meta-tag.type {
  background: #8b5cf6;
  color: #ffffff;
}

.meta-tag.source {
  background: #10b981;
  color: #1a1b2e;
  font-weight: 600;
}

/* 移动端适配 */
@media (max-width: 768px) {
  .video-meta {
    padding: 12px 16px;
    margin-bottom: 12px;
    border-radius: 8px;
  }
  
  .video-title {
    font-size: 18px;
    margin-bottom: 12px;
  }
  
  .video-meta-bar {
    gap: 8px;
  }
  
  .meta-tags {
    gap: 6px;
  }
  
  .meta-tag {
    padding: 4px 8px;
    font-size: 12px;
    border-radius: 4px;
  }
  
  .fullscreen-description-btn {
    padding: 4px 8px;
    font-size: 12px;
    gap: 3px;
  }
  
  .fullscreen-description-btn svg {
    width: 14px;
    height: 14px;
  }
}

/* 小屏幕适配 */
@media (max-width: 480px) {
  .video-meta {
    padding: 10px 12px;
  }
  
  .video-title {
    font-size: 16px;
    margin-bottom: 10px;
  }
  
  .meta-tag {
    padding: 3px 6px;
    font-size: 11px;
  }
  
  .fullscreen-description-btn {
    padding: 3px 6px;
    font-size: 11px;
    gap: 2px;
  }
  
  .fullscreen-description-btn svg {
    width: 12px;
    height: 12px;
  }
}
</style> 