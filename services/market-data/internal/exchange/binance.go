package exchange

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/adshao/go-binance/v2"
	log "github.com/sirupsen/logrus"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
)

const refreshIntervalSymbols = 5 * time.Minute

var binanceTimeFrameMappings = map[grpc_models.Timeframe]string{
	grpc_models.Timeframe_Minute:        "1m",
	grpc_models.Timeframe_FiveMinutes:   "5m",
	grpc_models.Timeframe_ThirtyMinutes: "30m",
	grpc_models.Timeframe_Hour:          "1h",
	grpc_models.Timeframe_SixHours:      "6h",
	grpc_models.Timeframe_Day:           "1d",
	grpc_models.Timeframe_Week:          "1w",
	grpc_models.Timeframe_Month:         "1M",
}

var binanceLogger = log.WithField("service", "websocket/binance")

var symbols []binance.Symbol

func GetBinanceClient() (*BinanceClient, error) {
	client := &BinanceClient{
		binanceClient: binance.NewClient("", ""),
		client:        createClient(),
	}
	err := client.fetchAndSetSymbols()
	if err != nil {
		return nil, err
	}
	go client.refreshSymbols()
	return client, nil
}

type BinanceClient struct {
	binanceClient *binance.Client
	*client
}

func (client *BinanceClient) Status() []*grpc_models.Market {
	markets := make([]*grpc_models.Market, 0)
	for _, market := range client.connectedMarkets {
		markets = append(markets, market.Market)
	}
	return markets
}

func (client *BinanceClient) SubscribeToMarket(market *grpc_models.Market) (chan *grpc_models.Trade, chan struct{}, chan *OHLC, chan struct{}, error) {
	if err := checkMarketAvailability(market); err != nil {
		return nil, nil, nil, nil, errors.New("unable to subscribe to market, as it does not exist")
	}
	return client.add(market, func(marketToConnect *grpc_models.Market, timeframe grpc_models.Timeframe) (chan *grpc_models.Trade, chan struct{}, *grpc_models.Trade, chan *OHLC, *time.Ticker, chan struct{}, *OHLC, error) {
		tradeChannel := make(chan *grpc_models.Trade)
		ohlcChannel := make(chan *OHLC)
		ohlcUpdate := time.NewTicker(ohlcUpdateInterval)
		ohlcUpdateStop := make(chan struct{})

		latestTrade, err := client.getLatestTrade(marketToConnect)
		if err != nil {
			return nil, nil, nil, nil, nil, nil, nil, err
		}
		candles, err := client.getCandles(marketToConnect)
		if err != nil {
			return nil, nil, nil, nil, nil, nil, nil, err
		}
		latestOHLC := &OHLC{
			Market: marketToConnect,
			Interval: &grpc_models.Interval{
				Timeframe: timeframe,
				Candles:   candles,
			},
		}
		go client.sendPeriodicOHLCUpdates(marketToConnect, ohlcChannel, ohlcUpdate, ohlcUpdateStop)
		_, tradeUpdateStop, err := binance.WsTradeServe(convertMarketSymbol(marketToConnect), client.tradeHandler, client.errorHandler)
		if err != nil {
			return nil, nil, nil, nil, nil, nil, nil, err
		}
		return tradeChannel, tradeUpdateStop, latestTrade, ohlcChannel, ohlcUpdate, ohlcUpdateStop, latestOHLC, err
	})
}

func (client *BinanceClient) UnsubscribeToMarket(market *grpc_models.Market) error {
	return client.remove(market)
}

func (client *BinanceClient) ResetMarkets() error {
	return client.client.resetMarkets()
}

func (client *BinanceClient) SetTimeframe(timeframe grpc_models.Timeframe) {
	client.updateTimeframe(timeframe, client.sendPeriodicOHLCUpdates)
}

func (client *BinanceClient) SendOHLCUpdate() {
	for _, connectedMarket := range client.connectedMarkets {
		connectedMarket.OHLC <- connectedMarket.LatestOHLC
	}
}

func (client *BinanceClient) SendLatestTrade() {
	for _, connectedMarket := range client.connectedMarkets {
		connectedMarket.Trades <- connectedMarket.LatestTrade
	}
}

func (client *BinanceClient) tradeHandler(event *binance.WsTradeEvent) {
	symbol, err := getSymbolToTrade(event)
	if err != nil {
		logger.WithError(err).Warning("error while trying to parse trade event")
		return
	}
	findMarket := &grpc_models.Market{
		Exchange: grpc_models.Exchange_Binance,
		Pair: &grpc_models.Pair{
			Symbol: fmt.Sprintf("%s_%s", symbol.BaseAsset, symbol.QuoteAsset),
			Base: &grpc_models.Asset{
				Symbol: symbol.BaseAsset,
			},
			Quote: &grpc_models.Asset{
				Symbol: symbol.QuoteAsset,
			},
		},
		Price: event.Price,
	}
	// Check if we are still subscribed to market
	_, connectedMarket, err := client.findConnectedMarket(findMarket)
	if err != nil {
		binanceLogger.WithError(err).Warning("not subscribed to market anymore, skipping trade")
		return
	}
	if connectedMarket.LatestTrade != nil && connectedMarket.LatestTrade.Price == event.Price {
		binanceLogger.Info("received trade with previous price, skipping trade")
		return
	}
	// Note: Important use the market we found in order to preserve the row
	trade := &grpc_models.Trade{
		Price:  event.Price,
		Market: connectedMarket.Market,
	}
	err = client.setSide(trade)
	if err != nil {
		binanceLogger.WithError(err).Warning("error while trying to parse trade event")
		return
	}
	connectedMarket.LatestTrade = trade
	connectedMarket.Trades <- trade
}

