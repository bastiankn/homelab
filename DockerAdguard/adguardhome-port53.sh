#!/bin/bash

# Define variables
PORT=53
HOME_SERVER_IP="192.168.178.84"  # Replace with your AdGuard Home server's IP
DOCKER_IMAGE="adguard/adguardhome"
COMPOSE_FILE="docker-compose.yml"  # Specify your Docker Compose YAML file name

# Step 1: Pull the latest AdGuard Home Docker image
echo "Pulling AdGuard Home image..."
docker pull $DOCKER_IMAGE

# Step 2: Check if port 53 is in use
if sudo netstat -tuln | grep ":$PORT" > /dev/null; then
    echo "Port $PORT is already in use. Checking which service is using it..."

    # Identify the process using port 53
    PID=$(sudo lsof -t -i :$PORT)
    SERVICE=$(ps -p $PID -o comm=)

    echo "Service using port $PORT: $SERVICE (PID: $PID)"
    
    # Stop the service if it's systemd-related (systemd-resolved or bind9)
    if [ "$SERVICE" == "systemd-resolved" ]; then
        echo "Stopping systemd-resolved service..."
        sudo systemctl stop systemd-resolved
        sudo systemctl disable systemd-resolved
        sudo rm /etc/resolv.conf  # Remove systemd-generated resolv.conf
        sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf  # Recreate symlink if needed
        echo "systemd-resolved service stopped and disabled."
    elif [ "$SERVICE" == "bind9" ]; then
        echo "Stopping bind9 service..."
        sudo systemctl stop bind9
        sudo systemctl disable bind9
        echo "bind9 service stopped and disabled."
    else
        echo "Unknown service using port 53: $SERVICE"
    fi
else
    echo "Port $PORT is not in use. You can proceed with AdGuard setup."
fi

# Step 3: Build and run the Docker container using docker-compose without networking
echo "Starting AdGuard Home container without networking..."
docker-compose -f $COMPOSE_FILE up -d --no-deps --build

# Step 4: Now configure networking and DNS (once the container is running)
# Configure /etc/resolv.conf to use AdGuard Home IP
echo "Configuring /etc/resolv.conf to use $HOME_SERVER_IP as DNS server..."
echo "nameserver $HOME_SERVER_IP" | sudo tee /etc/resolv.conf > /dev/null

# Ensure /etc/resolv.conf has the correct permissions
sudo chmod 644 /etc/resolv.conf

# Step 5: Restart networking service
echo "Restarting networking service to apply changes..."
sudo systemctl restart networking || echo "Failed to restart networking service. Please ensure it's installed."

# Step 6: Verify DNS resolution with nslookup
echo "Testing DNS resolution with the new server..."
nslookup example.com

# Final message
echo "AdGuard Home setup complete. DNS should now be working through AdGuard Home."
