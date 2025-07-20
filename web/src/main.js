import { createApp } from 'vue'
import App from './App.vue'

console.log('VastVideo-Go Vue App 启动中...')

// 添加初始加载状态
const appEl = document.getElementById('app')
if (appEl) {
  appEl.classList.add('loading')
}

// 创建Vue应用实例
const app = createApp(App)

// 全局错误处理
app.config.errorHandler = (err, vm, info) => {
  console.error('Vue应用错误:', err)
  console.error('错误信息:', info)
  console.error('组件实例:', vm)
}

// 挂载应用
app.mount('#app')

console.log('VastVideo-Go Vue App 启动完成!')

// 立即移除loading状态，显示应用
setTimeout(() => {
  if (appEl) {
    appEl.classList.remove('loading')
    appEl.classList.add('loaded')
  }
}, 100)

// 页面加载完成后的处理
window.addEventListener('load', () => {
  console.log('页面完全加载完成')
  
  // 确保页面滚动到顶部
  window.scrollTo(0, 0)
  
  // 确保应用完全可见
  const appEl = document.getElementById('app')
  if (appEl) {
    appEl.classList.remove('loading')
    appEl.classList.add('loaded')
  }
})

// 页面可见性变化处理
document.addEventListener('visibilitychange', () => {
  if (!document.hidden) {
    console.log('页面重新可见')
  }
})

// 窗口焦点变化处理
window.addEventListener('focus', () => {
  console.log('窗口获得焦点')
})

// 网络状态监听
window.addEventListener('online', () => {
  console.log('网络连接恢复')
})

window.addEventListener('offline', () => {
  console.log('网络连接断开')
}) 