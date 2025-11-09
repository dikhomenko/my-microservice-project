#!/bin/bash

# =============================================================================
# Development Tools Installation Script
# This script installs Docker, Docker Compose, Python and Django
# =============================================================================

set -e  # Exit on any error

# Debug: Print script start with timestamp
echo "=== Script started at $(date) with PID $$ ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if this is a Debian/Ubuntu compatible system
print_status "Checking system compatibility..."
if ! command_exists apt && ! command_exists apt-get; then
    print_error "ERROR: This script requires a Debian/Ubuntu-based system with apt."
    print_error "Current system is not compatible."
    exit 1
else
    print_success "Debian/Ubuntu compatible system detected"
fi

# Update package manager
print_status "Updating package manager..."
sudo apt update

# =============================================================================
# DOCKER INSTALLATION
# =============================================================================

print_status "Checking if Docker exists on the system..."
# Test if Docker is actually functional with timeout to prevent hanging
DOCKER_VERSION=""
if command_exists docker; then
    # Use timeout to prevent hanging on docker version command
    DOCKER_VERSION=$(timeout 5 docker version --format '{{.Client.Version}}' 2>/dev/null || timeout 5 docker --version 2>/dev/null | sed 's/Docker version \([^,]*\).*/\1/' || echo "")
fi

if [ -n "$DOCKER_VERSION" ] && [ "$DOCKER_VERSION" != "" ]; then
    print_success "Docker version $DOCKER_VERSION found, skipping installation..."
else
    print_status "Docker has not been found, installing Docker..."
    
    # Check for any existing Docker packages before installing
    print_status "Checking for existing Docker packages..."
    EXISTING_DOCKER=$(dpkg -l | grep -E "docker|containerd" 2>/dev/null || true)
    if [ ! -z "$EXISTING_DOCKER" ]; then
        print_status "Found existing Docker-related packages:"
        echo "$EXISTING_DOCKER"
        print_status "Skipping Docker installation to preserve existing setup."
        print_status "If you want to upgrade, please manually remove old packages first."
    else
        print_status "No conflicting Docker packages found, proceeding with installation..."
    
        # Install prerequisites
        sudo apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        
        # Add Docker's official GPG key
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        # Set up repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker Engine
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
        
        # Add current user to docker group
        sudo usermod -aG docker $USER
        
        print_success "Docker installed successfully!"
    fi
fi

# =============================================================================
# DOCKER COMPOSE INSTALLATION
# =============================================================================

print_status "Checking if Docker Compose exists on the system..."
if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
    if command_exists docker-compose; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        print_success "Docker Compose version $COMPOSE_VERSION found, skipping installation..."
    else
        COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "plugin")
        print_success "Docker Compose (plugin) version $COMPOSE_VERSION found, skipping installation..."
    fi
else
    print_status "Docker Compose has not been found, installing Docker Compose..."
    
    # Get latest version
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    # Download and install
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    print_success "Docker Compose installed successfully!"
fi

# =============================================================================
# PYTHON INSTALLATION
# =============================================================================

print_status "Checking if Python 3.9+ exists on the system..."
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)
    
    if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 9 ]; then
        print_success "Python version $PYTHON_VERSION found (3.9+), skipping installation..."
    else
        print_status "Python version $PYTHON_VERSION found, but version 3.9+ recommended."
        print_status "Keeping existing Python $PYTHON_VERSION to avoid breaking dependencies."
    fi
else
    print_status "Python has not been found, installing Python 3.9+..."
    
    # Install Python 3.9+
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update
    sudo apt-get install -y python3.9 python3.9-pip python3.9-venv python3.9-dev
    
    print_success "Python installed successfully!"
fi

# =============================================================================
# PIP INSTALLATION/UPDATE
# =============================================================================

