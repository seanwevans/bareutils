; include/sysdefs.inc

; Syscall numbers for Linux x86_64
%define SYS_READ     0
%define SYS_WRITE    1
%define SYS_OPEN     2
%define SYS_CLOSE    3
%define SYS_UNAME    63
%define SYS_CHOWN    92
%define SYS_GETUID   102
%define SYS_GETEUID  107
%define SYS_EXIT     60

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
