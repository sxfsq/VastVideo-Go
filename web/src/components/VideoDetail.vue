<template>
  <!-- 桌面端布局 -->
  <VideoDetailDesktop 
    v-if="isDesktop"
    :video-data="videoData"
    @video-select="handleVideoSelect"
    @search="$emit('search', $event)"
  />
  
  <!-- 移动端布局 -->
  <VideoDetailMobile 
    v-else
    :video-data="videoData"
    @go-back="goBack"
    @video-select="handleVideoSelect"
    @search="$emit('search', $event)"
  />
</template>

<script>
import { defineComponent, ref, onMounted, onUnmounted } from 'vue'
import VideoDetailDesktop from './VideoDetailDesktop.vue'
import VideoDetailMobile from './VideoDetailMobile.vue'

export default defineComponent({
  name: 'VideoDetail',
  components: {
    VideoDetailDesktop,
    VideoDetailMobile
  },
  props: {
    videoData: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  emits: ['go-back', 'video-select'],
  setup(props, { emit }) {
    const isDesktop = ref(false)
    
    const checkScreenSize = () => {
      isDesktop.value = window.innerWidth >= 768
    }
    
    const goBack = () => {
      emit('go-back')
    }

    const handleVideoSelect = (video) => {
      emit('video-select', video)
    }

    onMounted(() => {
      checkScreenSize()
      window.addEventListener('resize', checkScreenSize)
    })

    onUnmounted(() => {
      window.removeEventListener('resize', checkScreenSize)
    })

    return {
      isDesktop,
      goBack,
      handleVideoSelect
    }
  }
})
</script>

<style scoped>
/* 智能布局容器组件，无需额外样式 */
</style>
