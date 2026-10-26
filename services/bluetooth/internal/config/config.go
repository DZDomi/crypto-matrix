package config

type Config struct {
	AppName string
	Debug   bool

	WifiServiceGrpcPath       string
	DisplayServiceGrpcPath    string
	MarketDataServiceGrpcPath string

	AdapterId      string
	BaseUUIDPrefix string
	BaseUUIDSuffix string

	MaxRows int
}

func Parse() Config {
	return Config{
		AppName: GetEnvAsString("APP_NAME", "crypto-matrix"),
		Debug:   GetEnvAsBool("DEBUG", false),

		WifiServiceGrpcPath:       GetEnvAsString("WIFI_SERVICE_GRPC_PATH", "unix:///run/crypto-matrix/wifi.sock"),
		DisplayServiceGrpcPath:    GetEnvAsString("DISPLAY_SERVICE_GRPC_PATH", "unix:///run/crypto-matrix/display.sock"),
		MarketDataServiceGrpcPath: GetEnvAsString("MARKET_DATA_SERVICE_GRPC_PATH", "unix:///run/crypto-matrix/market-data.sock"),

		AdapterId:      GetEnvAsString("ADAPTER_ID", "hci0"),
		BaseUUIDPrefix: GetEnvAsString("BASE_UUID_PREFIX", "d551"),
		BaseUUIDSuffix: GetEnvAsString("BASE_UUID_SUFFIX", "-fa5e-4343-b3f6-7c77b90d6e0f"),

		MaxRows: GetEnvAsInt("MAX_ROWS", 8),
	}
}
