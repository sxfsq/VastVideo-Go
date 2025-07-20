<template>
  <div class="video-card" @click="handleClick">
    <div class="video-cover-container">
      <img 
        :src="finalCoverUrl" 
        :alt="title"
        class="video-cover"
        loading="lazy" 
        referrerpolicy="no-referrer"
        @error="handleImageError"
        @load="handleImageLoad"
      >
      <!-- 视频源标签 -->
      <div class="video-source">{{ source }}</div>
    </div>
    <div class="video-info">
      <div class="video-title" :title="title">{{ title }}</div>
      <div class="video-meta">
        <span class="meta-badge type">{{ type }}</span>
        <span v-if="tag" class="meta-badge tag">{{ tag }}</span>
        <span v-if="rate" class="meta-badge rate">★ {{ rate }}</span>
        <span v-if="year" class="meta-badge year">{{ year }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import { defineComponent, computed, ref } from 'vue'

export default defineComponent({
  name: 'VideoCard',
  props: {
    video: {
      type: Object,
      required: true
    },
    source: {
      type: String,
      default: '豆瓣推荐'
    }
  },
  emits: ['click'],
  setup(props, { emit }) {
    const imageError = ref(false)
    
    // 计算属性
    const title = computed(() => {
      return props.video.title || props.video.vod_name || props.video.name || '未知标题'
    })
    
    const originalCover = computed(() => {
      return props.video.cover || props.video.pic || props.video.vod_pic || ''
    })
    
    const year = computed(() => {
      return props.video.year || props.video.pubdate || props.video.vod_year || ''
    })
    
    const rate = computed(() => {
      return props.video.rate || props.video.rating || props.video.vod_score || ''
    })
    
    const type = computed(() => {
      // 可以从props.video.type_name或者父组件传递的类型判断
      return props.video.type_name || props.video.vod_type_name || 
             (props.video.type === 'movie' ? '电影' : '电视剧') || '影视'
    })
    
    const tag = computed(() => {
      return props.video.tag || props.video.vod_class || ''
    })
    
    const finalCoverUrl = computed(() => {
      if (imageError.value) {
        return getDefaultSvgUrl()
      }
      
      const url = originalCover.value
      if (!url || typeof url !== 'string' || url.trim() === '' || url.includes('placeholder.com')) {
        return getDefaultSvgUrl()
      }
      
      return url.trim()
    })
    
    // 方法
    const getDefaultSvgUrl = () => {
      return 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTQwIiBoZWlnaHQ9IjIxMCIgdmlld0JveD0iMCAwIDE0MCAyMTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIxNDAiIGhlaWdodD0iMjEwIiBmaWxsPSIjMjMyNDRhIi8+CjxyZWN0IHg9IjEwIiB5PSIxMCIgd2lkdGg9IjEyMCIgaGVpZ2h0PSIxNjAiIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzNjM2M1YSIgc3Ryb2tlLXdpZHRoPSIxIi8+CjxwYXRoIGQ9Ik0zMCA2MGg4MHY0MEgzMHoiIGZpbGw9IiMzYzNjNWEiIGZpbGwtb3BhY2l0eT0iMC4zIi8+Cjx0ZXh0IHg9IjcwIiB5PSIxODAiIGZvbnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSIxMiIgZmlsbD0iI2I5YmJkNCIgdGV4dC1hbmNob3I9Im1pZGRsZSI+6K+36L6T5YWl5Y2a5L2N5L2N5Y2aPC90ZXh0Pgo8L3N2Zz4K'
    }
    
    const handleImageError = () => {
      console.log('图片加载失败:', originalCover.value)
      imageError.value = true
    }
    
    const handleImageLoad = () => {
      console.log('图片加载成功:', originalCover.value)
      imageError.value = false
    }
    
    const handleClick = () => {
      emit('click', props.video)
    }
    
    return {
      title,
      finalCoverUrl,
      year,
      rate,
      type,
      tag,
      source: props.source,
      handleImageError,
      handleImageLoad,
      handleClick
    }
  }
})
</script>

<style scoped>
.video-card {
  background: #23244a;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
  transition: transform 0.3s, box-shadow 0.3s;
  cursor: pointer;
  position: relative;
  width: 100%;
  box-sizing: border-box;
}

.video-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(108,99,255,0.18);
}

