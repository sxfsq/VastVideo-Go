import { ref, onMounted } from 'vue'
import api from '../services/api.js'

const videoSources = ref([])
const selectedSources = ref([])

export function useVideoSources() {
  const fetchVideoSources = async () => {
    try {
      console.log('正在从API获取视频源列表...')
      const data = await api.sources.list()
      
      if (data.success && data.data) {
        videoSources.value = data.data
        console.log('视频源列表获取成功:', videoSources.value.length, '个源')
        
        // 从本地存储加载已选择的源
        loadSelectedSources()
        
        // 验证已选择的源是否仍然存在
        const validSources = selectedSources.value.filter(code => 
          videoSources.value.some(src => src.code === code)
        )
        if (validSources.length !== selectedSources.value.length) {
          console.log('部分已选择的源不存在，更新选择列表')
          selectedSources.value = validSources
          saveSelectedSources()
        }
        
        // 如果没有任何选择的源，使用后端配置的默认源
        if (selectedSources.value.length === 0 && videoSources.value.length > 0) {
          const defaultSources = videoSources.value.filter(src => src.is_default).map(src => src.code)
          if (defaultSources.length > 0) {
            selectedSources.value = defaultSources
            console.log('使用后端配置的默认源:', defaultSources)
          } else {
            // 如果没有配置默认源，使用前两个源作为备用
            selectedSources.value = videoSources.value.slice(0, 2).map(src => src.code)
            console.log('使用备用默认源:', selectedSources.value)
          }
          saveSelectedSources()
        }
      } else {
        throw new Error('API返回数据格式错误')
      }
    } catch (error) {
      console.error('获取视频源列表失败:', error)
      // 使用默认源列表作为备用
      videoSources.value = [
        { code: 'bfzy', name: '暴风资源', url: 'https://bfzyapi.com/api.php/provide/vod', is_default: true },
        { code: 'dyttzy', name: '电影天堂资源', url: 'http://caiji.dyttzyapi.com/api.php/provide/vod', is_default: true }
      ]
      loadSelectedSources()
      if (selectedSources.value.length === 0) {
        selectedSources.value = ['bfzy', 'dyttzy']
        saveSelectedSources()
      }
    }
  }
  
  const loadSelectedSources = () => {
    const stored = localStorage.getItem('vastvideo_sources_mobile')
    if (stored) {
      try {
        selectedSources.value = JSON.parse(stored)
      } catch (error) {
        console.error('解析已选择的视频源失败:', error)
        selectedSources.value = []
      }
    }
  }
  
  const saveSelectedSources = () => {
    localStorage.setItem('vastvideo_sources_mobile', JSON.stringify(selectedSources.value))
    console.log('✅ 视频源选择已保存:', selectedSources.value)
  }
  
  return {
    videoSources,
    selectedSources,
    fetchVideoSources,
    saveSelectedSources
  }
} 