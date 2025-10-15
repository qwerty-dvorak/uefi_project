# Changing cursor position in UEFI console

To change the cursor position in a UEFI console application, you can use the `SetCursorPosition` function provided by the UEFI Simple Text Output Protocol. For getting the current cursor position, you can use the `GetCursorPosition` function.

`EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL` is defined as follows:

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
} EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL
```

`SIMPLE_TEXT_OUTPUT_MODE` is defined as follows:

```c
typedef struct {
 INT32                              MaxMode;
 INT32                              Mode;
 INT32                              Attribute;
 INT32                              CursorColumn;
 INT32                              CursorRow;
 BOOLEAN                            CursorVisible;
} SIMPLE_TEXT_OUTPUT_MODE;
```

Now to access the position of the cursor, you can read the `CursorColumn` and `CursorRow` fields from the `Mode` structure of the `EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL`. The offset of the `Mode` field in the `EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL` struct is 72 bytes (0x48 in hexadecimal).

And then you can set the cursor position using the `SetCursorPosition` function, which takes two parameters: the column and row where you want to move the cursor. The offset of the `SetCursorPosition` function in the `EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL` struct is 64 bytes (0x40 in hexadecimal).

## Setting cursor position

`SetCursorPosition` function is defined as follows:

```c
typedef
EFI_STATUS
(EFIAPI *EFI_TEXT_SET_CURSOR_POSITION) (
 IN EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL             *This,
 IN UINTN                                       Column,
 IN UINTN                                       Row
 );
```

The `SetCursorPosition` function takes three parameters:
- `This`: A pointer to the EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL instance.
- `Column`: The column position to set the cursor to.
- `Row`: The row position to set the cursor to.

The function returns an `EFI_STATUS` code indicating the success or failure of the operation.

We can calculate the field offsets in the `EFI_SYSTEM_TABLE` struct in the previous section. The `ConOut` field is located at offset 24 + 8 + 4 + 4 + 8 + 8 + 8 = 64 (0x40 in hexadecimal).

So to call the `SetCursorPosition` function, we would do the following in assembly:

```asm
call [[rdx + 64] + 64]             ; Call SetCursorPosition (offset 64 in the struct)
```

RDX here stores the pointer to the `EFI_SYSTEM_TABLE` struct. We first dereference it to get the pointer to the `EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL` struct (at offset 64), and then dereference that to get the `SetCursorPosition` function pointer (at offset 64) before calling it.

Now we need to define the arguments passed to the function. According to the Microsoft x64 ABI, the first argument is passed in RCX, the second argument is passed in RDX, and the third argument is passed in R8.

RCX will have *This (i.e., the pointer to the `EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL` instance), which we can get by dereferencing the `ConOut` field from the `EFI_SYSTEM_TABLE` struct.

RDX will have the column position to set the cursor to.

R8 will have the row position to set the cursor to.

```asm
mov rcx, [rdx + 64]               ; Load ConOut (EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *)
mov rdx, 10                        ; Set column to 10
mov r8, 5                          ; Set row to 5
call [[rcx + 64]]                  ; Call SetCursorPosition
```

## Getting cursor position

`SIMPLE_TEXT_OUTPUT_MODE` struct has the read-only fields `CursorColumn` and `CursorRow` which can be used to get the current cursor position.

Field sizes and alignment:
- MaxMode (INT32): 4 bytes
- Mode (INT32): 4 bytes
- Attribute (INT32): 4 bytes
- CursorColumn (INT32): 4 bytes
- CursorRow (INT32): 4 bytes
- CursorVisible (BOOLEAN): 1 byte

The offsets of these fields in the `SIMPLE_TEXT_OUTPUT_MODE` struct are:
- `CursorColumn`: 12 bytes (0x0C in hexadecimal)
- `CursorRow`: 16 bytes (0x10 in hexadecimal)

To access these fields, we first need to get the `Mode` field from the `EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL` struct, which is located at offset 72 bytes (0x48 in hexadecimal).

```asm
mov rcx, [rdx + 64]               ; Load ConOut (EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *)
mov rbx, [rcx + 72]               ; Load Mode (SIMPLE_TEXT
mov eax, [rbx + 12]               ; Load CursorColumn
mov ebx, [rbx + 16]               ; Load CursorRow
```