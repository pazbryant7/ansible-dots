# Docker-Ansible Test Image

Dotfiles setup for archlinux and ubuntu

## Prerequisites

- Ansible
- Docker
- Docker Compose

## Usage

1. Start the containers:

   ```bash
   # for archlinux
   docker compose up -d `ansible-arch`

   # for ubuntu
   docker compose up -d `ansible-ubuntu`
   ```

2. Run the Ansible script:

   ```bash
   cd ansible-dots && ./dots
   ```

3. Verify installation:

   ```bash
   # For Arch container
   docker exec -it ansible-arch /usr/bin/zsh

   # For Ubuntu container
   docker exec -it ansible-ubuntu  /usr/bin/zsh
   ```

## Project Structure

- `docker-compose.yml`: Defines both containers and mounts Ansible directory
- `Dockerfile.archlinux`: Arch Linux container configuration
- `Dockerfile.ubuntu`: Ubuntu container configuration
- `local.yml`: Contains all Ansible-related files