func (client *BinanceClient) errorHandler(err error) {
	binanceLogger.WithError(err).Error("error from ws subscribe")
}

func (client *BinanceClient) refreshSymbols() {
	for range time.Tick(refreshIntervalSymbols) {
		err := client.fetchAndSetSymbols()
		if err != nil {
			binanceLogger.WithError(err).Warning("unable to refresh symbols")
		}
	}
}

func (client *BinanceClient) fetchAndSetSymbols() error {
	response, err := client.binanceClient.NewExchangeInfoService().Do(context.Background())
	if err != nil {
		return err
	}
	binanceLogger.Infof("got %d symbols from binance", len(response.Symbols))
	symbols = response.Symbols
	return nil
}

func (client *BinanceClient) getLatestTrade(market *grpc_models.Market) (*grpc_models.Trade, error) {
	recentTrades, err := client.binanceClient.NewRecentTradesService().Symbol(convertMarketSymbol(market)).Limit(2).Do(context.Background())
	if err != nil {
		return nil, err
	}
	recentTrade := recentTrades[0]
	secondRecentTrade := recentTrades[1]

	recentPrice, err := strconv.ParseFloat(recentTrade.Price, 64)
	if err != nil {
		return nil, err
	}
	secondRecentPrice, err := strconv.ParseFloat(secondRecentTrade.Price, 64)
	if err != nil {
		return nil, err
	}

	var side grpc_models.Side
	if recentPrice > secondRecentPrice {
		side = grpc_models.Side_Buy
	} else {
		side = grpc_models.Side_Sell
	}
	return &grpc_models.Trade{
		Price:  recentTrade.Price,
		Side:   side,
		Market: market,
	}, nil
}

func (client *BinanceClient) sendPeriodicOHLCUpdates(market *grpc_models.Market, ohlcChannel chan *OHLC, ohlcUpdate *time.Ticker, ohlcUpdateStop chan struct{}) {
	for {
		select {
		case <-ohlcUpdateStop:
			binanceLogger.WithFields(log.Fields{
				"market": market.Pair.Symbol,
			}).Debug("got signal to stop ohlc update")
			return
		case <-ohlcUpdate.C:
			go client.publishOHLCUpdate(market, ohlcChannel)
		}
	}
}

func (client *BinanceClient) publishOHLCUpdate(market *grpc_models.Market, ohlcChannel chan *OHLC) {
	candles, err := client.getCandles(market)
	if err != nil {
		binanceLogger.WithError(err).Warning("unable to get candles from api")
		return
	}
	_, connectedMarket, err := client.findConnectedMarket(market)
	if err != nil {
		binanceLogger.Warning("not connected to market anymore, skipping ohlc update")
		return
	}
	binanceLogger.Infof("sending %d candles to channel", len(candles))
	ohlc := &OHLC{
		Market: market,
		Interval: &grpc_models.Interval{
			Timeframe: client.timeframe,
			Candles:   candles,
		},
	}
	connectedMarket.LatestOHLC = ohlc
	ohlcChannel <- ohlc
}

func (client *BinanceClient) getCandles(market *grpc_models.Market) ([]*grpc_models.Candle, error) {
	response, err := client.binanceClient.NewKlinesService().Symbol(convertMarketSymbol(market)).Interval(binanceTimeFrameMappings[client.timeframe]).Do(context.Background())
	if err != nil {
		return nil, err
	}
	candles := make([]*grpc_models.Candle, 0)
	for _, candle := range response {
		candles = append(candles, &grpc_models.Candle{
			Open:        candle.Open,
			High:        candle.High,
			Low:         candle.Low,
			Close:       candle.Close,
			Volume:      candle.Volume,
			VolumeQuote: candle.QuoteAssetVolume,
		})
	}
	return candles, nil
}

func checkMarketAvailability(market *grpc_models.Market) error {
	for _, symbol := range symbols {
		if symbol.Symbol == convertMarketSymbol(market) {
			return nil
		}
	}
	return errors.New("unable to find market")
}

func getSymbolToTrade(trade *binance.WsTradeEvent) (binance.Symbol, error) {
	for _, symbol := range symbols {
		if symbol.Symbol == trade.Symbol {
			return symbol, nil
		}
	}
	return binance.Symbol{}, errors.New("unable to find matching symbol")
}

func convertMarketSymbol(market *grpc_models.Market) string {
	return fmt.Sprintf("%s%s", market.Pair.Base.Symbol, market.Pair.Quote.Symbol)
}
