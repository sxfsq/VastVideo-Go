package main

import (
	"embed"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"runtime"
	"vastproxy-go/components"
	"vastproxy-go/utils"
)

//go:embed html/index_mobile.html html/about.html
var htmlContent embed.FS

//go:embed config/config.ini
var ConfigContent embed.FS

var GlobalConfig *utils.Config

func main() {
	// 加载配置文件
	if err := LoadConfig(); err != nil {
		log.Fatalf("❌ 加载配置文件失败: %v", err)
	}

	// 初始化视频源配置
	sourcesConfig := components.NewSourcesConfig()
	configData, err := ConfigContent.ReadFile("config/config.ini")
	if err != nil {
		log.Fatalf("❌ 读取配置文件失败: %v", err)
	}
	if err := sourcesConfig.LoadFromConfigFile(configData); err != nil {
		log.Fatalf("❌ 加载视频源配置失败: %v", err)
	}
	log.Printf("✅ 视频源配置加载成功，共 %d 个源", len(sourcesConfig.GetSources()))

	// 定义命令行参数
	var (
		noOpen = flag.Bool("no-open", !GlobalConfig.Browser.AutoOpen, "不自动打开浏览器")
		port   = flag.String("port", GlobalConfig.Server.Port, "服务端口")
	)
	flag.Parse()

	// 设置日志输出
	var outputs []io.Writer
	if GlobalConfig.Logging.ConsoleOutput {
		outputs = append(outputs, os.Stdout)
	}
	if GlobalConfig.Logging.FileOutput {
		logFile, err := os.OpenFile(GlobalConfig.Logging.LogFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
		if err != nil {
			log.Fatalf("无法打开日志文件: %v", err)
		}
		outputs = append(outputs, logFile)
	}

	if len(outputs) > 0 {
		log.SetOutput(io.MultiWriter(outputs...))
	}

	// 检查并处理端口占用
	log.Printf("🔍 检查端口 %s 是否可用...", *port)
	if err := checkAndKillPortProcess(*port); err != nil {
		log.Fatalf("❌ 端口检查失败: %v", err)
	}

	// 注册路由
	if GlobalConfig.Features.ProxyService {
		http.HandleFunc("/proxy", func(w http.ResponseWriter, r *http.Request) {
			components.ProxyHandler(w, r, GlobalConfig)
		})
	}
	if GlobalConfig.Features.HealthCheck {
		http.HandleFunc("/health", healthHandler)
	}
	if GlobalConfig.Features.InfoPage {
		http.HandleFunc("/info", infoHandler)
		http.HandleFunc("/mobile", mobileHandler)
		http.HandleFunc("/about", aboutHandler)
		http.HandleFunc("/about.html", aboutHandler)
		http.HandleFunc("/", indexHandler)
	}
	if GlobalConfig.Features.DoubanAPI {
		http.HandleFunc("/douban", func(w http.ResponseWriter, r *http.Request) {
			components.DoubanHandler(w, r, GlobalConfig)
		})
	}

	// 添加视频源API路由
	http.HandleFunc("/api/sources", sourcesConfig.HandleSourcesAPI)
	http.HandleFunc("/api/source_search", sourcesConfig.HandleSourceSearchAPI)

	// 获取本地IP地址
	localIP := components.GetLocalIP()

	log.Println("🚀 VastProxy-Go 代理服务启动中...")
	log.Printf("📍 服务地址: http://%s:%s", localIP, *port)
	if GlobalConfig.Features.HealthCheck {
		log.Printf("🔗 健康检查: http://%s:%s/health", GlobalConfig.Server.Host, *port)
	}
	if GlobalConfig.Features.InfoPage {
		log.Printf("📄 信息页面: http://%s:%s/info", GlobalConfig.Server.Host, *port)
		log.Printf("📱 移动端页面: http://%s:%s/mobile", GlobalConfig.Server.Host, *port)
		log.Printf("🏠 首页(移动端): http://%s:%s/", GlobalConfig.Server.Host, *port)
	}
	if GlobalConfig.Features.DoubanAPI {
		log.Printf("🎬 豆瓣API: http://%s:%s/douban", GlobalConfig.Server.Host, *port)
	}
	log.Printf("🎯 视频源API: http://%s:%s/api/sources", GlobalConfig.Server.Host, *port)
	log.Printf("📝 日志文件: %s", GlobalConfig.Logging.LogFile)
	log.Println(strings.Repeat("=", 50))

	// 启动服务器
	go func() {
		err := http.ListenAndServe(GlobalConfig.Server.Host+":"+*port, nil)
		if err != nil {
			log.Fatalf("服务启动失败: %v", err)
		}
	}()

	// 等待一秒确保服务器启动
	time.Sleep(1 * time.Second)

	// 根据参数决定是否打开浏览器
	if !*noOpen {
		homeURL := fmt.Sprintf("http://%s:%s/", localIP, *port)

		// 检查操作系统，在Windows和macOS上自动启动浏览器
		if runtime.GOOS == "windows" || runtime.GOOS == "darwin" {
			log.Printf("🌐 检测到 %s 系统，自动启动浏览器...", runtime.GOOS)
			serverReady := make(chan bool, 1)

			// 启动浏览器
			go func() {
				// 等待服务器就绪
				time.Sleep(2 * time.Second)
				serverReady <- true

				if err := components.StartBrowserWithServer(homeURL, serverReady); err != nil {
					log.Printf("❌ 浏览器启动失败: %v", err)
				}
			}()
		} else {
			log.Printf("🐧 检测到 Linux 系统，不自动启动浏览器")
			log.Printf("📱 请手动访问: %s", homeURL)
		}
	} else {
		log.Println("🚫 已禁用自动打开浏览器")
		log.Printf("📱 访问地址: http://%s:%s/", localIP, *port)
	}

	// 设置信号处理
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// 保持主程序运行，等待信号或浏览器关闭
	select {
	case sig := <-sigChan:
		log.Printf("📴 收到信号 %v，正在退出...", sig)
	case <-time.After(24 * time.Hour): // 防止无限等待
		log.Println("⏰ 程序运行超时，正在退出...")
	}
}

// LoadConfig 加载配置文件
func LoadConfig() error {
	configData, err := ConfigContent.ReadFile("config/config.ini")
	if err != nil {
		return fmt.Errorf("读取配置文件失败: %v", err)
	}

	config, err := utils.LoadConfigFromData(configData)
	if err != nil {
		return err
	}

	GlobalConfig = config
	return nil
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"healthy","service":"VastProxy-Go","version":"1.0.0","timestamp":` +
		fmt.Sprintf("%d", time.Now().Unix()) + `}`))
}

func infoHandler(w http.ResponseWriter, r *http.Request) {
	// 只处理 /info 路径请求
	if r.URL.Path != "/info" {
		http.NotFound(w, r)
		return
	}

	// 设置响应头
	w.Header().Set("Content-Type", "text/html; charset=utf-8")

	// 读取嵌入的 HTML 文件
	content, err := htmlContent.ReadFile("html/info.html")
	if err != nil {
		log.Printf("❌ 读取嵌入的 HTML 文件失败: %v [IP:%s]", err, utils.GetRequestIP(r))
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	// 返回 HTML 内容
	w.Write(content)
	log.Printf("📄 返回信息页面 HTML [IP:%s]", utils.GetRequestIP(r))
}

func mobileHandler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/mobile" {
		http.Redirect(w, r, "/mobile", http.StatusFound)
		return
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")

	content, err := htmlContent.ReadFile("html/index_mobile.html")
	if err != nil {
		log.Printf("❌ 读取 html/index_mobile.html 失败: %v [IP:%s]", err, utils.GetRequestIP(r))
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	w.Write(content)
	log.Printf("📱 返回移动端页面 html/index_mobile.html [IP:%s]", utils.GetRequestIP(r))
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.Redirect(w, r, "/", http.StatusFound)
		return
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")

	// 直接返回移动端页面，取消客户端类型判断
	content, err := htmlContent.ReadFile("html/index_mobile.html")
	if err != nil {
		log.Printf("❌ 读取 html/index_mobile.html 失败: %v [IP:%s]", err, utils.GetRequestIP(r))
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}
	w.Write(content)
	log.Printf("📱 返回移动端页面 html/index_mobile.html [IP:%s]", utils.GetRequestIP(r))
}

func aboutHandler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/about" && r.URL.Path != "/about.html" {
		http.NotFound(w, r)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	content, err := htmlContent.ReadFile("html/about.html")
	if err != nil {
		log.Printf("❌ 读取 html/about.html 失败: %v [IP:%s]", err, utils.GetRequestIP(r))
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}
	w.Write(content)
	log.Printf("📄 返回关于页面 html/about.html [IP:%s]", utils.GetRequestIP(r))
}

// checkAndKillPortProcess 检查端口是否被占用，如果被占用则杀死相关进程
func checkAndKillPortProcess(port string) error {
	// 尝试监听端口来检查是否被占用
	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Printf("⚠️  端口 %s 被占用，正在查找并杀死相关进程...", port)

		// 根据操作系统查找并杀死占用端口的进程
		switch runtime.GOOS {
		case "darwin", "linux":
			return killProcessOnPortUnix(port)
		case "windows":
			return killProcessOnPortWindows(port)
		default:
			return fmt.Errorf("不支持的操作系统: %s", runtime.GOOS)
		}
	}

	// 端口可用，关闭监听器
	listener.Close()
	log.Printf("✅ 端口 %s 可用", port)
	return nil
}

// killProcessOnPortUnix 在Unix系统上杀死占用指定端口的进程
func killProcessOnPortUnix(port string) error {
	cmd := exec.Command("lsof", "-ti", ":"+port)
	output, err := cmd.Output()
	if err != nil {
		log.Printf("⚠️  未找到占用端口 %s 的进程，可能端口被系统保留", port)
		return nil
	}
	pids := strings.Fields(string(output))
	if len(pids) == 0 {
		log.Printf("✅ 端口 %s 已释放", port)
		return nil
	}
	for _, pid := range pids {
		pid = strings.TrimSpace(pid)
		if pid == "" {
			continue
		}
		log.Printf("🔫 正在杀死进程 PID: %s", pid)
		killCmd := exec.Command("kill", "-9", pid)
		if err := killCmd.Run(); err != nil {
			log.Printf("⚠️  杀死进程 %s 失败: %v", pid, err)
		} else {
			log.Printf("✅ 成功杀死进程 PID: %s", pid)
		}
	}
	time.Sleep(500 * time.Millisecond)
	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		return fmt.Errorf("端口 %s 仍然被占用，无法启动服务", port)
	}
	listener.Close()
	log.Printf("✅ 端口 %s 已成功释放并可用", port)
	return nil
}

// killProcessOnPortWindows 在Windows系统上杀死占用指定端口的进程
func killProcessOnPortWindows(port string) error {
	cmd := exec.Command("netstat", "-ano")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("执行 netstat 失败: %v", err)
	}
	lines := strings.Split(string(output), "\n")
	var pids []string
	for _, line := range lines {
		if strings.Contains(line, ":"+port) && strings.Contains(line, "LISTENING") {
			fields := strings.Fields(line)
			if len(fields) >= 5 {
				pid := fields[len(fields)-1]
				if pid != "0" {
					pids = append(pids, pid)
				}
			}
		}
	}
	if len(pids) == 0 {
		log.Printf("✅ 端口 %s 已释放", port)
		return nil
	}
	for _, pid := range pids {
		log.Printf("🔫 正在杀死进程 PID: %s", pid)
		killCmd := exec.Command("taskkill", "/F", "/PID", pid)
		if err := killCmd.Run(); err != nil {
			log.Printf("⚠️  杀死进程 %s 失败: %v", pid, err)
		} else {
			log.Printf("✅ 成功杀死进程 PID: %s", pid)
		}
	}
	time.Sleep(500 * time.Millisecond)
	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		return fmt.Errorf("端口 %s 仍然被占用，无法启动服务", port)
	}
	listener.Close()
	log.Printf("✅ 端口 %s 已成功释放并可用", port)
	return nil
}
