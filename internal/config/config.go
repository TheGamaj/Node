package config

import (
	"bufio"
	"errors"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
)

const NodeVersionFallback = "is.0.0.1"

type Settings struct {
	AppName     string
	InstallMode string
	ServiceHost string
	ServicePort int

	XrayAPIHost        string
	XrayAPIPort        int
	GamajDataDir     string
	XrayExecutablePath string
	XrayAssetsPath     string
	XrayLogDir         string

	NodeVersion string

	SSLCertFile       string
	SSLKeyFile        string
	SSLClientCertFile string

	Debug    bool
	Inbounds []string
}

func LoadDotEnv(path string) {
	file, err := os.Open(path)
	if err != nil {
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if strings.HasPrefix(line, "export ") {
			line = strings.TrimSpace(strings.TrimPrefix(line, "export "))
		}
		key, value, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		key = strings.TrimSpace(key)
		value = strings.TrimSpace(value)
		value = strings.Trim(value, `"'`)
		if key != "" {
			if _, exists := os.LookupEnv(key); exists {
				continue
			}
			_ = os.Setenv(key, value)
		}
	}
}

func Load() Settings {
	LoadDotEnv(".env")
	dataDir := getString("GAMAJ_DATA_DIR", "/var/lib/gamaj-node")
	serviceHost := getString("GAMAJ_NODE_SERVICE_HOST", "0.0.0.0")
	servicePort := getInt("GAMAJ_NODE_SERVICE_PORT", 62050)
	xrayAPIPort := getInt("GAMAJ_NODE_XRAY_API_PORT", 62051)
	return Settings{
		AppName:            getString("GAMAJ_NODE_APP_NAME", "gamaj-node"),
		InstallMode:        getInstallMode(),
		ServiceHost:        serviceHost,
		ServicePort:        servicePort,
		XrayAPIHost:        getString("GAMAJ_NODE_XRAY_API_HOST", "0.0.0.0"),
		XrayAPIPort:        xrayAPIPort,
		GamajDataDir:     dataDir,
		XrayExecutablePath: resolveXrayExecutablePath(dataDir),
		XrayAssetsPath:     resolveXrayAssetsPath(dataDir),
		XrayLogDir:         strings.TrimSpace(getString("GAMAJ_NODE_XRAY_LOG_DIR", "")),

		NodeVersion: getString("GAMAJ_NODE_VERSION", NodeVersionFallback),

		SSLCertFile:       getString("GAMAJ_NODE_SSL_CERT_FILE", "/var/lib/gamaj-node/ssl_cert.pem"),
		SSLKeyFile:        getString("GAMAJ_NODE_SSL_KEY_FILE", "/var/lib/gamaj-node/ssl_key.pem"),
		SSLClientCertFile: getString("GAMAJ_NODE_SSL_CLIENT_CERT_FILE", ""),

		Debug:    getBool("GAMAJ_DEBUG", false),
		Inbounds: getCSV("GAMAJ_NODE_INBOUNDS"),
	}
}

func resolveXrayExecutablePath(dataDir string) string {
	persistentExecutable := filepath.Join(dataDir, "xray-core", executableName("xray"))
	if fileExists(persistentExecutable) {
		return persistentExecutable
	}
	if configured := getString("GAMAJ_XRAY_EXECUTABLE_PATH", ""); configured != "" {
		return configured
	}
	return "/usr/local/bin/xray"
}

func resolveXrayAssetsPath(dataDir string) string {
	for _, candidate := range []string{
		filepath.Join(dataDir, "assets"),
		filepath.Join(dataDir, "xray-core"),
	} {
		if fileExists(filepath.Join(candidate, "geoip.dat")) || fileExists(filepath.Join(candidate, "geosite.dat")) {
			return candidate
		}
	}
	if configured := getString("GAMAJ_XRAY_ASSETS_PATH", ""); configured != "" {
		return configured
	}
	return "/usr/local/share/xray"
}

func executableName(name string) string {
	if runtime.GOOS == "windows" {
		return name + ".exe"
	}
	return name
}

func fileExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

func ParseBool(value string) (bool, error) {
	normalized := strings.ToLower(strings.TrimSpace(value))
	switch normalized {
	case "1", "true", "yes", "y", "on", "debug":
		return true, nil
	case "0", "false", "no", "n", "off", "", "release", "prod", "production":
		return false, nil
	default:
		return false, errors.New("invalid truth value: " + value)
	}
}

func getString(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return strings.TrimSpace(value)
	}
	return fallback
}

// getInstallMode reports the node install flavour. Gamaj Node ships as a single
// native binary/service install, so "binary" is the only valid mode.
func getInstallMode() string {
	mode := strings.ToLower(strings.TrimSpace(getString("GAMAJ_NODE_INSTALL_MODE", "binary")))
	if mode == "" {
		return "binary"
	}
	return mode
}

func getInt(key string, fallback int) int {
	value, ok := os.LookupEnv(key)
	if !ok {
		return fallback
	}
	parsed, err := strconv.Atoi(strings.TrimSpace(value))
	if err != nil {
		return fallback
	}
	return parsed
}

func getBool(key string, fallback bool) bool {
	value, ok := os.LookupEnv(key)
	if !ok {
		return fallback
	}
	parsed, err := ParseBool(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func getCSV(key string) []string {
	return getCSVDefault(key, "")
}

func getCSVDefault(key, fallback string) []string {
	value := getString(key, fallback)
	if strings.TrimSpace(value) == "" {
		return nil
	}
	parts := strings.Split(value, ",")
	items := make([]string, 0, len(parts))
	for _, part := range parts {
		item := strings.TrimSpace(part)
		if item != "" {
			items = append(items, item)
		}
	}
	return items
}
