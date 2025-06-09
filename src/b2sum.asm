; src/b2sum.asm

%include "include/sysdefs.inc"

section .data
    b2sum_path  db "/usr/bin/b2sum",0
    exec_fail_msg db "Failed to exec b2sum",10
    exec_fail_len equ $ - exec_fail_msg

section .text
    global _start

_start:
    pop rax                     ; argc
    mov rbx, rsp                ; rbx points to argv[0]

    lea rdx, [rbx + rax*8 + 8]  ; rdx = envp pointer
    lea rdi, [rel b2sum_path]
    mov [rbx], rdi              ; replace argv[0] with path
    mov rsi, rbx                ; argv pointer

    mov rax, SYS_EXECVE
    syscall

    ; If execve returns, it failed
    write STDERR_FILENO, exec_fail_msg, exec_fail_len
    exit 1
