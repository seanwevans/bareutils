; src/printenv.asm

%include "include/sysdefs.inc"

section .bss

section .data
    newline db WHITESPACE_NL
    
section .text
    global  _start

_start:
    mov     rsi, rsp
    mov     rdi, [rsi]      ; argc
    add     rsi, 8          ; skip argc

.skip_argv:
    cmp     rdi, 0
    jle     .find_env_null
    add     rsi, 8          ; skip argv[i]
    dec     rdi
    jmp     .skip_argv

.find_env_null:
    add     rsi, 8          ; Skip the argv NULL terminator, rsi now points to envp[0]
    mov     r12, rsi        ; Use r12 as the envp iterator pointer

.loop_env:
    mov     rbx, [r12]      ; envp[i]
    test    rbx, rbx        ; Check if the pointer is NULL
    je      .exit           ; If NULL, we're done with environment variables

    mov     rdi, rbx        ; Arg 1 for strlen: pointer to string
    call    strlen

    mov     rax, 1          
    mov     rdi, 1          
    mov     rsi, rbx
    mov     rdx, rcx
    syscall
    
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT_FILENO
    mov     rsi, newline    ; Buffer: address of newline character
    mov     rdx, 1          ; Length: 1 byte
    syscall

    add     r12, 8          ; next envp pointer (envp[i+1])
    jmp     .loop_env       ; Repeat

.exit:    
    exit    0
