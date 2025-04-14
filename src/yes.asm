; src/yes.asm

%include "include/sysdefs.inc"

section .data
    msg db "y", 10
    len equ $ - msg

section .text
    global _start

_start:
.loop:
    write 1, msg, len
    jmp .loop
