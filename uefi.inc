; ---------------------------------------------------------------------------
; uefi.inc - Minimal UEFI definitions for NASM x86_64
; ---------------------------------------------------------------------------
%ifndef UEFI_INC_GUARD
%define UEFI_INC_GUARD 1

; --------------------------------
; Table header constants
; --------------------------------
%define EFI_TABLE_HEADER_size        (8 + 4 + 4 + 4 + 4)  ; 24 bytes

; --------------------------------
; EFI_SYSTEM_TABLE offsets
; --------------------------------
; struct EFI_SYSTEM_TABLE layout for x86_64:
;   +0..23   Hdr (EFI_TABLE_HEADER, 24 bytes)
;   +24..31  FirmwareVendor
;   +32..35  FirmwareRevision
;   +36..39  padding
;   +40..47  ConsoleInHandle
;   +48..55  ConIn  (EFI_SIMPLE_TEXT_INPUT_PROTOCOL*)
;   +56..63  ConsoleOutHandle
;   +64..71  ConOut (EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL*)
;   +72..79  ConsoleErrHandle
;   +80..87  StdErr
;   +88..95  RuntimeServices (EFI_RUNTIME_SERVICES*)
;   +96..103 BootServices (EFI_BOOT_SERVICES*)
;   +104..111 NumberOfTableEntries
;   +112..119 ConfigurationTable
%define EFI_SYSTEM_TABLE_ConIn       (EFI_TABLE_HEADER_size + 24)  ; +48
%define EFI_SYSTEM_TABLE_ConOut      (EFI_TABLE_HEADER_size + 40)  ; +64
%define EFI_SYSTEM_TABLE_StdErr      (EFI_TABLE_HEADER_size + 56)  ; +80
%define EFI_SYSTEM_TABLE_RuntimeServices (EFI_TABLE_HEADER_size + 64) ; +88
%define EFI_SYSTEM_TABLE_BootServices    (EFI_TABLE_HEADER_size + 72) ; +96

; --------------------------------
; EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL
; --------------------------------
; struct layout (each pointer is 8 bytes):
;   +0   Reset
;   +8   OutputString
;   +16  TestString
;   +24  QueryMode
;   +32  SetMode
;   +40  SetAttribute
;   +48  ClearScreen
;   +56  SetCursorPos
;   +64  EnableCursor
;   +72  Mode
%define EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_Reset         0
%define EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString  8

; --------------------------------
; EFI_SIMPLE_TEXT_INPUT_PROTOCOL
; --------------------------------
; struct layout:
;   +0   Reset
;   +8   ReadKeyStroke
;   +16  WaitForKey
%define EFI_SIMPLE_TEXT_INPUT_PROTOCOL_Reset         0
%define EFI_SIMPLE_TEXT_INPUT_PROTOCOL_ReadKeyStroke 8
%define EFI_SIMPLE_TEXT_INPUT_PROTOCOL_WaitForKey    16

; --------------------------------
; EFI_RUNTIME_SERVICES
; --------------------------------
; struct layout (many fields omitted). We want the offset for ResetSystem().
; Typically it's around offset 120. We'll define it here:
%define EFI_RUNTIME_SERVICES_ResetSystem             120

; --------------------------------
; EFI_BOOT_SERVICES
; --------------------------------
; We only need the offset for WaitForEvent in this example:
; struct layout:
;   +0..23   Hdr
;   +24..(various)...

;   +96  WaitForEvent
%define EFI_BOOT_SERVICES_WaitForEvent               96

; --------------------------------
; EFI_INPUT_KEY
; --------------------------------
; struct layout:
;   +0   ScanCode (uint16)
;   +2   UnicodeChar (uint16)
; total size = 4
%define EFI_INPUT_KEY_size 4

; --------------------------------
; ResetSystem() types
; --------------------------------
%define ResetCold      0
%define ResetWarm      1
%define ResetShutdown  2

%endif ; UEFI_INC_GUARD
