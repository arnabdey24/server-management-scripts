#!/bin/bash

# Script to set up PostgreSQL in Docker on a remote VM
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
print_message "Starting PostgreSQL Docker setup script"

# Check if running as root or with sudo privileges
if [ "$EUID" -ne 0 ]; then
    print_warning "This script needs to be run with sudo privileges"
    exit 1
fi

# Prompt for PostgreSQL credentials
read -p "Enter PostgreSQL username: " PG_USER
read -s -p "Enter PostgreSQL password: " PG_PASSWORD
echo
read -p "Enter PostgreSQL database name: " PG_DB

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_message "Docker not found. Installing Docker and Docker Compose..."

    # Check if install-docker.sh exists and is executable
    if [ -f "./install-docker.sh" ] && [ -x "./install-docker.sh" ]; then
        ./install-docker.sh
    else
        print_warning "Docker installation script not found or not executable."
        print_warning "Please run install-docker.sh first or install Docker manually."
        exit 1
    fi
else
    print_message "Docker is already installed, continuing with setup..."
fi

# Create directory for PostgreSQL data
print_message "Creating directory for PostgreSQL data..."
mkdir -p ~/postgres-docker/data
cd ~/postgres-docker

# Create docker-compose.yml file
print_message "Creating docker-compose.yml file..."
cat > docker-compose.yml << EOF
services:
  postgres:
    image: postgres:latest
    container_name: postgres
    restart: always
    environment:
      POSTGRES_USER: ${PG_USER}
      POSTGRES_PASSWORD: ${PG_PASSWORD}
      POSTGRES_DB: ${PG_DB}
    ports:
      - "5432:5432"
    volumes:
      - ./data:/var/lib/postgresql/data
EOF

# Start PostgreSQL container
print_message "Starting PostgreSQL container..."
docker-compose up -d

# Wait for PostgreSQL to start
print_message "Waiting for PostgreSQL to start (30 seconds)..."
sleep 30

# Configure PostgreSQL to allow remote connections
print_message "Configuring PostgreSQL to allow remote connections..."

# Configure postgresql.conf
docker exec -i postgres bash << 'EOF'
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/postgresql/data/postgresql.conf
EOF

# Configure pg_hba.conf to allow connections from any IP
print_message "Configuring pg_hba.conf..."
docker exec -i postgres bash << 'EOF'
echo "host    all             all             0.0.0.0/0               md5" >> /var/lib/postgresql/data/pg_hba.conf
EOF

# Restart PostgreSQL container to apply changes
print_message "Restarting PostgreSQL container to apply changes..."
docker-compose restart

# Configure firewall to allow connections to port 5432
print_message "Configuring firewall to allow connections to port 5432..."
if command -v ufw > /dev/null; then
    ufw allow 5432/tcp
    print_message "Firewall rule added for port 5432"
else
    print_warning "UFW firewall not found. Please ensure port 5432 is open in your firewall manually."
fi

# Get the server's IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

# Display connection information
print_message "PostgreSQL server setup complete!"
echo "-----------------------------------------------"
echo "Connection Information:"
echo "Host: ${SERVER_IP}"
echo "Port: 5432"
echo "Username: ${PG_USER}"
echo "Password: [HIDDEN]"
echo "Database: ${PG_DB}"
echo "-----------------------------------------------"
echo "Connection string: postgresql://${PG_USER}:${PG_PASSWORD}@${SERVER_IP}:5432/${PG_DB}"
echo "Connect with psql: psql -h ${SERVER_IP} -U ${PG_USER} -d ${PG_DB}"
echo "-----------------------------------------------"
print_warning "SECURITY NOTICE: Your PostgreSQL server is now accessible from any IP address."
print_warning "For production environments, consider implementing additional security measures:"
print_warning "- Use a VPN or SSH tunnel instead of allowing all IPs"
print_warning "- Implement IP filtering"
print_warning "- Use SSL connections for encryption"
