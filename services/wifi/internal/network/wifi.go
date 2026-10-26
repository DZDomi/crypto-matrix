package network

import (
	"errors"
	"fmt"
	"net"
	"net/http"
	"time"

	wifi "github.com/mark2b/wpa-connect"

	"github.com/DZDomi/crypto-matrix/proto/gen/go/grpc_models"
)

var exchangeUrls = map[grpc_models.Exchange]string{
	grpc_models.Exchange_Binance: "https://api.binance.com",
}

const healthCheckTimeout = 5 * time.Second

func ScanNetworks() ([]wifi.BSS, error) {
	networks, err := wifi.ScanManager.Scan()
	if err != nil {
		return nil, err
	}
	networksToSend := make([]wifi.BSS, 0)
	for _, network := range networks {
		if network.SSID == "" {
			continue
		}
		networksToSend = append(networksToSend, network)
	}
	return networksToSend, nil
}

func ConnectToNetwork(ssid string, password string, timeout time.Duration) (wifi.ConnectionInfo, error) {
	return wifi.ConnectManager.Connect(ssid, password, timeout)
}

func CheckNetworkConnection() error {
	iface, err := net.InterfaceByName("wlan0")
	if err != nil {
		return err
	}
	addresses, err := iface.Addrs()
	if err != nil {
		return err
	}
	if len(addresses) == 0 {
		return errors.New("no addresses assigned to iface: wlan0")
	}
	client := http.Client{
		Timeout: healthCheckTimeout,
	}
	for _, exchangeUrl := range exchangeUrls {
		response, err := client.Get(exchangeUrl)
		if err != nil {
			return err
		}
		if response.StatusCode != http.StatusOK {
			return errors.New(fmt.Sprintf("invalid status code received: %d", response.StatusCode))
		}
	}
	return nil
}
