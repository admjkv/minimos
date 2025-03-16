; bootx64.asm

[bits 64]
%include "uefi.inc"

section .text align=16
global _start

_start:
    and   rsp, -16
    mov   [OurImageHandle], rcx
    mov   [SystemTablePtr], rdx

    mov   rax, [SystemTablePtr]
    mov   r8,  [rax + EFI_SYSTEM_TABLE_ConOut]
    mov   rcx, r8
    mov   rdx, 0  ; Clear screen
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_ClearScreen]
    
    ; Set color
    mov   rcx, r8
    mov   rdx, EFI_LIGHTGREEN | (EFI_BLACK << 4)  ; Light green on black
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_SetAttribute]

    mov   rcx, r8
    mov   rdi, WelcomeStr
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    ; Check for error
    test  rax, rax
    js    ErrorHandler

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
    ; Check for error
    test  rax, rax
    js    ErrorHandler

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
    ; Check for error
    test  rax, rax
    js    ErrorHandler
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
    pop   rdi
    cmp   rax, 0
    je    .do_echo

    ; Compare with "reboot"
    push  rdi
    mov   rsi, CMD_REBOOT
    call  StrCmpToken
    pop   rdi
    cmp   rax, 0
    je    .do_reboot

    ; Compare with "run"
    push  rdi
    mov   rsi, CMD_RUN
    call  StrCmpToken
    pop   rdi
    cmp   rax, 0
    je    .do_run

    ; Compare with "help"
    push  rdi
    mov   rsi, CMD_HELP
    call  StrCmpToken
    pop   rdi
    cmp   rax, 0
    je    .do_help

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
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    ; Check for error
    test  rax, rax
    js    ErrorHandler
    ; newline
    mov   rdi, CRLF
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    ; Check for error
    test  rax, rax
    js    ErrorHandler
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

.do_help:
    mov   rax, [SystemTablePtr]
    mov   r8,  [rax + EFI_SYSTEM_TABLE_ConOut]
    mov   rcx, r8
    mov   rdi, HelpText
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    ; Check for error
    test  rax, rax
    js    ErrorHandler
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
    ; Check for error
    test  rax, rax
    js    ErrorHandler

    ; Print filename user typed
    mov   rdi, rdi
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    ; Check for error
    test  rax, rax
    js    ErrorHandler

    ; Newline
    mov   rdi, CRLF
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    ; Check for error
    test  rax, rax
    js    ErrorHandler
    ret


; -------------------------------------------------------
; ReadLine: input into [rdi] (ASCII), ends on Enter
; -------------------------------------------------------
ReadLine:
    push  rbx
    push  r12
    xor   r12, r12
    mov   rax, [SystemTablePtr]
    mov   rbx, [rax + EFI_SYSTEM_TABLE_ConIn]
    mov   byte [CmdHistoryIndex], 0  ; Reset history index
.next_char:
    ; WaitForEvent(1, &ConIn->WaitForKey, &WaitIndex)
    mov   rax, [SystemTablePtr]                  ; Reload system table pointer
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
    cmp   ax, 0x0000             ; Check for special keys
    je    .special_key

    cmp   r12, 127
    jae   .loop
    mov   [rdi + r12], al
    inc   r12

    ; Echo typed char
    mov   [CharBuf], ax
    mov   word [CharBuf + 2], 0
    push  rax
    mov   rax, [SystemTablePtr]
    mov   r8, [rax + EFI_SYSTEM_TABLE_ConOut]
    mov   rcx, r8
    mov   rdx, CharBuf
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    ; Check for error
    test  rax, rax
    js    ErrorHandler
    pop   rax
.loop:
    jmp   .next_char

