; bootx64.asm - Minimal UEFI x86_64 example (PE+).

[bits 64]
%include "uefi.inc"

section .text align=16
global _start

_start:
    and   rsp, -16               ; <-- stack alignment fix
    mov   [OurImageHandle], rcx
    mov   [SystemTablePtr], rdx

    mov   rax, [SystemTablePtr]
    mov   r8,  [rax + EFI_SYSTEM_TABLE_ConOut]
    mov   rcx, r8
    mov   rdi, WelcomeStr
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]

    jmp   MainLoop

MainLoop:
    ; Print prompt
    mov   rax, [SystemTablePtr]
    mov   r8,  [rax + EFI_SYSTEM_TABLE_ConOut]
    mov   rcx, r8
    mov   rdi, PromptStr
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]

    ; Read line -> parse
    mov   rdi, InputBuffer
    call  ReadLine
    call  ParseCommand
    cmp   rax, 0
    je    .done
    ; Unknown command
    mov   rcx, rax
    mov   rdi, UnknownCmdStr
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
.done:
    jmp   MainLoop


; -------------------------------------------------------
; ParseCommand
; -------------------------------------------------------
ParseCommand:
    push  rbx
    call  SkipSpaces
    mov   rbx, rdi
    cmp   byte [rbx], 0
    je    .empty

    ; Compare with "echo"
    push  rdi
    mov   rsi, CMD_ECHO
    call  StrCmpToken
    add   rsp, 8
    cmp   rax, 0
    je    .do_echo

    ; Compare with "reboot"
    push  rdi
    mov   rsi, CMD_REBOOT
    call  StrCmpToken
    add   rsp, 8
    cmp   rax, 0
    je    .do_reboot

    ; Compare with "run"
    push  rdi
    mov   rsi, CMD_RUN
    call  StrCmpToken
    add   rsp, 8
    cmp   rax, 0
    je    .do_run

    ; Unrecognized
    mov   rax, [SystemTablePtr]
    mov   rax, [rax + EFI_SYSTEM_TABLE_ConOut]
    pop   rbx
    ret

.empty:
    xor   rax, rax
    pop   rbx
    ret

.do_echo:
    call  SkipToken
    call  SkipSpaces
    mov   rax, [SystemTablePtr]
    mov   r8,  [rax + EFI_SYSTEM_TABLE_ConOut]
    mov   rcx, r8
    ; rdi points to remainder of line -> convert -> print
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    ; newline
    mov   rdi, CRLF
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    xor   rax, rax
    pop   rbx
    ret

.do_reboot:
    ; ResetSystem(ResetCold, 0, 0, NULL)
    mov   rax, [SystemTablePtr]
    mov   r11, [rax + EFI_SYSTEM_TABLE_RuntimeServices]
    mov   rcx, ResetCold   ; first param
    xor   rdx, rdx         ; second param
    xor   r8,  r8          ; third param
    xor   r9,  r9          ; fourth param
    call  [r11 + EFI_RUNTIME_SERVICES_ResetSystem]
    xor   rax, rax
    pop   rbx
    ret

.do_run:
    call  SkipToken
    call  SkipSpaces
    cmp   byte [rdi], 0
    je    .done_run
    call  FakeLoadAndStartImage
.done_run:
    xor   rax, rax
    pop   rbx
    ret


; -------------------------------------------------------
; FakeLoadAndStartImage
; -------------------------------------------------------
FakeLoadAndStartImage:
    mov   rax, [SystemTablePtr]
    mov   r8,  [rax + EFI_SYSTEM_TABLE_ConOut]
    mov   rcx, r8

    ; Print "Running "
    mov   rdi, RunningStr
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]

    ; Print filename user typed
    mov   rdi, rdi
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]

    ; Newline
    mov   rdi, CRLF
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    ret


; -------------------------------------------------------
; ReadLine: input into [rdi] (ASCII), ends on Enter
; -------------------------------------------------------
ReadLine:
    push  rbx
    xor   rcx, rcx
    mov   rax, [SystemTablePtr]
    mov   rbx, [rax + EFI_SYSTEM_TABLE_ConIn]
