#!/bin/bash
# Install Pull Image because DNS Server removed
docker pull adguard/adguardhome

# Define the port to check
PORT=53
HOME_SERVER_IP="192.168.178.84"  # Replace with your AdGuard Home server's IP

# Check if port 53 is in use using ss
if sudo ss -tuln | grep ":$PORT" > /dev/null; then
    echo "Port $PORT is already in use. Checking which service is using it..."

    # Identify the process using the port (in case it's systemd related)
    PID=$(sudo lsof -t -i :$PORT)
    SERVICE=$(ps -p $PID -o comm=)

    echo "Service using port $PORT: $SERVICE (PID: $PID)"
    
    # Stop the service if it is running under systemd (common for DNS services like systemd-resolved or bind9)
    if [ "$SERVICE" == "systemd-resolved" ]; then
        echo "Stopping systemd-resolved service..."
        sudo systemctl stop systemd-resolved
        sudo systemctl disable systemd-resolved
        sudo rm /etc/resolv.conf  # Remove the systemd-generated resolv.conf
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

# Now configure /etc/resolv.conf to point to AdGuard Home or your home server's IP
echo "Configuring /etc/resolv.conf to use $HOME_SERVER_IP as DNS server..."
echo "nameserver $HOME_SERVER_IP" | sudo tee /etc/resolv.conf > /dev/null

# Ensure the /etc/resolv.conf has the right permissions
sudo chmod 644 /etc/resolv.conf

# Change to the directory where the .yaml and script are located
cd "$(dirname "$0")"

# Start AdGuard Home container using docker-compose
echo "Starting AdGuard Home container using docker-compose..."
docker-compose up -d

# Restart networking service to apply changes
echo "Restarting networking service..."
sudo systemctl restart networking

# Verify the DNS resolution
echo "Testing DNS resolution with the new server..."
nslookup example.com

echo "DNS configuration complete."
