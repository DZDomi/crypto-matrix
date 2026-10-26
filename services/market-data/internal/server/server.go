package server

import (
	"context"
	"net"
	"os"
	"sort"
	"time"

	log "github.com/sirupsen/logrus"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
	"github.com/DZDomi/crypto-matrix/proto/gen/go/services/streams"
	"github.com/DZDomi/crypto-matrix/services/market-data/internal/config"
	"github.com/DZDomi/crypto-matrix/services/market-data/internal/display"
	"github.com/DZDomi/crypto-matrix/services/market-data/internal/exchange"
	"github.com/DZDomi/crypto-matrix/services/market-data/internal/persist"
)

const rotateInterval = 5 * time.Second

var logger = log.WithField("service", "stream")

type StreamServiceImpl struct {
	streams.UnimplementedStreamServiceServer
	clients   map[grpc_models.Exchange]exchange.IExchangeClient
	ledClient *display.LedClient
}

func StartServer(cfg config.Config, clients map[grpc_models.Exchange]exchange.IExchangeClient, ledClient *display.LedClient) error {

	_ = os.Remove(cfg.GrpcPath)

	listener, err := net.Listen("unix", cfg.GrpcPath)
	if err != nil {
		return err
	}
	defer listener.Close()

	grpcServer := grpc.NewServer()
	if cfg.Debug {
		reflection.Register(grpcServer)
	}

	serviceImpl := &StreamServiceImpl{
		clients:   clients,
		ledClient: ledClient,
	}
	streams.RegisterStreamServiceServer(grpcServer, serviceImpl)

	go serviceImpl.setActiveMarket()
	return grpcServer.Serve(listener)
}

func (impl *StreamServiceImpl) Status(_ context.Context, _ *streams.StatusRequest) (*streams.StatusResponse, error) {
	return &streams.StatusResponse{
		Connected: true,
		Markets:   impl.getConnectedMarkets(),
	}, nil
}

func (impl *StreamServiceImpl) SubscribeToMarkets(_ context.Context, request *streams.SubscribeToMarketsRequest) (*streams.SubscribeToMarketsResponse, error) {
	marketsToSubscribe := impl.filterNotSupportedMarkets(request.Markets)
	for _, marketToSubscribe := range marketsToSubscribe {
		// Note: we will try to sub to all the markets and if some fail,
		// we will just log the error
		trades, tradesStop, ohlc, ohlcStop, err := impl.clients[marketToSubscribe.Exchange].SubscribeToMarket(marketToSubscribe)
		if err != nil {
			logger.WithError(err).Warning("unable to subscribe to market")
			continue
		}
		go impl.ledClient.ListenForTrades(trades, tradesStop)
		go impl.ledClient.ListenForOHLC(ohlc, ohlcStop)
	}
	connectedMarkets := impl.getConnectedMarkets()
	impl.saveMarkets(connectedMarkets)

	return &streams.SubscribeToMarketsResponse{
		Success: true,
		Markets: connectedMarkets,
	}, nil

}

func (impl *StreamServiceImpl) UnsubscribeToMarkets(_ context.Context, request *streams.UnsubscribeToMarketsRequest) (*streams.UnsubscribeToMarketsResponse, error) {
	marketsToUnsubscribe := impl.filterNotSupportedMarkets(request.Markets)
	for _, marketToUnsubscribe := range marketsToUnsubscribe {
		// Note: we will try to unsub to all the markets and if some fail,
		// we will just log the error
		err := impl.clients[marketToUnsubscribe.Exchange].UnsubscribeToMarket(marketToUnsubscribe)
		if err != nil {
			logger.WithError(err).Warning("unable to unsubscribe to market")
			continue
		}
	}
	connectedMarkets := impl.getConnectedMarkets()
	impl.saveMarkets(connectedMarkets)

	return &streams.UnsubscribeToMarketsResponse{
		Success:           true,
		SubscribedMarkets: connectedMarkets,
	}, nil

}

