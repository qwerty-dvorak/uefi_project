bits 64

section .text
global efi_main
efi_main:
    mov rax, [rdx + 64]
    mov rcx, rax
    lea rdx, [rel hello_msg]
    call [rax + 8]
    ret
section .data
hello_msg:
    dw 'H', 'i', '!', 10, 13, 0

