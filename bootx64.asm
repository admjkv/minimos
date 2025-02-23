; ===========================================================================
; bootx64.asm - Minimal UEFI "kernel" in NASM x86_64 assembly
; ===========================================================================
; This example:
;  - Prints a welcome banner via UEFI ConOut->OutputString
;  - Has a tiny CLI with commands: echo, reboot, run (placeholder).
;  - Demonstrates reading keyboard input via ConIn->ReadKeyStroke
;  - Illustrates a (fake) run command that would load another .EFI program.
;
; Build steps (example):
;   nasm -f win64 bootx64.asm -o bootx64.o
;   lld -subsystem=efi_application -entry=_start -o BOOTx64.EFI bootx64.o
; or (with GNU ld + a PE linker script).
;
; Copy BOOTx64.EFI to \EFI\BOOT\BOOTx64.EFI on a FAT32 partition.
; Boot on a UEFI system or QEMU/OVMF to see the prompt.
; ===========================================================================
[bits 64]

%include "uefi.inc"

section .text
global _start               ; UEFI entry point

; Data references (pointers to system table, etc.) are in .data
extern _DYNAMIC             ; needed by some linkers to create a valid PE

; ---------------------------------------------------------------------------
; UEFI Entry Point
;   RCX = ImageHandle
;   RDX = EFI_SYSTEM_TABLE*
; ---------------------------------------------------------------------------
_start:
    ; Store arguments
    mov     [OurImageHandle], rcx
    mov     [SystemTablePtr], rdx

    ; Print a welcome banner:
    ;   rax = SystemTable
    mov     rax, [SystemTablePtr]
    ;   r8 = ConOut pointer -> [rax + EFI_SYSTEM_TABLE_ConOut]
    mov     r8, [rax + EFI_SYSTEM_TABLE_ConOut]
    ;   rcx = this pointer (ConOut), rdx = address of string
    mov     rcx, r8
    mov     rdx, WelcomeStr
    ;   call OutputString -> [r8 + offset]
    call    [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]

MainLoop:
    ; Print prompt
    mov     rax, [SystemTablePtr]
    mov     r8, [rax + EFI_SYSTEM_TABLE_ConOut]
    mov     rcx, r8
    mov     rdx, PromptStr
    call    [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]

    ; Read a line into InputBuffer
    mov     rdi, InputBuffer
    call    ReadLine

    ; rdi points to the command text. Parse & execute
    call    ParseCommand

    ; If ParseCommand returns 0 in rax, the command is handled.
    ; If it returns non-zero (ConOut pointer), we print "Unknown command."
    cmp     rax, 0
    je      .done
    mov     rcx, rax
    mov     rdx, UnknownCmdStr
    call    [rax + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]

.done:
    jmp     MainLoop

; ---------------------------------------------------------------------------
; ParseCommand
;   rdi -> input line
;   returns rax=0 if recognized/handled, else rax=ConOut pointer
; ---------------------------------------------------------------------------
ParseCommand:
    push    rbx

    ; Skip leading spaces
    call    SkipSpaces
    ; rdi -> start of command token
    mov     rbx, rdi

    ; If empty line => do nothing
    cmp     byte [rbx], 0
    je      .empty

    ; Compare with "echo"
    push    rdi
    mov     rsi, CMD_ECHO
    call    StrCmpToken
    add     rsp, 8
    cmp     rax, 0
    je      .do_echo

    ; Compare with "reboot"
    push    rdi
    mov     rsi, CMD_REBOOT
    call    StrCmpToken
    add     rsp, 8
    cmp     rax, 0
    je      .do_reboot

    ; Compare with "run"
    push    rdi
    mov     rsi, CMD_RUN
    call    StrCmpToken
    add     rsp, 8
    cmp     rax, 0
    je      .do_run

    ; Not recognized => return ConOut pointer for "Unknown command" print
    mov     rax, [SystemTablePtr]
    mov     rax, [rax + EFI_SYSTEM_TABLE_ConOut]
    pop     rbx
    ret

.empty:
    xor     rax, rax
    pop     rbx
    ret

.do_echo:
    ; skip "echo"
    call    SkipToken
    call    SkipSpaces
    ; now rdi -> string to echo
    mov     rax, [SystemTablePtr]
    mov     r8, [rax + EFI_SYSTEM_TABLE_ConOut]
    mov     rcx, r8
    mov     rdx, rdi
    call    [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]

    ; newline
    mov     rdx, CRLF
    call    [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]

    xor     rax, rax
    pop     rbx
    ret

.do_reboot:
    ; call ResetSystem(ResetCold, ...)
    mov     rax, [SystemTablePtr]
    mov     r8, [rax + EFI_SYSTEM_TABLE_RuntimeServices]
    mov     rcx, ResetCold   ; reset type
    xor     rdx, rdx         ; reset status
    xor     r9, r9           ; reset data
    xor     rax, rax         ; data size
    ; [r8 + EFI_RUNTIME_SERVICES_ResetSystem]
    call    [r8 + EFI_RUNTIME_SERVICES_ResetSystem]
    ; if it returns, do nothing else
    xor     rax, rax
    pop     rbx
    ret

.do_run:
    ; skip "run"
    call    SkipToken
    call    SkipSpaces
    ; rdi -> filename
    cmp     byte [rdi], 0
    je      .done_run

    ; "fake" loading + starting another EFI, just to demonstrate
    call    FakeLoadAndStartImage

.done_run:
    xor     rax, rax
    pop     rbx
    ret