.backspace:
    cmp   r12, 0
    je    .next_char
    dec   r12
    mov   byte [rdi + r12], 0
    push  rax
    mov   rax, [SystemTablePtr]
    mov   r8, [rax + EFI_SYSTEM_TABLE_ConOut]
    mov   rcx, r8
    push  rdi
    mov   rdi, BkspStr
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [r8 + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    ; Check for error
    test  rax, rax
    js    ErrorHandler
    pop   rdi
    pop   rax
    jmp   .next_char

.special_key:
    ; Check scan code for up/down arrows
    mov   al, [KeyDataBuf]       ; ScanCode
    cmp   al, 0x01               ; Up arrow
    je    .history_up
    cmp   al, 0x02               ; Down arrow
    je    .history_down
    jmp   .loop

.history_up:
    ; Check if we have history and can go back
    movzx rax, byte [CmdHistoryIndex]
    cmp   rax, byte [CmdHistoryCount]
    jae   .loop
    ; Clear current line
    call  ClearCurrentLine
    ; Get history entry
    inc   byte [CmdHistoryIndex]
    movzx rax, byte [CmdHistoryIndex]
    dec   rax
    imul  rax, 128
    lea   rsi, [CmdHistory + rax]
    mov   rdi, InputBuffer
    call  CopyString
    mov   r12, rax               ; Length of copied string
    ; Display the history entry
    mov   rcx, [SystemTablePtr]
    mov   rcx, [rcx + EFI_SYSTEM_TABLE_ConOut]
    mov   rdi, InputBuffer
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    jmp   .loop

.history_down:
    ; Check if we have history to navigate downward
    cmp   byte [CmdHistoryIndex], 0
    je    .clear_line
    dec   byte [CmdHistoryIndex]
    cmp   byte [CmdHistoryIndex], 0
    jne   .history_up
.clear_line:
    ; Clear line and input buffer
    call  ClearCurrentLine
    mov   rdi, InputBuffer
    mov   rcx, 128
    xor   al, al
    rep   stosb
    mov   rdi, InputBuffer
    xor   r12, r12
    jmp   .loop

.done:
    mov   byte [rdi + r12], 0
    pop   r12
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

; Copies string from [rsi] to [rdi], returns length in rax
CopyString:
    push  rcx
    xor   rcx, rcx
.copy_loop:
    mov   al, [rsi + rcx]
    mov   [rdi + rcx], al
    inc   rcx
    test  al, al
    jnz   .copy_loop
    dec   rcx        ; Don't count null terminator
    mov   rax, rcx
    pop   rcx
    ret

; Clears the current command line
ClearCurrentLine:
    push  rax
    push  rcx
    push  rdx
    push  rdi
    mov   rax, [SystemTablePtr]
    mov   rcx, [rax + EFI_SYSTEM_TABLE_ConOut]
    mov   rdi, PromptStr
    call  ConvertAsciiToUtf16
    mov   rdx, rax
    call  [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString]
    pop   rdi
    pop   rdx
    pop   rcx
    pop   rax
    ret

; -------------------------------------------------------
; ConvertAsciiToUtf16
;   rdi -> ASCII string, returns rax -> wide buffer
; -------------------------------------------------------
ConvertAsciiToUtf16:
    push  rbx
    mov   rbx, WideBuf
.cloop:
    movzx eax, byte [rdi]
    mov   word [rbx], ax
    cmp   al, 0
    je    .done
    add   rbx, 2
    inc   rdi
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

WelcomeStr      db "Welcome to MinimOS! It works!",0
PromptStr       db 13,10,"[minimos]$ ",0
UnknownCmdStr   db "Unknown command.",13,10,0
RunningStr      db "Running ",0
CRLF            db 13,10,0
BkspStr         db 8,' ',8,0

CMD_ECHO        db "echo",0
CMD_REBOOT      db "reboot",0
CMD_RUN         db "run",0
CMD_HELP        db "help",0

InputBuffer     times 128 db 0
CharBuf         times 4   db 0
KeyDataBuf      times 4   db 0
CmdHistory      times 5*128 db 0  ; Store last 5 commands
CmdHistoryCount db 0
CmdHistoryIndex db 0

HelpText db "Available commands:",13,10
         db "  help   - Show this help",13,10
         db "  echo   - Display text",13,10
         db "  reboot - Restart system",13,10
         db "  run    - Execute program",13,10,0

section .bss align=8
WideBuf   resb 1024
WaitIndex resq 1
