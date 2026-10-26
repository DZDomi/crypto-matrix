#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

git pull
go build -o market-data ./cmd/market-data
sudo systemctl stop crypto-matrix-market-data.service
sudo cp market-data /opt/crypto-matrix/market-data/bin/market-data
rm market-data
sudo systemctl start crypto-matrix-market-data.service
