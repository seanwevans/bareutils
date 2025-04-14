; src/cp.asm

%include "include/sysdefs.inc"

%define BUFFER_SIZE 4096
%define ARG_PTR_SIZE 8

section .data
    error_msg_open db "Error opening file", 10
    error_msg_open_len equ $ - error_msg_open
    error_msg_read db "Error reading file", 10
    error_msg_read_len equ $ - error_msg_read
    error_msg_write db "Error writing file", 10
    error_msg_write_len equ $ - error_msg_write

section .bss
    buffer resb BUFFER_SIZE  ; Buffer for file data

section .text
    global _start

_start:

    pop rcx             ; Get argc
    cmp rcx, 1          ; If only program name, use stdin/stdout
    je use_stdio
    cmp rcx, 2          ; If only source, use source/stdout
    je source_only
    cmp rcx, 3          ; If source and dest, use both
    je source_and_dest
    jmp use_stdio       ; Default to stdin/stdout for any other case

source_only:
    pop rdi             ; Remove program name from stack
    pop r8              ; Get source filename
    mov rdi, STDIN_FILENO ; Default source is stdin
    mov rsi, r8
    call open_file      ; Open source file
    mov r8, rax         ; Save source fd
    mov r9, STDOUT_FILENO ; Destination is stdout
    jmp copy_loop

source_and_dest:
    pop rdi             ; Remove program name from stack
    pop r8              ; Get source filename
    pop r9              ; Get dest filename

    mov rdi, STDIN_FILENO ; Default source is stdin
    mov rsi, r8
    call open_file
    mov r8, rax         ; Save source fd

    mov rdi, STDOUT_FILENO ; Default dest is stdout
    mov rsi, r9
    call open_dest_file
    mov r9, rax         ; Save dest fd
    jmp copy_loop

use_stdio:
    mov r8, STDIN_FILENO   ; Source is stdin
    mov r9, STDOUT_FILENO  ; Destination is stdout

copy_loop:

    mov rax, SYS_READ
    mov rdi, r8          ; Source fd
    mov rsi, buffer      ; Buffer
    mov rdx, BUFFER_SIZE ; Buffer size
    syscall

    cmp rax, 0
    jl read_error
    je end_copy          ; End of file

    mov rdx, rax         ; Bytes read
    mov rax, SYS_WRITE
    mov rdi, r9          ; Destination fd - FIXED: use r9 instead of overwriting rdi
    mov rsi, buffer      ; Buffer
    syscall

    cmp rax, 0
    jl write_error

    jmp copy_loop        ; Continue copying

end_copy:

    cmp r8, STDIN_FILENO
    je check_dest
    mov rax, SYS_CLOSE
    mov rdi, r8
    syscall

check_dest:
    cmp r9, STDOUT_FILENO
    je exit_success
    mov rax, SYS_CLOSE
    mov rdi, r9          ; FIXED: Use r9 instead of expecting rdi to still have the value
    syscall

exit_success:
    exit 0

read_error:
    write STDERR_FILENO, error_msg_read, error_msg_read_len
    exit 1

write_error:
    write STDERR_FILENO, error_msg_write, error_msg_write_len
    exit 2

open_file:

    cmp rsi, 0
    je use_default_fd

    mov rax, SYS_OPEN
    mov rdi, rsi        ; Filename
    mov rsi, O_RDONLY   ; Open for reading
    mov rdx, 0          ; Mode (ignored for O_RDONLY)
    syscall

    cmp rax, 0
    jl open_error
    ret

open_dest_file:

    cmp rsi, 0
    je use_default_fd

    mov rax, SYS_OPEN
    mov rdi, rsi                    ; Filename
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC  ; Create and truncate
    mov rdx, DEFAULT_MODE           ; File permissions
    syscall

    cmp rax, 0
    jl open_error
    ret

use_default_fd:
    mov rax, rdi        ; Return the default fd
    ret

open_error:
    write STDERR_FILENO, error_msg_open, error_msg_open_len
    exit 1