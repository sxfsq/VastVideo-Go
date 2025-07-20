<template>
  <div>
    <!-- 侧边栏 -->
    <aside class="sidebar" :class="{ active: isActive }">
      <button 
        class="close-btn" 
        @click="closeSidebar"
        aria-label="关闭侧边栏"
      >
        <svg viewBox="0 0 24 24">
          <line x1="6" y1="6" x2="18" y2="18"/>
          <line x1="18" y1="6" x2="6" y2="18"/>
        </svg>
      </button>
      
      <!-- 搜索容器 -->
      <div class="search-container">
        <div class="search-input-wrapper">
          <input 
            type="text" 
            class="search-input" 
            v-model="searchKeyword"
            @keypress.enter="handleSearch"
            @input="handleSearchInputChange"
            placeholder="关键字或直接搜索返回最新"
          >
          <button 
            class="search-clear-btn" 
            v-show="searchKeyword.trim().length > 0"
            @click="clearSearch"
            title="清空搜索"
          >
            <svg viewBox="0 0 24 24" width="16" height="16">
              <line x1="18" y1="6" x2="6" y2="18"/>
              <line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>
        <button class="search-btn" @click="handleSearch">搜索</button>
      </div>

      <!-- 筛选选项 -->
      <div class="filter-section">
        <h3 class="filter-title">豆瓣内容类别</h3>
        <div class="filter-tabs">
          <button 
            class="filter-tab" 
            :class="{ active: currentType === 'movie' }"
            @click="switchType('movie')"
          >
            电影
          </button>
          <button 
            class="filter-tab" 
            :class="{ active: currentType === 'tv' }"
            @click="switchType('tv')"
          >
            电视剧
          </button>
        </div>
      </div>

      <!-- 标签选择 -->
      <div class="filter-section">
        <h3 class="filter-title">豆瓣内容标签</h3>
        <div class="tags-container">
          <button 
            v-for="tag in tags" 
            :key="tag"
            class="tag-btn" 
            :class="{ active: tag === currentTag }"
            @click="selectTag(tag)"
          >
            {{ tag }}
          </button>
          <span v-if="tagsLoading" class="loading">加载中...</span>
        </div>
      </div>

      <!-- 功能按钮区域 -->
      <div class="filter-section" style="border-bottom:none;position:relative;">
        <button 
          class="function-btn"
          @click="toggleSourceSelection"
        >
          视频源选择
        </button>
        <button 
          class="function-btn"
          @click="toggleFilterSettings"
        >
          过滤设置
        </button>
      </div>
      
      <!-- 视频源选择覆盖层 -->
      <div 
        v-show="showSourceSelection" 
        class="overlay-area"
      >
        <div class="overlay-header">
          <div class="overlay-title">选择视频源</div>
          <button class="overlay-close-btn" @click="closeSourceSelection">×</button>
        </div>
        <div class="sources-list">
          <label 
            v-for="source in videoSources" 
            :key="source.code"
            class="source-item"
          >
            <input 
              type="checkbox" 
              :value="source.code"
              v-model="selectedSources"
            >
            <span>{{ source.name }}</span>
          </label>
        </div>
        <div class="overlay-actions">
          <button class="action-btn primary" @click="selectAllSources">全选</button>
          <button class="action-btn secondary" @click="invertSourceSelection">反选</button>
        </div>
        <button class="action-btn primary full-width" @click="saveSourceSelection">保存选择</button>
      </div>

      <!-- 过滤设置覆盖层 -->
      <div 
        v-show="showFilterSettings" 
        class="overlay-area"
      >
        <!-- 密码验证界面 -->
        <div v-if="!isFilterAuthenticated" class="auth-section">
          <h4 class="auth-title">管理员验证</h4>
          <div class="auth-input-group">
            <input 
              type="password" 
              v-model="adminPassword"
              @keypress.enter="submitPassword"
              placeholder="请输入管理员密码"
              class="auth-input"
            >
          </div>
          <div class="auth-actions">
            <button class="action-btn primary" @click="submitPassword">确认</button>
            <button class="action-btn secondary" @click="closeFilterSettings">取消</button>
          </div>
        </div>
        
        <!-- 过滤设置界面 -->
        <div v-else class="filter-settings-section">
          <h4 class="settings-title">内容过滤</h4>
          <div class="setting-item">
            <label class="setting-label">
              <span>隐藏成人内容</span>
              <div class="toggle-switch">
                <input 
                  type="checkbox" 
                  v-model="adultContentFilter"
                  style="display:none;"
                >
                <span class="toggle-slider"></span>
              </div>
            </label>
            <p class="setting-description">开启后将隐藏伦理片、理论片类型的内容</p>
          </div>
          
          <div class="setting-item">
            <label class="setting-label">
              <span>修改管理员密码</span>
              <button class="change-password-btn" @click="togglePasswordChange">修改</button>
            </label>
          </div>
          
          <div v-show="showPasswordChange" class="password-change-section">
            <input 
              type="password" 
              v-model="newPassword"
              placeholder="新密码"
              class="auth-input"
            >
            <input 
              type="password" 
              v-model="confirmPassword"
              placeholder="确认新密码"
              class="auth-input"
            >
          </div>
          
          <div class="settings-actions">
            <button class="action-btn primary" @click="saveFilterSettings">保存设置</button>
            <button class="action-btn secondary" @click="closeFilterSettings">关闭</button>
          </div>
        </div>
      </div>
    </aside>
    
    <!-- 遮罩层 -->
    <div 
      class="sidebar-mask" 
      :class="{ active: isActive }"
      @click="closeSidebar"
    ></div>
  </div>
