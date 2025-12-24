bits 16        ; Tell the assembler we're in 16-bit real mode
org 0x7c00     ; The BIOS loads our boot sector at this memory address

start:
    ; --- Setup Data Segment (DS) ---
    ; We can't load DS directly, so we use AX as a helper.
    ; We set DS to the same segment as CS (0x0000).
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; --- Print "Hello, Bootloader!" ---
    mov si, msg  ; Point SI to our message string
    call print_string

    ; --- Hang forever ---
    ; An infinite loop to stop the CPU from executing random memory.
    cli          ; Clear interrupts
    hlt          ; Halt the CPU

print_string:
    ; --- BIOS Interrupt routine to print a string ---
    ; Input: SI points to a null-terminated string
.loop:
    lodsb        ; Load byte from [SI] into AL, and increment SI
    or al, al    ; Check if AL is zero (the null terminator)
    jz .done     ; If zero, we're done

    ; --- Use BIOS interrupt 0x10, function 0x0e ---
    ; This is the "teletype" output, which prints one character
    mov ah, 0x0e ; Function 0x0e: write character in AL
    mov bh, 0x00 ; Page number
    mov bl, 0x07 ; Text attribute (light grey on black)
    int 0x10     ; Call the BIOS video interrupt

    jmp .loop    ; Loop to the next character
.done:
    ret          ; Return from the function

; --- Data ---
msg: db 'Hello, Bootloader!', 0x0D, 0x0A, 0  ; The string, followed by newline, and null terminator.

; --- Boot Sector Padding and Magic Number ---
; A boot sector must be exactly 512 bytes long
; and end with the magic number 0xAA55.
times 510 - ($ - $$) db 0   ; Pad the rest of the file with zeros
dw 0xaa55                  ; The magic boot signature
