#!/bin/bash

mkdir /minimos/efi_dir
mkdir -p /minimos/efi_dir/EFI/BOOT

nasm -f win64 bootx64.asm -o bootx64.obj
lld-link /subsystem:efi_application /entry:_start /machine:x64 /out:BOOTx64.EFI bootx64.obj

cp BOOTx64.EFI /minimos/efi_dir/EFI/BOOT/

qemu-system-x86_64 \
  -enable-kvm \
  -bios /usr/share/edk2/x64/OVMF_CODE.4m.fd \
  -drive if=none,format=raw,file=fat:rw:/minimos/efi_dir,id=fs0 \
  -device usb-storage,drive=fs0