</template>

<script>
import { defineComponent, ref, computed, watch, onMounted } from 'vue'
import { useToast } from '@/composables/useToast'
import { useVideoSources } from '@/composables/useVideoSources'
import api from '@/services/api.js'

export default defineComponent({
  name: 'SideBar',
  props: {
    isActive: {
      type: Boolean,
      default: false
    }
  },
  emits: ['close', 'search', 'type-change', 'tag-change'],
  setup(props, { emit }) {
    const { showToast } = useToast()
    const { videoSources, selectedSources, fetchVideoSources, saveSelectedSources } = useVideoSources()
    
    // 搜索相关
    const searchKeyword = ref('')
    
    // 筛选相关
    const currentType = ref('movie')
    const currentTag = ref('')
    const tags = ref([])
    const tagsLoading = ref(false)
    
    // 覆盖层状态
    const showSourceSelection = ref(false)
    const showFilterSettings = ref(false)
    const isFilterAuthenticated = ref(false)
    
    // 过滤设置
    const adminPassword = ref('')
    const adultContentFilter = ref(true)
    const showPasswordChange = ref(false)
    const newPassword = ref('')
    const confirmPassword = ref('')
    
    // 方法
    const closeSidebar = () => {
      emit('close')
    }
    
    const handleSearch = () => {
      emit('search', searchKeyword.value.trim())
      closeSidebar()
    }
    
    const clearSearch = () => {
      searchKeyword.value = ''
      showToast('搜索内容已清空', 'info', 1500)
    }
    
    const handleSearchInputChange = () => {
      // 这里可以添加输入变化的处理逻辑
    }
    
    const switchType = (type) => {
      if (currentType.value !== type) {
        currentType.value = type
        emit('type-change', type)
        fetchTags()
        closeSidebar()
      }
    }
    
    const selectTag = (tag) => {
      if (currentTag.value !== tag) {
        currentTag.value = tag
        emit('tag-change', tag)
        closeSidebar()
      }
    }
    
    const fetchTags = async () => {
      tagsLoading.value = true
      try {
        const data = await api.douban.tags(currentType.value)
        tags.value = data.tags || []
        // 优先选择"最新"标签
        currentTag.value = tags.value.find(tag => tag === '最新') || tags.value[0] || ''
      } catch (error) {
        console.error('获取标签失败:', error)
        // 使用默认标签
        tags.value = currentType.value === 'movie' 
          ? ['热门', '最新', '高分', '动作', '喜剧', '爱情', '科幻', '恐怖', '剧情', '动画']
          : ['热门', '最新', '高分', '都市', '古装', '悬疑', '喜剧', '爱情', '科幻', '战争']
        currentTag.value = tags.value.find(tag => tag === '最新') || tags.value[0]
      } finally {
        tagsLoading.value = false
      }
    }
    
    // 视频源选择相关方法
    const toggleSourceSelection = () => {
      showSourceSelection.value = !showSourceSelection.value
      if (showSourceSelection.value) {
        showFilterSettings.value = false
      }
    }
    
    const closeSourceSelection = () => {
      showSourceSelection.value = false
    }
    
    const selectAllSources = () => {
      selectedSources.value = videoSources.value.map(source => source.code)
    }
    
    const invertSourceSelection = () => {
      const currentSelected = new Set(selectedSources.value)
      selectedSources.value = videoSources.value
        .filter(source => !currentSelected.has(source.code))
        .map(source => source.code)
    }
    
    const saveSourceSelection = () => {
      if (selectedSources.value.length === 0) {
        showToast('请至少选择一个视频源', 'warning', 2000)
        return
      }
      saveSelectedSources()
      showToast('视频源选择已保存', 'success', 2000)
      closeSourceSelection()
    }
    
    // 过滤设置相关方法
    const toggleFilterSettings = () => {
      showFilterSettings.value = !showFilterSettings.value
      if (showFilterSettings.value) {
        showSourceSelection.value = false
        isFilterAuthenticated.value = false
        adminPassword.value = ''
      }
    }
    
    const closeFilterSettings = () => {
      showFilterSettings.value = false
      isFilterAuthenticated.value = false
      showPasswordChange.value = false
      adminPassword.value = ''
      newPassword.value = ''
      confirmPassword.value = ''
    }
    
    const submitPassword = () => {
      const storedPassword = localStorage.getItem('vastvideo_admin_password')
      const correctPassword = (storedPassword && storedPassword.trim() !== '') ? storedPassword : '8228'
      
      if (adminPassword.value === correctPassword) {
        isFilterAuthenticated.value = true
        // 加载当前过滤设置
        const filterSetting = localStorage.getItem('vastvideo_adult_filter')
        adultContentFilter.value = filterSetting ? JSON.parse(filterSetting) : true
      } else {
        showToast('密码错误', 'error', 2000)
      }
    }
    
    const togglePasswordChange = () => {
      showPasswordChange.value = !showPasswordChange.value
      if (!showPasswordChange.value) {
        newPassword.value = ''
        confirmPassword.value = ''
      }
    }
    
    const saveFilterSettings = () => {
      // 保存过滤设置
      localStorage.setItem('vastvideo_adult_filter', JSON.stringify(adultContentFilter.value))
      
      // 如果输入了新密码
      if (newPassword.value && newPassword.value === confirmPassword.value) {
        localStorage.setItem('vastvideo_admin_password', newPassword.value)
        showToast('密码已更新', 'success', 2000)
        showPasswordChange.value = false
        newPassword.value = ''
        confirmPassword.value = ''
      } else if (newPassword.value && newPassword.value !== confirmPassword.value) {
        showToast('两次输入的密码不一致', 'error', 2000)
        return
      }
      
      showToast('过滤设置已保存', 'success', 2000)
      closeFilterSettings()
    }
    
    // 监听过滤开关变化
    watch(adultContentFilter, (newValue) => {
      localStorage.setItem('vastvideo_adult_filter', JSON.stringify(newValue))
    })
    
    // 组件挂载时获取数据
    onMounted(() => {
      fetchVideoSources()
      fetchTags()
    })
    
    return {
      // 数据
      searchKeyword,
      currentType,
      currentTag,
      tags,
      tagsLoading,
      showSourceSelection,
      showFilterSettings,
      isFilterAuthenticated,
      adminPassword,
      adultContentFilter,
      showPasswordChange,
      newPassword,
      confirmPassword,
      videoSources,
      selectedSources,
      
      // 方法
      closeSidebar,
      handleSearch,
      clearSearch,
      handleSearchInputChange,
      switchType,
      selectTag,
      toggleSourceSelection,
      closeSourceSelection,
      selectAllSources,
      invertSourceSelection,
      saveSourceSelection,
      toggleFilterSettings,
      closeFilterSettings,
      submitPassword,
      togglePasswordChange,
      saveFilterSettings
    }
  }
})
</script>

