package config

type Config struct {
	Debug    bool
	GrpcPath string
}

func Parse() Config {
	return Config{
		Debug:    GetEnvAsBool("DEBUG", false),
		GrpcPath: GetEnvAsString("GRPC_PATH", "/run/crypto-matrix/wifi.sock"),
	}
}
