<template>
  <header class="header">
    <button 
      class="menu-btn" 
      @click="toggleSidebar"
      :class="{ active: sidebarActive }"
    >
      <span></span>
      <span></span>
      <span></span>
    </button>
    
    <h1 
      class="header-title" 
      @click="goHome"
      style="font-family:'Montserrat',sans-serif;font-size:1.6rem;letter-spacing:1.5px;cursor:pointer;transition:color 0.2s;"
    >
      VastVideo-Go
    </h1>
    
    <button 
      class="about-btn" 
      @click="showAbout"
      v-show="showAboutBtn"
      aria-label="关于" 
      title="关于 VastVideo-Go"
    >
      <svg viewBox="0 0 24 24" width="20" height="20">
        <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none"/>
        <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" stroke="currentColor" stroke-width="2" fill="none"/>
        <line x1="12" y1="17" x2="12.01" y2="17" stroke="currentColor" stroke-width="2"/>
      </svg>
    </button>
    
    <button 
      class="back-btn" 
      @click="goBack"
      v-show="showBackBtn"
      aria-label="返回"
    >
      <svg viewBox="0 0 24 24">
        <path d="M15 18l-6-6 6-6"/>
      </svg>
    </button>
  </header>
</template>

<script>
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'HeaderMenu',
  props: {
    sidebarActive: {
      type: Boolean,
      default: false
    },
    showAboutBtn: {
      type: Boolean,
      default: true
    },
    showBackBtn: {
      type: Boolean,
      default: false
    }
  },
  emits: ['toggle-sidebar', 'show-about', 'go-back', 'go-home'],
  methods: {
    toggleSidebar() {
      this.$emit('toggle-sidebar')
    },
    showAbout() {
      this.$emit('show-about')
    },
    goBack() {
      this.$emit('go-back')
    },
    goHome() {
      this.$emit('go-home')
    }
  }
})
</script>

<style scoped>
/* 悬浮置顶菜单栏 */
.header {
  position: fixed;
  top: 0; 
  left: 0; 
  right: 0;
  width: 100%;
  height: 52px;
  background: #23244a;
  z-index: 10000 !important;
  display: flex !important;
  align-items: center;
  justify-content: space-between;
  padding: 0 16px;
  opacity: 1 !important;
  visibility: visible !important;
  pointer-events: auto !important;
  box-sizing: border-box;
  transition: none !important;
  min-width: 100%;
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
}

.menu-btn {
  width: 40px;
  height: 40px;
  background: #23244a;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  display: flex !important;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  transition: background 0.2s, box-shadow 0.2s;
  flex-shrink: 0;
  opacity: 1 !important;
  visibility: visible !important;
}

.menu-btn:hover {
  background: #6c63ff;
  box-shadow: 0 2px 8px rgba(108,99,255,0.18);
}

.menu-btn span {
  width: 22px;
  height: 3px;
  background: #fff;
  border-radius: 2px;
  margin: 2.5px 0;
  display: block;
  transition: none;
  pointer-events: none;
}

.header-title {
  flex: 1;
  text-align: center;
  font-size: 1.4rem; 
  color: #fff; 
  font-weight: 700;
  pointer-events: auto;
  margin: 0;
  line-height: 1.2;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* 关于按钮样式 */
.about-btn, .back-btn {
  width: 40px;
  height: 40px;
  background: #23244a;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  margin-left: auto;
  margin-right: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s, transform 0.2s;
  z-index: 10001;
  position: relative;
}

.about-btn:hover {
  background: #6c63ff;
  transform: scale(1.08);
}

.about-btn svg {
  width: 20px;
  height: 20px;
  stroke: #fff;
  stroke-width: 2.5;
  stroke-linecap: round;
  fill: none;
}

/* 顶部菜单返回按钮 */
.back-btn {
  width: 40px;
  height: 40px;
  background: #23244a;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  margin-left: auto;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s, transform 0.2s;
  z-index: 10001;
  position: relative;
}

.back-btn:hover {
  background: #6c63ff;
  transform: scale(1.08);
}

.back-btn svg {
  width: 20px;
  height: 20px;
  stroke: #fff;
  stroke-width: 2.5;
  stroke-linecap: round;
  fill: none;
}
</style> 