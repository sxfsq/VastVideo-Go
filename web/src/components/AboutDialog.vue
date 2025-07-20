<template>
  <div class="about-overlay" @click.self="closeDialog">
    <div class="about-dialog">
      <div class="about-header">
        <h2 class="about-title">关于 VastVideo-Go</h2>
        <button class="close-btn" @click="closeDialog">
          <svg viewBox="0 0 24 24">
            <line x1="18" y1="6" x2="6" y2="18"/>
            <line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
        </button>
      </div>
      
      <div class="about-content">
        <div class="logo-section">
          <div class="logo">
            <div class="logo-icon">
              <svg viewBox="0 0 24 24" width="48" height="48">
                <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none"/>
                <polygon points="10,8 16,12 10,16" fill="currentColor"/>
              </svg>
            </div>
            <h3>VastVideo-Go</h3>
          </div>
          <p class="version">Version 1.0.0</p>
        </div>
        
        <div class="description">
          <p>VastVideo-Go 是一个聚合型视频搜索平台，整合多个视频源为用户提供丰富的影视内容。</p>
        </div>
        
        <div class="features">
          <h4>主要特性</h4>
          <ul>
            <li>🎬 聚合多个视频源</li>
            <li>🔍 智能搜索功能</li>
            <li>📱 响应式设计，支持移动端</li>
            <li>🎯 豆瓣推荐内容</li>
            <li>⚙️ 个性化设置</li>
          </ul>
        </div>
        
        <div class="tech-stack">
          <h4>技术栈</h4>
          <div class="tech-tags">
            <span class="tech-tag">Vue 3</span>
            <span class="tech-tag">Go</span>
            <span class="tech-tag">Vite</span>
            <span class="tech-tag">Composition API</span>
          </div>
        </div>
        
        <div class="footer">
          <p>© 2024 VastVideo-Go. 仅供学习交流使用。</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'AboutDialog',
  emits: ['close'],
  setup(props, { emit }) {
    const closeDialog = () => {
      emit('close')
    }
    
    return {
      closeDialog
    }
  }
})
</script>

<style scoped>
.about-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(24, 25, 43, 0.8);
  backdrop-filter: blur(10px);
  z-index: 10000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  animation: fadeIn 0.3s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.about-dialog {
  background: linear-gradient(135deg, #23244a 0%, #2a2b4a 100%);
  border-radius: 20px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.4);
  border: 1px solid rgba(108, 99, 255, 0.2);
  max-width: 500px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(-30px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.about-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px 24px 16px;
  border-bottom: 1px solid rgba(108, 99, 255, 0.1);
}

.about-title {
  font-size: 24px;
  font-weight: 700;
  color: #fff;
  margin: 0;
}

.close-btn {
  width: 40px;
  height: 40px;
  border: none;
  border-radius: 50%;
  background: rgba(108, 99, 255, 0.1);
  color: #6c63ff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.close-btn:hover {
  background: rgba(108, 99, 255, 0.2);
  transform: scale(1.1);
}

.close-btn svg {
  width: 20px;
  height: 20px;
  stroke: currentColor;
  stroke-width: 2;
  fill: none;
}

.about-content {
  padding: 24px;
}

.logo-section {
  text-align: center;
  margin-bottom: 24px;
}

.logo {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 12px;
}

.logo-icon {
  width: 80px;
  height: 80px;
  background: linear-gradient(135deg, #6c63ff 0%, #8b5cf6 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 16px;
  color: #fff;
  box-shadow: 0 8px 32px rgba(108, 99, 255, 0.3);
}

.logo h3 {
  font-size: 28px;
  font-weight: 700;
  color: #fff;
  margin: 0;
  font-family: 'Montserrat', sans-serif;
  letter-spacing: 1px;
}

.version {
  color: #b3b6d4;
  font-size: 14px;
  margin: 0;
}

.description {
  margin-bottom: 24px;
}

.description p {
  color: #b3b6d4;
  line-height: 1.6;
  font-size: 16px;
  margin: 0;
}

.features, .tech-stack {
  margin-bottom: 24px;
}

.features h4, .tech-stack h4 {
  color: #fff;
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 12px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.features h4::before, .tech-stack h4::before {
  content: '';
  width: 4px;
  height: 18px;
  background: #6c63ff;
  border-radius: 2px;
}

.features ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.features li {
  color: #b3b6d4;
  font-size: 15px;
  line-height: 1.8;
  margin-bottom: 8px;
  padding-left: 0;
}

.tech-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tech-tag {
  background: rgba(108, 99, 255, 0.1);
  border: 1px solid rgba(108, 99, 255, 0.3);
  color: #6c63ff;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 500;
}

.footer {
  text-align: center;
  border-top: 1px solid rgba(108, 99, 255, 0.1);
  padding-top: 20px;
  margin-top: 20px;
}

.footer p {
  color: #888;
  font-size: 13px;
  margin: 0;
}

/* 移动端优化 */
@media (max-width: 480px) {
  .about-overlay {
    padding: 16px;
  }
  
  .about-dialog {
    border-radius: 16px;
  }
  
  .about-header {
    padding: 20px 20px 12px;
  }
  
  .about-title {
    font-size: 20px;
  }
  
  .about-content {
    padding: 20px;
  }
  
  .logo-icon {
    width: 60px;
    height: 60px;
  }
  
  .logo h3 {
    font-size: 24px;
  }
  
  .features h4, .tech-stack h4 {
    font-size: 16px;
  }
  
  .description p {
    font-size: 15px;
  }
  
  .features li {
    font-size: 14px;
  }
}
</style> 