; ---------------------------------------------------------------------------
; FakeLoadAndStartImage - placeholder for "run" command
; ---------------------------------------------------------------------------
FakeLoadAndStartImage:
    ; Just print "Running <filename>\r\n"
    mov     rax, [SystemTablePtr]
    mov     r8, [rax + EFI_SYSTEM_TABLE_ConOut]
    mov     rcx, r8
    mov     rdx, RunningStr
    call    [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]

    mov     rdx, rdi
    call    [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]

    mov     rdx, CRLF
    call    [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    ret

; ---------------------------------------------------------------------------
; ReadLine
;   rdi -> buffer (stores ASCII line, null-terminated)
;   reads from ConIn->WaitForKey, ReadKeyStroke
; ---------------------------------------------------------------------------
ReadLine:
    push    rbx
    xor     rcx, rcx         ; count of chars typed
    mov     rax, [SystemTablePtr]
    ; rbx = ConIn pointer
    mov     rbx, [rax + EFI_SYSTEM_TABLE_ConIn]

.next_char:
    ; WaitForEvent(1, &ConIn->WaitForKey, &index)
    mov     r8, [rax + EFI_SYSTEM_TABLE_BootServices]
    mov     r9, [r8 + EFI_BOOT_SERVICES_WaitForEvent]
    mov     rcx, 1
    lea     rdx, [rbx + EFI_SIMPLE_TEXT_INPUT_PROTOCOL_WaitForKey]
    ; we won't store index properly, just push a dummy
    push    0
    call    r9
    add     rsp, 8

    ; read key stroke
    mov     rcx, rbx
    mov     rdx, KeyDataBuf
    call    [rbx + EFI_SIMPLE_TEXT_INPUT_PROTOCOL_ReadKeyStroke]

    ; KeyDataBuf is EFI_INPUT_KEY { ScanCode, UnicodeChar }
    mov     ax, [KeyDataBuf+2]   ; UnicodeChar

    cmp     ax, 0x0D    ; Enter?
    je      .done
    cmp     ax, 0x08    ; Backspace?
    je      .backspace

    ; store char if not full
    cmp     rcx, 127
    jae     .loop
    mov     [rdi + rcx], al
    inc     rcx

    ; echo the char
    mov     [CharBuf], ax      ; store the 2-byte Unicode
    mov     word [CharBuf+2], 0
    mov     r8, [rax + EFI_SYSTEM_TABLE_ConOut]
    mov     rcx, r8
    mov     rdx, CharBuf
    call    [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]

.loop:
    jmp     .next_char

.backspace:
    cmp     rcx, 0
    je      .next_char
    dec     rcx
    ; remove char from the buffer
    mov     byte [rdi + rcx], 0
    ; print a backspace, space, backspace to erase on screen
    mov     r8, [rax + EFI_SYSTEM_TABLE_ConOut]
    mov     rcx, r8
    mov     rdx, BkspStr
    call    [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    jmp     .next_char

.done:
    ; null-terminate
    mov     byte [rdi + rcx], 0
    pop     rbx
    ret

; ---------------------------------------------------------------------------
; StrCmpToken - compare the token at [rdi] with string [rsi]
;   Return rax=0 if match, else rax=1
;   The token ends on space or null
; ---------------------------------------------------------------------------
StrCmpToken:
    push    rdx
    push    rbx
    xor     rax, rax

.compare_loop:
    mov     dl, [rsi]
    mov     bl, [rdi]
    ; if pattern ended => check delimiter in input
    cmp     dl, 0
    jne     .check_char
    ; pattern ended => check if input is space or 0 or any delimiter
    cmp     bl, 0
    je      .matched
    cmp     bl, ' '
    je      .matched
    jmp     .nomatch

.check_char:
    ; still comparing
    cmp     bl, dl
    jne     .nomatch
    ; keep going
    inc     rsi
    inc     rdi
    jmp     .compare_loop

.matched:
    pop     rbx
    pop     rdx
    ret

.nomatch:
    mov     rax, 1
    pop     rbx
    pop     rdx
    ret

; ---------------------------------------------------------------------------
; SkipSpaces, SkipToken
; ---------------------------------------------------------------------------
SkipSpaces:
.skip:
    cmp     byte [rdi], ' '
    jne     .done
    inc     rdi
    jmp     .skip
.done:
    ret

SkipToken:
.st:
    mov     al, [rdi]
    cmp     al, 0
    je      .done
    cmp     al, ' '
    je      .done
    inc     rdi
    jmp     .st
.done:
    ret

; ===========================================================================
; Data sections
; ===========================================================================
section .data

; We'll store the system table pointers here (initialized to 0).
align 8
OurImageHandle  dq 0
SystemTablePtr  dq 0

WelcomeStr      db  "Welcome to Tiny UEFI kernel (assembly)!", 13,10,0
PromptStr       db  13,10, "uefi-os> ",0
UnknownCmdStr   db  "Unknown command.",13,10,0
RunningStr      db  "Running ",0
CRLF            db  13,10,0
BkspStr         db  8, ' ', 8, 0       ; backspace trick

CMD_ECHO        db  "echo",0
CMD_REBOOT      db  "reboot",0
CMD_RUN         db  "run",0

; Buffers
InputBuffer     times 128 db 0      ; typed line
CharBuf         times 4 db 0        ; store one Unicode char (2 bytes + 0)
KeyDataBuf      times 4 db 0        ; EFI_INPUT_KEY = 4 bytes
