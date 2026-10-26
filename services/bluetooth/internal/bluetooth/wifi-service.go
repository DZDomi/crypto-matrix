package bluetooth

import (
	bluetoothService "github.com/muka/go-bluetooth/api/service"
	"github.com/muka/go-bluetooth/bluez/profile/gatt"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
	"github.com/DZDomi/crypto-matrix/proto/gen/go/services/blt"
	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/clients/wificlient"
)

func getWifiService() *service {
	return &service{
		name:    "wifi",
		address: "3000",
		characteristics: map[string]*characteristic{
			"start-scan-for-networks": {
				address: "3001",
				flags: []string{
					gatt.FlagCharacteristicRead,
				},
				onRead: onReadScanForNetworks,
			},
			"found-networks": {
				address: "3002",
				flags: []string{
					gatt.FlagCharacteristicNotify,
					gatt.FlagCharacteristicWrite,
				},
			},
			"connect-to-network": {
				address: "3003",
				flags: []string{
					gatt.FlagCharacteristicWrite,
				},
				onWrite: onWriteConnectToNetwork,
			},
			"connected-to-network": {
				address: "3004",
				flags: []string{
					gatt.FlagCharacteristicNotify,
					gatt.FlagCharacteristicWrite,
				},
			},
		},
	}
}

func onReadScanForNetworks(_ *bluetoothService.Char, options map[string]interface{}) ([]byte, error) {
	networks, err := wificlient.Scan()
	if isError, response := handleErrorWithResponse(err, blt.Error_ServerError); isError {
		return response, nil
	}
	go notifyFoundNetworks(networks, options)
	return handleSuccessResponse()
}

func notifyFoundNetworks(networks []*grpc_models.Network, options map[string]interface{}) {
	foundNetworkChannel := advertisedServices["wifi"].characteristics["found-networks"].ref
	if isError := handleErrorWithoutResponse(foundNetworkChannel.StartNotify()); isError {
		return
	}
	for _, network := range networks {
		resp, _ := handleSuccessResponseWithMessage(network)
		dbusError := foundNetworkChannel.WriteValue(resp, options)
		if isError := handleErrorWithoutResponse(dbusError); isError {
			return
		}
	}
	handleErrorWithoutResponse(foundNetworkChannel.StopNotify())
}

func onWriteConnectToNetwork(_ *bluetoothService.Char, value []byte) ([]byte, error) {
	request := &blt.WifiConnectRequest{}
	if isError, response := parseMessage(value, request); isError {
		return response, nil
	}
	go notifyConnectedNetwork(request)

	return handleSuccessResponse()
}

func notifyConnectedNetwork(request *blt.WifiConnectRequest) {
	connectedNetworkChannel := advertisedServices["wifi"].characteristics["connected-to-network"].ref
	if handleErrorWithoutResponse(connectedNetworkChannel.StartNotify()) {
		return
	}
	connected, err := wificlient.ConnectToNetwork(request.Ssid, request.Password)
	if handleErrorWithNotifyResponse(err, blt.Error_ServerError, connectedNetworkChannel) {
		return
	}
	resp, _ := handleSuccessResponseWithMessage(&blt.WifiConnectResponse{
		Connected: connected,
	})
	dbusError := connectedNetworkChannel.WriteValue(resp, nil)
	handleErrorWithoutResponse(dbusError)
	handleErrorWithoutResponse(connectedNetworkChannel.StopNotify())
}
