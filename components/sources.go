package components

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"strings"
	"time"

	"vastproxy-go/utils"

	"gopkg.in/ini.v1"
)

// VideoSource 视频源结构
type VideoSource struct {
	Code      string `json:"code"`
	Name      string `json:"name"`
	URL       string `json:"url"`
	IsDefault bool   `json:"is_default"`
}

// VideoItem 视频项目结构
type VideoItem struct {
	VodName     string `json:"vod_name"`
	VodPic      string `json:"vod_pic"`
	VodYear     string `json:"vod_year"`
	TypeName    string `json:"type_name"`
	VodScore    string `json:"vod_score"`
	VodContent  string `json:"vod_content"`
	VodActor    string `json:"vod_actor"`
	VodDirector string `json:"vod_director"`
	VodArea     string `json:"vod_area"`
	VodLang     string `json:"vod_lang"`
	VodTime     string `json:"vod_time"`
	VodRemarks  string `json:"vod_remarks"`
	VodPlayUrl  string `json:"vod_play_url"`
}

// SearchResponse 搜索响应结构
type SearchResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    []VideoItem `json:"data"`
	Count   int         `json:"count"`
}

// SourcesConfig 视频源配置管理器
type SourcesConfig struct {
	sources []VideoSource
}

// NewSourcesConfig 创建新的视频源配置管理器
func NewSourcesConfig() *SourcesConfig {
	return &SourcesConfig{
		sources: []VideoSource{},
	}
}

// LoadFromConfigFile 从配置文件加载视频源
func (sc *SourcesConfig) LoadFromConfigFile(configData []byte) error {
	sc.sources = []VideoSource{}

	// 解析INI配置文件
	cfg, err := ini.Load(configData)
	if err != nil {
		return fmt.Errorf("解析配置文件失败: %v", err)
	}

	// 从配置文件中读取 [sources] 部分
	sourcesSection := cfg.Section("sources")
	if sourcesSection == nil {
		return fmt.Errorf("配置文件中未找到 [sources] 部分")
	}

	// 用于临时存储源数据的map
	sourceMap := make(map[string]map[string]string)

	// 遍历所有配置项
	for _, key := range sourcesSection.KeyStrings() {
		value := sourcesSection.Key(key).String()

		// 解析 key 格式: code.field
		parts := strings.Split(key, ".")
		if len(parts) != 2 {
			continue // 跳过格式不正确的配置
		}

		code := parts[0]
		field := parts[1]

		// 初始化源数据map
		if sourceMap[code] == nil {
			sourceMap[code] = make(map[string]string)
		}

		// 存储字段值
		sourceMap[code][field] = strings.TrimSpace(value)
	}

	// 从map构建VideoSource对象
	for code, fields := range sourceMap {
		// 检查必需字段
		name, hasName := fields["name"]
		url, hasURL := fields["url"]
		if !hasName || !hasURL {
			continue // 跳过缺少必需字段的配置
		}

		// 解析is_default字段，默认为false
		isDefault := false
		if isDefaultStr, hasIsDefault := fields["is_default"]; hasIsDefault {
			isDefault = isDefaultStr == "1" || strings.ToLower(isDefaultStr) == "true"
		}

		source := VideoSource{
			Code:      code,
			Name:      name,
			URL:       url,
			IsDefault: isDefault,
		}

		sc.sources = append(sc.sources, source)
	}

	return nil
}

// GetSources 获取所有视频源
func (sc *SourcesConfig) GetSources() []VideoSource {
	return sc.sources
}

// GetSourceByCode 根据代码获取视频源
func (sc *SourcesConfig) GetSourceByCode(code string) *VideoSource {
	for _, source := range sc.sources {
		if source.Code == code {
			return &source
		}
	}
	return nil
}

