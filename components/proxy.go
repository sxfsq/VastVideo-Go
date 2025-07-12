package components

import (
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"vastproxy-go/utils"
)

// ProxyHandler 处理代理请求
func ProxyHandler(w http.ResponseWriter, r *http.Request, globalConfig interface{}) {
	startTime := time.Now()
	fullQuery := r.URL.RawQuery
	log.Printf("🔍 完整查询字符串: %s [IP:%s]", fullQuery, utils.GetRequestIP(r))

	urlParam := r.URL.Query().Get("url")
	if urlParam == "" {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("Missing url param"))
		return
	}

	decodedURL, err := url.QueryUnescape(urlParam)
	if err != nil {
		log.Printf("❌ URL解码失败: %v [IP:%s]", err, utils.GetRequestIP(r))
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("Invalid URL encoding"))
		return
	}
	log.Printf("🔍 解码后的URL: %s [IP:%s]", decodedURL, utils.GetRequestIP(r))
	log.Printf("📋 来源IP: %s [IP:%s]", r.RemoteAddr, utils.GetRequestIP(r))
	log.Printf("🔗 最终请求URL: %s [IP:%s]", decodedURL, utils.GetRequestIP(r))

	// 构建请求
	req, err := http.NewRequest("GET", decodedURL, nil)
	if err != nil {
		log.Printf("❌ 构建请求失败: %v [IP:%s]", err, utils.GetRequestIP(r))
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("Invalid target URL"))
		return
	}

	// 复制前端请求头，排除Host、Content-Length、Content-Encoding
	for k, v := range r.Header {
		kLower := strings.ToLower(k)
		if kLower == "host" || kLower == "content-length" || kLower == "content-encoding" {
			continue
		}
		for _, vv := range v {
			req.Header.Add(k, vv)
		}
	}
	// 设置 User-Agent
	if req.Header.Get("User-Agent") == "" {
		req.Header.Set("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36")
	}
	// 强制禁用压缩
	req.Header.Set("Accept-Encoding", "identity")

	client := &http.Client{
		Timeout: 30 * time.Second,
	}
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("❌ 代理请求失败: %v [IP:%s]", err, utils.GetRequestIP(r))
		if os.IsTimeout(err) {
			w.WriteHeader(http.StatusGatewayTimeout)
			w.Write([]byte("Request timeout"))
		} else {
			w.WriteHeader(http.StatusBadGateway)
			w.Write([]byte("Proxy error: " + err.Error()))
		}
		return
	}
	defer resp.Body.Close()

	requestTime := time.Since(startTime).Seconds()
	log.Printf("✅ 目标服务器响应: %d (%.2fs) [IP:%s]", resp.StatusCode, requestTime, utils.GetRequestIP(r))
	log.Printf("📥 响应头: %+v [IP:%s]", resp.Header, utils.GetRequestIP(r))
	log.Printf("🔗 最终URL: %s [IP:%s]", resp.Request.URL.String(), utils.GetRequestIP(r))

	// 读取前1000字节用于日志
	preview := make([]byte, 1000)
	n, _ := resp.Body.Read(preview)
	log.Printf("📄 响应内容预览: %s... [IP:%s]", string(preview[:n]), utils.GetRequestIP(r))

	// 重新构造响应体（包含预览和剩余内容）
	bodyReader := io.MultiReader(strings.NewReader(string(preview[:n])), resp.Body)

	// 设置响应头，移除Content-Encoding、Transfer-Encoding、Content-Length
	for k, v := range resp.Header {
		kLower := strings.ToLower(k)
		if kLower == "transfer-encoding" || kLower == "content-encoding" || kLower == "content-length" {
			continue
		}
		for _, vv := range v {
			w.Header().Add(k, vv)
		}
	}
	// 添加CORS头
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Range")

	// JSON响应类型修正
	if strings.Contains(resp.Header.Get("Content-Type"), "application/json") {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
	}

	w.WriteHeader(resp.StatusCode)
	// 流式写入响应体
	_, err = io.Copy(w, bodyReader)
	if err != nil {
		log.Printf("⚠️ 流式传输异常: %v [IP:%s]", err, utils.GetRequestIP(r))
	}
	log.Printf("✅ 完成流式返回内容 [IP:%s]", utils.GetRequestIP(r))
}
