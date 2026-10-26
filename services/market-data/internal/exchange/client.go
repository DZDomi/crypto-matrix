package exchange

import (
	"errors"
	"fmt"
	"strconv"
	"sync"
	"time"

	log "github.com/sirupsen/logrus"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
)

// The candles are refreshed every minute independent of the timeframe, so the
// latest candle of the chart stays up to date
const ohlcUpdateInterval = time.Minute

var logger = log.WithField("service", "websocket/exchange-client")

type client struct {
	connectedMarkets []*ConnectedMarket
	timeframe        grpc_models.Timeframe

	lock *sync.Mutex
}

func createClient() *client {
	return &client{
		lock:             &sync.Mutex{},
		connectedMarkets: make([]*ConnectedMarket, 0),
	}
}

func (client *client) add(market *grpc_models.Market, connect func(*grpc_models.Market, grpc_models.Timeframe) (chan *grpc_models.Trade, chan struct{}, *grpc_models.Trade, chan *OHLC, *time.Ticker, chan struct{}, *OHLC, error)) (chan *grpc_models.Trade, chan struct{}, chan *OHLC, chan struct{}, error) {
	client.lock.Lock()
	defer client.lock.Unlock()
	_, connectedMarket, err := client.findConnectedMarket(market)
	if err == nil {
		if connectedMarket.Market.Row == market.Row {
			logger.WithFields(log.Fields{
				"exchange": market.Exchange,
				"pair":     market.Pair.Symbol,
				"row":      market.Row,
			}).Warning("already subscribed to market, with the same row")
			return connectedMarket.Trades, connectedMarket.TradeUpdateStop, connectedMarket.OHLC, connectedMarket.OHLCUpdateStop, nil
		}
		// If the rows do not match we do not need to resubscribe to the whole market,
		// we can just update the row and send a new trade event
		connectedMarket.Market.Row = market.Row
		// We will publish the latest trade delayed
		go func(connectedMarket *ConnectedMarket) {
			time.Sleep(100 * time.Millisecond)
			connectedMarket.OHLC <- connectedMarket.LatestOHLC
			connectedMarket.Trades <- connectedMarket.LatestTrade
		}(connectedMarket)
		return connectedMarket.Trades, connectedMarket.TradeUpdateStop, connectedMarket.OHLC, connectedMarket.OHLCUpdateStop, nil
	}
	tradeChannel, tradeUpdateStop, latestTrade, ohlcChannel, ohlcUpdate, ohlcUpdateStop, latestOHLC, err := connect(market, client.timeframe)
	if err != nil {
		return nil, nil, nil, nil, err
	}
	market.Price = latestTrade.Price
	client.connectedMarkets = append(client.connectedMarkets, &ConnectedMarket{
		Market:          market,
		Trades:          tradeChannel,
		TradeUpdateStop: tradeUpdateStop,
		LatestTrade:     latestTrade,
		OHLC:            ohlcChannel,
		OHLCUpdate:      ohlcUpdate,
		OHLCUpdateStop:  ohlcUpdateStop,
		LatestOHLC:      latestOHLC,
	})

	// Send first trade and ohlc after we connected successfully
	go func(tradeChannel chan *grpc_models.Trade, latestTrade *grpc_models.Trade, ohlcChannel chan *OHLC, latestOHLC *OHLC) {
		tradeChannel <- latestTrade
		ohlcChannel <- latestOHLC
	}(tradeChannel, latestTrade, ohlcChannel, latestOHLC)
	return tradeChannel, tradeUpdateStop, ohlcChannel, ohlcUpdateStop, nil
}

func (client *client) remove(market *grpc_models.Market) error {
	client.lock.Lock()
	defer client.lock.Unlock()
	_, marketToUnsubscribe, err := client.findConnectedMarket(market)
	if err != nil {
		logger.WithFields(log.Fields{
			"exchange": market.Exchange,
			"pair":     fmt.Sprintf("%s", market.Pair.Symbol),
		}).Warning("not subscribed to market")
		return errors.New("not subscribed to market")
	}
	marketToUnsubscribe.TradeUpdateStop <- struct{}{}
	marketToUnsubscribe.OHLCUpdate.Stop()
	marketToUnsubscribe.OHLCUpdateStop <- struct{}{}
	return client.removeMarket(marketToUnsubscribe.Market)
}

func (client *client) setSide(trade *grpc_models.Trade) error {
	_, connectedMarket, err := client.findConnectedMarket(trade.Market)
	if err != nil {
		return err
	}
	currentPrice, err := strconv.ParseFloat(connectedMarket.Market.Price, 64)
	if err != nil {
		return err
	}
	newPrice, err := strconv.ParseFloat(trade.Price, 64)
	if err != nil {
		return err
	}
	connectedMarket.Market.Price = trade.Price
	if newPrice > currentPrice {
		trade.Side = grpc_models.Side_Buy
	} else {
		trade.Side = grpc_models.Side_Sell
	}
	return nil
}

func (client *client) resetMarkets() error {
	for _, connectedMarket := range client.connectedMarkets {
		err := client.remove(connectedMarket.Market)
		if err != nil {
			return err
		}
	}
	return nil
}

func (client *client) findConnectedMarket(market *grpc_models.Market) (int, *ConnectedMarket, error) {
	for i, connectedMarket := range client.connectedMarkets {
		if connectedMarket.Market.Exchange == market.Exchange && connectedMarket.Market.Pair.Symbol == market.Pair.Symbol {
			return i, connectedMarket, nil
		}
	}
	return -1, nil, errors.New("market not found")
}

func (client *client) removeMarket(market *grpc_models.Market) error {
	indexToRemove, _, err := client.findConnectedMarket(market)
	if err != nil {
		return err
	}
	client.connectedMarkets[indexToRemove] = client.connectedMarkets[len(client.connectedMarkets)-1]
	client.connectedMarkets = client.connectedMarkets[:len(client.connectedMarkets)-1]
	return nil
}

func (client *client) updateTimeframe(timeframe grpc_models.Timeframe, startPeriodicUpdate func(*grpc_models.Market, chan *OHLC, *time.Ticker, chan struct{})) {
	client.timeframe = timeframe
	for _, connectedMarket := range client.connectedMarkets {
		connectedMarket.OHLCUpdate.Stop()
		connectedMarket.OHLCUpdateStop <- struct{}{}
		connectedMarket.OHLCUpdate = time.NewTicker(ohlcUpdateInterval)
		go startPeriodicUpdate(connectedMarket.Market, connectedMarket.OHLC, connectedMarket.OHLCUpdate, connectedMarket.OHLCUpdateStop)
	}
}
