#!/bin/bash

echo "Pulling AdGuard Home image..."
docker pull adguard/adguardhome

PORT=53
HOME_SERVER_IP="192.168.1.100"  # Replace with your AdGuard Home server's IP

echo "Checking if port $PORT is in use..."
if sudo ss -tuln | grep ":$PORT" > /dev/null; then
    echo "Port $PORT is in use. Stopping systemd-resolved..."
    
    # Stop and disable systemd-resolved unconditionally
    sudo systemctl stop systemd-resolved
    sudo systemctl disable systemd-resolved
    
    # Ensure /etc/resolv.conf is properly set
    sudo rm -f /etc/resolv.conf
    sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
    
    echo "systemd-resolved has been stopped and disabled."
else
    echo "Port $PORT is free. Proceeding..."
fi

# Set /etc/resolv.conf to point to AdGuard Home
echo "Configuring /etc/resolv.conf to use $HOME_SERVER_IP as DNS server..."
echo "nameserver $HOME_SERVER_IP" | sudo tee /etc/resolv.conf > /dev/null
sudo chmod 644 /etc/resolv.conf

# Change to the directory where the script and docker-compose.yml are located
cd "$(dirname "$0")"

# Start AdGuard Home container using docker-compose
echo "Starting AdGuard Home container using docker-compose..."
docker-compose up -d

# Restart networking if possible
if systemctl list-units --full --all | grep -q "NetworkManager.service"; then
    echo "Restarting NetworkManager..."
    sudo systemctl restart NetworkManager
elif systemctl list-units --full --all | grep -q "networking.service"; then
    echo "Restarting networking service..."
    sudo systemctl restart networking
else
    echo "No known networking service found to restart."
fi

# Verify DNS resolution
echo "Testing DNS resolution..."
nslookup example.com

echo "AdGuard Home setup complete. DNS should now be working."
