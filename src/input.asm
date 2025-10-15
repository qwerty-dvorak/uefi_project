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
    lea rdx, [rel newline]
    call [rcx + 8]
    mov rcx, [r12 + 64]
    mov ax, [rsp + 2]
    mov [rsp + 8], ax
    mov word [rsp + 10], 0
    lea rdx, [rsp + 8]
    call [rcx + 8]
    mov rcx, [r12 + 64]
    lea rdx, [rel newline]
    call [rcx + 8]
    add rsp, 24
    ret

section .data
newline:
    dw 13, 10, 0
