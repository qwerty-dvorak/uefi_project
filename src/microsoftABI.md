# Microsoft x64 ABI (Windows)

Quick reference for the Microsoft x64 (Windows) calling convention.

## Summary
- First four integer/pointer arguments: RCX, RDX, R8, R9 (in that order).
- Shadow space/reserved stack space: 32 bytes (allocated by caller before call).
- Stack must be 16-byte aligned at the point of a CALL instruction.
- Return values: RAX (and RDX for 128-bit/large values as applicable).

## Argument registers
- 1st: RCX
- 2nd: RDX
- 3rd: R8
- 4th: R9
- Additional arguments passed on the stack (right-to-left).

## Volatile (caller-saved) registers
- RAX, RCX, RDX, R8, R9, R10, R11

Caller must assume these may be clobbered by the callee.

## Non-volatile (callee-saved) registers
- RBX, RBP, RSI, RDI, R12, R13, R14, R15

Callee must preserve these across the call (restore before return).

## Shadow space
- 32 bytes of stack space reserved by the caller (regardless of number of parameters).
- The callee may use this space for register spill/locals.

## Stack alignment
- Stack must be 16-byte aligned at the CALL instruction.
- Because the CALL instruction pushes an 8-byte return address, the caller usually ensures RSP is 8 mod 16 before the CALL so that inside the callee RSP is 0 mod 16.

## Notes
- Floating-point/Vector arguments use XMM registers according to platform ABI rules (consult compiler docs for exact mapping).
- For variadic functions, integer arguments still follow the RCX/RDX/R8/R9 convention; additional state (e.g., register save area) may be required by compiler.