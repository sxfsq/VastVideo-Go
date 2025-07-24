<template>
  <div class="cast-section" v-if="actorsList.length > 0">
    <h3 class="section-title">主要演员</h3>
    
    <!-- PC端网格布局 -->
    <div class="cast-grid desktop-layout">
      <div 
        v-for="(actor, index) in actorsList" 
        :key="index" 
        class="cast-item"
        @click="selectActor(actor)"
      >
        <div class="cast-avatar">{{ actor.charAt(0) }}</div>
        <div class="cast-info">
          <div class="cast-name">{{ actor }}</div>
        </div>
      </div>
    </div>

    <!-- 移动端卡片布局 -->
    <div class="cast-mobile mobile-layout">
      <div class="cast-horizontal">
        <div 
          v-for="(actor, index) in actorsList" 
          :key="index" 
          class="cast-card"
          @click="selectActor(actor)"
        >
          <div class="cast-avatar">{{ actor.charAt(0) }}</div>
          <div class="cast-name">{{ actor }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { defineComponent, computed } from 'vue'

export default defineComponent({
  name: 'CastList',
  props: {
    videoData: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  emits: ['actor-select'],
  setup(props, { emit }) {
    const actorsList = computed(() => {
      if (!props.videoData?.vod_actor) return []
      return props.videoData.vod_actor
        .split(',')
        .map(actor => actor.trim())
        .filter(actor => actor)
        .slice(0, 12)
    })

    const selectActor = (actor) => {
      console.log('选择演员:', actor)
      emit('actor-select', actor)
    }
    
    return {
      actorsList,
      selectActor
    }
  }
})
</script>

<style scoped>
/* 基础样式 */
.cast-section { 
  background: #23244a; 
  padding: 20px; 
  border-radius: 12px; 
  margin-bottom: 16px; 
}

.section-title { 
  font-size: 18px; 
  font-weight: 600; 
  color: #fff; 
  margin: 0 0 12px 0; 
}

/* PC端网格布局 */
.desktop-layout {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.cast-item { 
  display: flex; 
  align-items: center; 
  gap: 12px; 
  padding: 12px; 
  background: #2a2b4a; 
  border-radius: 8px; 
  cursor: pointer; 
  transition: all 0.2s; 
}

.cast-item:hover { 
  background: #3a3b5a; 
  transform: translateY(-1px); 
}

.cast-avatar { 
  width: 50px; 
  height: 50px; 
  background: linear-gradient(135deg, #6366f1, #8b5cf6); 
  border-radius: 50%; 
  flex-shrink: 0; 
  display: flex; 
  align-items: center; 
  justify-content: center; 
  color: white; 
  font-weight: bold; 
  font-size: 18px; 
  text-transform: uppercase; 
}

.cast-info { 
  flex: 1; 
  min-width: 0; 
}

.cast-name { 
  font-size: 14px; 
  font-weight: 500; 
  color: #fff; 
  margin-bottom: 2px; 
  overflow: hidden; 
  text-overflow: ellipsis; 
  white-space: nowrap; 
}



/* 移动端卡片布局 */
.mobile-layout {
  display: none;
}

.cast-mobile {
  width: 100%;
}

.cast-horizontal {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  justify-content: flex-start;
}

.cast-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 80px;
  cursor: pointer;
  transition: transform 0.2s;
  background: #2a2b4a;
  border-radius: 8px;
  padding: 8px 4px;
  margin-bottom: 8px;
}

.cast-card:hover {
  transform: scale(1.05);
  background: #3a3b5a;
}

.cast-card .cast-avatar {
  width: 40px;
  height: 40px;
  font-size: 16px;
  margin-bottom: 4px;
}

.cast-card .cast-name {
  font-size: 12px;
  text-align: center;
  margin-bottom: 2px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 100%;
}



/* 响应式设计 */
@media (max-width: 768px) {
  .cast-section {
    padding: 16px;
    margin-bottom: 12px;
  }
  
  .section-title {
    font-size: 16px;
    margin-bottom: 8px;
  }
  
  /* 隐藏PC端布局，显示移动端布局 */
  .desktop-layout {
    display: none;
  }
  
  .mobile-layout {
    display: block;
  }
  
  .cast-horizontal {
    padding: 0;
  }
}

@media (max-width: 480px) {
  .cast-section {
    padding: 12px;
  }
  
  .cast-horizontal {
    gap: 8px;
  }
  
  .cast-card {
    width: 70px;
    padding: 6px 2px;
  }
  
  .cast-card .cast-avatar {
    width: 35px;
    height: 35px;
    font-size: 14px;
  }
  
  .cast-card .cast-name {
    font-size: 11px;
  }
  

}
</style> 