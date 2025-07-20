<template>
  <div class="cast-mobile">
    <div v-if="actorsList.length > 0" class="cast-section">
      <h3 class="section-title">主要演员</h3>
      <div class="cast-scroll">
        <div class="cast-horizontal">
          <div 
            v-for="(actor, index) in actorsList" 
            :key="index" 
            class="cast-card"
            @click="selectActor(actor)"
          >
            <div class="cast-avatar">{{ actor.charAt(0) }}</div>
            <div class="cast-name">{{ actor }}</div>
            <div class="cast-role">演员</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { defineComponent, computed } from 'vue'

export default defineComponent({
  name: 'CastMobile',
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
.cast-mobile {
  width: 100%;
}

.cast-section {
  padding: 16px 0;
  border-bottom: 1px solid #272727;
}

.cast-section .section-title {
  padding: 0 16px;
  margin-bottom: 12px;
  font-size: 16px;
  font-weight: 600;
  color: #ffffff;
}

.cast-scroll {
  overflow-x: auto;
  scrollbar-width: none;
  -ms-overflow-style: none;
}

.cast-scroll::-webkit-scrollbar {
  display: none;
}

.cast-horizontal {
  display: flex;
  gap: 12px;
  padding: 0 16px;
  min-width: max-content;
}

.cast-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 80px;
  cursor: pointer;
  transition: transform 0.2s;
}

.cast-card:hover {
  transform: scale(1.05);
}

.cast-avatar {
  width: 60px;
  height: 60px;
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  border-radius: 50%;
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
  font-size: 18px;
  text-transform: uppercase;
}

.cast-name {
  font-size: 12px;
  font-weight: 500;
  color: #ffffff;
  text-align: center;
  margin-bottom: 2px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 80px;
}

.cast-role {
  font-size: 11px;
  color: #aaaaaa;
  text-align: center;
}
</style>
