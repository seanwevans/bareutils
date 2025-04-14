; src/false.asm

%include "include/sysdefs.inc"

section .text
    global _start

_start:
    exit 1
