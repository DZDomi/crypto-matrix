#!/usr/bin/env bash

set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

cd "$(dirname "$0")"

# Only the display service runs as root, as it needs access to the GPIO pins
if ! id crypto-matrix &>/dev/null; then
  useradd --system --no-create-home --shell /usr/sbin/nologin crypto-matrix
fi

cp crypto-matrix.conf /etc/tmpfiles.d/
systemd-tmpfiles --create /etc/tmpfiles.d/crypto-matrix.conf

for unit in crypto-matrix-*.service; do
  name="${unit#crypto-matrix-}"
  name="${name%.service}"
  mkdir -p "/opt/crypto-matrix/$name/bin"
  cp "$unit" /etc/systemd/system/
done

systemctl daemon-reload

for unit in crypto-matrix-*.service; do
  systemctl enable "$unit"
done
