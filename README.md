# MinimOS

Minimal UEFI "OS" in pure x86_64 assembly for fun and educational purposes.

## Features

- Written entirely in 64-bit NASM assembly
- Uses UEFI Simple Text Output/Input protocols for I/O
- Demonstrates:
  - ASCII to UTF-16 conversion on the fly
  - Reading keystrokes via `ConIn->WaitForKey` and `ReadKeyStroke`
  - Basic command parsing (`echo`, `reboot`, `run`)

## Requirements

- **NASM**
- **LLVM lld-link** or a PE-capable linker
- **QEMU** (to emulate UEFI x86_64)
- **OVMF** firmware (`edk2-ovmf` package)

