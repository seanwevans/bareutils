; src/uname.asm
%include "include/sysdefs.inc"

section .bss
    uts resb 390

section .text
    global _start

_start:
    mov     rax, 63         ; SYS_uname
    mov     rdi, uts
    syscall

    lea     rsi, [uts + 0]      ; sysname
    call    print_line

    lea     rsi, [uts + 65]     ; nodename
    call    print_line

    lea     rsi, [uts + 130]    ; release
    call    print_line

    lea     rsi, [uts + 195]    ; version
    call    print_line

    lea     rsi, [uts + 260]    ; machine
    call    print_line

    exit 0

; ------------------------------------------------------------
print_line:
    call strlen
    write 1, rsi, rbx
    write 1, newline, 1
    ret

strlen:
    xor rbx, rbx
.loop:
    cmp byte [rsi + rbx], 0
    je .done
    inc rbx
    jmp .loop
.done:
    ret

section .data
    newline db 10
