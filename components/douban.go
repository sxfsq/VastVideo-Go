package components

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"time"

	"vastproxy-go/utils"
)

// 豆瓣 API 响应结构体
type DoubanTagsResponse struct {
	Tags []string `json:"tags"`
}

type DoubanSubject struct {
	Title string `json:"title"`
	Rate  string `json:"rate"`
	Cover string `json:"cover"`
	URL   string `json:"url"`
}

type DoubanSubjectsResponse struct {
	Subjects []DoubanSubject `json:"subjects"`
}

// DoubanHandler 处理豆瓣API请求
func DoubanHandler(w http.ResponseWriter, r *http.Request, globalConfig interface{}) {
	// 设置响应头
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Range")

	// 处理预检请求
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	// 只允许 GET 请求
	if r.Method != "GET" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// 获取查询参数
	action := r.URL.Query().Get("action")

	switch action {
	case "tags":
		handleDoubanTags(w, r)
	case "subjects":
		handleDoubanSubjects(w, r)
	default:
		// 返回 API 使用说明
		apiInfo := map[string]interface{}{
			"service": "豆瓣 API 代理服务",
			"version": "1.0.0",
			"endpoints": map[string]interface{}{
				"获取标签": map[string]string{
					"url": "/douban?action=tags&type=movie",
					"参数":  "type: movie 或 tv",
				},
				"获取推荐": map[string]string{
					"url": "/douban?action=subjects&type=movie&tag=热门&page_limit=16&page_start=0",
					"参数":  "type: movie 或 tv, tag: 标签名, page_limit: 每页数量, page_start: 起始位置",
				},
			},
			"example": map[string]string{
				"获取电影标签":  "/douban?action=tags&type=movie",
				"获取电视剧标签": "/douban?action=tags&type=tv",
				"获取热门电影":  "/douban?action=subjects&type=movie&tag=热门&page_limit=16&page_start=0",
				"获取美剧推荐":  "/douban?action=subjects&type=tv&tag=美剧&page_limit=16&page_start=0",
			},
		}

		json.NewEncoder(w).Encode(apiInfo)
	}
}

// handleDoubanTags 处理豆瓣标签请求
func handleDoubanTags(w http.ResponseWriter, r *http.Request) {
	mediaType := r.URL.Query().Get("type")
	if mediaType == "" {
		mediaType = "movie" // 默认电影
	}

	if mediaType != "movie" && mediaType != "tv" {
		http.Error(w, "Invalid type parameter. Use 'movie' or 'tv'", http.StatusBadRequest)
		return
	}

	// 构建豆瓣 API URL
	doubanURL := fmt.Sprintf("https://movie.douban.com/j/search_tags?type=%s", mediaType)

	// 通过代理获取数据
	data, err := fetchDoubanData(doubanURL)
	if err != nil {
		log.Printf("❌ 获取豆瓣标签失败: %v [IP:%s]", err, utils.GetRequestIP(r))
		http.Error(w, "Failed to fetch douban tags", http.StatusInternalServerError)
		return
	}

	// 返回数据
	w.WriteHeader(http.StatusOK)
	w.Write(data)
	log.Printf("✅ 返回豆瓣 %s 标签数据 [IP:%s]", mediaType, utils.GetRequestIP(r))
}

// handleDoubanSubjects 处理豆瓣推荐请求
func handleDoubanSubjects(w http.ResponseWriter, r *http.Request) {
	// 获取查询参数
	mediaType := r.URL.Query().Get("type")
	tag := r.URL.Query().Get("tag")
	pageLimit := r.URL.Query().Get("page_limit")
	pageStart := r.URL.Query().Get("page_start")

	// 参数验证和默认值
	if mediaType == "" {
		mediaType = "movie"
	}
	if mediaType != "movie" && mediaType != "tv" {
		http.Error(w, "Invalid type parameter. Use 'movie' or 'tv'", http.StatusBadRequest)
		return
	}

	if tag == "" {
		tag = "热门"
	}

	if pageLimit == "" {
		pageLimit = "16"
	}

	if pageStart == "" {
		pageStart = "0"
	}

	// 构建豆瓣 API URL
	doubanURL := fmt.Sprintf("https://movie.douban.com/j/search_subjects?type=%s&tag=%s&sort=recommend&page_limit=%s&page_start=%s",
		mediaType, url.QueryEscape(tag), pageLimit, pageStart)

	// 通过代理获取数据
	data, err := fetchDoubanData(doubanURL)
	if err != nil {
		log.Printf("❌ 获取豆瓣推荐失败: %v [IP:%s]", err, utils.GetRequestIP(r))
		http.Error(w, "Failed to fetch douban subjects", http.StatusInternalServerError)
		return
	}

	// 返回数据
	w.WriteHeader(http.StatusOK)
	w.Write(data)
	log.Printf("✅ 返回豆瓣 %s 推荐数据 (标签: %s, 数量: %s) [IP:%s]", mediaType, tag, pageLimit, utils.GetRequestIP(r))
}

// fetchDoubanData 获取豆瓣数据
func fetchDoubanData(targetURL string) ([]byte, error) {
	// 构建请求
	req, err := http.NewRequest("GET", targetURL, nil)
	if err != nil {
		return nil, fmt.Errorf("构建请求失败: %v", err)
	}

	// 设置请求头
	req.Header.Set("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36")
	req.Header.Set("Referer", "https://movie.douban.com/")
	req.Header.Set("Accept", "application/json, text/plain, */*")

	// 创建客户端
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

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

	return body, nil
}
