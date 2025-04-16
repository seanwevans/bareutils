; src/chmod.asm

%include "include/sysdefs.inc"

section .bss
    mode_buf resb 16           ; buffer for mode string
    path_buf resb 4096         ; buffer for pathname

section .data
    usage_msg db "Usage: chmod <mode> <path>", 10
    usage_len equ $ - usage_msg
    error_msg db "chmod failed", 10
    error_len equ $ - error_msg

section .text
    global _start

_start:
    ; argc = [rsp]
    mov rbx, [rsp]
    cmp rbx, 3
    je .use_args

    mov rax, SYS_READ
    mov rdi, STDIN_FILENO
    mov rsi, mode_buf
    mov rdx, 16
    syscall
    cmp rax, 0
    jle .usage
    
    mov rsi, mode_buf
    mov rcx, rax
.find_space:
    cmp byte [rsi], WHITESPACE_SPACE
    je .found
    cmp byte [rsi], WHITESPACE_TAB
    je .found
    cmp byte [rsi], WHITESPACE_NL
    je .found
    inc rsi
    loop .find_space
    jmp .usage

.found:
    mov byte [rsi], 0          ; null-terminate mode string
    inc rsi
    mov rdi, path_buf
    mov rcx, mode_buf + 16 - rsi
.copy_path:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    dec rcx
    cmp al, 0
    jne .copy_path
    mov rsi, path_buf
    mov rdi, mode_buf
    jmp .parse_and_chmod

.use_args:    
    mov rsi, [rsp + 16]        ; path
    mov rdi, [rsp + 8]         ; mode

.parse_and_chmod:    
    xor rbx, rbx               ; result
    xor rcx, rcx               ; temp
.octal_loop:
    mov al, [rdi]
    cmp al, 0
    je .do_chmod
    sub al, '0'
    cmp al, 7
    ja .usage
    mov cl, al
    shl rbx, 3
    or rbx, rcx
    inc rdi
    jmp .octal_loop

.do_chmod:
    mov rax, 90                ; SYS_CHMOD
    mov rdi, rsi               ; path
    mov rsi, rbx               ; mode
    syscall
    test rax, rax
    js .fail
    exit 0

.usage:
    write STDOUT_FILENO, usage_msg, usage_len
    exit 1

.fail:
    write STDERR_FILENO, error_msg, error_len
    exit 2
