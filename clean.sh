#!/bin/bash
# clean.sh: Remove build artifacts.

echo "Cleaning up build artifacts..."
rm -f bootloader.bin kernel.bin os.img
rm -f BOOTx64.EFI bootx64.obj OVMF_VARS.fd
rm -f efi_dir/EFI/BOOT/BOOTx64.EFI
rmdir efi_dir/EFI/BOOT
rmdir efi_dir/EFI
rmdir efi_dir
echo "Cleanup complete."
