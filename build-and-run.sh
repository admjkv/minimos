#!/bin/bash
set -e

rm -rf efi_dir
mkdir -p efi_dir/EFI/BOOT

nasm -f win64 bootx64.asm -o bootx64.obj
lld-link /subsystem:efi_application /entry:_start /machine:x64 /out:BOOTx64.EFI bootx64.obj

cp BOOTx64.EFI efi_dir/EFI/BOOT/
cp /usr/share/edk2/x64/OVMF_VARS.4m.fd OVMF_VARS.fd

qemu-system-x86_64 \
  -accel kvm \
  -machine q35 \
  -serial stdio \
  -display none \
  \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
  -drive if=pflash,format=raw,file=OVMF_VARS.fd \
  \
  -drive file=fat:rw:efi_dir,format=raw,media=disk
