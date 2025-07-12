package utils

import (
	"net/http"
	"strings"
)

// GetRequestIP 获取请求的真实IP地址
func GetRequestIP(r *http.Request) string {
	// 尝试从各种头部获取真实IP
	headers := []string{
		"X-Forwarded-For",
		"X-Real-IP",
		"X-Client-IP",
		"CF-Connecting-IP", // Cloudflare
		"True-Client-IP",   // Akamai
	}

	for _, header := range headers {
		if ip := r.Header.Get(header); ip != "" {
			// 如果IP包含多个值（如X-Forwarded-For），取第一个
			if strings.Contains(ip, ",") {
				ip = strings.TrimSpace(strings.Split(ip, ",")[0])
			}
			if ip != "" && ip != "unknown" {
				return ip
			}
		}
	}

	// 如果头部都没有，使用RemoteAddr
	if r.RemoteAddr != "" {
		// RemoteAddr格式通常是 "IP:PORT"，需要去掉端口
		if strings.Contains(r.RemoteAddr, ":") {
			return strings.Split(r.RemoteAddr, ":")[0]
		}
		return r.RemoteAddr
	}

	return "unknown"
}
