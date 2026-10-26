package display

import (
	"context"

	log "github.com/sirupsen/logrus"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
	"github.com/DZDomi/crypto-matrix/proto/gen/go/services/ledmatrix"
	"github.com/DZDomi/crypto-matrix/services/market-data/internal/exchange"
)

var service ledmatrix.LedMatrixServiceClient

var logger = log.WithField("service", "ledmatrix")

type LedClient struct {
	service ledmatrix.LedMatrixServiceClient
}

func NewClient(path string) (*LedClient, error) {
	conn, err := grpc.NewClient(path, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, err
	}
	service = ledmatrix.NewLedMatrixServiceClient(conn)
	return &LedClient{
		service: service,
	}, nil
}

func (client *LedClient) ListenForTrades(trades chan *grpc_models.Trade, tradesStop chan struct{}) {
	for {
		select {
		case trade := <-trades:
			client.sendTrade(trade)
			break
		case <-tradesStop:
			return
		}
	}
}

func (client *LedClient) ListenForOHLC(ohlc chan *exchange.OHLC, ohlcStop chan struct{}) {
	for {
		select {
		case update := <-ohlc:
			client.sendOHLCUpdate(update)
			break
		case <-ohlcStop:
			return
		}
	}
}

func (client *LedClient) sendTrade(trade *grpc_models.Trade) {
	request := &ledmatrix.ReceiveTradeRequest{}
	request.Trades = []*grpc_models.Trade{trade}

	logger.WithField("trade", trade).Debug("sending trade to ledmatrix")
	// We do not react on trade write error as it can happen all the time
	_, err := service.ReceiveTrade(context.Background(), request)
	if err != nil {
		logger.WithError(err).Debug("unable to send trade to led matrix")
	}
}

func (client *LedClient) sendOHLCUpdate(ohlc *exchange.OHLC) {
	request := &ledmatrix.ReceiveOHLCUpdateRequest{
		Market:   ohlc.Market,
		Interval: ohlc.Interval,
	}

	logger.WithField("market", request.Market.Pair.Symbol).Debug("sending ohlc update to ledmatrix")
	// We do not react on ohlc write error as it can happen all the time
	_, err := service.ReceiveOHLCUpdate(context.Background(), request)
	if err != nil {
		logger.WithError(err).Debug("unable to send ohlc to led matrix")
	}
}
