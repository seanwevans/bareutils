%include "include/sysdefs.inc"       ; already provided include file

section .data
    space     db " "               ; space separator for output
    newline   db 10                ; newline character for output

section .bss
    buffer    resb 4096            ; input buffer for file reading
    number_str resb 32             ; buffer for decimal conversion

section .text
global _start

_start:
    mov rdi, [rsp]               ; get argc from stack
    cmp rdi, 2                   ; check if a file argument is provided
    jb use_stdin                 ; if less than 2, use standard input
    mov rax, [rsp+16]            ; get pointer to argv[1]
    mov rdi, rax                 ; set filename pointer for SYS_OPEN
    mov rsi, O_RDONLY            ; open file read-only
    mov rdx, 0                   ; mode 0 (unused for O_RDONLY)
    mov rax, SYS_OPEN            ; syscall number for open
    syscall                      ; attempt to open file
    cmp rax, 0                   ; check if open succeeded (rax >= 0)
    jl exit_fail                 ; on error, exit with status 1
    mov r12, rax                 ; store file descriptor in r12
    jmp process_file

use_stdin:
    mov r12, STDIN_FILENO        ; use standard input if no file argument

process_file:
    xor r13, r13                 ; clear r13 for line count = 0
    xor r14, r14                 ; clear r14 for word count = 0
    xor r15, r15                 ; clear r15 for byte count = 0
    xor rbx, rbx                 ; clear rbx for word flag (0 = outside word)

read_loop:
    mov rdi, r12                 ; file descriptor in rdi
    mov rsi, buffer              ; pointer to buffer for reading
    mov rdx, 4096                ; read up to 4096 bytes
    mov rax, SYS_READ            ; syscall number for read
    syscall                      ; perform read
    cmp rax, 0                 ; check for end-of-file (0 bytes read)
    je close_file                ; if 0, exit reading loop
    cmp rax, 0                   ; check for read error (<0)
    jl exit_fail                 ; on error, exit with status 1
    add r15, rax                 ; add number of bytes read to total byte count
    mov rcx, rax                 ; set inner loop counter to number of bytes read
    mov rsi, buffer              ; reset buffer pointer

process_buffer:
    cmp rcx, 0                 ; check if buffer fully processed
    je read_loop_continue        ; if done, continue reading more data
    dec rcx                    ; decrement byte counter
    mov al, [rsi]              ; load current byte into AL
    inc rsi                    ; advance buffer pointer
    cmp al, 10                 ; check if byte is newline (LF)
    je count_newline
    cmp al, 9                  ; check if byte is a tab character
    je reset_word
    cmp al, 32                 ; check if byte is a space character
    je reset_word
    cmp rbx, 0                 ; if word flag is 0 (not in word)
    jne process_buffer         ; if already inside a word, continue
    mov rbx, 1                 ; set word flag: entering a word
    inc r14                    ; increment word count
    jmp process_buffer

reset_word:
    mov rbx, 0                 ; reset word flag (outside a word)
    jmp process_buffer

count_newline:
    inc r13                    ; increment line count
    mov rbx, 0                 ; reset word flag after newline
    jmp process_buffer

read_loop_continue:
    jmp read_loop              ; go back to read next chunk

close_file:
    cmp r12, STDIN_FILENO      ; check if file descriptor is not STDIN
    je print_results           ; if STDIN, skip closing
    mov rdi, r12               ; set file descriptor for close syscall
    mov rax, SYS_CLOSE         ; syscall number for close
    syscall                    ; close the file

print_results:
    ; Print line count
    mov rdi, r13               ; load line count into rdi for printing
    call print_decimal         ; print number in decimal
    mov rdi, STDOUT_FILENO     ; set file descriptor for write
    mov rsi, space             ; pointer to space character
    mov rdx, 1                 ; length = 1
    mov rax, SYS_WRITE         ; syscall number for write
    syscall                    ; write space separator

    ; Print word count
    mov rdi, r14               ; load word count into rdi for printing
    call print_decimal         ; print number in decimal
    mov rdi, STDOUT_FILENO     ; set file descriptor for write
    mov rsi, space             ; pointer to space character
    mov rdx, 1                 ; length = 1
    mov rax, SYS_WRITE         ; syscall number for write
    syscall                    ; write space separator

    ; Print byte count
    mov rdi, r15               ; load byte count into rdi for printing
    call print_decimal         ; print number in decimal
    mov rdi, STDOUT_FILENO     ; set file descriptor for write
    mov rsi, newline           ; pointer to newline character
    mov rdx, 1                 ; length = 1
    mov rax, SYS_WRITE         ; syscall number for write
    syscall                    ; write newline

    mov rdi, 0                 ; exit with status 0
    exit 0

exit_fail:
    mov rdi, 1                 ; exit with status 1 on failure
    exit 1

; print_decimal: prints the unsigned number in rdi as a decimal string to STDOUT
print_decimal:
    push rbx                   ; save rbx (callee-saved register)
    cmp rdi, 0                 ; check if number is zero
    jne .print_loop_start      ; if not zero, jump to conversion loop
    mov byte [number_str+31], '0'  ; store '0' in conversion buffer
    mov rdx, 1                ; set length to 1
    mov rsi, number_str+31    ; point to the '0' character
    mov rdi, STDOUT_FILENO    ; file descriptor for STDOUT
    mov rax, SYS_WRITE        ; syscall number for write
    syscall                   ; write the '0'
    pop rbx                   ; restore rbx
    ret

.print_loop_start:
    mov rsi, number_str+32    ; set pointer at the end of the conversion buffer
    xor rcx, rcx              ; clear digit counter
    mov rax, rdi              ; copy number into rax for division
    mov r8, 10                ; divisor constant 10 in r8
.print_loop:
    xor rdx, rdx              ; clear remainder register before division
    div r8                    ; divide rax by 10; quotient in rax, remainder in rdx
    add rdx, '0'              ; convert remainder digit to ASCII
    dec rsi                   ; decrement pointer to store digit
    mov [rsi], dl             ; store ASCII digit in buffer
    inc rcx                  ; increment digit count
    test rax, rax             ; check if division result is zero
    jnz .print_loop           ; repeat if quotient is not zero
    mov rdi, STDOUT_FILENO    ; set file descriptor for STDOUT
    mov rax, SYS_WRITE        ; syscall number for write
    mov rdx, rcx              ; length equals number of digits
    syscall                   ; output the converted number string
    pop rbx                   ; restore rbx
    ret
