; src/unexpand.asm

%include "include/sysdefs.inc"

section .bss
    buffer      resb buffer_size ; I/O buffer
    spaces      resb buffer_size ; Temporary buffer for spaces
    output      resb buffer_size ; Output buffer

section .data
    tab_size    equ 8           ; Default tab size (8 spaces per tab)
    buffer_size equ 4096        ; Size of the I/O buffer

section .text

global _start

_start:

    pop     rcx                 ; Get argc
    pop     rdi                 ; Skip argv[0] (program name)
    
    mov     r8, STDIN_FILENO    ; Default input file descriptor
    mov     r9, STDOUT_FILENO   ; Default output file descriptor
    
    dec     rcx                 ; Check if we have any arguments
    jz      process_input       ; If no arguments, use defaults

    pop     rdi                 ; Get argv[1] (input filename)
    mov     rax, SYS_OPEN
    mov     rsi, O_RDONLY
    mov     rdx, 0              ; Not creating a file, so no mode needed
    syscall
    
    cmp     rax, 0              ; Check if open succeeded
    jl      use_stdin           ; If error, use stdin
    mov     r8, rax             ; Save input file descriptor
    
    dec     rcx                 ; Check if we have output file argument
    jz      process_input       ; If no output file, use stdout

    pop     rdi                 ; Get argv[2] (output filename)
    mov     rax, SYS_OPEN
    mov     rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov     rdx, DEFAULT_MODE   ; File permissions if created
    syscall
    
    cmp     rax, 0              ; Check if open succeeded
    jl      use_stdout          ; If error, use stdout
    mov     r9, rax             ; Save output file descriptor
    jmp     process_input
    
use_stdin:
    mov     r8, STDIN_FILENO    ; Use standard input
    jmp     process_input
    
use_stdout:
    mov     r9, STDOUT_FILENO   ; Use standard output

process_input:

    
read_loop:

    mov     rax, SYS_READ
    mov     rdi, r8             ; Input file descriptor
    mov     rsi, buffer         ; Buffer to read into
    mov     rdx, buffer_size    ; Amount to read
    syscall
    
    cmp     rax, 0              ; Check for EOF or error
    jle     cleanup             ; If EOF or error, exit
    
    mov     r10, rax            ; Save number of bytes read
    mov     r11, 0              ; Initialize position counter
    mov     r12, 0              ; Initialize output position
    mov     r14, 0              ; Flag: 0 = start of line, 1 = not at start
    mov     r15, 0              ; Space counter

process_char:
    cmp     r11, r10            ; Check if we've processed all input
    jge     write_output        ; If yes, write the output buffer
    
    movzx   rax, byte [buffer + r11] ; Get current character
    inc     r11                 ; Move to next character
    
    cmp     r14, 0              ; Are we at the start of a line?
    jne     not_line_start      ; If not, handle differently

    cmp     al, WHITESPACE_SPACE ; Is it a space?
    jne     check_tab           ; If not, check if it's a tab

    mov     byte [spaces + r15], al ; Store space in temporary buffer
    inc     r15                 ; Increment space counter

    cmp     r15, tab_size
    jl      process_char        ; If not enough spaces yet, continue

    mov     byte [output + r12], WHITESPACE_TAB ; Add tab to output
    inc     r12                 ; Move output position
    mov     r15, 0              ; Reset space counter
    jmp     process_char        ; Continue processing
    
check_tab:
    cmp     al, WHITESPACE_TAB  ; Is it a tab?
    jne     flush_spaces        ; If not, flush any pending spaces

    mov     r15, 0              ; Reset space counter
    mov     byte [output + r12], WHITESPACE_TAB ; Add tab to output
    inc     r12                 ; Move output position
    jmp     process_char        ; Continue processing
    
flush_spaces:

    cmp     r15, 0              ; Any spaces to flush?
    je      regular_char        ; If not, handle as regular character

    mov     rcx, r15            ; Set counter to number of spaces
    mov     r13, 0              ; Initialize index
    
copy_spaces:
    mov     bl, byte [spaces + r13] ; Get space from temp buffer
    mov     byte [output + r12], bl ; Copy to output buffer
    inc     r12                 ; Advance output position
    inc     r13                 ; Advance temp buffer position
    loop    copy_spaces         ; Continue until all spaces copied
    
    mov     r15, 0              ; Reset space counter


regular_char:

    mov     byte [output + r12], al ; Add the character to output
    inc     r12                 ; Move output position
    mov     r14, 1              ; Set flag to indicate not at line start
    jmp     process_char        ; Continue processing
    
not_line_start:

    cmp     al, WHITESPACE_NL   ; Is it a newline?
    jne     copy_char           ; If not, just copy it

    mov     byte [output + r12], al ; Add newline to output
    inc     r12                 ; Move output position
    mov     r14, 0              ; Reset to start of line
    jmp     process_char        ; Continue processing
    
copy_char:

    mov     byte [output + r12], al ; Add character to output
    inc     r12                 ; Move output position
    jmp     process_char        ; Continue processing
    
write_output:

    mov     rax, SYS_WRITE
    mov     rdi, r9             ; Output file descriptor
    mov     rsi, output         ; Output buffer
    mov     rdx, r12            ; Number of bytes to write
    syscall

    jmp     read_loop
    
cleanup:

    cmp     r8, STDIN_FILENO
    je      check_output
    
    mov     rax, SYS_CLOSE
    mov     rdi, r8             ; Input file descriptor
    syscall
    
check_output:

    cmp     r9, STDOUT_FILENO
    je      exit_program
    
    mov     rax, SYS_CLOSE
    mov     rdi, r9             ; Output file descriptor
    syscall
    
exit_program:

    exit 0