.video-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(135deg, rgba(108,99,255,0.1) 0%, rgba(108,99,255,0.05) 100%);
  opacity: 0;
  transition: opacity 0.3s ease;
  pointer-events: none;
  z-index: 1;
}

.video-card:hover::before {
  opacity: 1;
}

.video-cover-container {
  position: relative;
  width: 100%;
}

.video-cover {
  width: 100%;
  aspect-ratio: 2/3;
  object-fit: cover;
  background: #18192b;
  display: block;
  transition: opacity 0.3s ease;
}

.video-source {
  position: absolute;
  top: 8px;
  right: 8px;
  background: rgba(0, 0, 0, 0.4);
  color: #fff;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 500;
  backdrop-filter: blur(2px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  opacity: 0.8;
  transition: all 0.3s ease;
}

.video-card:hover .video-source {
  background: rgba(0, 0, 0, 0.7);
  opacity: 1;
  backdrop-filter: blur(4px);
}

.video-cover.loading {
  opacity: 0.7;
}

.video-cover.loaded {
  opacity: 1;
}

.video-info {
  padding: 12px;
  display: flex;
  flex-direction: column;
  height: auto;
  min-height: 64px; /* 确保最小高度 */
}

.video-title {
  font-size: 14px;
  font-weight: 500;
  color: #fff;
  margin-bottom: 8px;
  line-height: 1.3;
  height: 36px; /* 固定高度，约2.8行 */
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  word-break: break-word;
  text-overflow: ellipsis;
}

.video-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.meta-badge {
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 500;
}

.meta-badge.type {
  background: #ff6b6b;
  color: #fff;
}

.meta-badge.rate {
  background: #ffd93d;
  color: #333;
}

.meta-badge.year {
  background: #6bcf7f;
  color: #fff;
}

.meta-badge.tag {
  background: #23244a;
  color: #b3b6d4;
}

/* 响应式调整 */
@media (max-width: 480px) {
  .video-info {
    padding: 8px;
    min-height: 56px;
  }

  .video-title {
    font-size: 13px;
    height: 32px;
  }

  .video-source {
    top: 6px;
    right: 6px;
    font-size: 9px;
    padding: 3px 6px;
  }

  .meta-badge {
    font-size: 9px;
    padding: 1px 4px;
  }
}

/* PC端调整 */
@media (min-width: 769px) {
  .video-card {
    max-width: none;
    width: 100%;
  }
  
  .video-info {
    min-height: 72px;
  }
  
  .video-title {
    font-size: 16px;
    height: 40px;
  }
  
  .video-source {
    top: 10px;
    right: 10px;
    font-size: 11px;
    padding: 5px 10px;
  }
  
  .meta-badge {
    font-size: 12px;
    padding: 3px 8px;
  }
}

/* 平板优化 */
@media (min-width: 768px) and (max-width: 1024px) {
  .video-info {
    min-height: 68px;
  }
  
  .video-title {
    font-size: 15px;
    height: 38px;
  }
}

/* 超大屏幕优化 */
@media (min-width: 1200px) {
  .video-title {
    font-size: 17px;
    margin-bottom: 10px;
    height: 44px;
  }
  
  .video-info {
    padding: 14px;
    min-height: 80px;
  }
  
  .video-source {
    top: 12px;
    right: 12px;
    font-size: 12px;
    padding: 6px 12px;
  }
  
  .meta-badge {
    font-size: 13px;
    padding: 4px 10px;
  }
}
</style> 