print_status "Checking if pip exists on the system..."
if command_exists pip3 || python3 -m pip --version >/dev/null 2>&1; then
    PIP_VERSION=$(python3 -m pip --version | cut -d' ' -f2)
    print_success "pip version $PIP_VERSION found, attempting to update pip..."
    
    # Try to update pip with proper handling for externally managed environments
    if python3 -m pip install --user --upgrade pip 2>/dev/null; then
        print_success "pip updated successfully in user space!"
    elif python3 -m pip install --break-system-packages --upgrade pip 2>/dev/null; then
        print_success "pip updated successfully with --break-system-packages!"
    else
        print_status "pip update failed, but existing pip version $PIP_VERSION should work fine."
    fi
else
    print_status "pip has not been found, installing pip..."
    sudo apt-get install -y python3-pip
    print_success "pip installed successfully!"
fi

# =============================================================================
# DJANGO INSTALLATION
# =============================================================================

print_status "Checking if Django exists on the system..."
DJANGO_VERSION=$(python3 -c "import django; print(django.get_version())" 2>/dev/null)
if [ -n "$DJANGO_VERSION" ]; then
    print_success "Django version $DJANGO_VERSION found, skipping installation..."
else
    print_status "Django has not been found, installing Django via pip..."
    # Install Django with proper handling for externally managed environments
    print_status "Attempting Django installation..."
    
    # Try user installation first
    if python3 -m pip install --user Django 2>/dev/null; then
        print_success "Django installed successfully in user space!"
    else
        # If user installation fails due to externally managed environment, use break-system-packages
        print_status "User installation failed, trying with --break-system-packages flag..."
        if python3 -m pip install --break-system-packages Django 2>/dev/null; then
            print_success "Django installed successfully with --break-system-packages!"
        else
            # Try with sudo and --break-system-packages
            print_status "Attempting system-wide installation with elevated privileges..."
            if sudo python3 -m pip install --break-system-packages Django 2>/dev/null; then
                print_success "Django installed successfully system-wide!"
            else
                print_error "Failed to install Django. Please install manually with: pip install Django"
            fi
        fi
    fi
fi

# =============================================================================
# FINAL VERIFICATION
# =============================================================================

print_status "Verifying all installations..."

echo
print_status "=== Installation Summary ==="

# Docker verification
if command_exists docker; then
    # Test if Docker is actually functional
    if timeout 5 docker version >/dev/null 2>&1; then
        DOCKER_VERSION=$(timeout 5 docker version --format '{{.Client.Version}}' 2>/dev/null || echo "unknown")
        print_success "Docker: $DOCKER_VERSION (functional)"
    else
        print_error "Docker: Command exists but not functional (check Docker daemon status)"
    fi
else
    print_error "Docker: Not installed"
fi

# Docker Compose verification
COMPOSE_FUNCTIONAL=false
if command_exists docker-compose; then
    if timeout 5 docker-compose --version >/dev/null 2>&1; then
        COMPOSE_VERSION=$(docker-compose --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1 || echo "unknown")
        print_success "Docker Compose: $COMPOSE_VERSION (standalone)"
        COMPOSE_FUNCTIONAL=true
    fi
elif timeout 5 docker compose version >/dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "plugin")
    print_success "Docker Compose: $COMPOSE_VERSION (plugin)"
    COMPOSE_FUNCTIONAL=true
fi

if [ "$COMPOSE_FUNCTIONAL" = false ]; then
    print_error "Docker Compose: Not functional (requires working Docker)"
fi

# Python verification
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version 2>/dev/null | cut -d' ' -f2)
    print_success "Python: $PYTHON_VERSION"
else
    print_error "Python: Not installed"
fi

# Django verification
DJANGO_VERSION=$(python3 -c "import django; print(django.get_version())" 2>/dev/null)
if [ -n "$DJANGO_VERSION" ]; then
    print_success "Django: $DJANGO_VERSION"
else
    print_error "Django: Not installed"
fi

echo
print_success "Installation script completed!"
print_status "Note: If Docker was just installed, you may need to re-login to the terminal."
print_status "Or run: newgrp docker"