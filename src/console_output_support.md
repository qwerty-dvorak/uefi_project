# Console Output in UEFI
This document explains how to print text to the console in a UEFI application using the UEFI system table and the Simple Text Output Protocol.

EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL is defined as 

```c
typedef struct _EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL {
 EFI_TEXT_RESET                           Reset;
 EFI_TEXT_STRING                          OutputString;
 EFI_TEXT_TEST_STRING                     TestString;
 EFI_TEXT_QUERY_MODE                      QueryMode;
 EFI_TEXT_SET_MODE                        SetMode;
 EFI_TEXT_SET_ATTRIBUTE                   SetAttribute;
 EFI_TEXT_CLEAR_SCREEN                    ClearScreen;
 EFI_TEXT_SET_CURSOR_POSITION             SetCursorPosition;
 EFI_TEXT_ENABLE_CURSOR                   EnableCursor;
 SIMPLE_TEXT_OUTPUT_MODE                  *Mode;
} EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL;
```

## Simple Text Output Protocol 
To print a text we need to that the `OutputString` function which is defined as 

```c
typedef
EFI_STATUS
(EFIAPI *EFI_TEXT_STRING) (
 IN EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL    *This,
 IN CHAR16                             *String
 );
```

We would to need to get the `ConOut` field from the `EFI_SYSTEM_TABLE` struct which is a pointer to `EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL` struct and then call the `OutputString` function pointer with the string we want to print.

The `OutputString` function takes two parameters:
- `This`: A pointer to the EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL instance.
- `String`: A pointer to a null-terminated string of 16-bit characters (CHAR16) to be printed.

The function returns an `EFI_STATUS` code indicating the success or failure of the operation.

We can calculate the field offsets in the `EFI_SYSTEM_TABLE` struct in the previous section. The `ConOut` field is located at offset 24 + 8 + 4 + 4 + 8 + 8 + 8 = 64 (0x40 in hexadecimal).

So to call the `OutputString` function, we would do the following in assembly:

```asm
call [[rdx + 64] + 8]             ; Call OutputString (offset 8 in the struct)
```

RDX here stores the pointer to the `EFI_SYSTEM_TABLE` struct. We first dereference it to get the pointer to the `EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL` struct (at offset 64), and then dereference that to get the `OutputString` function pointer (at offset 8) before calling it.

Now we need to define the arguments passed to the function. According to the Microsoft x64 ABI, the first argument is passed in RCX and the second argument is passed in RDX.

RCX will have *This (i.e., the pointer to the `EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL` instance), which we can get by dereferencing the `ConOut` field from the `EFI_SYSTEM_TABLE` struct.

RDX will have the pointer to the string we want to print. We can load the address of the string into RDX using the `LEA` instruction.

```asm
mov rcx, [rdx + 64]               ; Load ConOut (EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *)
lea rdx, [rel hello_msg]           ; Load address of the string to print
call [rcx + 8]                     ; Call OutputString
```