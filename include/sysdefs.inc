; include/sysdefs.inc

    %include "include/defines.inc"
    %include "include/macros.inc"

section .bss

section .text
global open_file
global open_dest_file
global strlen
global close_file
global read_all

section .data
    error_msg_open db "Error opening file", 10
    error_msg_open_len equ $ - error_msg_open
    error_msg_read db "Error reading file", 10
    error_msg_read_len equ $ - error_msg_read
    error_msg_write db "Error writing file", 10
    error_msg_write_len equ $ - error_msg_write

section .text

open_file:
    cmp rsi, 0
    je .use_default
    mov rax, SYS_OPEN
    mov rdi, rsi
    mov rsi, O_RDONLY
    mov rdx, 0
    syscall
    cmp rax, 0
    jl .fail
    ret
.use_default:
    mov rax, rdi
    ret
.fail:
    write STDERR_FILENO, error_msg_open, error_msg_open_len
    exit 1

open_dest_file:
    cmp rsi, 0
    je .use_default
    mov rax, SYS_OPEN
    mov rdi, rsi
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, DEFAULT_MODE
    syscall
    cmp rax, 0
    jl .fail
    ret
.use_default:
    mov rax, rdi
    ret
.fail:
    write STDERR_FILENO, error_msg_open, error_msg_open_len
    exit 1

strlen:
    xor rbx, rbx
.loop:
    cmp byte [rsi + rbx], 0
    je .done
    inc rbx
    jmp .loop
.done:
    ret

close_file:
    cmp rdi, STDERR_FILENO
    jle .done
    mov rax, SYS_CLOSE
    syscall
.done:
    ret

read_all:
    mov rax, SYS_READ
    syscall
    cmp rax, 0
    jge .ok
    write STDERR_FILENO, error_msg_read, error_msg_read_len
    exit 1
.ok:
    ret
