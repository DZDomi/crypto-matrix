package main

import (
	"github.com/joho/godotenv"
	log "github.com/sirupsen/logrus"

	"github.com/DZDomi/crypto-matrix/services/wifi/internal/config"
	"github.com/DZDomi/crypto-matrix/services/wifi/internal/must"
	"github.com/DZDomi/crypto-matrix/services/wifi/internal/server"
)

var logger = log.WithField("service", "main")

func main() {
	err := godotenv.Load()
	if err != nil {
		logger.WithError(err).Warning("unable to load dot env")
	}
	cfg := config.Parse()
	logger.Infof("start listening on path: %s", cfg.GrpcPath)
	must.Succeed(server.StartServer(cfg.GrpcPath))
}
