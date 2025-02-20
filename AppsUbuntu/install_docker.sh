# Update packages
sudo apt update
sudo apt upgrade

# Install Docker
sudo apt install docker.io -y

# Install Docker Compose
sudo apt install docker-compose -y

# Permissons to Docker
sudo usermod -aG docker $USER
