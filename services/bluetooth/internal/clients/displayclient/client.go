package displayclient

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
	"github.com/DZDomi/crypto-matrix/proto/gen/go/services/ledmatrix"
)

var service ledmatrix.LedMatrixServiceClient

func Connect(path string) error {
	conn, err := grpc.NewClient(path, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return err
	}
	service = ledmatrix.NewLedMatrixServiceClient(conn)
	return nil
}

func SetBrightness(percent int) (bool, error) {
	request := &ledmatrix.SetBrightnessRequest{
		Brightness: int32(percent),
	}
	resp, err := service.SetBrightness(context.Background(), request)
	if err != nil {
		return false, err
	}
	return resp.Success, nil
}

func SetDesign(design *grpc_models.Design) (bool, error) {
	request := &ledmatrix.SetDesignRequest{
		Design: design,
	}
	resp, err := service.SetDesign(context.Background(), request)
	if err != nil {
		return false, err
	}
	return resp.Success, nil
}

func EmptyRow(row uint) (bool, error) {
	request := &ledmatrix.EmptyRowRequest{
		Row: int32(row),
	}
	resp, err := service.EmptyRow(context.Background(), request)
	if err != nil {
		return false, err
	}
	return resp.Success, nil
}

func Clear() (bool, error) {
	resp, err := service.Clear(context.Background(), &ledmatrix.ClearRequest{})
	if err != nil {
		return false, err
	}
	return resp.Success, nil
}
