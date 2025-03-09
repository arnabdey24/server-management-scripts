#!/bin/bash

# Script to set up MinIO in Docker on a remote VM
# accessible from any IP address

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

# Welcome message
print_message "Starting MinIO Docker setup script"

# Check if running as root or with sudo privileges
if [ "$EUID" -ne 0 ]; then
    print_warning "This script needs to be run with sudo privileges"
    exit 1
fi

# Set default MinIO credentials if not provided as arguments
MINIO_ROOT_USER=${1:-"minioadmin"}
MINIO_ROOT_PASSWORD=${2:-"minioadmin"}
MINIO_PORT=${3:-"9000"}
MINIO_CONSOLE_PORT=${4:-"9001"}

print_message "Using MinIO credentials:"
print_message "Root User: $MINIO_ROOT_USER"
print_message "Root Password: [HIDDEN]"
print_message "API Port: $MINIO_PORT"
print_message "Console Port: $MINIO_CONSOLE_PORT"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_message "Docker not found. Installing Docker and Docker Compose..."

    # Install Docker
    apt update
    apt install -y docker.io docker-compose
    systemctl enable --now docker
else
    print_message "Docker is already installed, continuing with setup..."
fi

# Create directory for MinIO data
print_message "Creating directory for MinIO data..."
mkdir -p ~/minio-docker/data
cd ~/minio-docker

# Create docker-compose.yml file
print_message "Creating docker-compose.yml file..."
cat > docker-compose.yml << 'EOL'
version: '3'
services:
  minio:
    image: minio/minio:latest
    container_name: minio
    restart: always
    environment:
      MINIO_ROOT_USER: "${MINIO_ROOT_USER}"
      MINIO_ROOT_PASSWORD: "${MINIO_ROOT_PASSWORD}"
    ports:
      - "${MINIO_PORT}:9000"
      - "${MINIO_CONSOLE_PORT}:9001"
    volumes:
      - ./data:/data
    command: server /data --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3
EOL

# Replace the placeholders with actual values
sed -i "s/\"\${MINIO_ROOT_USER}\"/${MINIO_ROOT_USER}/g" docker-compose.yml
sed -i "s/\"\${MINIO_ROOT_PASSWORD}\"/${MINIO_ROOT_PASSWORD}/g" docker-compose.yml
sed -i "s/\"\${MINIO_PORT}\"/${MINIO_PORT}/g" docker-compose.yml
sed -i "s/\"\${MINIO_CONSOLE_PORT}\"/${MINIO_CONSOLE_PORT}/g" docker-compose.yml

# Start MinIO container
print_message "Starting MinIO container..."
docker-compose up -d

# Configure firewall to allow connections to MinIO ports
print_message "Configuring firewall to allow connections to MinIO ports..."
if command -v ufw > /dev/null; then
    ufw allow ${MINIO_PORT}/tcp
    ufw allow ${MINIO_CONSOLE_PORT}/tcp
    print_message "Firewall rules added for ports ${MINIO_PORT} and ${MINIO_CONSOLE_PORT}"
else
    print_warning "UFW firewall not found. Please ensure ports ${MINIO_PORT} and ${MINIO_CONSOLE_PORT} are open in your firewall manually."
fi

# Wait for MinIO to start
print_message "Waiting for MinIO to start (10 seconds)..."
sleep 10

# Get the server's IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

# Display connection information
print_message "MinIO server setup complete!"
echo "-----------------------------------------------"
echo "Connection Information:"
echo "Host: ${SERVER_IP}"
echo "API Port: ${MINIO_PORT}"
echo "Console Port: ${MINIO_CONSOLE_PORT}"
echo "Username: ${MINIO_ROOT_USER}"
echo "Password: [HIDDEN]"
echo "-----------------------------------------------"
echo "S3 API Endpoint: http://${SERVER_IP}:${MINIO_PORT}"
echo "Web Console URL: http://${SERVER_IP}:${MINIO_CONSOLE_PORT}"
echo "-----------------------------------------------"
print_warning "SECURITY NOTICE: Your MinIO server is now accessible from any IP address."
print_warning "For production environments, consider implementing additional security measures:"
print_warning "- Use TLS/SSL for secure connections"
print_warning "- Implement proper access control policies"
print_warning "- Consider using a reverse proxy with authentication"