<style scoped>
/* 侧边栏 */
.sidebar {
  position: fixed;
  left: -280px; 
  top: 0;
  width: 280px; 
  height: 100vh;
  background: #23244a !important;
  z-index: 2001 !important;
  transition: left 0.3s cubic-bezier(0.4,0,0.2,1);
  overflow-y: auto;
}

.sidebar.active { 
  left: 0; 
}

.close-btn {
  position: absolute;
  top: 8px;
  right: 8px;
  width: 40px;
  height: 40px;
  background: #23244a;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  z-index: 10001;
}

.close-btn:hover {
  background: rgba(108,99,255,0.8) !important;
  color: #fff !important;
  transform: scale(1.1);
}

.close-btn svg {
  width: 20px;
  height: 20px;
  stroke: #fff;
  stroke-width: 2;
  fill: none;
}

.search-container {
  padding: 16px;
  border-bottom: 1px solid #3a3b5a;
  margin-top: 60px;
}

.search-input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

.search-input {
  width: 100%;
  padding: 12px 16px;
  padding-right: 40px;
  border: 1px solid #3a3b5a;
  border-radius: 8px;
  font-size: 16px;
  outline: none;
  transition: border-color 0.3s;
  background: #18192b;
  color: #fff;
  -webkit-appearance: none;
  -webkit-border-radius: 8px;
  border-radius: 8px;
  transform: translateZ(0);
}

