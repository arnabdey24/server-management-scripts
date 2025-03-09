#!/bin/bash

# Script to install Docker and Docker Compose on a remote VM

# Exit script if any command fails
set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo privileges
if [ "$EUID" -ne 0 ]; then
    print_warning "This script needs to be run with sudo privileges"
    exit 1
fi

# Install Docker
print_message "Updating package list..."
apt update

print_message "Installing Docker..."
apt install -y docker.io

# Enable and start Docker service
print_message "Enabling and starting Docker service..."
systemctl enable --now docker

# Install Docker Compose
print_message "Installing Docker Compose..."
apt install -y docker-compose

# Verify installations
DOCKER_VERSION=$(docker --version)
COMPOSE_VERSION=$(docker-compose --version)

print_message "Docker installation complete!"
print_message "Docker version: ${DOCKER_VERSION}"
print_message "Docker Compose version: ${COMPOSE_VERSION}"
