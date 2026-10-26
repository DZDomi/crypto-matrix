#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

git pull
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
sudo systemctl stop crypto-matrix-display.service
sudo cp build/display /opt/crypto-matrix/display/bin/display
sudo cp -r fonts /opt/crypto-matrix/display
sudo systemctl start crypto-matrix-display.service
