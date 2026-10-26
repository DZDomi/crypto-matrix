package persist

import (
	"os"

	log "github.com/sirupsen/logrus"
	"google.golang.org/protobuf/encoding/protojson"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
	"github.com/DZDomi/crypto-matrix/services/market-data/internal/config"
)

var statePath string

var logger = log.WithField("service", "persist")

var currentState = &grpc_models.State{
	Markets:   make([]*grpc_models.Market, 0),
	Timeframe: grpc_models.Timeframe_Day,
}

func LoadState(cfg config.Config) *grpc_models.State {
	statePath = cfg.StatePath
	err := loadFromDisk()
	// If there is an error then either file does not
	// exist or we cannot load it, which is fine :tm:
	if err != nil {
		logger.WithError(err).Warning("unable to load state. defaulting to empty state")
	}
	return currentState
}

func SaveState() error {
	return saveToDisk()
}

func SaveMarketsToDisk(markets []*grpc_models.Market) error {
	currentState.Markets = markets
	return saveToDisk()
}

func SaveTimeframeToDisk(timeframe grpc_models.Timeframe) error {
	currentState.Timeframe = timeframe
	return saveToDisk()
}

func loadFromDisk() error {
	if _, err := os.Stat(statePath); err != nil {
		return err
	}
	contents, err := os.ReadFile(statePath)
	if err != nil {
		return err
	}
	return protojson.Unmarshal(contents, currentState)
}

func saveToDisk() error {
	content, err := protojson.Marshal(currentState)
	if err != nil {
		return err
	}
	return os.WriteFile(statePath, content, 0644)
}
