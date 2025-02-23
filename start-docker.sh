#!/usr/bin/env bash
set -e

docker build -t minimos-uefi .

docker run --rm -it \
    --device /dev/kvm \
    --security-opt seccomp=unconfined \
    -v "$(pwd)":/minimos \
    -w /minimos \
    minimos-uefi \
    ./build-and-run.sh
