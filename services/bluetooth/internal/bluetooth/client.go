package bluetooth

import (
	"time"

	bluetoothService "github.com/muka/go-bluetooth/api/service"
	"github.com/muka/go-bluetooth/bluez/profile/agent"
	"github.com/muka/go-bluetooth/bluez/profile/device"
	"github.com/muka/go-bluetooth/hw"
	log "github.com/sirupsen/logrus"

	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/config"
	"github.com/DZDomi/crypto-matrix/services/bluetooth/internal/must"
)

// 6 hours, after this we have to re advertise
const advertiseTimeout = uint32(60 * 60 * 6)
const isStillConnectedTimeout = 15 * time.Second

type CancelAdvertisement func()
type Client struct {
	app      *bluetoothService.App
	services []*service

	cancelAdvertisement CancelAdvertisement
	advertiseTimer      *time.Timer
	stopTimer           chan bool

	isStillConnected *time.Ticker
	//done             chan bool
}

// TODO: Change to being inside the client
var done = make(chan bool, 1)

var logger = log.WithField("service", "bluetooth")

var advertisedServices = make(map[string]*service)

func init() {
	advertisedServices["info"] = getInfoService()
	advertisedServices["ticker"] = getTickerService()
	advertisedServices["wifi"] = getWifiService()
}

func GetClient(cfg config.Config) *Client {
	client := &Client{
		app:       initAdapter(cfg),
		stopTimer: make(chan bool),
	}
	client.registerServices()
	return client
}

func (client *Client) registerServices() {
	for _, s := range advertisedServices {
		serv, err := client.app.NewService(s.address)
		must.Succeed(err)
		must.Succeed(client.app.AddService(serv))
		// go-bluetooth does not add the service to the advertisement on its own,
		// but the app scans for devices by service UUID
		client.app.GetAdvertisement().AddServiceUUID(s.address)

		for name, char := range s.characteristics {
			c, err := serv.NewChar(char.address)
			must.Succeed(err)

			char.ref = c
			c.Properties.Flags = char.flags
			func(name string, c *bluetoothService.Char, char *characteristic) {
				if char.onRead != nil {
					c.OnRead(func(c *bluetoothService.Char, options map[string]interface{}) ([]byte, error) {
						logger.WithFields(log.Fields{
							"function": "onRead",
							"char":     name,
						}).Infof("received message")
						client.refreshTimer()
						return char.onRead(c, options)
					})
				}
				if char.onWrite != nil {
					c.OnWrite(func(c *bluetoothService.Char, value []byte) ([]byte, error) {
						logger.WithFields(log.Fields{
							"function": "onWrite",
							"char":     name,
							"message":  string(value),
						}).Infof("received message")
						client.refreshTimer()
						return char.onWrite(c, value)
					})
				}
			}(name, c, char)

			must.Succeed(serv.AddChar(c))
			logger.WithFields(log.Fields{
				"characteristic": name,
				"service":        s.name,
			}).Info("Registered characteristic")
		}
		logger.WithFields(log.Fields{
			"service": s.name,
		})
		logger.Println("Registered service")
	}
}

func (client *Client) Run() {
	must.Succeed(client.app.Run())
	must.Succeed(client.startAdvertising())

	watchdog := time.NewTicker(1 * time.Second)
	go func() {
		for {
			select {
			case <-watchdog.C:
				client.checkForConnectedDevices()
			}
		}
	}()
}

func (client *Client) cancelAdvertise() {
	if client.cancelAdvertisement != nil {
		logger.Info("Found old cancel advertising, cancelling...")
		client.cancelAdvertisement()
		client.cancelAdvertisement = nil
	}
	client.sendStopTimer()
}

func (client *Client) startAdvertising() error {
	client.cancelAdvertise()
	logger.Info("Starting advertising...")
	var err error
	client.cancelAdvertisement, err = client.app.Advertise(advertiseTimeout)
	if err != nil {
		return err
	}
	client.advertiseTimer = time.NewTimer(time.Duration(advertiseTimeout) * time.Second)
	go func(t *time.Timer) {
		select {
		case <-t.C:
			// TODO
			must.Succeed(client.startAdvertising())
			break
		case <-client.stopTimer:
			// Nothing to do just exit the select
			logger.Info("Got stop signal, exiting timer")
		}
	}(client.advertiseTimer)
	logger.Println("Advertising...")
	return nil
}

func (client *Client) sendStopTimer() {
	select {
	case client.stopTimer <- true:
		logger.Info("Sending stop signal to old timer")
		break
	default:
		logger.Info("No old timer listening, not sending stop signal")
		break
	}
}

func (client *Client) getConnectedDevices() ([]*device.Device1, error) {
	devices, _ := client.app.GetAdapter().GetDevices()
	connectedDevices := make([]*device.Device1, 0)
	for _, availableDevice := range devices {
		connected, err := availableDevice.GetConnected()
		if err != nil {
			return nil, err
		}
		if connected {
			connectedDevices = append(connectedDevices, availableDevice)
		}
	}
	return connectedDevices, nil
}

func (client *Client) checkForConnectedDevices() {
	connectedDevices, err := client.getConnectedDevices()
	//TODO ?
	must.Succeed(err)
	if len(connectedDevices) > 0 && client.cancelAdvertisement != nil {
		client.cancelAdvertise()
		for _, availableDevice := range connectedDevices {
			logger.Infof("Connected: Device: %s, Connected: %t", availableDevice.Properties.Name, availableDevice.Properties.Connected)
		}
		client.waitForDisconnect(func() {
			client.disconnect()
		})
	}
}

func (client *Client) waitForDisconnect(expired func()) {
	go func() {
		client.isStillConnected = time.NewTicker(isStillConnectedTimeout)
		defer expired()
		defer client.isStillConnected.Stop()
		select {
		case <-client.isStillConnected.C:
			logger.Println("Received timer timeout, stopping")
			return
		case <-done:
			logger.Println("Received done channel, stopping")
			return
		}
	}()
}

func (client *Client) refreshTimer() {
	client.isStillConnected.Reset(isStillConnectedTimeout)
}

func (client *Client) disconnect() {
	connectedDevices, err := client.getConnectedDevices()
	//TODO?
	must.Succeed(err)
	for _, connectedDevice := range connectedDevices {
		err = connectedDevice.Disconnect()
		//TODO?
		must.Succeed(err)
	}
	must.Succeed(client.startAdvertising())
}

func (client *Client) Close() {
	client.app.Close()
}

func initAdapter(cfg config.Config) *bluetoothService.App {

	btMgmt := hw.NewBtMgmt(cfg.AdapterId)
	// set LE mode
	must.Succeed(btMgmt.SetPowered(false))
	must.Succeed(btMgmt.SetLe(true))
	must.Succeed(btMgmt.SetBredr(false))
	must.Succeed(btMgmt.SetPowered(true))

	options := bluetoothService.AppOptions{
		AdapterID:  cfg.AdapterId,
		AgentCaps:  agent.CapNoInputNoOutput,
		UUID:       cfg.BaseUUIDPrefix,
		UUIDSuffix: cfg.BaseUUIDSuffix,
	}

	app, err := bluetoothService.NewApp(options)
	must.Succeed(err)

	if !app.Adapter().Properties.Powered {
		must.Succeed(app.Adapter().SetPowered(true))
	}
	if app.GetAdapter().Properties.Pairable {
		must.Succeed(app.GetAdapter().SetPairable(false))
	}

	app.SetName(cfg.AppName)
	return app
}
