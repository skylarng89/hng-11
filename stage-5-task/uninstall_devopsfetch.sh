#!/bin/bash

# Stop the service
if ! sudo systemctl stop devopsfetch.service; then
    echo "Failed to stop devopsfetch service. Please try again."
    exit 1
fi

# Disable the service
if ! sudo systemctl disable devopsfetch.service; then
    echo "Failed to disable devopsfetch service. Please try again."
    exit 1
fi

# Remove the service file
if ! sudo rm /etc/systemd/system/devopsfetch.service; then
    echo "Failed to remove devopsfetch service file. Please try again."
    exit 1
fi

# Reload the systemd daemon
if ! sudo systemctl daemon-reload; then
    echo "Failed to reload systemd daemon. Please try again."
    exit 1
fi

# Optionally remove log files
if ! sudo rm /var/log/devopsfetch.log; then
    echo "Failed to remove devopsfetch log file. Please try again."
fi

echo "devopsfetch service has been uninstalled successfully."
