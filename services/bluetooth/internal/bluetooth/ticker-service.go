package bluetooth

import (
	"errors"

	bluetoothService "github.com/muka/go-bluetooth/api/service"
	"github.com/muka/go-bluetooth/bluez/profile/gatt"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
	"github.com/DZDomi/crypto-matrix/proto/gen/go/services/blt"
	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/clients/displayclient"
	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/clients/marketdataclient"
)

func getTickerService() *service {
	return &service{
		name:    "ticker",
		address: "2000",
		characteristics: map[string]*characteristic{
			"set-brightness": {
				address: "2001",
				flags: []string{
					gatt.FlagCharacteristicWrite,
				},
				onWrite: onWriteSetBrightness,
			},
			"set-design": {
				address: "2002",
				flags: []string{
					gatt.FlagCharacteristicWrite,
				},
				onWrite: onWriteSetDesign,
			},
			"update-markets": {
				address: "2003",
				flags: []string{
					gatt.FlagCharacteristicWrite,
				},
				onWrite: onWriteUpdateMarkets,
			},
			"set-timeframe": {
				address: "2004",
				flags: []string{
					gatt.FlagCharacteristicWrite,
				},
				onWrite: onWriteSetTimeframe,
			},
		},
	}
}

func onWriteSetBrightness(_ *bluetoothService.Char, value []byte) ([]byte, error) {
	request := &blt.SetBrightnessRequest{}
	if isError, response := parseMessage(value, request); isError {
		return response, nil
	}

	success, err := displayclient.SetBrightness(int(request.Brightness))
	if isError, response := handleErrorWithResponse(err, blt.Error_ServerError); isError {
		return response, nil
	}

	if success {
		return handleSuccessResponse()
	} else {
		_, resp := handleErrorWithResponse(errors.New("unable to set brightness"), blt.Error_ServerError)
		return resp, nil
	}
}

func onWriteSetDesign(_ *bluetoothService.Char, value []byte) ([]byte, error) {
	request := &blt.SetDesignRequest{}
	if isError, response := parseMessage(value, request); isError {
		return response, nil
	}
	//markets, err := marketdataclient.GetMarkets()
	//if isError, response := handleErrorWithResponse(err, ServerError); isError {
	//	return response, nil
	//}
	//err = marketdataclient.ResetMarkets()
	//if isError, response := handleErrorWithResponse(err, ServerError); isError {
	//	return response, nil
	//}
	style := request.GetDesign().GetStyle()
	if _, ok := grpc_models.Design_Style_name[int32(style)]; !ok {
		_, response := handleErrorWithResponse(errors.New("invalid design style"), blt.Error_InvalidJson)
		return response, nil
	}
	design := &grpc_models.Design{
		Style: style,
	}
	success, err := displayclient.SetDesign(design)
	if isError, response := handleErrorWithResponse(err, blt.Error_ServerError); isError {
		return response, nil
	}
	if !success {
		_, response := handleErrorWithResponse(errors.New("unable to set design"), blt.Error_ServerError)
		return response, nil
	}

	success, err = displayclient.Clear()
	if isError, response := handleErrorWithResponse(err, blt.Error_ServerError); isError {
		return response, nil
	}
	if !success {
		_, response := handleErrorWithResponse(errors.New("unable to clear led matrix"), blt.Error_ServerError)
		return response, nil
	}

	switch design.Style {
	case grpc_models.Design_SINGLE_ASSET:
		err = marketdataclient.SendOHLCUpdate()
		if isError, response := handleErrorWithResponse(err, blt.Error_ServerError); isError {
			return response, nil
		}
		err = marketdataclient.SendLatestTrade()
		if isError, response := handleErrorWithResponse(err, blt.Error_ServerError); isError {
			return response, nil
		}
		break
	case grpc_models.Design_MULTI_ASSET:
		err = marketdataclient.SendLatestTrade()
		if isError, response := handleErrorWithResponse(err, blt.Error_ServerError); isError {
			return response, nil
		}
		break
	}

	return handleSuccessResponse()
}

func onWriteUpdateMarkets(_ *bluetoothService.Char, value []byte) ([]byte, error) {
	request := &blt.UpdateMarketsRequest{}
	if isError, response := parseMessage(value, request); isError {
		return response, nil
	}

	err := marketdataclient.SyncMarkets(request.Markets)
	if isError, response := handleErrorWithResponse(err, blt.Error_ServerError); isError {
		return response, nil
	}
	return handleSuccessResponse()
}

func onWriteSetTimeframe(_ *bluetoothService.Char, value []byte) ([]byte, error) {
	request := &blt.SetTimeframeRequest{}
	if isError, response := parseMessage(value, request); isError {
		return response, nil
	}
	err := marketdataclient.SetTimeframe(request.Timeframe)
	if isError, response := handleErrorWithResponse(err, blt.Error_ServerError); isError {
		return response, nil
	}
	return handleSuccessResponse()
}
