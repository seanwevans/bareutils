; src/truncate.asm

%include "include/sysdefs.inc"

section .bss
    filename    resb 256        ; buffer for filename
    filesize    resq 1          ; buffer for file size

section .data
    usage_msg   db "Usage: truncate FILENAME LENGTH", 10, 0
    usage_len   equ $ - usage_msg
    error_msg   db "Error: Could not truncate file", 10, 0
    error_len   equ $ - error_msg
    success_msg db "File truncated successfully", 10, 0
    success_len equ $ - success_msg

section .text
    global      _start

_start:
    pop         rcx                     ; argc
    cmp         rcx, 3                  ; Need program name + filename + length
    jne         print_usage             ; If not 3 args, print usage and exit

    pop         rdi                     ; Remove program name from stack
    pop         rdi                     ; Get filename pointer
    mov         r12, rdi                ; Save filename pointer in r12
    pop         rdi                     ; Get length string pointer
    call        string_to_int           ; Convert string to integer in RAX
    
    mov         r13, rax                ; Save length in r13
    mov         rax, SYS_TRUNCATE       ; truncate syscall
    mov         rdi, r12                ; filename
    mov         rsi, r13                ; length
    syscall

    test        rax, rax
    js          error_exit
    
    jmp         exit_success

print_usage:
    write       STDOUT_FILENO, usage_msg, usage_len
    jmp         exit_failure

error_exit:
    write       STDOUT_FILENO, error_msg, error_len
    jmp         exit_failure

exit_success:
    exit        0

exit_failure:
    exit        1

string_to_int:
    xor         rax, rax                ; Initialize result to 0
    xor         rcx, rcx                ; Initialize current character
    xor         r8, r8                  ; Initialize sign flag (0 = positive)
    mov         cl, byte [rdi]
    cmp         cl, '-'
    jne         .process_digits         ; Not negative, start processing digits
    
    inc         rdi                     ; Move past the '-' sign
    mov         r8, 1                   ; Set sign flag to negative

.process_digits:
    mov         cl, byte [rdi]
    test        cl, cl
    jz          .done

    sub         cl, '0'
    cmp         cl, 9
    ja          .done                    ; If > 9, not a digit, we're done

    imul        rax, 10
    add         rax, rcx

    inc         rdi
    jmp         .process_digits

.done:
    test        r8, r8
    jz          .positive
    neg         rax                     ; Negate the result if sign flag is set

.positive:
    ret