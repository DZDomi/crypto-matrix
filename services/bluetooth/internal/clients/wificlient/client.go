package wificlient

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
	"github.com/DZDomi/crypto-matrix/proto/gen/go/services/wifi"
)

var service wifi.WifiServiceClient

func Connect(path string) error {
	conn, err := grpc.NewClient(path, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return err
	}
	service = wifi.NewWifiServiceClient(conn)
	return nil
}

func Scan() ([]*grpc_models.Network, error) {
	resp, err := service.Scan(context.Background(), &wifi.ScanRequest{})
	if err != nil {
		return nil, err
	}
	return resp.Networks, nil
}

func ConnectToNetwork(ssid string, password string) (bool, error) {
	resp, err := service.Connect(context.Background(), &wifi.ConnectRequest{
		Network: &grpc_models.Network{
			Ssid:     ssid,
			Password: password,
		},
	})
	if err != nil {
		return false, err
	}
	return resp.Connected, nil
}

func IsConnected() (bool, error) {
	resp, err := service.Status(context.Background(), &wifi.StatusRequest{})
	if err != nil {
		return false, err
	}
	return resp.Connected, nil
}
