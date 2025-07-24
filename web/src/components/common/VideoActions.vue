<template>
  <div class="video-actions">
    <!-- PC端水平按钮布局 -->
    <div class="action-bar desktop-layout">
      <button class="action-btn primary" :disabled="!hasSearchResults">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
          <path d="M8 5v14l11-7z"/>
        </svg>
        播放
      </button>
      <button class="action-btn" :disabled="!hasSearchResults">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.29 1.51 4.04 3 5.5l7 7z"/>
        </svg>
        收藏
      </button>
      <button class="action-btn" :disabled="!hasSearchResults">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/>
          <polyline points="16,6 12,2 8,6"/>
          <line x1="12" y1="2" x2="12" y2="15"/>
        </svg>
        分享
      </button>
      <button class="action-btn" :disabled="!hasSearchResults">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
          <polyline points="7,10 12,15 17,10"/>
          <line x1="12" y1="15" x2="12" y2="3"/>
        </svg>
        下载
      </button>
    </div>

    <!-- 移动端图标+文字垂直布局 -->
    <div class="action-bar mobile-layout">
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
</template>

<script>
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'VideoActions',
  props: {
    hasSearchResults: { 
      type: Boolean, 
      default: false 
    }
  }
})
</script>

<style scoped>
.video-actions {
  width: 100%;
  margin-bottom: 16px;
}

/* PC端水平按钮布局 */
.desktop-layout {
  display: flex;
  gap: 8px;
}

.action-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  background: #3a3b5a;
  color: #e0e0e0;
  transition: all 0.2s;
}

.action-btn:hover:not(:disabled) {
  background: #4a4b6a;
}

.action-btn.primary {
  background: #6366f1;
  color: white;
}

.action-btn.primary:hover:not(:disabled) {
  background: #5b5fef;
}

.action-btn:disabled {
  background: #2a2b4a;
  color: #6b7280;
  cursor: not-allowed;
  opacity: 0.6;
}

/* 移动端图标+文字垂直布局 */
.mobile-layout {
  display: none;
}

.action-bar {
  width: 100%;
}

.action-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  background: none;
  border: none;
  color: #fff;
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
  color: #666;
  cursor: not-allowed;
  opacity: 0.5;
}

.action-item span {
  font-size: 12px;
  font-weight: 500;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .video-actions {
    margin-bottom: 16px;
    margin-top: 8px;
  }
  
  /* 隐藏PC端布局，显示移动端布局 */
  .desktop-layout {
    display: none;
  }
  
  .mobile-layout {
    display: flex;
    justify-content: space-around;
    padding: 8px 0;
  }
}

@media (max-width: 480px) {
  .action-item {
    min-width: 50px;
    padding: 6px;
  }
  
  .action-item span {
    font-size: 11px;
  }
}
</style> 