func (impl *StreamServiceImpl) ResetMarkets(_ context.Context, _ *streams.ResetMarketsRequest) (*streams.ResetMarketsResponse, error) {
	for _, client := range impl.clients {
		// Note: we will try to reset all the markets and if some fail,
		// we will just log the error
		err := client.ResetMarkets()
		if err != nil {
			logger.WithError(err).Warning("unable to reset market")
			continue
		}
	}
	connectedMarkets := impl.getConnectedMarkets()
	impl.saveMarkets(connectedMarkets)

	return &streams.ResetMarketsResponse{
		Success: true,
	}, nil

}

func (impl *StreamServiceImpl) SetTimeframe(_ context.Context, request *streams.SetTimeframeRequest) (*streams.SetTimeframeResponse, error) {
	for _, client := range impl.clients {
		client.SetTimeframe(request.Timeframe)
	}
	impl.saveTimeframe(request.Timeframe)
	return &streams.SetTimeframeResponse{
		Success: true,
	}, nil

}

func (impl *StreamServiceImpl) SendOHLC(_ context.Context, _ *streams.SendOHLCRequest) (*streams.SendOHLCResponse, error) {
	for _, client := range impl.clients {
		client.SendOHLCUpdate()
	}
	return &streams.SendOHLCResponse{
		Success: true,
	}, nil

}

func (impl *StreamServiceImpl) SendLatestTrade(_ context.Context, _ *streams.SendLatestTradeRequest) (*streams.SendLatestTradeResponse, error) {
	for _, client := range impl.clients {
		client.SendLatestTrade()
	}
	return &streams.SendLatestTradeResponse{
		Success: true,
	}, nil

}

func (impl *StreamServiceImpl) getConnectedMarkets() []*grpc_models.Market {
	connectedMarkets := make([]*grpc_models.Market, 0)
	for _, client := range impl.clients {
		connectedMarketsFromClient := client.Status()
		for _, market := range connectedMarketsFromClient {
			connectedMarkets = append(connectedMarkets, market)
		}
	}
	return connectedMarkets
}

func (impl *StreamServiceImpl) saveMarkets(markets []*grpc_models.Market) {
	err := persist.SaveMarketsToDisk(markets)
	if err != nil {
		logger.WithError(err).Warning("unable to persist markets to disk")
	}
}

func (impl *StreamServiceImpl) saveTimeframe(timeframe grpc_models.Timeframe) {
	err := persist.SaveTimeframeToDisk(timeframe)
	if err != nil {
		logger.WithError(err).Warning("unable to persist timeframe to disk")
	}
}

func (impl *StreamServiceImpl) filterNotSupportedMarkets(markets []*grpc_models.Market) []*grpc_models.Market {
	filteredMarkets := make([]*grpc_models.Market, 0)
	for _, market := range markets {
		if _, ok := impl.clients[market.Exchange]; !ok {
			logger.WithFields(log.Fields{
				"exchange": market.Exchange.String(),
			}).Warning("filtered out unsupported exchange")
			continue
		}
		filteredMarkets = append(filteredMarkets, market)
	}
	return filteredMarkets
}

func (impl *StreamServiceImpl) setActiveMarket() {
	currentActiveMarket := -1
	for range time.Tick(rotateInterval) {
		logger.Info("changing active market")
		connectedMarkets := make([]*grpc_models.Market, 0)
		for _, client := range impl.clients {
			for _, connectedMarket := range client.Status() {
				connectedMarket.Active = false
				connectedMarkets = append(connectedMarkets, connectedMarket)
			}
		}
		if len(connectedMarkets) == 0 {
			continue
		} else if len(connectedMarkets) == 1 {
			connectedMarkets[0].Active = true
			continue
		}
		sort.Slice(connectedMarkets, func(i, j int) bool {
			return connectedMarkets[i].Row < connectedMarkets[j].Row
		})
		if currentActiveMarket+1 >= len(connectedMarkets) {
			currentActiveMarket = 0
		} else {
			currentActiveMarket++
		}
		newActiveMarket := connectedMarkets[currentActiveMarket]
		newActiveMarket.Active = true

		logger.WithField("market", newActiveMarket.Pair.Symbol).Info("set new active market")

		for _, client := range impl.clients {
			client.SendOHLCUpdate()
			client.SendLatestTrade()
		}
	}
}
