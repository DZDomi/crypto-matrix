package exchange

import (
	"time"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
)

type IExchangeClient interface {
	Status() []*grpc_models.Market
	SubscribeToMarket(*grpc_models.Market) (chan *grpc_models.Trade, chan struct{}, chan *OHLC, chan struct{}, error)
	UnsubscribeToMarket(*grpc_models.Market) error
	ResetMarkets() error
	SetTimeframe(timeframe grpc_models.Timeframe)
	SendOHLCUpdate()
	SendLatestTrade()
}

type OHLC struct {
	Market   *grpc_models.Market
	Interval *grpc_models.Interval
}

type ConnectedMarket struct {
	Market *grpc_models.Market

	LatestTrade     *grpc_models.Trade
	Trades          chan *grpc_models.Trade
	TradeUpdateStop chan struct{}

	LatestOHLC     *OHLC
	OHLC           chan *OHLC
	OHLCUpdate     *time.Ticker
	OHLCUpdateStop chan struct{}
}
