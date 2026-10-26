package exchange

import (
	"errors"
	"testing"
	"time"

	log "github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
)

const testTimeReceiveTrades = 1 * time.Minute

var exchanges = map[string]grpc_models.Exchange{
	"binance": grpc_models.Exchange_Binance,
}

var validMarkets = map[string]*grpc_models.Market{
	"BTC_USDT": {
		Pair: &grpc_models.Pair{
			Symbol: "BTC_USDT",
			Base: &grpc_models.Asset{
				Symbol: "BTC",
			},
			Quote: &grpc_models.Asset{
				Symbol: "USDT",
			},
		},
	},
	"ETH_USDT": {
		Pair: &grpc_models.Pair{
			Symbol: "ETH_USDT",
			Base: &grpc_models.Asset{
				Symbol: "ETH",
			},
			Quote: &grpc_models.Asset{
				Symbol: "USDT",
			},
		},
	},
}

var invalidMarkets = map[string]*grpc_models.Market{
	"BTC_USF": {
		Pair: &grpc_models.Pair{
			Symbol: "BTC_USF",
			Base: &grpc_models.Asset{
				Symbol: "BTC",
			},
			Quote: &grpc_models.Asset{
				Symbol: "USF",
			},
		},
	},
	"YTU_USDT": {
		Pair: &grpc_models.Pair{
			Symbol: "YTU_USDT",
			Base: &grpc_models.Asset{
				Symbol: "YTU",
			},
			Quote: &grpc_models.Asset{
				Symbol: "USDT",
			},
		},
	},
}

func TestAddingPairs(t *testing.T) {
	log.Infof("Running test: %s", t.Name())
	for _, exchange := range exchanges {
		client := getClientFromExchange(t, exchange)
		for marketName, market := range validMarkets {
			_, _, _, _, err := client.SubscribeToMarket(market)
			assert.NoErrorf(t, err, "able to subscribe to market: %s", marketName)
		}
		for marketName, market := range invalidMarkets {
			_, _, _, _, err := client.SubscribeToMarket(market)
			assert.Errorf(t, err, "unable to subscribe to market: %s", marketName)
		}
		connectedMarkets := client.Status()
		assert.Lenf(t, connectedMarkets, len(validMarkets), "subscribed to %d markets", len(validMarkets))
		for marketName, market := range validMarkets {
			_, _, _, _, err := client.SubscribeToMarket(market)
			assert.NoErrorf(t, err, "able to subscribe to market: %s", marketName)
		}
		connectedMarkets = client.Status()
		assert.Lenf(t, connectedMarkets, len(validMarkets), "subscribed to %d markets", len(validMarkets))
	}
}

func TestRemovingPairs(t *testing.T) {
	log.Infof("Running test: %s", t.Name())
	for _, exchange := range exchanges {
		client := getClientFromExchange(t, exchange)
		for marketName, market := range validMarkets {
			_, _, _, _, err := client.SubscribeToMarket(market)
			assert.NoErrorf(t, err, "able to subscribe to market: %s", marketName)
		}
		connectedMarkets := client.Status()
		assert.Lenf(t, connectedMarkets, len(validMarkets), "subscribed to %d markets", len(validMarkets))

		err := client.UnsubscribeToMarket(validMarkets["BTC_USDT"])
		assert.NoError(t, err, "able to unsubscribe from BTC_USDT")
		connectedMarkets = client.Status()
		assert.Lenf(t, connectedMarkets, len(validMarkets)-1, "subscribed to %d markets", len(validMarkets)-1)

		err = client.UnsubscribeToMarket(invalidMarkets["BTC_USF"])
		assert.Error(t, err, "unable to unsubscribe from BTC_USF")
		connectedMarkets = client.Status()
		assert.Lenf(t, connectedMarkets, len(validMarkets)-1, "subscribed to %d markets", len(validMarkets)-1)

		err = client.UnsubscribeToMarket(validMarkets["BTC_USDT"])
		assert.Error(t, err, "unable to unsubscribe from BTC_USDT")
		connectedMarkets = client.Status()
		assert.Lenf(t, connectedMarkets, len(validMarkets)-1, "subscribed to %d markets", len(validMarkets)-1)

		err = client.UnsubscribeToMarket(validMarkets["ETH_USDT"])
		assert.NoError(t, err, "able to unsubscribe from ETH_USDT")
		connectedMarkets = client.Status()
		assert.Lenf(t, connectedMarkets, len(validMarkets)-2, "subscribed to %d markets", len(validMarkets)-2)

		err = client.UnsubscribeToMarket(validMarkets["ETH_USDT"])
		assert.Error(t, err, "unable to unsubscribe from ETH_USDT")
		connectedMarkets = client.Status()
		assert.Lenf(t, connectedMarkets, len(validMarkets)-2, "subscribed to %d markets", len(validMarkets)-2)
	}
}

func TestResetMarkets(t *testing.T) {
	log.Infof("Running test: %s", t.Name())
	for _, exchange := range exchanges {
		client := getClientFromExchange(t, exchange)
		for marketName, market := range validMarkets {
			_, _, _, _, err := client.SubscribeToMarket(market)
			assert.NoErrorf(t, err, "able to subscribe to market: %s", marketName)
		}

		connectedMarkets := client.Status()
		assert.Lenf(t, connectedMarkets, len(validMarkets), "subscribed to %d markets", len(validMarkets))

		err := client.ResetMarkets()
		assert.NoError(t, err, "able to reset markets")

		connectedMarkets = client.Status()
		assert.Lenf(t, connectedMarkets, 0, "subscribed to %d markets", 0)

		err = client.ResetMarkets()
		assert.NoError(t, err, "able to reset markets")

		connectedMarkets = client.Status()
		assert.Lenf(t, connectedMarkets, 0, "subscribed to %d markets", 0)
	}
}

func TestReceiveTrades(t *testing.T) {
	log.Infof("Running test: %s", t.Name())
	clientChannels := map[IExchangeClient]map[*grpc_models.Market]chan *grpc_models.Trade{}
	for _, exchange := range exchanges {
		client := getClientFromExchange(t, exchange)
		clientChannels[client] = make(map[*grpc_models.Market]chan *grpc_models.Trade)
		for marketName, market := range validMarkets {
			trades, _, _, _, err := client.SubscribeToMarket(market)
			assert.NoErrorf(t, err, "able to subscribe to market: %s", marketName)
			clientChannels[client][market] = trades
		}
	}

	for start := time.Now(); time.Since(start) < testTimeReceiveTrades; {
		for _, markets := range clientChannels {
			for market, channel := range markets {
				select {
				case trade := <-channel:
					assert.True(t, market.Pair.Symbol == trade.Market.Pair.Symbol, "trade is equal to market symbol")
					assert.True(t, market.Exchange == trade.Market.Exchange, "trade is equal to exchange")
				}
			}
		}
	}
}

func getClientFromExchange(t *testing.T, exchange grpc_models.Exchange) IExchangeClient {
	if testing.Short() {
		t.Skip("requires network access to the exchange")
	}
	var client IExchangeClient
	var err error

	switch exchange {
	case grpc_models.Exchange_Binance:
		client, err = GetBinanceClient()
		break
	default:
		err = errors.New("exchange not implemented")
		break
	}
	assert.NoError(t, err, "no error returned on client init")
	assert.NotNil(t, client, "client is not null")
	return client
}
