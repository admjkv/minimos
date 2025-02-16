#!/bin/bash
# build.sh: Build the bootloader and kernel, create the disk image, and run QEMU.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Assembling bootloader..."
nasm -f bin bootloader.asm -o bootloader.bin || { echo "Failed to build bootloader"; exit 1; }

echo "Assembling kernel..."
nasm -f bin kernel.asm -o kernel.bin || { echo "Failed to build kernel"; exit 1; }

echo "Creating disk image (os.img)..."
# Concatenate the bootloader and kernel into one disk image.
cat bootloader.bin kernel.bin > os.img

echo "Launching QEMU..."
# Launch QEMU with the disk image:
#   -drive: Specify the file, format, and interface (floppy in this case)
#   -no-reboot: Prevents QEMU from rebooting after shutdown
#   -nographic: Disables graphical output and directs serial I/O to the terminal
qemu-system-i386 -drive file=os.img,format=raw,if=floppy -no-reboot -nographic -device isa-debug-exit

