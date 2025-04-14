; src/printenv.asm

%include "include/sysdefs.inc"

section .bss

section .data
    newline db 10
    
section .text
    global _start

_start:
    mov rsi, rsp            ; rsi = stack base
    mov rdi, [rsi]          ; rdi = argc
    add rsi, 8              ; skip argc

.skip_argv:                 ; Skip over argv pointers
    cmp rdi, 0
    jle .find_env_null
    add rsi, 8              ; skip argv[i]
    dec rdi
    jmp .skip_argv

.find_env_null:
    add rsi, 8              ; Skip the argv NULL terminator, rsi now points to envp[0]
    mov r12, rsi            ; Use r12 as the envp iterator pointer

.loop_env:
    mov rbx, [r12]          ; rbx = envp[i] (pointer to string)
    test rbx, rbx           ; Check if the pointer is NULL
    je .exit                ; If NULL, we're done with environment variables

    mov rdi, rbx            ; Arg 1 for strlen: pointer to string
    call strlen             ; rcx = length of string

    mov rax, 1              ; SYS_write
    mov rdi, 1              ; FD: stdout
    mov rsi, rbx            ; Buffer: the environment string itself
    mov rdx, rcx            ; Length: from strlen
    syscall                 ; Write the string
    
    mov rax, 1              ; SYS_write
    mov rdi, 1              ; FD: stdout
    mov rsi, newline        ; Buffer: address of newline character
    mov rdx, 1              ; Length: 1 byte
    syscall                 ; Write the newline

    add r12, 8              ; Move iterator to next envp pointer (envp[i+1])
    jmp .loop_env           ; Repeat

.exit:    
    exit 0

; strlen(rdi) -> rcx
strlen:
    xor rcx, rcx
.loop:
    cmp byte [rdi + rcx], 0
    je .done
    inc rcx
    jmp .loop
.done:
    ret
