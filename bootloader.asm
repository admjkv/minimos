; bootloader.asm - Minimal Bootloader (512 bytes)
; This bootloader is loaded by the BIOS at 0x7C00.
; It reads one sector (sector 2) from the boot drive into memory at 0x9000,
; then jumps to that kernel code.

[org 0x7C00]           ; Set origin where BIOS loads this code (0x7C00)

start:
    ; Save boot drive number (BIOS passes it in DL)
    mov [boot_drive], dl

    ; Initialize segment registers for a simple flat memory model.
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00     ; Set up a safe stack pointer

    ; Load the kernel from disk (sector 2) into memory at 0x9000.
    ; BIOS INT 13h, function 02h: Read sectors.
    mov bx, 0x9000     ; Destination address (DS:BX = 0:9000)
    mov dh, 0        ; Head 0
    mov ch, 0        ; Cylinder 0
    mov cl, 2        ; Sector 2 (sector 1 is the bootloader)
    mov dl, [boot_drive] ; Boot drive number (saved from DL)
    mov ah, 0x02     ; BIOS read sectors function
    mov al, 3        ; Read 3 sectors (1536 bytes)
    int 0x13         ; BIOS disk interrupt
    jc disk_error    ; If error (carry flag set), jump to error handler

    ; Jump to the loaded kernel at 0x9000.
    jmp 0x900:0x0000    ; Jump CS=0x900 and IP=0x0000 point to start_kernel.

disk_error:
    ; On disk error, display an error message and halt.
    mov si, errorMsg
    call print_string
    jmp $

; -----------------------------------------------------------
; Subroutine: print_string
; Prints a null-terminated string pointed to by DS:SI using BIOS teletype.
; -----------------------------------------------------------
print_string:
    mov ah, 0x0E     ; BIOS teletype output function
.print_loop:
    lodsb            ; Load next byte from DS:SI into AL
    cmp al, 0
    je .done
    int 0x10         ; BIOS video interrupt to print character in AL
    jmp .print_loop
.done:
    ret

; Data storage.
boot_drive: db 0           ; Will hold the boot drive number from BIOS
errorMsg:   db "Disk read error!", 0

; Fill remaining space to make a 510-byte boot sector.
times 510 - ($ - $$) db 0

; Boot signature (0x55AA) must be at bytes 511-512.
dw 0xAA55
