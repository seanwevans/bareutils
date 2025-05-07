; src/chmod.asm

%include "include/sysdefs.inc"

section .bss
    mode            resq 1          ; file mode
    filename:       resb 256        ; file name
    
section .data
    error_usage     db "Usage: chmod mode file", 10, 0
    error_usage_len equ $ - error_usage
    error_chmod     db "chmod: Failed to change file mode", 10, 0
    error_chmod_len equ $ - error_chmod
    
section .text
    global          _start

_start:
    pop             rcx             ; argc
    cmp             rcx, 3          ; do we have 3 arguments?
    jne             usage_error     ; If not, show usage error

    pop             rdi
    pop             rdi
    call            parse_mode      ; Parse octal mode string to numeric value
    mov             [mode], rax     ; Store the parsed mode

    pop             rdi
    mov             rsi, filename   ; Destination buffer
    call            copy_string     ; Copy filename to our buffer

    mov             rax, SYS_CHMOD  ; syscall number for chmod
    mov             rdi, filename   ; filename
    mov             rsi, [mode]     ; mode
    syscall

    test            rax, rax
    js              chmod_error

    exit            0

parse_mode:
    xor             rax, rax        ; Clear result register
    
.next_char:
    movzx           rcx, byte [rdi] ; Get current character
    test            rcx, rcx
    jz              .done
    
    sub             rcx, '0'        ; Convert ASCII to numeric
    cmp             rcx, 7          ; Check if digit is valid octal (0-7)
    ja              .done           ; If above 7, it's not valid octal
    
    shl             rax, 3          ; Multiply current result by 8 (octal shift)
    add             rax, rcx        ; Add new digit
    
    inc             rdi             ; Move to next character
    jmp             .next_char
    
.done:
    ret

copy_string:
    mov             al, [rdi]       ; Get character from source
    mov             [rsi], al       ; Store in destination
    test            al, al
    jz              .done
    
    inc             rdi             ; Next source character
    inc             rsi             ; Next destination position
    jmp             copy_string     ; Continue copying
    
.done:
    ret

usage_error:
    write           STDERR_FILENO, error_usage, error_usage_len
    exit            1
    
chmod_error:
    write           STDERR_FILENO, error_chmod, error_chmod_len
    exit            1