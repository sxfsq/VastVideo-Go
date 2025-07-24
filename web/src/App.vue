<template>
  <div id="app" class="app">
    <!-- 顶部菜单 -->
    <HeaderMenu 
      :sidebar-active="sidebarActive"
      :show-about-btn="!showSearchResults && !showVideoDetail"
      :show-back-btn="showSearchResults || showVideoDetail"
      @toggle-sidebar="toggleSidebar"
      @show-about="showAbout"
      @go-back="goBack"
      @go-home="goHome"
    />
    
    <!-- 侧边栏 -->
    <SideBar 
      :is-active="sidebarActive"
      @close="closeSidebar"
      @search="handleSearch"
      @type-change="handleTypeChange"
      @tag-change="handleTagChange"
    />
    
    <!-- 主页内容 -->
    <HomePage 
      v-show="!showVideoDetail"
      ref="homePageRef"
      :current-type="currentType"
      :current-tag="currentTag"
      :showing-detail="showVideoDetail"
      @video-click="handleVideoClick"
    />
    
    <!-- 视频详情页 -->
    <VideoDetail 
      v-show="showVideoDetail"
      :video-data="currentVideo"
      @go-back="closeVideoDetail"
      @video-select="handleRelatedVideoSelect"
      @search="handleSearch"
    />
    
    <!-- 关于对话框 -->
    <AboutDialog v-show="showAboutDialog" @close="closeAbout" />
  </div>
</template>

<script>
import { defineComponent, ref, onMounted, nextTick } from 'vue'
import HeaderMenu from './components/HeaderMenu.vue'
import SideBar from './components/SideBar.vue'
import HomePage from './components/HomePage.vue'
import VideoDetail from './components/VideoDetail.vue'
import AboutDialog from './components/AboutDialog.vue'
import { useToast } from './composables/useToast'

export default defineComponent({
  name: 'App',
  components: {
    HeaderMenu,
    SideBar,
    HomePage,
    VideoDetail,
    AboutDialog
  },
  setup() {
    const { showToast } = useToast()
    
    // 状态管理
    const sidebarActive = ref(false)
    const showAboutDialog = ref(false)
    const showSearchResults = ref(false)
    const showVideoDetail = ref(false)
    const currentVideo = ref({})
    const currentType = ref('movie')
    const currentTag = ref('')
    const homePageRef = ref(null)
    
    // 方法
    const toggleSidebar = () => {
      sidebarActive.value = !sidebarActive.value
      console.log('侧边栏状态:', sidebarActive.value)
    }
    
    const closeSidebar = () => {
      sidebarActive.value = false
    }
    
    const showAbout = () => {
      showAboutDialog.value = true
      console.log('显示关于对话框')
    }
    
    const closeAbout = () => {
      showAboutDialog.value = false
    }
    
    const goBack = () => {
      if (showVideoDetail.value) {
        closeVideoDetail()
      } else if (showSearchResults.value && homePageRef.value) {
        homePageRef.value.backToRecommend()
        showSearchResults.value = false
      }
    }
    
    const goHome = () => {
      if (showVideoDetail.value) {
        closeVideoDetail()
      } else if (showSearchResults.value && homePageRef.value) {
        homePageRef.value.backToRecommend()
        showSearchResults.value = false
      }
      // 直接回到页面顶部
      window.scrollTo(0, 0)
    }
    
    const handleSearch = (keyword) => {
      console.log('应用级搜索:', keyword)
      if (homePageRef.value) {
        homePageRef.value.performSearch(keyword)
        showSearchResults.value = true
        showVideoDetail.value = false // 新增：搜索时关闭播放页
      }
    }
    
    const handleTypeChange = (type) => {
      console.log('类型切换:', type)
      currentType.value = type
      showSearchResults.value = false
      
      // 切换类型时直接回到顶部
      window.scrollTo(0, 0)
    }
    
    const handleTagChange = (tag) => {
      console.log('标签切换:', tag)
      currentTag.value = tag
      showSearchResults.value = false
      
      // 如果当前在播放页，返回到豆瓣推荐页
      if (showVideoDetail.value) {
        showVideoDetail.value = false
        currentVideo.value = {}
        showToast(`已切换到标签: ${tag}`, 'info', 2000)
      }
      
      // 切换标签时直接回到顶部
      window.scrollTo(0, 0)
    }
    
    const handleVideoClick = (video) => {
      console.log('视频点击:', video)
      currentVideo.value = video
      showVideoDetail.value = true
      showSearchResults.value = false
      // 滚动到顶部
      window.scrollTo(0, 0)
      showToast(`正在加载视频详情: ${video.title || video.vod_name}`, 'info', 2000)
    }
    
    const closeVideoDetail = () => {
      showVideoDetail.value = false
      currentVideo.value = {}
      // 滚动到顶部
      window.scrollTo(0, 0)
      // 新增：根据进入路径返回
      if (showSearchResults.value) {
        // 返回搜索结果页
        // 不需要额外处理，HomePage 会自动显示搜索结果
      } else {
        // 返回豆瓣推荐页
        if (homePageRef.value) {
          homePageRef.value.backToRecommend()
        }
      }
    }

    const handleRelatedVideoSelect = (video) => {
      console.log('选择相关视频:', video)
      currentVideo.value = video
      // 保持在详情页面，只是切换视频内容
      // 滚动到顶部以便查看新视频
      window.scrollTo(0, 0)
      showToast(`正在切换视频: ${video.title || video.vod_name}`, 'info', 2000)
    }
    
    // 组件挂载后的初始化
    onMounted(async () => {
      console.log('应用初始化...')
      
      // 确保页面滚动到顶部
      window.scrollTo(0, 0)
      
      // 显示加载完成的动画
      await nextTick()
      const appEl = document.getElementById('app')
      if (appEl) {
        appEl.classList.add('loaded')
      }
      
      // iOS设备特殊处理
      const isIOS = /iPad|iPhone|iPod/.test(navigator.platform)
      if (isIOS) {
        console.log('iOS设备初始化')
        
        // 确保视口设置正确
        const viewport = document.querySelector('meta[name=viewport]')
        if (viewport) {
          viewport.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no')
        }
        
        // 防止iOS双击缩放
        let lastTouchEnd = 0
        document.addEventListener('touchend', function (event) {
          const now = (new Date()).getTime()
          if (now - lastTouchEnd <= 300) {
            event.preventDefault()
          }
          lastTouchEnd = now
        }, false)
        
        // 防止iOS双指缩放
        document.addEventListener('gesturestart', function (event) {
          event.preventDefault()
        }, false)
        
        document.addEventListener('gesturechange', function (event) {
          event.preventDefault()
        }, false)
        
        document.addEventListener('gestureend', function (event) {
          event.preventDefault()
        }, false)
      }
      
      console.log('应用初始化完成')
    })
    
    return {
      // 状态
      sidebarActive,
      showAboutDialog,
      showSearchResults,
      showVideoDetail,
      currentVideo,
      currentType,
      currentTag,
      homePageRef,
      
      // 方法
      toggleSidebar,
      closeSidebar,
      showAbout,
      closeAbout,
      goBack,
      goHome,
      handleSearch,
      handleTypeChange,
      handleTagChange,
      handleVideoClick,
      closeVideoDetail,
      handleRelatedVideoSelect
    }
  }
})
</script>

