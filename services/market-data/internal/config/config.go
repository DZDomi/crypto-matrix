package config

type Config struct {
	Debug                  bool
	StatePath              string
	GrpcPath               string
	DisplayServiceGrpcPath string
}

func Parse() Config {
	return Config{
		Debug:                  GetEnvAsBool("DEBUG", false),
		StatePath:              GetEnvAsString("STATE_PATH", "state.json"),
		GrpcPath:               GetEnvAsString("GRPC_PATH", "/run/crypto-matrix/market-data.sock"),
		DisplayServiceGrpcPath: GetEnvAsString("DISPLAY_SERVICE_GRPC_PATH", "unix:///run/crypto-matrix/display.sock"),
	}
}
