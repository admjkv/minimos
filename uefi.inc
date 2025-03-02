; file: uefi.inc
%ifndef UEFI_INC_GUARD
%define UEFI_INC_GUARD 1                  ; Include guard to prevent multiple inclusions

; -----------------------------------------------------------------------------
; UEFI Structure Sizes and Offsets
; -----------------------------------------------------------------------------

%define EFI_TABLE_HEADER_size 24          ; Size of the standard EFI table header structure

; Offsets within EFI_SYSTEM_TABLE structure
%define EFI_SYSTEM_TABLE_ConIn            (EFI_TABLE_HEADER_size + 24)  ; Pointer to console input protocol
%define EFI_SYSTEM_TABLE_ConOut           (EFI_TABLE_HEADER_size + 40)  ; Pointer to console output protocol
%define EFI_SYSTEM_TABLE_StdErr           (EFI_TABLE_HEADER_size + 56)  ; Pointer to standard error output
%define EFI_SYSTEM_TABLE_RuntimeServices  (EFI_TABLE_HEADER_size + 64)  ; Pointer to runtime services table
%define EFI_SYSTEM_TABLE_BootServices     (EFI_TABLE_HEADER_size + 72)  ; Pointer to boot services table

; -----------------------------------------------------------------------------
; Console Output Function Offsets
; -----------------------------------------------------------------------------

; Function offsets within the EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL structure
%define EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_Reset         0  ; Reset the text output device
%define EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString  8  ; Display a null-terminated string on the output device

; -----------------------------------------------------------------------------
; Console Input Function Offsets 
; -----------------------------------------------------------------------------

; Function offsets within the EFI_SIMPLE_TEXT_INPUT_PROTOCOL structure
%define EFI_SIMPLE_TEXT_INPUT_PROTOCOL_Reset          0  ; Reset the input device
%define EFI_SIMPLE_TEXT_INPUT_PROTOCOL_ReadKeyStroke  8  ; Read next keystroke from input device
%define EFI_SIMPLE_TEXT_INPUT_PROTOCOL_WaitForKey     16 ; Event that is signaled when a key is pressed

; -----------------------------------------------------------------------------
; UEFI Service Function Offsets
; -----------------------------------------------------------------------------

%define EFI_RUNTIME_SERVICES_ResetSystem  120 ; Offset to ResetSystem function in RuntimeServices table
%define EFI_BOOT_SERVICES_WaitForEvent    96  ; Offset to WaitForEvent function in BootServices table

; -----------------------------------------------------------------------------
; Structure Sizes and Constants
; -----------------------------------------------------------------------------

%define EFI_INPUT_KEY_size 4              ; Size of the EFI_INPUT_KEY structure (ScanCode + UnicodeChar)

; Reset types for ResetSystem function
%define ResetCold     0                   ; Cold restart - full hardware initialization
%define ResetWarm     1                   ; Warm restart - CPU reset but memory preserved when possible
%define ResetShutdown 2                   ; Shutdown - attempt to power off the system

%endif                                    ; End of include guard
