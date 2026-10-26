package main

import (
	"errors"
	"os"
	"os/signal"
	"syscall"

	"github.com/joho/godotenv"
	log "github.com/sirupsen/logrus"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
	"github.com/DZDomi/crypto-matrix/services/market-data/internal/config"
	"github.com/DZDomi/crypto-matrix/services/market-data/internal/display"
	"github.com/DZDomi/crypto-matrix/services/market-data/internal/exchange"
	"github.com/DZDomi/crypto-matrix/services/market-data/internal/persist"
	"github.com/DZDomi/crypto-matrix/services/market-data/internal/server"
)

var supportedExchanges = [...]grpc_models.Exchange{
	grpc_models.Exchange_Binance,
}

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
	registerHandlers()

	ledClient, err := display.NewClient(cfg.DisplayServiceGrpcPath)
	handleError(err)

	exchangeClients := initClients()

	loadedState := persist.LoadState(cfg)
	restoreState(loadedState.Markets, exchangeClients, ledClient)

	logger.Info("start listening on: " + cfg.GrpcPath)
	handleError(server.StartServer(cfg, exchangeClients, ledClient))
}

func handleError(err error) {
	if err != nil {
		logger.Panic(err)
	}
}

func registerHandlers() {
	signals := make(chan os.Signal, 1)
	signal.Notify(signals, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-signals
		if err := persist.SaveState(); err != nil {
			logger.WithError(err).Warning("unable to save state")
		}
		os.Exit(0)
	}()
}

func initClients() map[grpc_models.Exchange]exchange.IExchangeClient {
	clients := make(map[grpc_models.Exchange]exchange.IExchangeClient)
	for _, supportedExchange := range supportedExchanges {
		var err error
		var client exchange.IExchangeClient = nil
		switch supportedExchange {
		case grpc_models.Exchange_Binance:
			client, err = exchange.GetBinanceClient()
			break
		default:
			err = errors.New("exchange not implemented")
		}
		handleError(err)
		clients[supportedExchange] = client
	}
	return clients
}

func restoreState(markets []*grpc_models.Market, clients map[grpc_models.Exchange]exchange.IExchangeClient, ledClient *display.LedClient) {
	for _, market := range markets {
		if _, ok := clients[market.Exchange]; !ok {
			// TODO: Probably unsubscribe
			logger.WithField("exchange", market.Exchange).Warning("unable to restore not supported exchange")
			continue
		}
		trades, tradesStop, ohlc, ohlcStop, err := clients[market.Exchange].SubscribeToMarket(market)
		if err != nil {
			logger.WithError(err).Warning("unable to restore market")
			continue
		}
		go ledClient.ListenForTrades(trades, tradesStop)
		go ledClient.ListenForOHLC(ohlc, ohlcStop)
	}
}
