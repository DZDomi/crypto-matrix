package server

import (
	"context"
	"net"
	"os"
	"time"

	log "github.com/sirupsen/logrus"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
	"github.com/DZDomi/crypto-matrix/proto/gen/go/services/wifi"
	"github.com/DZDomi/crypto-matrix/services/wifi/internal/network"
)

const connectTimeout = time.Second * 30

var logger = log.WithField("service", "wifi")

func StartServer(path string) error {

	_ = os.Remove(path)

	listener, err := net.Listen("unix", path)
	if err != nil {
		return err
	}
	defer listener.Close()

	grpcServer := grpc.NewServer()
	wifi.RegisterWifiServiceServer(grpcServer, &WifiServiceImpl{})

	return grpcServer.Serve(listener)
}

type WifiServiceImpl struct {
	wifi.UnimplementedWifiServiceServer
}

func (impl *WifiServiceImpl) Scan(_ context.Context, _ *wifi.ScanRequest) (*wifi.ScanResponse, error) {
	foundNetworks, err := network.ScanNetworks()
	if err != nil {
		logger.WithError(err).Error("unable to scan for networks")
		return nil, status.Errorf(codes.Unknown, "unable to scan for networks: %s", err.Error())
	}
	serializedNetworks := make([]*grpc_models.Network, 0)
	for _, foundNetwork := range foundNetworks {
		keyMgmt := foundNetwork.KeyMgmt
		// wpa-connect only reports the RSN (WPA2/WPA3) key management, so legacy
		// WPA networks would show up as open networks without a password prompt
		if len(keyMgmt) == 0 && foundNetwork.Privacy {
			keyMgmt = []string{"wpa-psk"}
		}
		serializedNetworks = append(serializedNetworks, &grpc_models.Network{
			Ssid:    foundNetwork.SSID,
			Signal:  int32(foundNetwork.Signal),
			KeyMgmt: keyMgmt,
		})
	}
	return &wifi.ScanResponse{
		Networks: serializedNetworks,
	}, nil
}

func (impl *WifiServiceImpl) Status(_ context.Context, _ *wifi.StatusRequest) (*wifi.StatusResponse, error) {
	err := network.CheckNetworkConnection()
	if err != nil {
		logger.WithError(err).Warning("not connected to network")
	}
	return &wifi.StatusResponse{
		Connected: err == nil,
		Network:   nil,
	}, nil
}

func (impl *WifiServiceImpl) Connect(_ context.Context, in *wifi.ConnectRequest) (*wifi.ConnectResponse, error) {
	_, err := network.ConnectToNetwork(in.Network.Ssid, in.Network.Password, connectTimeout)
	if err != nil {
		logger.WithError(err).Error("unable to connect to network")
	}
	return &wifi.ConnectResponse{
		Connected: err == nil,
	}, nil
}

func (impl *WifiServiceImpl) Disconnect(_ context.Context, _ *wifi.DisconnectRequest) (*wifi.DisconnectResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "not implemented")
}