.search-input:focus {
  border-color: #6c63ff;
  font-size: 16px !important;
  transform: translateZ(0);
}

.search-input::placeholder {
  color: #888;
}

.search-clear-btn {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  width: 24px;
  height: 24px;
  border: none;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
  color: #b3b6d4;
}

.search-clear-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  color: #fff;
  transform: translateY(-50%) scale(1.1);
}

.search-clear-btn svg {
  width: 14px;
  height: 14px;
  stroke: currentColor;
  stroke-width: 2;
  fill: none;
}

.search-btn {
  width: 100%;
  padding: 12px;
  background: #6c63ff;
  color: #fff;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  margin-top: 8px;
  transition: background 0.3s;
}

.search-btn:hover {
  background: #554eea;
}

/* 筛选选项 */
.filter-section {
  padding: 16px;
  border-bottom: 1px solid #3a3b5a;
}

.filter-title {
  font-size: 14px;
  font-weight: 600;
  color: #fff;
  margin-bottom: 12px;
}

.filter-tabs {
  display: flex;
  background: #18192b;
  border-radius: 8px;
  padding: 4px;
  margin-bottom: 16px;
}

.filter-tab {
  flex: 1;
  padding: 8px 12px;
  background: none;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.3s;
  color: #b3b6d4;
}

.filter-tab.active {
  background: #6c63ff;
  color: #fff;
}

.tags-container {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag-btn {
  padding: 6px 12px;
  background: #23244a;
  border: none;
  border-radius: 16px;
  font-size: 12px;
  color: #b3b6d4;
  cursor: pointer;
  transition: all 0.3s;
}

.tag-btn.active {
  background: #6c63ff;
  color: #fff;
}

.loading {
  color: #b3b6d4;
  font-size: 12px;
}

/* 功能按钮 */
.function-btn {
  width: 100%;
  background: #23244a;
  color: #b3b6d4;
  border: none;
  border-radius: 8px;
  padding: 12px 0;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  margin-bottom: 12px;
  transition: all 0.2s;
}

.function-btn:hover {
  background: #6c63ff;
  color: #fff;
}

/* 覆盖层样式 */
.overlay-area {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: #23244a;
  z-index: 1000;
  padding: 16px;
  overflow-y: auto;
}

.overlay-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.overlay-title {
  font-size: 16px;
  font-weight: 600;
  color: #fff;
}

.overlay-close-btn {
  background: none;
  color: #b3b6d4;
  border: none;
  font-size: 20px;
  cursor: pointer;
  padding: 4px;
}

.sources-list {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  padding-bottom: 4px;
  margin-bottom: 12px;
}

.source-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  color: #b3b6d4;
  padding: 10px 8px;
  cursor: pointer;
  background: rgba(24,25,43,0.7);
  border-radius: 8px;
  border: 1px solid rgba(108,99,255,0.1);
  user-select: none;
  transition: all 0.2s ease;
}

