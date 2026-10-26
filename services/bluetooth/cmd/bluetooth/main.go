package main

import (
	"github.com/joho/godotenv"
	log "github.com/sirupsen/logrus"

	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/bluetooth"
	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/clients/displayclient"
	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/clients/marketdataclient"
	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/clients/wificlient"
	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/config"
	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/must"
)

var logger = log.WithField("service", "main")

func main() {

	err := godotenv.Load()
	if err != nil {
		// Ignore on purpose cause of normal env variables
		logger.WithError(err).Warning("unable to load dot env")
	}
	cfg := config.Parse()

	if cfg.Debug {
		log.SetLevel(log.DebugLevel)
	} else {
		log.SetLevel(log.WarnLevel)
	}
	log.SetReportCaller(cfg.Debug)

	logger.Info("Initialising adapter...")
	client := bluetooth.GetClient(cfg)
	defer client.Close()
	logger.Info("Initialisation done")

	logger.Info("Connecting to Wifi Service...")
	must.Succeed(wificlient.Connect(cfg.WifiServiceGrpcPath))
	logger.Info("Connected to Wifi Service")

	logger.Info("Connecting to Led Service...")
	must.Succeed(displayclient.Connect(cfg.DisplayServiceGrpcPath))
	logger.Info("Connected to Led Service")

	logger.Info("Connecting to Streams Service...")
	must.Succeed(marketdataclient.Connect(cfg.MarketDataServiceGrpcPath, cfg.MaxRows))
	logger.Info("Connected to Streams Service")

	client.Run()

	// Block forever to keep the program running
	select {}
}
