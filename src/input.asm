bits 64

section .text
global efi_main
efi_main:
    sub rsp, 24
    mov r12, rdx
read_loop:
    mov rcx, [r12 + 48]
    lea rdx, [rsp]
    call [rcx + 8]   
    cmp rax, 0
    jne read_loop

    mov rcx, [r12 + 64]
    add rsp, 2
    mov word [rsp + 2], 0
    mov rdx, rsp
    call [rcx + 8]
    mov rcx, [r12 + 64]
    lea rdx, [rel newline]
    call [rcx + 8]
    add rsp, 22
    ret

section .data
newline:
    dw 13, 10, 0
