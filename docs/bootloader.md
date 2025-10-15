# UEFI Bootloader — Entry Point & System Table Layout

Assumptions: x86_64 / LP64 (pointers and UINTN = 8 bytes)

Main entry point for a UEFI image is `EFI_IMAGE_ENTRY_POINT`:
```c
typedef
EFI_STATUS
(EFIAPI *EFI_IMAGE_ENTRY_POINT) (
    IN EFI_HANDLE    ImageHandle,
    IN EFI_SYSTEM_TABLE *SystemTable
);
```
On x86_64 (Microsoft x64 ABI) the first two pointer-sized arguments are passed in registers:
- rcx = `ImageHandle` (EFI_HANDLE)
- rdx = `SystemTable` (EFI_SYSTEM_TABLE *)

EFI_HANDLE is an opaque pointer type:

```c
typedef struct {} *EFI_HANDLE;
```
(Size: 8 bytes on x86_64/LP64)

## EFI_SYSTEM_TABLE (layout & sizes)

Definition:

```c
typedef struct {
    EFI_TABLE_HEADER                 Hdr;
    CHAR16                           *FirmwareVendor;
    UINT32                           FirmwareRevision;
    EFI_HANDLE                       ConsoleInHandle;
    EFI_SIMPLE_TEXT_INPUT_PROTOCOL   *ConIn;
    EFI_HANDLE                       ConsoleOutHandle;
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL  *ConOut;
    EFI_HANDLE                       StandardErrorHandle;
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL  *StdErr;
    EFI_RUNTIME_SERVICES             *RuntimeServices;
    EFI_BOOT_SERVICES                *BootServices;
    UINTN                            NumberOfTableEntries;
    EFI_CONFIGURATION_TABLE          *ConfigurationTable;
} EFI_SYSTEM_TABLE;
```

`EFI_TABLE_HEADER` is defined as:

```c
typedef struct {
    UINT64    Signature;
    UINT32    Revision;
    UINT32    HeaderSize;
    UINT32    CRC32;
    UINT32    Reserved;
} EFI_TABLE_HEADER;
```

`EFI_HANDLE` is defined as:

```c
typedef struct {} *EFI_HANDLE;
```

Field sizes and alignment:
- `Hdr` (EFI_TABLE_HEADER): (64 + 32 + 32 + 32 + 32) / 8 = 24 bytes
- `FirmwareVendor` (CHAR16 *): 8 bytes
- `FirmwareRevision` (UINT32): 4 bytes
- Padding: 4 bytes (to align next pointer)
- `ConsoleInHandle` (EFI_HANDLE): 8 bytes
- `ConIn` (pointer): 8 bytes
- `ConsoleOutHandle` (EFI_HANDLE): 8 bytes
- `ConOut` (pointer): 8 bytes
- `StandardErrorHandle` (EFI_HANDLE): 8 bytes
- `StdErr` (pointer): 8 bytes
- `RuntimeServices` (pointer): 8 bytes
- `BootServices` (pointer): 8 bytes
- `NumberOfTableEntries` (UINTN): 8 bytes
- `ConfigurationTable` (pointer): 8 bytes

Total size (with padding): 120 bytes

## To print text in console
We need to look into the `ConOut` struct

## Notes
- The 4-byte padding after `FirmwareRevision` aligns subsequent 8-byte pointers to 8-byte boundaries.
- EFI_STATUS is an int code for success, errors, and warnings. See [UEFI Status Codes](https://uefi.org/specs/UEFI/2.10/Apx_D_Status_Codes.html).
- IN is a no-op annotation macro used for documentation to mark input parameters
- OUT is a no-op annotation macro used for documentation to mark output parameters
