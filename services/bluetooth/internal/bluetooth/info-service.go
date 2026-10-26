package bluetooth

import (
	bluetoothService "github.com/muka/go-bluetooth/api/service"
	"github.com/muka/go-bluetooth/bluez/profile/gatt"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
	"github.com/DZDomi/crypto-matrix/proto/gen/go/services/blt"
	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/clients/marketdataclient"
	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/clients/wificlient"
)

func getInfoService() *service {
	return &service{
		name:    "info",
		address: "1000",
		characteristics: map[string]*characteristic{
			"get-blt-com-state": {
				address: "1001",
				flags: []string{
					gatt.FlagCharacteristicRead,
				},
				onRead: onReadGetBltComState,
			},
			"get-market-state": {
				address: "1002",
				flags: []string{
					gatt.FlagCharacteristicRead,
				},
				onRead: onReadGetMarketState,
			},
			"connected-markets": {
				address: "1003",
				flags: []string{
					gatt.FlagCharacteristicNotify,
					gatt.FlagCharacteristicWrite,
				},
			},
			"get-wifi-state": {
				address: "1004",
				flags: []string{
					gatt.FlagCharacteristicRead,
				},
				onRead: onReadGetWifiState,
			},
			"disconnect": {
				address: "1005",
				flags: []string{
					gatt.FlagCharacteristicWrite,
				},
				onWrite: onWriteDisconnect,
			},
		},
	}
}

func onReadGetBltComState(_ *bluetoothService.Char, _ map[string]interface{}) ([]byte, error) {
	return handleSuccessResponse()
}

func onReadGetMarketState(_ *bluetoothService.Char, options map[string]interface{}) ([]byte, error) {
	connectedMarkets, err := marketdataclient.GetMarkets()
	if isError, resp := handleErrorWithResponse(err, blt.Error_ServerError); isError {
		return resp, nil
	}
	go notifyConnectedMarkets(connectedMarkets, options)
	return handleSuccessResponse()
}

func notifyConnectedMarkets(markets []*grpc_models.Market, options map[string]interface{}) {
	connectedMarketsChannel := advertisedServices["info"].characteristics["connected-markets"].ref
	if isError := handleErrorWithoutResponse(connectedMarketsChannel.StartNotify()); isError {
		return
	}

	for _, market := range markets {
		resp, _ := handleSuccessResponseWithMessage(market)
		dbusError := connectedMarketsChannel.WriteValue(resp, options)
		if isError := handleErrorWithoutResponse(dbusError); isError {
			return
		}
	}
	handleErrorWithoutResponse(connectedMarketsChannel.StopNotify())
}

func onReadGetWifiState(_ *bluetoothService.Char, _ map[string]interface{}) ([]byte, error) {
	connected, err := wificlient.IsConnected()
	if isError, resp := handleErrorWithResponse(err, blt.Error_ServerError); isError {
		return resp, nil
	}
	wifiStatusResponse := &blt.WifiStatusResponse{
		Connected: connected,
	}
	return handleSuccessResponseWithMessage(wifiStatusResponse)
}

func onWriteDisconnect(_ *bluetoothService.Char, _ []byte) ([]byte, error) {
	select {
	case done <- true:
		break
	default:
		break
	}
	return handleSuccessResponse()
}
