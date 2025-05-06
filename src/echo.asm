; src/echo.asm

%include "include/sysdefs.inc"

section .bss

section .data
    newline db 10

section .text
    global _start

_start:
    mov rsi, rsp          ; rsi = stack pointer
    mov rdi, [rsi]        ; argc
    add rsi, 8            ; argv[0]
    add rsi, 8            ; argv[1]

    cmp rdi, 1
    jle .print_nl

    mov rsi, [rsi]        ; deref argv[1]
    call strlen

    write 1, rsi, rbx     ; stdout, str, len

.print_nl:
    write 1, newline, 1
    exit 0
