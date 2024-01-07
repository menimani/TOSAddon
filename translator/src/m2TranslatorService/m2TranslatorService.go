//go:build windows
// +build windows

package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/fsnotify/fsnotify"
	"golang.org/x/sys/windows/svc"
	"golang.org/x/sys/windows/svc/eventlog"
)

type service struct {
	APIUrl   string
	APIKey   string
	WatchDir string
}

type Config struct {
	APIUrl   string `json:"api_url"`
	APIKey   string `json:"api_key"`
	WatchDir string `json:"watch_dir"`
}

const (
	serviceName   = "m2TranslatorService"
	maxRetries    = 3           // 最大リトライ回数
	retryInterval = time.Second // リトライ間隔
)

func (s *service) Execute(args []string, r <-chan svc.ChangeRequest, changes chan<- svc.Status) (svcSpecificEC bool, exitCode uint32) {
	const cmdsAccepted = svc.AcceptStop | svc.AcceptShutdown
	changes <- svc.Status{State: svc.StartPending}
	go s.run()
	changes <- svc.Status{State: svc.Running, Accepts: cmdsAccepted}
loop:
	for {
		select {
		case c := <-r:
			switch c.Cmd {
			case svc.Interrogate:
				changes <- c.CurrentStatus
			case svc.Stop, svc.Shutdown:
				break loop
			default:
				log.Printf("unexpected control request #%d\n", c)
			}
		}
	}
	changes <- svc.Status{State: svc.StopPending}
	return
}

func (s *service) run() {
	elog, err := eventlog.Open(serviceName)
	if err != nil {
		log.Fatal("Failed to open event log:", err)
	}
	defer elog.Close()

	// ファイルシステムの監視を開始
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		elog.Error(1, fmt.Sprintf("Failed to create file watcher: %v", err))
		return
	}
	defer watcher.Close()

	done := make(chan bool)

	go func() {
		for {
			elog.Info(1, "service working...")
			select {
			case event := <-watcher.Events:
				if event.Op&fsnotify.Create == fsnotify.Create {
					filename := filepath.Base(event.Name)
					if strings.HasPrefix(filename, "input_") {
						inputPath := event.Name
						outputPath := filepath.Join(s.WatchDir, strings.Replace(filename, "input_", "output_", 1))

						// ファイルを読み込んで翻訳し、出力ファイルに書き込む
						translateAndSave(inputPath, outputPath, s.APIUrl, s.APIKey)
					}
				}
			case err := <-watcher.Errors:
				elog.Error(1, fmt.Sprintf("Watcher error: %v", err))
			case <-done:
				return
			}
		}
	}()

	err = watcher.Add(s.WatchDir)
	if err != nil {
		elog.Error(1, fmt.Sprintf("Failed to add directory to watcher: %v", err))
		return
	}

	<-done // サービスが停止するまでブロック
}

// translateAndSave は指定されたファイルを読み込み、翻訳して、出力ファイルに保存する関数です。
func translateAndSave(inputPath string, outputPath string, apiUrl string, apiKey string) {

	elog, err := eventlog.Open(serviceName)
	if err != nil {
		elog.Error(1, fmt.Sprintf("Failed to open event log: %v", err))
	}
	defer elog.Close()

	// ファイルを読み込む
	requestJson, err := readFileWithRetry(inputPath)
	if err != nil {
		elog.Error(1, fmt.Sprintf("Failed to read input file: %v", err))
		return
	}

	// テキストを翻訳する
	translatedText, err := translateText(string(requestJson), apiUrl, apiKey)
	if err != nil {
		elog.Error(1, fmt.Sprintf("Failed to translate text: %v", err))
		return
	}

	// 翻訳結果を出力ファイルに書き込む
	err = os.WriteFile(outputPath, []byte(translatedText), 0644)
	if err != nil {
		elog.Error(1, fmt.Sprintf("Failed to write output file: %v", err))
		return
	}
}

func translateText(requestJson string, apiUrl string, apiKey string) (string, error) {
	elog, err := eventlog.Open(serviceName)
	if err != nil {
		log.Fatal("Failed to open event log:", err)
	}
	defer elog.Close()

	// HTTPリクエストの作成
	req, err := http.NewRequest("POST", apiUrl, bytes.NewBuffer([]byte(requestJson)))
	if err != nil {
		return "", fmt.Errorf("リクエストの作成に失敗しました: %v", err)
	}

	// ヘッダーの設定
	req.Header.Set("Authorization", "DeepL-Auth-Key "+apiKey)
	req.Header.Set("Content-Type", "application/json")

	// HTTPクライアントの作成とリクエストの送信
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("リクエストの送信に失敗しました: %v", err)
	}
	defer resp.Body.Close()

	// レスポンスボディの読み取り
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("レスポンスの読み取りに失敗しました: %v", err)
	}

	return string(body), nil
}

func main() {

	config, err := loadConfig()
	if err != nil {
		log.Fatal("Error loading config file: ", err)
		return
	}

	err = svc.Run(serviceName, &service{
		APIUrl:   config.APIUrl,
		APIKey:   config.APIKey,
		WatchDir: config.WatchDir,
	})

	if err != nil {
		log.Fatal(err)
	}
}

// config.json から設定を読み込む関数です。
func loadConfig() (Config, error) {
	var config Config
	exePath, err := os.Executable()
	if err != nil {
		log.Fatal(err)
	}
	exeDir := filepath.Dir(exePath)
	configPath := filepath.Join(exeDir, "config.json")

	configFile, err := os.Open(configPath)
	if err != nil {
		return config, err
	}
	defer configFile.Close()

	bytes, err := io.ReadAll(configFile)
	if err != nil {
		return config, err
	}

	err = json.Unmarshal(bytes, &config)
	return config, err
}

// readFileWithRetry はリトライロジックを含むファイル読み込み関数です。
func readFileWithRetry(filepath string) ([]byte, error) {
	var err error
	for i := 0; i < maxRetries; i++ {
		var data []byte
		data, err = os.ReadFile(filepath)
		if err == nil {
			return data, nil
		}

		// エラーメッセージによってはリトライしない
		if os.IsPermission(err) {
			return nil, err
		}

		// リトライ前に一定時間待機
		time.Sleep(retryInterval)
	}
	return nil, err
}
