; src/groups.asm

%include "include/sysdefs.inc"

section .bss
    groups_buf  resd 32         ; buffer for group IDs (32-bit each)
    numbuf      resb 16         ; temporary buffer for printing numbers

section .data
    newline     db 10
    space       db ' '

section .text
    global _start

_start:
    mov     rax, SYS_GETGROUPS
    mov     rdi, 32             ; max groups
    mov     rsi, groups_buf
    syscall

    mov     rcx, rax            ; number of groups
    cmp     rcx, 0
    je      .done

    xor     rbx, rbx            ; index
.next_group:
    mov     edi, [groups_buf + rbx*4]
    call    print_num

    inc     rbx
    cmp     rbx, rcx
    je      .done

    call    write_space
    jmp     .next_group

.done:
    write   STDOUT_FILENO, newline, 1
    exit    0

print_num:
    mov     rax, rdi
    mov     rsi, numbuf + 15
    mov     byte [rsi], 0
    mov     rcx, 10

.print_loop:
    xor     rdx, rdx
    div     rcx
    dec     rsi
    add     dl, '0'
    mov     [rsi], dl
    test    rax, rax
    jnz     .print_loop

    mov     rax, SYS_WRITE
    mov     rdi, STDOUT_FILENO
    mov     rdx, numbuf + 16
    sub     rdx, rsi
    syscall
    ret

write_space:
    write   STDOUT_FILENO, space, 1
    ret
