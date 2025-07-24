<template>
  <div v-if="isFullscreen" class="fullscreen-overlay" @click="closeFullscreen">
    <div class="fullscreen-content" @click.stop>
      <div class="fullscreen-header">
        <h2 class="fullscreen-title">剧情介绍</h2>
        <button class="close-btn" @click="closeFullscreen">
          <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor">
            <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
          </svg>
        </button>
      </div>
      <div class="fullscreen-description">
        <div v-html="sanitizedDescription"></div>
      </div>
    </div>
  </div>
</template>

<script>
import { computed } from 'vue'

export default {
  name: 'VideoDescription',
  props: {
    videoData: { type: Object, default: () => ({}) },
    isFullscreen: { type: Boolean, default: false }
  },
  emits: ['close'],
  setup(props, { emit }) {
    const closeFullscreen = () => {
      emit('close')
    }
    
    // 清理和解析HTML内容
    const sanitizedDescription = computed(() => {
      const description = props.videoData?.description || props.videoData?.vod_content || '暂无剧情简介'
      
      if (!description || description === '暂无剧情简介') {
        return '<p>暂无剧情简介</p>'
      }
      
      // 清理HTML标签，保留安全的标签
      const cleanHtml = description
        .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '') // 移除script标签
        .replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi, '') // 移除iframe标签
        .replace(/<object\b[^<]*(?:(?!<\/object>)<[^<]*)*<\/object>/gi, '') // 移除object标签
        .replace(/<embed\b[^<]*(?:(?!<\/embed>)<[^<]*)*<\/embed>/gi, '') // 移除embed标签
        .replace(/on\w+\s*=\s*["'][^"']*["']/gi, '') // 移除事件处理器
        .replace(/javascript:/gi, '') // 移除javascript协议
        .replace(/data:/gi, '') // 移除data协议
        .replace(/vbscript:/gi, '') // 移除vbscript协议
        
      // 如果内容没有HTML标签，自动包装成段落
      if (!/<[^>]*>/.test(cleanHtml)) {
        return `<p>${cleanHtml}</p>`
      }
      
      return cleanHtml
    })
    
    return { closeFullscreen, sanitizedDescription }
  }
}
</script>

<style scoped>
.fullscreen-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.9);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  backdrop-filter: blur(8px);
  animation: fadeIn 0.3s ease;
}

.fullscreen-content {
  background: #1a1b2e;
  border-radius: 16px;
  max-width: 90vw;
  max-height: 80vh;
  width: 600px;
  overflow: hidden;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
  animation: slideIn 0.3s ease;
}

.fullscreen-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid #2d2d3a;
  background: #23244a;
  /* 移动端安全区域处理 */
  padding-top: calc(20px + env(safe-area-inset-top, 0px));
}

.fullscreen-title {
  font-size: 20px;
  font-weight: 600;
  color: #ffffff;
  margin: 0;
}

