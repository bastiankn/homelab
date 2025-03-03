# Update packages
sudo apt update
sudo apt upgrade

# Qemu for better performsnce
sudo apt install qemu-guest-agent
sudo systemctl start qemu-guest-agent.service


# Install Docker
sudo apt install docker.io -y

# Install Docker Compose
sudo apt install docker-compose -y

# Permissons to Docker
sudo usermod -aG docker $USER

# Reboot for changes to work
sudo reboot
