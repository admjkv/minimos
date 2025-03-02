#!/usr/bin/env bash
# Build and run minimos UEFI environment in Docker
set -e

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

echo "Building Docker image..."
docker build -t minimos-uefi:latest .

echo "Starting UEFI environment..."
docker run --rm -it \
    --device /dev/kvm \
    --security-opt seccomp=unconfined \
    -v "$(pwd)":/minimos \
    -w /minimos \
    minimos-uefi:latest \
    ./build-and-run.sh
