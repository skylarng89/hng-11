#!/bin/bash

# Install necessary dependencies
if ! sudo apt update; then
    echo "Could not update package list. Please try again."
    exit 1
fi

if ! sudo apt install -y net-tools; then
    echo "Could not install net-tools. Please try again."
    exit 1
fi

if ! sudo apt install docker.io && sudo systemctl start docker && sudo systemctl enable docker; then
    echo "Could not install docker.io. Please try again."
    exit 1
fi

# Create a systemd service file for devopsfetch
cat << EOF | sudo tee /etc/systemd/system/devopsfetch.service > /dev/null
[Unit]
Description=DevOps Fetch Service
After=network.target

[Service]
ExecStart=$HOME/devopsfetch.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=devopsfetch
User=root

[Install]
WantedBy=multi-user.target

EOF

if ! sudo systemctl daemon-reload; then
    echo "Could not reload systemd daemon. Please try again."
    exit 1
fi

if ! sudo systemctl enable devopsfetch.service; then
    echo "Could not enable devopsfetch service. Please try again."
    exit 1
fi

if ! sudo systemctl start devopsfetch.service; then
    echo "Could not start devopsfetch service. Please try again."
    exit 1
fi