; src/pwd.asm

%include "include/sysdefs.inc"

section .bss
    path resb 512

section .text
    global _start

_start:
    mov rax, 79         ; SYS_getcwd
    mov rdi, path
    mov rsi, 512
    syscall

    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, path
    syscall

    write 1, newline, 1
    exit 0

section .data
    newline db 10
