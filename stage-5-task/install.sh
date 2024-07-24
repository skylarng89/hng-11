#!/bin/bash

# Install necessary dependencies
if ! sudo apt update && sudo apt -y upgrade; then
    echo "Could not update package list. Please try again."
    exit 1
fi

if ! sudo apt install -y net-tools; then
    echo "Could not install net-tools. Please try again."
    exit 1
fi

if ! sudo apt install -y nginx; then
    echo "Could not install Nginx. Please try again."
    exit 1
fi

if ! sudo apt install -y docker.io && sudo systemctl start docker && sudo systemctl enable docker; then
    echo "Could not install and enable Docker. Please try again."
    exit 1
fi

# if ! sudo groupadd docker; then
#     # echo "docker group not created. Please try again."
#     exit 1
# fi

# if ! sudo usermod -aG docker $USER ; then
#     echo "The user was not added to the docker group. Please try again."
#     exit 1
# fi

# Create a systemd service file for devopsfetch
cat << EOF | sudo tee /etc/systemd/system/devopsfetch.service > /dev/null
[Unit]
Description=DevOps Fetch Service
After=network.target

[Service]
ExecStart=$HOME/devopsfetch.sh
Restart=always
RestartSec=30
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

# Reload docker group...this should always be last
# if ! newgrp docker ; then
#     echo "docker group not reloaded. Please try again."
#     exit 1
# fi