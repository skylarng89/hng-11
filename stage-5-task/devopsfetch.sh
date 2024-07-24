#!/bin/bash

LOG_FILE="/var/log/devopsfetch.log"
exec > >(tee -a $LOG_FILE) 2>&1 || { echo "Failed to open log file for writing."; exit 1; }

# Log the start of the script
echo "Starting devopsfetch script at $(date)"

# Show help message
function show_help() {
    cat << EOF
Usage: $0 [OPTIONS]
Options:
  -p, --port              Display all active ports and services
  -p <port_number>        Provide detailed information about a specific port
  -d, --docker            List all Docker images and containers
  -d <container_name>     Provide detailed information about a specific container
  -n, --nginx             Display all Nginx domains and their ports
  -n <domain>             Provide detailed configuration information about a specific domain
  -u, --users             List all users and their last login times
  -u <username>           Provide detailed information about a specific user
  -t, --time              Display activities within a specified time range
  -h, --help              Show this help message
EOF
}

# Function to print a separator line
function print_separator() {
    echo "========================================="
}

# Function to log start and end times
function log_time() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# List all active ports and services
function list_ports() {
    if ! command -v netstat &> /dev/null; then
        echo "netstat command not found. Please install net-tools." | logger -t devopsfetch
        return 1
    fi

    log_time "Starting port list collection"
    netstat -tuln | awk 'BEGIN {printf "%-10s %-20s %-10s\n", "Protocol", "Local Address", "State"} NR>2 {printf "%-10s %-20s %-10s\n", $1, $4, $6}' || { echo "Failed to retrieve ports." | logger -t devopsfetch; return 1; }
    log_time "Finished port list collection"
    print_separator
}

# List all Docker images and containers
function list_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker command not found." | logger -t devopsfetch
        return 1
    fi

    if ! sudo systemctl is-active --quiet docker; then
        echo "Docker service is not running. Starting Docker service..." | logger -t devopsfetch
        sudo systemctl start docker || { echo "Failed to start Docker service." | logger -t devopsfetch; return 1; }
    fi

    log_time "Starting Docker images and containers collection"
    echo "Docker Images:"
    sudo docker images || { echo "Failed to retrieve Docker images." | logger -t devopsfetch; return 1; }
    echo ""
    echo "Docker Containers:"
    sudo docker ps -a || { echo "Failed to retrieve Docker containers." | logger -t devopsfetch; return 1; }
    log_time "Finished Docker images and containers collection"
    print_separator
}

# Provide detailed information about a specific container
function container_details() {
    if ! command -v docker &> /dev/null; then
        echo "Docker command not found." | logger -t devopsfetch
        return 1
    fi

    if ! sudo systemctl is-active --quiet docker; then
        echo "Docker service is not running. Starting Docker service..." | logger -t devopsfetch
        sudo systemctl start docker || { echo "Failed to start Docker service." | logger -t devopsfetch; return 1; }
    fi

    log_time "Starting Docker container details collection for container $1"
    docker inspect "$1" || { echo "Failed to retrieve information for container $1." | logger -t devopsfetch; return 1; }
    log_time "Finished Docker container details collection for container $1"
    print_separator
}

# List all Nginx domains and their ports
function list_nginx() {
    if ! command -v nginx &> /dev/null; then
        echo "Nginx command not found." | logger -t devopsfetch
        return 1
    fi

    log_time "Starting Nginx domains and ports collection"
    grep -E "server_name|listen" /etc/nginx/sites-available/* /etc/nginx/sites-enabled/* | awk 'BEGIN {printf "%-20s %-15s %-20s\n", "File", "Directive", "Value"} {printf "%-20s %-15s %-20s\n", $1, $2, $3}' || { echo "Failed to retrieve Nginx domains and ports." | logger -t devopsfetch; return 1; }
    log_time "Finished Nginx domains and ports collection"
    print_separator
}

# List all users and their last login times
function list_users() {
    if ! command -v lastlog &> /dev/null; then
        echo "lastlog command not found." | logger -t devopsfetch
        return 1
    fi

    log_time "Starting users and last login times collection"
    lastlog | awk 'BEGIN {printf "%-20s %-20s\n", "Username", "Last Login"} {printf "%-20s %-20s %-20s %-20s %-20s %-20s %-20s\n", $1, $4, $5, $6, $7, $8, $9}' || { echo "Failed to retrieve users." | logger -t devopsfetch; return 1; }
    log_time "Finished users and last login times collection"
    print_separator
}

# Main loop to collect information every 30 seconds
while true; do
    log_time "Collection cycle started"

    list_ports || echo "Port collection failed, proceeding to next task." | logger -t devopsfetch
    list_docker || echo "Docker collection failed, proceeding to next task." | logger -t devopsfetch
    list_nginx || echo "Nginx collection failed, proceeding to next task." | logger -t devopsfetch
    list_users || echo "User collection failed, proceeding to next task." | logger -t devopsfetch

    log_time "Collection cycle completed"
    print_separator
    # Run loop at intervals
    sleep 300
done

# Log the end of the script (this will not be reached if the script runs indefinitely)
echo "Ending devopsfetch script at $(date)"