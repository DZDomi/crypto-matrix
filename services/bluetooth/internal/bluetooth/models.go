package bluetooth

import bluetoothService "github.com/muka/go-bluetooth/api/service"

type service struct {
	name            string
	address         string
	characteristics map[string]*characteristic
}

type characteristic struct {
	address string
	flags   []string
	onRead  func(c *bluetoothService.Char, options map[string]interface{}) ([]byte, error)
	onWrite func(c *bluetoothService.Char, value []byte) ([]byte, error)
	ref     *bluetoothService.Char
}
