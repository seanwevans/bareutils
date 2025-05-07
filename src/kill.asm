; src/kill.asm

%include "include/sysdefs.inc"

section .bss
    buffer      resb 32         ; Buffer for argument parsing
    number_buf  resb 32         ; Buffer for number conversion
    signal      resq 1          ; Signal number
    pid         resq 1          ; Process ID

section .data
    usage_msg   db "Usage: kill [-s signum] pid", 10, 0
    usage_len   equ $ - usage_msg
    invalid_pid db "kill: invalid pid", 10, 0
    invalid_pid_len equ $ - invalid_pid
    invalid_sig db "kill: invalid signal specification", 10, 0
    invalid_sig_len equ $ - invalid_sig
    debug_msg   db "Debug: signal=", 0
    debug_msg_len   equ $ - debug_msg
    newline     db WHITESPACE_NL, 0
    default_signal  equ 15

section .text
    global      _start

_start:
    mov         rbp, rsp
    mov         qword [signal], default_signal  ; Default signal is SIGTERM (15)
    mov         rdi, [rbp]          ; Get argc from stack
    cmp         rdi, 1              ; Check if we have at least one argument
    jle         show_usage          ; If no args, show usage

    mov         rsi, 1              ; Start argument index at 1
    
parse_args:
    cmp         rsi, [rbp]          ; Compare current index with argc
    jge         check_pid           ; If done parsing, check if PID set

    mov         rax, [rbp + rsi*8 + 8]  ; Get argv[rsi]
    cmp         byte [rax], '-'
    jne         parse_as_pid        ; If not an option, assume it's a PID

    cmp         byte [rax+2], 0     ; Check if string is exactly 2 chars
    jne         check_s_option

    movzx       rdx, byte [rax+1]   ; Get signal character
    sub         rdx, '0'            ; Convert to number
    cmp         rdx, 9              ; Ensure it's a digit
    ja          invalid_signal      ; If not 0-9, error

    mov         [signal], rdx
    inc         rsi                 ; Move to next argument
    jmp         parse_args
    
check_s_option:
    cmp         byte [rax+1], 's'
    jne         invalid_signal      ; If not -s, error
    cmp         byte [rax+2], 0     ; Ensure it's just "-s"
    jne         invalid_signal

    inc         rsi                 ; Move to next argument
    cmp         rsi, [rbp]          ; Check if we have more arguments
    jge         show_usage          ; If no more args, show usage

    mov         rdi, [rbp + rsi*8 + 8]  ; Get signal number arg
    call        parse_number        ; Parse it as a number
    cmp         rax, -1             ; Check for parse error
    je          invalid_signal

    mov         [signal], rax
    inc         rsi                 ; Move to next argument
    jmp         parse_args
    
parse_as_pid:
    mov         rdi, rax            ; Pass argument pointer
    call        parse_number        ; Parse it as a number
    
    cmp         rax, -1             ; Check for parse error
    je          invalid_pid_err

    mov         [pid], rax
    inc         rsi                 ; Move to next argument
    jmp         parse_args

check_pid:
    cmp         qword [pid], 0
    je          show_usage
    
send_signal:
    mov         rax, SYS_KILL
    mov         rdi, [pid]          ; pid
    mov         rsi, [signal]       ; signum
    syscall

    test        rax, rax
    js          error_exit

    exit        0

show_usage:
    write       STDERR_FILENO, usage_msg, usage_len
    exit        1

invalid_pid_err:
    write       STDERR_FILENO, invalid_pid, invalid_pid_len
    exit        1

invalid_signal:
    write       STDERR_FILENO, invalid_sig, invalid_sig_len
    exit        1

error_exit:
    neg         rax                 ; Convert negative error code to positive
    exit        rax

parse_number:
    xor         rax, rax            ; Initialize result to 0
    xor         rcx, rcx            ; Initialize index to 0
    
parse_loop:
    movzx       rdx, byte [rdi+rcx] ; Get current character
    test        rdx, rdx            ; Check for null terminator
    jz          parse_done

    sub         rdx, '0'
    cmp         rdx, 9
    ja          parse_error         ; If not 0-9, error

    imul        rax, 10
    add         rax, rdx
    inc         rcx                 ; Move to next character
    jmp         parse_loop
    
parse_done:
    test        rcx, rcx
    jz          parse_error
    ret
    
parse_error:
    mov         rax, -1              ; Return error
    ret
