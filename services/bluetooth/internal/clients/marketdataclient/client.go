package marketdataclient

import (
	"context"
	"errors"

	log "github.com/sirupsen/logrus"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
	"github.com/DZDomi/crypto-matrix/proto/gen/go/services/streams"
	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/clients/displayclient"
)

var maxRows int

var service streams.StreamServiceClient

var logger = log.WithField("service", "client")

func Connect(path string, mR int) error {
	maxRows = mR
	conn, err := grpc.NewClient(path, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return err
	}
	service = streams.NewStreamServiceClient(conn)
	return nil
}

func GetMarkets() ([]*grpc_models.Market, error) {
	statusResponse, err := service.Status(context.Background(), &streams.StatusRequest{})
	if err != nil {
		return nil, err
	} else if !statusResponse.Connected {
		return nil, errors.New("not connected")
	}
	return statusResponse.Markets, nil
}

func SyncMarkets(markets []*grpc_models.Market) error {
	connectedMarkets, err := service.Status(context.Background(), &streams.StatusRequest{})
	if err != nil {
		return err
	} else if !connectedMarkets.Connected {
		return errors.New("not connected")
	}

	marketsToAdd := make([]*grpc_models.Market, 0)
	marketsToRemove := make([]*grpc_models.Market, 0)

	for _, newMarket := range markets {
		found := false
		for _, connectedMarket := range connectedMarkets.Markets {
			if compareMarkets(newMarket, connectedMarket) {
				found = true
				break
			}
		}
		if !found {
			marketsToAdd = append(marketsToAdd, newMarket)
		}
	}

	for _, connectedMarket := range connectedMarkets.Markets {
		found := false
		for _, newMarket := range markets {
			if compareMarkets(connectedMarket, newMarket) {
				found = true
				break
			}
		}
		if !found {
			marketsToRemove = append(marketsToRemove, connectedMarket)
		}
	}

	unsubscribeMarketResponse, err := service.UnsubscribeToMarkets(context.Background(), &streams.UnsubscribeToMarketsRequest{
		Markets: marketsToRemove,
	})
	if err != nil {
		return err
	} else if !unsubscribeMarketResponse.Success {
		return errors.New("unable to unsubscribe to markets")
	}

	if len(marketsToRemove) > len(marketsToAdd) {
		clearFromRow := len(connectedMarkets.Markets) + len(marketsToAdd) - len(marketsToRemove)
		for row := clearFromRow; row <= maxRows; row++ {
			success, err := displayclient.EmptyRow(uint(row))
			if err != nil {
				return err
			} else if !success {
				return errors.New("unable to empty row")
			}
		}
	}

	logger.Infof("Sending %d markets to sub", len(markets))
	subscribeResponse, err := service.SubscribeToMarkets(context.Background(), &streams.SubscribeToMarketsRequest{
		Markets: markets,
	})
	if err != nil {
		return err
	} else if !subscribeResponse.Success {
		return errors.New("unable to sub to markets")
	}
	return nil

}

func ResetMarkets() error {
	resetMarketResponse, err := service.ResetMarkets(context.Background(), &streams.ResetMarketsRequest{})
	if err != nil {
		return err
	} else if !resetMarketResponse.Success {
		return errors.New("unable to reset markets")
	}
	return nil
}

func SetTimeframe(timeframe grpc_models.Timeframe) error {
	setTimeframeResponse, err := service.SetTimeframe(context.Background(), &streams.SetTimeframeRequest{
		Timeframe: timeframe,
	})
	if err != nil {
		return err
	} else if !setTimeframeResponse.Success {
		return errors.New("unable to set timeframe")
	}
	return nil
}

func SendOHLCUpdate() error {
	sendOHLCUpdateResponse, err := service.SendOHLC(context.Background(), &streams.SendOHLCRequest{})
	if err != nil {
		return err
	} else if !sendOHLCUpdateResponse.Success {
		return errors.New("unable to send ohlc")
	}
	return nil
}

func SendLatestTrade() error {
	sendLatestTradeResponse, err := service.SendLatestTrade(context.Background(), &streams.SendLatestTradeRequest{})
	if err != nil {
		return err
	} else if !sendLatestTradeResponse.Success {
		return errors.New("unable to send latest trade")
	}
	return nil
}

func compareMarkets(a *grpc_models.Market, b *grpc_models.Market) bool {
	return a.Exchange == b.Exchange && a.Pair.Symbol == b.Pair.Symbol
}