// HandleSourcesAPI 处理 /api/sources 接口
func (sc *SourcesConfig) HandleSourcesAPI(w http.ResponseWriter, r *http.Request) {
	// 设置CORS头
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	// 处理OPTIONS请求
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	// 只允许GET请求
	if r.Method != "GET" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// 返回JSON格式的视频源列表
	response := map[string]interface{}{
		"success": true,
		"data":    sc.sources,
		"count":   len(sc.sources),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
	log.Printf("✅ /api/sources 请求 [IP:%s]", utils.GetRequestIP(r))
}

// HandleSourceSearchAPI 处理 /api/source_search 接口
func (sc *SourcesConfig) HandleSourceSearchAPI(w http.ResponseWriter, r *http.Request) {
	// 设置CORS头
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	// 处理OPTIONS请求
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	// 只允许GET请求
	if r.Method != "GET" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// 获取查询参数
	sourceCode := r.URL.Query().Get("source")
	keyword := r.URL.Query().Get("keyword")
	page := r.URL.Query().Get("page")
	isLatest := r.URL.Query().Get("latest") == "true"

	if sourceCode == "" {
		http.Error(w, "Missing source parameter", http.StatusBadRequest)
		return
	}

	// 如果不是获取最新推荐，则keyword是必需的
	if !isLatest && keyword == "" {
		http.Error(w, "Missing keyword parameter", http.StatusBadRequest)
		return
	}

	// 获取指定的视频源
	source := sc.GetSourceByCode(sourceCode)
	if source == nil {
		http.Error(w, "Source not found", http.StatusNotFound)
		return
	}

	// 执行搜索
	results, err := sc.searchSource(source, keyword, page)
	if err != nil {
		log.Printf("❌ 搜索失败: %v [IP:%s]", err, utils.GetRequestIP(r))
		http.Error(w, "Search failed", http.StatusInternalServerError)
		return
	}

	// 返回搜索结果
	response := SearchResponse{
		Success: true,
		Message: "搜索成功",
		Data:    results,
		Count:   len(results),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
	log.Printf("✅ /api/source_search 请求 [IP:%s]", utils.GetRequestIP(r))
}

// searchSource 搜索指定源
func (sc *SourcesConfig) searchSource(source *VideoSource, keyword, page string) ([]VideoItem, error) {
	// 构建请求URL
	baseURL := source.URL
	if !strings.HasSuffix(baseURL, "/") {
		baseURL += "/"
	}

	// 构建查询参数
	params := url.Values{}

	// 统一使用 videolist 接口
	params.Set("ac", "videolist")

	// 判断是搜索还是获取最新推荐
	if keyword == "" {
		// 获取最新推荐 - 使用默认参数
		params.Set("pg", "1") // 第一页
	} else {
		// 搜索 - 添加关键词
		params.Set("wd", keyword)
	}

	if page != "" {
		params.Set("pg", page)
	}

	requestURL := baseURL + "?" + params.Encode()

	// 创建HTTP客户端
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	// 创建请求
	req, err := http.NewRequest("GET", requestURL, nil)
	if err != nil {
		return nil, fmt.Errorf("创建请求失败: %v", err)
	}

	// 设置请求头
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36")
	req.Header.Set("Accept", "application/json, text/plain, */*")
	req.Header.Set("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.8")
	req.Header.Set("Cache-Control", "no-cache")

	// 发送请求
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("请求失败: %v", err)
	}
	defer resp.Body.Close()

	// 检查响应状态
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP错误: %d", resp.StatusCode)
	}

	// 读取响应内容
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("读取响应失败: %v", err)
	}

	// 解析JSON响应
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("解析JSON失败: %v", err)
	}

	// 添加调试日志
	log.Printf("🔍 API响应状态: 成功")

	// 提取视频列表
	var videos []VideoItem

	// 尝试不同的数据结构
	if list, ok := result["list"].([]interface{}); ok {
		log.Printf("✅ 找到list字段，包含 %d 个视频", len(list))
		for _, item := range list {
			if videoMap, ok := item.(map[string]interface{}); ok {
				video := VideoItem{
					VodName:     getString(videoMap, "vod_name"),
					VodPic:      getString(videoMap, "vod_pic"),
					VodYear:     getString(videoMap, "vod_year"),
					TypeName:    getString(videoMap, "type_name"),
					VodScore:    getString(videoMap, "vod_score"),
					VodContent:  getString(videoMap, "vod_content"),
					VodActor:    getString(videoMap, "vod_actor"),
					VodDirector: getString(videoMap, "vod_director"),
					VodArea:     getString(videoMap, "vod_area"),
					VodLang:     getString(videoMap, "vod_lang"),
					VodTime:     getString(videoMap, "vod_time"),
					VodRemarks:  getString(videoMap, "vod_remarks"),
					VodPlayUrl:  getString(videoMap, "vod_play_url"),
				}
				videos = append(videos, video)
			}
		}
	} else {
		log.Printf("❌ 未找到list字段或格式不正确，result keys: %v", getMapKeys(result))
	}

	return videos, nil
}

// getString 安全地从map中获取字符串值
func getString(m map[string]interface{}, key string) string {
	if val, ok := m[key]; ok {
		if str, ok := val.(string); ok {
			return str
		}
	}
	return ""
}

// getMapKeys 获取map的所有键
func getMapKeys(m map[string]interface{}) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	return keys
}