.close-btn {
  background: none;
  border: none;
  color: #a5a5a5;
  cursor: pointer;
  padding: 8px;
  border-radius: 8px;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-btn:hover {
  background: #2d2d3a;
  color: #ffffff;
}

.fullscreen-description {
  padding: 24px;
  overflow-y: auto;
  max-height: calc(80vh - 80px);
  color: #ffffff !important;
  line-height: 1.8;
  font-size: 16px;
  text-align: justify;
  background: transparent !important;
}

.fullscreen-description p {
  margin: 0 0 16px 0;
  background: transparent !important;
  color: #ffffff !important;
}

.fullscreen-description div {
  color: #ffffff !important;
}

.fullscreen-description p:last-child {
  margin-bottom: 0;
  background: transparent !important;
}

.fullscreen-description * {
  background: transparent !important;
  color: #ffffff !important;
}

.fullscreen-description h1,
.fullscreen-description h2,
.fullscreen-description h3,
.fullscreen-description h4,
.fullscreen-description h5,
.fullscreen-description h6 {
  color: #ffffff !important;
  margin: 20px 0 12px 0;
  font-weight: 600;
}

.fullscreen-description h1 { font-size: 20px; }
.fullscreen-description h2 { font-size: 18px; }
.fullscreen-description h3 { font-size: 16px; }
.fullscreen-description h4 { font-size: 15px; }
.fullscreen-description h5 { font-size: 14px; }
.fullscreen-description h6 { font-size: 13px; }

.fullscreen-description strong,
.fullscreen-description b {
  color: #ffffff !important;
  font-weight: 600;
}

.fullscreen-description em,
.fullscreen-description i {
  font-style: italic;
}

.fullscreen-description ul,
.fullscreen-description ol {
  margin: 12px 0;
  padding-left: 20px;
}

.fullscreen-description li {
  margin: 4px 0;
}

.fullscreen-description a {
  color: #6366f1 !important;
  text-decoration: none;
}

.fullscreen-description a:hover {
  text-decoration: underline;
}

/* 滚动条样式 */
.fullscreen-description::-webkit-scrollbar {
  width: 6px;
}

.fullscreen-description::-webkit-scrollbar-track {
  background: #2d2d3a;
  border-radius: 3px;
}

.fullscreen-description::-webkit-scrollbar-thumb {
  background: #6366f1;
  border-radius: 3px;
}

.fullscreen-description::-webkit-scrollbar-thumb:hover {
  background: #5b5fef;
}

/* 动画 */
@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes slideIn {
  from {
    transform: scale(0.9) translateY(20px);
    opacity: 0;
  }
  to {
    transform: scale(1) translateY(0);
    opacity: 1;
  }
}

/* 移动端适配 */
@media (max-width: 768px) {
  .fullscreen-overlay {
    align-items: center;
    padding: 10px 0;
  }
  
  .fullscreen-content {
    width: 95vw;
    max-height: 90vh;
    border-radius: 12px;
    display: flex;
    flex-direction: column;
  }
  
  .fullscreen-header {
    padding: 16px 20px;
    flex-shrink: 0;
  }
  
  .fullscreen-title {
    font-size: 18px;
  }
  
  .fullscreen-description {
    padding: 20px;
    flex: 1;
    overflow-y: auto;
    max-height: none;
    font-size: 15px;
    line-height: 1.7;
    color: #ffffff !important;
  }
  
  .fullscreen-description div {
    color: #ffffff !important;
  }
  
  .fullscreen-description h1 { font-size: 18px; color: #ffffff; }
  .fullscreen-description h2 { font-size: 16px; color: #ffffff; }
  .fullscreen-description h3 { font-size: 15px; color: #ffffff; }
  .fullscreen-description h4 { font-size: 14px; color: #ffffff; }
  .fullscreen-description h5 { font-size: 13px; color: #ffffff; }
  .fullscreen-description h6 { font-size: 12px; color: #ffffff; }
  
  .fullscreen-description strong,
  .fullscreen-description b {
    color: #ffffff;
    font-weight: 600;
  }
  
  .fullscreen-description em,
  .fullscreen-description i {
    font-style: italic;
  }
  
  .fullscreen-description a {
    color: #6366f1;
    text-decoration: none;
  }
  
  .fullscreen-description a:hover {
    text-decoration: underline;
  }
  
  .close-btn {
    padding: 8px;
    min-width: 40px;
    min-height: 40px;
  }
}

/* 小屏幕适配 */
@media (max-width: 480px) {
  .fullscreen-overlay {
    align-items: center;
    padding: 20px 0;
  }
  
  .fullscreen-content {
    width: 95vw;
    max-height: 85vh;
    border-radius: 12px;
    display: flex;
    flex-direction: column;
  }
  
  .fullscreen-header {
    padding: 16px 20px;
    flex-shrink: 0;
  }
  
  .fullscreen-title {
    font-size: 18px;
    font-weight: 600;
  }
  
  .fullscreen-description {
    padding: 16px 20px;
    flex: 1;
    overflow-y: auto;
    max-height: none;
    font-size: 14px;
    line-height: 1.6;
    color: #ffffff !important;
  }
  
  .fullscreen-description div {
    color: #ffffff !important;
  }
  
  .fullscreen-description h1 { font-size: 16px; color: #ffffff; }
  .fullscreen-description h2 { font-size: 15px; color: #ffffff; }
  .fullscreen-description h3 { font-size: 14px; color: #ffffff; }
  .fullscreen-description h4 { font-size: 13px; color: #ffffff; }
  .fullscreen-description h5 { font-size: 12px; color: #ffffff; }
  .fullscreen-description h6 { font-size: 11px; color: #ffffff; }
  
  .fullscreen-description strong,
  .fullscreen-description b {
    color: #ffffff;
    font-weight: 600;
  }
  
  .fullscreen-description em,
  .fullscreen-description i {
    font-style: italic;
  }
  
  .fullscreen-description a {
    color: #6366f1;
    text-decoration: none;
  }
  
  .fullscreen-description a:hover {
    text-decoration: underline;
  }
  
  .close-btn {
    padding: 8px;
    min-width: 40px;
    min-height: 40px;
  }
}
</style> 