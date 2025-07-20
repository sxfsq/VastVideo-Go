import { ref } from 'vue'

const toasts = ref([])
let toastId = 0

export function useToast() {
  const showToast = (message, type = 'info', duration = 3000) => {
    const id = ++toastId
    const toast = {
      id,
      message,
      type,
      show: false
    }
    
    toasts.value.push(toast)
    
    // 下一帧显示动画
    setTimeout(() => {
      const toastElement = toasts.value.find(t => t.id === id)
      if (toastElement) {
        toastElement.show = true
      }
    }, 10)
    
    // 自动移除
    setTimeout(() => {
      removeToast(id)
    }, duration)
    
    // 触发页面上的toast显示
    createToastElement(message, type, duration)
    
    return id
  }
  
  const removeToast = (id) => {
    const index = toasts.value.findIndex(t => t.id === id)
    if (index > -1) {
      toasts.value.splice(index, 1)
    }
  }
  
  const createToastElement = (message, type, duration) => {
    // 创建toast容器（如果不存在）
    let container = document.getElementById('toast-container')
    if (!container) {
      container = document.createElement('div')
      container.id = 'toast-container'
      container.style.cssText = `
        position: fixed;
        top: 70px;
        left: 50%;
        transform: translateX(-50%);
        z-index: 10001;
        pointer-events: none;
      `
      document.body.appendChild(container)
    }
    
    // 创建toast元素
    const toast = document.createElement('div')
    toast.className = `toast ${type}`
    toast.textContent = message
    toast.style.cssText = `
      background: rgba(35, 36, 74, 0.95);
      backdrop-filter: blur(10px);
      border: 1px solid rgba(108, 99, 255, 0.2);
      border-radius: 12px;
      padding: 12px 20px;
      margin-bottom: 8px;
      color: #fff;
      font-size: 14px;
      font-weight: 500;
      text-align: center;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
      max-width: 300px;
      word-wrap: break-word;
      opacity: 0;
      transform: translateY(-20px);
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      pointer-events: auto;
    `
    
    // 设置不同类型的边框颜色
    switch (type) {
      case 'success':
        toast.style.borderColor = 'rgba(107, 207, 127, 0.3)'
        break
      case 'warning':
        toast.style.borderColor = 'rgba(255, 214, 61, 0.3)'
        break
      case 'error':
        toast.style.borderColor = 'rgba(255, 107, 107, 0.3)'
        break
      default:
        toast.style.borderColor = 'rgba(108, 99, 255, 0.3)'
    }
    
    container.appendChild(toast)
    
    // 显示动画
    setTimeout(() => {
      toast.style.opacity = '1'
      toast.style.transform = 'translateY(0)'
    }, 10)
    
    // 自动移除
    setTimeout(() => {
      toast.style.opacity = '0'
      toast.style.transform = 'translateY(-20px)'
      setTimeout(() => {
        if (container.contains(toast)) {
          container.removeChild(toast)
        }
      }, 300)
    }, duration)
  }
  
  return {
    toasts,
    showToast,
    removeToast
  }
} 