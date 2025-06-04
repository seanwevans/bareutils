; src/hash.asm

%include "include/sysdefs.inc"

%define BUFFER_SIZE 4096

section .bss
    buffer      resb BUFFER_SIZE
    num_buffer  resb 32

section .data
    fnv_offset  dq 0xcbf29ce484222325
    fnv_prime   dq 0x100000001b3
    decimal_base dq 10
    newline     db WHITESPACE_NL

section .text
    global _start

_start:
    mov rbx, [fnv_offset]        ; initial hash value

read_loop:
    mov rax, SYS_READ
    mov rdi, STDIN_FILENO
    mov rsi, buffer
    mov rdx, BUFFER_SIZE
    syscall
    cmp rax, 0
    jle  print_result
    mov rcx, rax
    mov rsi, buffer
.byte_loop:
    mov al, [rsi]
    xor bl, al
    mov rax, rbx
    mul qword [fnv_prime]
    mov rbx, rax
    inc rsi
    dec rcx
    jnz .byte_loop
    jmp read_loop

print_result:
    mov rax, rbx
    call print_int
    write STDOUT_FILENO, newline, 1
    exit 0

print_int:
    mov rbx, num_buffer
    add rbx, 31
    mov byte [rbx], 0
    dec rbx
    mov rcx, 0
    cmp rax, 0
    jge .convert_digits
    neg rax
    mov rcx, 1
.convert_digits:
    mov rdx, 0
    div qword [decimal_base]
    add dl, '0'
    mov [rbx], dl
    dec rbx
    test rax, rax
    jnz .convert_digits
    cmp rcx, 1
    jne .print_digits
    mov byte [rbx], '-'
    dec rbx
.print_digits:
    inc rbx
    mov rdx, num_buffer
    add rdx, 31
    sub rdx, rbx
    write STDOUT_FILENO, rbx, rdx
    ret
