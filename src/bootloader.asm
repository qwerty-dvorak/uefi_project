bits 64

section .text
global efi_main
efi_main:
    mov rcx, [rdx + 64]
    lea rdx, [rel hello_msg]
    call [rcx + 8]
    sub rcx, 32
    mov rdx, r12
    call [rcx + 8]
    add rcx, 32
    mov rdx, [r12 + 8]
    call [rcx + 8]
    ret
section .data
hello_msg:
    dw 'H', 'i', '!', 10, 13, 0

