package bluetooth

import (
	"github.com/godbus/dbus/v5"
	bluetoothService "github.com/muka/go-bluetooth/api/service"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/anypb"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/services/blt"
)

func parseMessage(message []byte, object proto.Message) (bool, []byte) {
	err := protojson.UnmarshalOptions{
		DiscardUnknown: true,
	}.Unmarshal(message, object)
	return handleErrorWithResponse(err, blt.Error_InvalidJson)
}

func handleErrorWithoutResponse(err interface{}) bool {
	if !isErrorToHandle(err) {
		return false
	}

	//TODO
	logger.WithField("err", err).Error("handleErrorWithoutResponse")
	return true
}

func handleErrorWithResponse(err interface{}, message blt.Error) (bool, []byte) {
	if !isErrorToHandle(err) {
		return false, nil
	}

	// TODO:?
	logger.WithField("err", err).Error("handleErrorWithResponse")

	// Ignore error here because this can never fail :tm:
	resp, _ := protojson.Marshal(&blt.Response{
		Success: false,
		Error:   message,
	})
	return true, resp
}

func handleErrorWithNotifyResponse(err interface{}, message blt.Error, char *bluetoothService.Char) bool {
	if !isErrorToHandle(err) {
		return false
	}
	_, response := handleErrorWithResponse(err, message)
	// TODO: Pass the options of the original request instead of nil
	return handleErrorWithoutResponse(char.WriteValue(response, nil))
}

func handleSuccessResponse() ([]byte, error) {
	resp, _ := protojson.Marshal(&blt.Response{
		Success: true,
		Error:   blt.Error_NoError,
	})
	return resp, nil
}

func handleSuccessResponseWithMessage(message proto.Message) ([]byte, error) {
	any, err := anypb.New(message)
	if err != nil {
		logger.WithError(err).Panic("unable to create any object")
	}
	response := &blt.Response{
		Success: true,
		Error:   blt.Error_NoError,
		Message: any,
	}
	serializedResponse, _ := protojson.MarshalOptions{
		EmitUnpopulated: true,
	}.Marshal(response)
	logger.WithField("message", string(serializedResponse)).Debug("sending message")
	return serializedResponse, nil
}

func isErrorToHandle(err interface{}) bool {
	switch err.(type) {
	case nil:
		return false
	case *dbus.Error:
		dbusError := err.(*dbus.Error)
		return dbusError != nil
	case error:
		return true
	}
	return false
}
