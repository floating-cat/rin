#!/bin/sh

sudo mkdir -p /run/systemd/system/nix-daemon.service.d/
sudo bash -c "cat > /run/systemd/system/nix-daemon.service.d/override.conf" << EOF
[Service]
Environment="https_proxy=http://127.0.0.1:1080"
EOF
sudo systemctl daemon-reload
sudo systemctl restart nix-daemon
