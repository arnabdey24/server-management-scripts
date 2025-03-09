# Server Management Scripts

This repository contains scripts to manage remote VM.

## Scripts

Script to install Docker and Docker Compose:
```bash
curl -sSL https://raw.githubusercontent.com/arnabdey24/server-management-scripts/master/install-docker.sh | bash
```

Script to set up PostgreSQL in Docker:
```bash
# Method 1: With default credentials (username=postgres, password=postgres, db=postgres)
curl -sSL https://raw.githubusercontent.com/arnabdey24/server-management-scripts/master/postgres-docker-setup.sh | bash

# Method 2: Specify custom credentials as arguments
curl -sSL https://raw.githubusercontent.com/arnabdey24/server-management-scripts/master/postgres-docker-setup.sh | bash -s username password dbname
```

Script to set up Minio in Docker:
```bash
curl -sSL https://raw.githubusercontent.com/arnabdey24/server-management-scripts/master/minio-docker-setup.sh | bash -s access_key secret_key 9000 9001
```

## Prerequisites

- A remote VM with a Linux operating system.
- Sudo privileges on the VM.
