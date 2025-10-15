# Console Input in UEFI
This document explains how to read text from the console in a UEFI application using the UEFI system table and the Simple Text Input Protocol.

`EFI_SIMPLE_TEXT_INPUT_PROTOCOL` is defined as

```c
typedef struct _EFI_SIMPLE_TEXT_INPUT_PROTOCOL {
 EFI_INPUT_RESET                       Reset;
 EFI_INPUT_READ_KEY                    ReadKeyStroke;
 EFI_EVENT                             WaitForKey;
} EFI_SIMPLE_TEXT_INPUT_PROTOCOL;
```

## Simple Text Input Protocol
To read a key we need to use the `ReadKeyStroke` function which is defined as
```c
typedef
EFI_STATUS
(EFIAPI *EFI_INPUT_READ_KEY) (
 IN EFI_SIMPLE_TEXT_INPUT_PROTOCOL    *This,
 OUT EFI_INPUT_KEY                    *Key
 );
 ```

 EFI_INPUT_KEY is defined as

 ```c
 typedef struct {
     UINT16  ScanCode;
     CHAR16  UnicodeChar;
 } EFI_INPUT_KEY;
 ```
 (Size of EFI_INPUT_KEY is 2 + 2 = 4 bytes)
 

We would to need to get the `ConIn` field from the `EFI_SYSTEM_TABLE` struct which is a pointer to `EFI_SIMPLE_TEXT_INPUT_PROTOCOL` struct and then call the `ReadKeyStroke` function pointer with the address of the `EFI_INPUT_KEY` structure we want to fill.

The `ReadKeyStroke` function takes two parameters:
- `This`: A pointer to the EFI_SIMPLE_TEXT_INPUT_PROTOCOL instance.
- `Key`: A pointer to an EFI_INPUT_KEY structure to be filled with the key information.

The function returns an `EFI_STATUS` code indicating the success or failure of the operation.

We have already calculated the field offsets in the `EFI_SYSTEM_TABLE` struct in the previous section. The `ConIn` field is located at offset 24 + 8 + 4 + 4 + 8 = 48 (0x30 in hexadecimal).

So to call the `ReadKeyStroke` function, we would do the following in assembly:

```asm
call [[rdx + 48] + 8]             ; Call ReadKeyStroke (offset 8 in the struct)
```

RDX here stores the pointer to the `EFI_SYSTEM_TABLE` struct. We first dereference it to get the pointer to the `EFI_SIMPLE_TEXT_INPUT_PROTOCOL` struct (at offset 48), and then dereference that to get the `ReadKeyStroke` function pointer (at offset 8) before calling it.

Now we need to define the arguments passed to the function. According to the Microsoft x64 ABI, the first argument is passed in RCX and the second argument is passed in RDX.

RCX will have *This (i.e., the pointer to the `EFI_SIMPLE_TEXT_INPUT_PROTOCOL` instance), which we can get by dereferencing the `ConIn` field from the `EFI_SYSTEM_TABLE` struct.

RDX will have the pointer to the `EFI_INPUT_KEY` structure we want to fill. We can use stack space for the struct and pass `[rsp]` to RDX, we can do `sub rsp, 8`, then get the unicode char at `rsp + 2` by just doing `add rsp, 2`.

```asm
sub rsp, 8
read_loop:
    mov rcx, [rdx + 48]
    lea rdx, [rsp]
    call [rcx + 8]   
    cmp rax, 0
    jne read_loop
```

## Notes

- The ReadKeyStroke() function reads the next keystroke from the input device. If there is no pending keystroke the function returns EFI_NOT_READY. 
- The function returns EFI_SUCCESS if a keystroke was successfully read.
- So we loop until we get EFI_SUCCESS (0) in RAX.