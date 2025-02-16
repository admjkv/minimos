; kernel.asm - Minimal Kernel
; This kernel is loaded by the bootloader into memory at 0x9000.
; It prints "Hello, World!", prompts for input, echoes the input, and then shuts down.

[org 0x9000]           ; Specify load address (matches bootloader jump target)

start_kernel:
    ; Initialize data segments.
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Print the "Hello, World!" message.
    mov si, msg_hello
    call print_string

    ; Print prompt for user input.
    mov si, msg_prompt
    call print_string

    ; Read a string from the keyboard.
    lea di, [input_buffer]  ; DI points to our input buffer
    call read_string        ; Reads until Enter (CR) is pressed

    ; Print a newline.
    mov si, newline
    call print_string

    ; Echo the user's input back.
    mov si, input_buffer
    call print_string

    ; Print a shutdown message.
    mov si, newline
    call print_string
    mov si, msg_shutdown
    call print_string

    ; Attempt to shut down the machine.
    call shutdown

    ; If shutdown fails, halt the CPU in an infinite loop.
halt_loop:
    hlt
    jmp halt_loop

; -----------------------------------------------------------
; Subroutine: print_string
; Prints a null-terminated string pointed to by DS:SI using BIOS teletype.
; -----------------------------------------------------------
print_string:
    mov ah, 0x0E            ; BIOS teletype function
.print_loop:
    lodsb                   ; Load next character into AL
    cmp al, 0
    je .done
    int 0x10                ; Print character in AL
    jmp .print_loop
.done:
    ret

; -----------------------------------------------------------
; Subroutine: read_string
; Reads characters from the keyboard until the Enter key (CR) is pressed.
; Characters are echoed and stored at ES:DI, and a null terminator is appended.
; -----------------------------------------------------------
read_string:
.read_char:
    mov ah, 0
    int 0x16                ; BIOS keyboard service: wait for key press (AL receives character)
    cmp al, 13              ; Check if Enter key (ASCII 13) is pressed.
    je .done_read
    ; Echo the character.
    mov ah, 0x0E
    int 0x10
    ; Store the character at ES:DI.
    stosb
    jmp .read_char
.done_read:
    ; Append a null terminator to the string.
    mov al, 0
    stosb
    ret

; -----------------------------------------------------------
; Subroutine: shutdown (for QEMU with isa-debug-exit)
; Writes a nonzero value to port 0xF4 to signal QEMU to exit.
; The exit code will be (AL >> 1).
; -----------------------------------------------------------
shutdown:
    mov dx, 0xf4    ; Debug exit port for isa-debug-exit
    mov al, 0x02    ; Nonzero value (0x02 >> 1 = exit code 1)
    out dx, al
    jmp $           ; Halt if QEMU doesn't exit immediately

; -----------------------------------------------------------
; Data Section
; -----------------------------------------------------------
msg_hello:    db "Hello, World!", 0x0D, 0x0A, 0
msg_prompt:   db "Enter your message: ", 0
msg_shutdown: db " Shutting down...", 0x0D, 0x0A, 0
newline:      db 0x0D, 0x0A, 0

; Buffer for storing user input (128 bytes maximum).
input_buffer: times 128 db 0
