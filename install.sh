#!/bin/bash

# User input
echo "Enter timezone (e.g. Europe/Berlin):"
read timezone

declare gitUrl="https://github.com/PaddeCraft/simple-home-server.git"

# Function that waits for user pressing enter
function waitForEnter() {
    echo "Press ENTER to continue..."
    read
}

# Packages:
sudo apt-get update
sudo apt-get install -y curl net-tools avahi-daemon avahi-utils git


# Docker:
sudo curl -fsSL https://get.docker.com | sh

# Install Yacht:
sudo docker volume create yacht
sudo docker run --restart=always -d \
    --name yacht \
    -p 1001:8000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v yacht:/config selfhostedpro/yacht


# Install homeassistant:
sudo docker run --restart=always -d \
    --name homeassistant \
    --privileged \
    -e TZ=$timezone \
    -v /VOLUME:/config \
    --network=host \
    ghcr.io/home-assistant/home-assistant:stable

# Install Nextcloud:
sudo docker run -d --restart=always \
    --name nextcloud \
    -p 1003:80 \
    nextcloud


# Install User Dashboard
sudo docker run -d --restart=always \
    -p 80:8080 \
    --name dashboard \
    -v /assets:/www/assets \
    b4bz/homer:latest


# Install Admin Dashboard:
sudo apt-get install -y cockpit cockpit-machines


# Configure Homer:
sudo mkdir /assets/ || true

# Download assets:
cd ~/
git clone $gitUrl
cd simple-home-server
sudo cp -r ./assets/* /assets/


# declare ipAddress=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
# Ask for the IP address of the server
echo "Enter IP address of the server:"
read ipAddress

# Ask for .local domain name(s) for the server
echo "Enter .local domain name for the server:"
read domainName

# sudo avahi-publish -a -R $domainName $ipAddress


# Install PiHole:
sudo docker volume create pihole_app
sudo docker volume create dns_config
sudo docker pull pihole/pihole
sudo systemctl stop systemd-resolved
sudo docker run --restart=always -d \
    --name=pihole \
    -e TZ=$timezone \
    -e SERVERIP=0.0.0.0 \
    -v pihole_app:/etc/pihole \
    -v dns_config:/etc/dnsmasq.d \
    -p 1002:80 -p 53:53/tcp -p 53:53/udp \
    pihole/pihole
sudo docker exec -it pihole /bin/bash pihole -a -p admin
sudo systemctl start systemd-resolved

# Tell user to change default credentials:
echo "Successfully installed all components."
echo "Please change the default credentials or create your accounts."
echo ""
echo "Navigate to $ipAddress if you use LAN on the server."
echo ""
echo "Yacht:           Default username: admin@yacht.local"
echo "Yacht:           Default password: pass"
echo ""
echo "PiHole:          Default password: admin"
echo "PiHole:          Run 'sudo docker exec -it pihole /bin/bash pihole -a -p'"
echo ""
echo "Dashboard:       Any user account from this server"
echo ""
echo "Homeassistant:   No default credentials"
echo "Nextcloud:       No default credentials"