; src/readlink.asm

%include "include/sysdefs.inc"

section .bss
    buffer resb 4096            ; Buffer to store the path read from the symlink
    path resb 4096              ; Buffer to store the path argument

section .data
    usage_msg db "Usage: readlink <path>", 10
    usage_len equ $ - usage_msg
    error_msg db "Error: Failed to read symbolic link", 10
    error_len equ $ - error_msg
    newline db 10               ; Newline character

section .text
    global _start

_start:
    pop rdi                     ; Get argc
    cmp rdi, 2                  ; We need exactly one argument (program name + symlink path)
    jne usage_error

    pop rsi                     ; Skip program name (argv[0])
    pop rsi                     ; Get symlink path (argv[1])
    mov rdi, path

    call copy_string
    mov rax, SYS_READLINK       ; Syscall number for readlink
    mov rdi, path               ; Path to the symlink
    mov rsi, buffer             ; Where to store the result
    mov rdx, 4096               ; Maximum size to read
    syscall

    test rax, rax
    js error_exit               ; Jump if sign flag is set (negative result = error)
    mov rdx, rax                ; Length of the path returned by readlink
    mov rsi, buffer             ; Buffer containing the path
    mov rdi, STDOUT_FILENO      ; File descriptor for stdout
    mov rax, SYS_WRITE
    syscall

    mov rdi, STDOUT_FILENO
    mov rsi, newline            ; Address of the newline in data section
    mov rdx, 1                  ; Length (just the newline)
    mov rax, SYS_WRITE
    syscall

    xor rdi, rdi                ; Exit code 0
    mov rax, SYS_EXIT
    syscall

copy_string:
    push rdi                    ; Save destination address
    
copy_loop:
    mov al, byte [rsi]          ; Load character from source
    mov byte [rdi], al          ; Store character to destination
    inc rsi                     ; Move to next source character
    inc rdi                     ; Move to next destination character
    test al, al                 ; Check if we reached the end of string
    jnz copy_loop               ; If not zero, continue copying
    
    pop rdi                     ; Restore original destination address
    ret

usage_error:
    mov rdi, STDERR_FILENO      ; File descriptor for stderr
    mov rsi, usage_msg          ; Message to print
    mov rdx, usage_len          ; Length of message
    mov rax, SYS_WRITE
    syscall
    mov rdi, 1                  ; Exit code 1
    mov rax, SYS_EXIT
    syscall

error_exit:
    mov rdi, STDERR_FILENO      ; File descriptor for stderr
    mov rsi, error_msg          ; Message to print
    mov rdx, error_len          ; Length of message
    mov rax, SYS_WRITE
    syscall
    mov rdi, 1                  ; Exit code 1
    mov rax, SYS_EXIT
    syscall