<style>
/* 全局样式重置 */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

/* 全局移动端容器 */
html, body {
  width: 100%;
  max-width: 100vw;
  overflow-x: hidden;
  /* 防止iOS缩放 */
  -webkit-text-size-adjust: 100%;
  -ms-text-size-adjust: 100%;
  text-size-adjust: 100%;
  /* 防止iOS滚动回弹 */
  -webkit-overflow-scrolling: touch;
}

/* 确保所有容器都不会超出屏幕 */
* {
  max-width: 100%;
}

/* 特别处理flex容器 */
.flex-container {
  flex-wrap: wrap;
  width: 100%;
  box-sizing: border-box;
}

html {
  scroll-behavior: auto;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #18192b;
  color: #fff;
  line-height: 1.6;
  min-height: 100vh;
  width: 100%;
  box-sizing: border-box;
  overflow-x: hidden;
}

.app {
  width: 100%;
  /* min-height: 100vh; */
  background: #18192b;
  color: #fff;
  position: relative;
  /* overflow-x: hidden; */
  padding-top: 50px; /* 为HeaderMenu预留空间 */
  box-sizing: border-box;
}

/* 确保内容可见 */
.app {
  display: block !important;
}

/* 页面加载动画 */
#app {
  opacity: 1;
  transition: opacity 0.3s ease-in-out;
}

/* 页面加载状态 */
#app.loading {
  opacity: 0.7;
}

#app.loaded {
  opacity: 1;
}

/* 滚动条样式 */
::-webkit-scrollbar {
  width: 6px;
}

::-webkit-scrollbar-track {
  background: rgba(24,25,43,0.3);
  border-radius: 3px;
}

::-webkit-scrollbar-thumb {
  background: linear-gradient(135deg, #6c63ff, #8b5cf6);
  border-radius: 3px;
  transition: background 0.2s ease;
}

::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(135deg, #554eea, #7c3aed);
}

/* Firefox滚动条样式 */
html {
  scrollbar-width: thin;
  scrollbar-color: #6c63ff rgba(24,25,43,0.3);
}

/* PC分辨率下的样式 */
@media (min-width: 769px) {
  .app {
    overflow-x: hidden;
    width: 100%;
    max-width: 100vw;
  }
}

html, body, #app, .app {
  height: auto !important;
  min-height: 0 !important;
  overflow-y: auto !important;
}
</style> 