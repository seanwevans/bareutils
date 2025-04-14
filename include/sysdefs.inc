; include/sysdefs.inc

; Syscall numbers for Linux x86_64
%define SYS_READ    0
%define SYS_WRITE   1
%define SYS_EXIT    60

; Convenience macro for exit
%macro exit 1
    mov rax, SYS_EXIT
    mov rdi, %1
    syscall
%endmacro

; Convenience macro for write(fd, buf, len)
%macro write 3
    mov rax, SYS_WRITE
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    syscall
%endmacro
