package utils

import (
	"fmt"
	"log"

	"gopkg.in/ini.v1"
)

// Config 配置结构体
type Config struct {
	Server struct {
		Port    string `ini:"port"`
		Host    string `ini:"host"`
		Timeout int    `ini:"timeout"`
	} `ini:"server"`
	Proxy struct {
		UserAgent          string `ini:"user_agent"`
		MaxRedirects       int    `ini:"max_redirects"`
		DisableCompression bool   `ini:"disable_compression"`
	} `ini:"proxy"`
	Browser struct {
		AutoOpen bool `ini:"auto_open"`
	} `ini:"browser"`
	Logging struct {
		LogFile       string `ini:"log_file"`
		LogLevel      string `ini:"log_level"`
		ConsoleOutput bool   `ini:"console_output"`
		FileOutput    bool   `ini:"file_output"`
	} `ini:"logging"`
	Security struct {
		CorsEnabled    bool   `ini:"cors_enabled"`
		CorsOrigin     string `ini:"cors_origin"`
		AllowedMethods string `ini:"allowed_methods"`
		AllowedHeaders string `ini:"allowed_headers"`
	} `ini:"security"`
	Features struct {
		HealthCheck  bool `ini:"health_check"`
		InfoPage     bool `ini:"info_page"`
		ProxyService bool `ini:"proxy_service"`
		DoubanAPI    bool `ini:"douban_api"`
	} `ini:"features"`
}

// LoadConfigFromData 从配置数据加载配置
func LoadConfigFromData(configData []byte) (*Config, error) {
	cfg, err := ini.Load(configData)
	if err != nil {
		return nil, fmt.Errorf("解析配置文件失败: %v", err)
	}

	var config Config
	err = cfg.MapTo(&config)
	if err != nil {
		return nil, fmt.Errorf("映射配置失败: %v", err)
	}

	log.Printf("✅ 配置文件加载成功")
	return &config, nil
}