.next_char:
    ; WaitForEvent(1, &ConIn->WaitForKey, &WaitIndex)
    mov   rdx, [rax + EFI_SYSTEM_TABLE_BootServices]
    mov   r11, [rdx + EFI_BOOT_SERVICES_WaitForEvent]
    mov   rcx, 1
    lea   rdx, [rbx + EFI_SIMPLE_TEXT_INPUT_PROTOCOL_WaitForKey]
    lea   r8,  [WaitIndex]
    call  r11

    ; ReadKeyStroke(ConIn, &KeyDataBuf)
    mov   rcx, rbx
    mov   rdx, KeyDataBuf
    call  [rbx + EFI_SIMPLE_TEXT_INPUT_PROTOCOL_ReadKeyStroke]

    mov   ax, [KeyDataBuf + 2] ; UnicodeChar
    cmp   ax, 0x0D             ; Enter?
    je    .done
    cmp   ax, 0x08             ; Backspace?
    je    .backspace

    cmp   rcx, 127
    jae   .loop
    mov   [rdi + rcx], al
    inc   rcx

    ; Echo typed char
    mov   [CharBuf], ax
    mov   word [CharBuf + 2], 0
    push  rax                                    ; Save character
    mov   rax, [SystemTablePtr]                 ; Get system table
    mov   r8, [rax + EFI_SYSTEM_TABLE_ConOut]   ; Get ConOut
    mov   rcx, r8
    mov   rdx, CharBuf
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    pop   rax                                    ; Restore character
.loop:
    jmp   .next_char

.backspace:
    cmp   rcx, 0
    je    .next_char
    dec   rcx
    mov   byte [rdi + rcx], 0
    mov   r8, [rax + EFI_SYSTEM_TABLE_ConOut]
    mov   rcx, r8
    mov   rdi, BkspStr
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    jmp   .next_char

.done:
    mov   byte [rdi + rcx], 0
    pop   rbx
    ret


; -------------------------------------------------------
; StrCmpToken
; -------------------------------------------------------
StrCmpToken:
    push  rdx
    push  rbx
    xor   rax, rax
.compare_loop:
    mov   dl, [rsi]
    mov   bl, [rdi]
    cmp   dl, 0
    jne   .check_char
    cmp   bl, 0
    je    .matched
    cmp   bl, ' '
    je    .matched
    jmp   .nomatch
.check_char:
    cmp   bl, dl
    jne   .nomatch
    inc   rsi
    inc   rdi
    jmp   .compare_loop
.matched:
    pop   rbx
    pop   rdx
    ret
.nomatch:
    mov   rax, 1
    pop   rbx
    pop   rdx
    ret


; -------------------------------------------------------
; SkipSpaces / SkipToken
; -------------------------------------------------------
SkipSpaces:
.skip:
    cmp   byte [rdi], ' '
    jne   .done
    inc   rdi
    jmp   .skip
.done:
    ret

SkipToken:
.st:
    mov   al, [rdi]
    cmp   al, 0
    je    .done
    cmp   al, ' '
    je    .done
    inc   rdi
    jmp   .st
.done:
    ret

; -------------------------------------------------------
; ConvertAsciiToUtf16
;   rdi -> ASCII string, returns rax -> wide buffer
; -------------------------------------------------------
ConvertAsciiToUtf16:
    push  rbx
    mov   rbx, WideBuf
.cloop:
    movzx eax, byte [rdi]    ; Zero extend the byte to 32 bits
    mov   word [rbx], ax     ; Store as UTF-16LE (low byte first)
    cmp   al, 0
    je    .done
    add   rbx, 2            ; Move to next UTF-16 position
    inc   rdi              ; Move to next ASCII char
    jmp   .cloop
.done:
    mov   rax, WideBuf
    pop   rbx
    ret


; -------------------------------------------------------
; Data
; -------------------------------------------------------
section .data align=8

OurImageHandle  dq 0
SystemTablePtr  dq 0

WelcomeStr      db "Welcome to Tiny UEFI kernel (assembly)!",0
PromptStr       db 13,10,"uefi-os> ",0
UnknownCmdStr   db "Unknown command.",13,10,0
RunningStr      db "Running ",0
CRLF            db 13,10,0
BkspStr         db 8,' ',8,0

CMD_ECHO        db "echo",0
CMD_REBOOT      db "reboot",0
CMD_RUN         db "run",0

InputBuffer     times 128 db 0
CharBuf         times 4   db 0
KeyDataBuf      times 4   db 0

section .bss align=8
WideBuf   resb 1024
WaitIndex resq 1
