package components

import (
	"fmt"
	"log"
	"net"
	"os/exec"
	"runtime"
	"time"
)

// GetLocalIP 获取本地IP地址
func GetLocalIP() string {
	conn, err := net.Dial("udp", "8.8.8.8:80")
	if err != nil {
		return "127.0.0.1"
	}
	defer conn.Close()

	localAddr := conn.LocalAddr().(*net.UDPAddr)
	return localAddr.IP.String()
}

// StartBrowser 启动浏览器
func StartBrowser(url string) error {
	var err error
	var browserName string

	switch runtime.GOOS {
	case "darwin": // macOS
		err = exec.Command("open", url).Start()
		browserName = "默认浏览器"
	case "windows":
		err = exec.Command("rundll32", "url.dll,FileProtocolHandler", url).Start()
		browserName = "默认浏览器"
	case "linux":
		// Linux不自动打开浏览器
		log.Printf("🐧 检测到 Linux 系统，不自动启动浏览器")
		return nil
	default:
		return fmt.Errorf("不支持的操作系统: %s", runtime.GOOS)
	}

	if err != nil {
		log.Printf("❌ 无法打开 %s: %v", browserName, err)
		return err
	}

	log.Printf("✅ 已使用 %s 打开: %s", browserName, url)
	return nil
}

// StartBrowserWithServer 启动浏览器并等待服务器就绪
func StartBrowserWithServer(url string, serverReady chan bool) error {
	// 等待服务器就绪
	select {
	case <-serverReady:
		log.Println("✅ 服务器已就绪，启动浏览器")
	case <-time.After(10 * time.Second):
		log.Println("⚠️ 等待服务器超时，尝试启动浏览器")
	}

	return StartBrowser(url)
}
