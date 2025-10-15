bits 64

section .text
global efi_main
efi_main:
    sub rsp, 8
    mov r12, rdx
    
    lea rdi, [rel choosing_msg]
    call print_string
    lea rdi, [rel pointer_arrow]
    call print_string
    lea rdi, [rel option_1]
    call print_string
    lea rdi, [rel option_2]
    call print_string
    lea rdi, [rel option_3]
    call print_string
    mov rax, 0
input_loop:
    mov rcx, [r12 + 48]
    lea rdx, [rsp]
    call [rcx + 8]   
    cmp rax, 0
    jne read_loop


    add rsp, 8
    ret

print_string:
    mov rcx, [r12 + 64]
    mov rdx, rdi
    call [rcx + 8]
    ret

section .data

choosing_msg:
    dw 'C','h','o','o','s','e',' ','a','n',' ','o','p','t','i','o','n',':', 10, 13, 0

pointer_arrow:
    dw '>', ' ', 0
option_1:
    dw 'N','e','w',' ','g','a','m','e', 10, 13, 0
option_2:
    dw 'L','o','a','d',' ','g','a','m','e', 10, 13, 0
option_3:
    dw 'E','x','i','t', 10, 13, 0

hello_msg:
    dw 'H', 'i', '!', 10, 13, 0
welcome_back_msg:
    dw 'W','e','l','c','o','m','e',' ','b','a','c','k','!',' ', 'L', 'o', 'a', 'd', 'i', 'n', 'g', ' ', 'y', 'o', 'u', 'r', ' ', 's', 'a', 'v', 'e', 'd', ' ', 'g', 'a', 'm', 'e', '.', '.', '.', 10, 13, 0