.source-item:hover {
  background: rgba(108,99,255,0.2);
  border-color: rgba(108,99,255,0.4);
}

.source-item input[type="checkbox"] {
  accent-color: #6c63ff;
  width: 16px;
  height: 16px;
}

.overlay-actions {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  margin-bottom: 12px;
}

.action-btn {
  border: none;
  border-radius: 8px;
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.action-btn.primary {
  background: #6c63ff;
  color: #fff;
}

.action-btn.primary:hover {
  background: #554eea;
}

.action-btn.secondary {
  background: #444;
  color: #fff;
}

.action-btn.secondary:hover {
  background: #555;
}

.action-btn.full-width {
  width: 100%;
  padding: 10px 0;
}

/* 认证和设置界面 */
.auth-section, .filter-settings-section {
  padding: 0;
}

.auth-title, .settings-title {
  color: #fff;
  margin-bottom: 12px;
  font-size: 14px;
}

.auth-input-group {
  margin-bottom: 12px;
}

.auth-input {
  width: 100%;
  padding: 12px;
  border: 1px solid #3a3b5a;
  border-radius: 8px;
  background: #18192b;
  color: #fff;
  font-size: 14px;
  outline: none;
  box-sizing: border-box;
  margin-bottom: 8px;
}

.auth-input:focus {
  border-color: #6c63ff;
}

.auth-actions, .settings-actions {
  display: flex;
  gap: 8px;
}

.setting-item {
  margin-bottom: 16px;
}

.setting-label {
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: #fff;
  font-size: 13px;
  margin-bottom: 8px;
}

.setting-description {
  color: #b3b6d4;
  font-size: 11px;
  margin: 0;
}

.change-password-btn {
  background: #444;
  color: #fff;
  border: none;
  border-radius: 4px;
  padding: 4px 8px;
  font-size: 11px;
  cursor: pointer;
}

.password-change-section {
  margin-bottom: 16px;
}

/* 切换开关样式 */
.toggle-switch {
  position: relative;
  width: 44px;
  height: 24px;
  background: #444;
  border-radius: 12px;
  cursor: pointer;
  transition: background 0.3s;
}

.toggle-switch input:checked + .toggle-slider {
  background: #6c63ff;
  transform: translateX(20px);
}

.toggle-slider {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 20px;
  height: 20px;
  background: #fff;
  border-radius: 50%;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.toggle-switch:hover .toggle-slider {
  box-shadow: 0 2px 8px rgba(0,0,0,0.3);
}

/* 遮罩层 */
.sidebar-mask {
  z-index: 2000 !important;
  display: none;
  position: fixed; 
  left: 0; 
  top: 0; 
  width: 100vw; 
  height: 100vh;
  background: rgba(24,25,43,0.35);
  opacity: 1;
  transition: none;
}

.sidebar-mask.active { 
  display: block; 
}

/* 滚动条样式 */
.sidebar::-webkit-scrollbar {
  width: 6px;
}

.sidebar::-webkit-scrollbar-track {
  background: rgba(24,25,43,0.3);
  border-radius: 3px;
}

.sidebar::-webkit-scrollbar-thumb {
  background: linear-gradient(135deg, #6c63ff, #8b5cf6);
  border-radius: 3px;
  transition: background 0.2s ease;
}

.sidebar::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(135deg, #554eea, #7c3aed);
}

/* Firefox滚动条样式 */
.sidebar {
  scrollbar-width: thin;
  scrollbar-color: #6c63ff rgba(24,25,43,0.3);
}
</style> 