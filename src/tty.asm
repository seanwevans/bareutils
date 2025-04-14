; src/tty.asm

%include "include/sysdefs.inc"

section .bss
    termios_buf resb 32             ; dummy termios struct
    result_buf  resb 128            ; for readlink result

section .data
    fd_path     db "/proc/self/fd/0", 0
    not_a_tty   db "not a tty", 10
    newline     db 10

section .text
    global _start

_start:
    ; Is stdin a TTY? (ioctl with TCGETS)
    mov     rax, 16                 ; SYS_ioctl
    mov     rdi, 0                  ; stdin
    mov     rsi, 0x5401             ; TCGETS
    lea     rdx, [termios_buf]
    syscall

    test    rax, rax
    js      .notty                 ; not a tty if ioctl fails

    ; readlink("/proc/self/fd/0") → result_buf
    mov     rax, 89                 ; SYS_readlink
    lea     rdi, [fd_path]
    lea     rsi, [result_buf]
    mov     rdx, 128
    syscall

    test    rax, rax
    js      .notty                 ; should never happen here

    ; write result_buf to stdout
    mov     rdi, 1                  ; stdout
    mov     rsi, result_buf
    mov     rdx, rax                ; rax = bytes read
    mov     rax, 1                  ; SYS_write
    syscall

    write   1, newline, 1
    exit    0

.notty:
    write   1, not_a_tty, 10
    exit    1
