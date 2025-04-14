; src/arch.asm

%include "include/sysdefs.inc"

section .bss
    uts resb 390          ; struct utsname is 390 bytes total

section .text
    global _start

_start:
    mov     rax, 63             ; SYS_uname
    mov     rdi, uts
    syscall

    lea     rsi, [uts + 260]    ; uts + 260 is the .machine field
    call    strlen

    write   1, rsi, rbx
    write   1, newline, 1
    exit    0

strlen:
    xor     rbx, rbx
.loop:
    cmp     byte [rsi + rbx], 0
    je      .done
    inc     rbx
    jmp     .loop
.done:
    ret

section .data
    newline db 10
