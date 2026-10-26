#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

git pull
go build -o wifi ./cmd/wifi
sudo systemctl stop crypto-matrix-wifi.service
sudo cp wifi /opt/crypto-matrix/wifi/bin/wifi
rm wifi
sudo systemctl start crypto-matrix-wifi.service
