#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

git pull
go build -o bluetooth ./cmd/bluetooth
sudo systemctl stop crypto-matrix-bluetooth.service
sudo cp bluetooth /opt/crypto-matrix/bluetooth/bin/bluetooth
rm bluetooth
sudo systemctl start crypto-matrix-bluetooth.service
