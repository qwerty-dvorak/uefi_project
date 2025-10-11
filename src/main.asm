; A fully corrected UEFI application that prints a message and waits for a keypress.

BITS 64

section .text
global efi_main

efi_main:
    ; Standard function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32         ; Shadow space for MS x64 ABI calls

    ; RDX holds the EFI_SYSTEM_TABLE pointer. Save it in a non-volatile register.
    mov     r12, rdx

    ; --- 1. Print a message to the console ---
    ; Get the Console Output Protocol pointer from the System Table.
    ; Correct offset for ConOut is 0x40 (64 bytes).
    mov     rcx, [r12 + 0x40]
    lea     rdx, [rel hello_string]
    mov     rax, [rcx + 0x08]   ; Get the OutputString function pointer
    call    rax                 ; Call OutputString

    ; --- 2. Wait for a key press ---
    ; Get the Console Input Protocol pointer from the System Table.
    ; Correct offset for ConIn is 0x38 (56 bytes).
    mov     rcx, [r12 + 0x38]
    ; Call the WaitForKeyEvent function. It is the second function in the
    ; ConIn protocol, so its pointer is at offset 0x08.
    mov     rax, [rcx + 0x08]   ; Get the WaitForKeyEvent function pointer
    call    rax                 ; Call WaitForKeyEvent(ConIn, &EfiKeyData)

    ; --- 3. Exit the application ---
    ; Return 0 (EFI_SUCCESS)
    xor     rax, rax
    add     rsp, 32
    pop     rbp
    ret

section .data
hello_string:
    dw 'H', 'e', 'l', 'l', 'o', ',', ' ', 'W', 'o', 'r', 'l', 'd', '!', 0x0D, 0x0A, 0
    ; 0x0D = Carriage Return, 0x0A = Line Feed