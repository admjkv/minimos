#!/bin/bash
# clean.sh: Remove build artifacts.

echo "Cleaning up build artifacts..."
rm -f bootloader.bin kernel.bin os.img
echo "Cleanup complete."
