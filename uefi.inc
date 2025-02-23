%ifndef UEFI_INC_GUARD
%define UEFI_INC_GUARD 1

%define EFI_TABLE_HEADER_size 24

%define EFI_SYSTEM_TABLE_ConIn            (EFI_TABLE_HEADER_size + 24)
%define EFI_SYSTEM_TABLE_ConOut           (EFI_TABLE_HEADER_size + 40)
%define EFI_SYSTEM_TABLE_StdErr           (EFI_TABLE_HEADER_size + 56)
%define EFI_SYSTEM_TABLE_RuntimeServices  (EFI_TABLE_HEADER_size + 64)
%define EFI_SYSTEM_TABLE_BootServices     (EFI_TABLE_HEADER_size + 72)

%define EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_Reset         0
%define EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OutputString  8

%define EFI_SIMPLE_TEXT_INPUT_PROTOCOL_Reset          0
%define EFI_SIMPLE_TEXT_INPUT_PROTOCOL_ReadKeyStroke  8
%define EFI_SIMPLE_TEXT_INPUT_PROTOCOL_WaitForKey     16

%define EFI_RUNTIME_SERVICES_ResetSystem  120
%define EFI_BOOT_SERVICES_WaitForEvent    96

%define EFI_INPUT_KEY_size 4

%define ResetCold     0
%define ResetWarm     1
%define ResetShutdown 2

%endif
