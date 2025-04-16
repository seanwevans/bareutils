; src/cat.asm

%include "include/sysdefs.inc"

section .bss
    buffer: resb 4096           ; Buffer for reading data
    buffer_size equ 4096        ; Size of the buffer

section .text
    global _start

_start:
    pop r12                     ; Get argc (number of arguments)
    pop rdi                     ; Discard argv[0] (program name)
    dec r12                     ; Decrease argc by 1 (to exclude program name)
    
    cmp r12, 0                  ; Check if there are no arguments
    je read_from_stdin          ; If no arguments, read from stdin
    
process_arguments:
    cmp r12, 0                  ; Check if we've processed all arguments
    je exit_success             ; If yes, exit successfully
    
    pop rdi                     ; Get the next argument (filename)
    call cat_file               ; Process the file
    
    dec r12                     ; Decrement argument counter
    jmp process_arguments       ; Process next argument
    
read_from_stdin:
    mov rdi, STDIN_FILENO       ; Set file descriptor to stdin
    call cat_fd                 ; Process the file descriptor
    jmp exit_success            ; Exit after processing
    
cat_file:
    mov rax, SYS_OPEN           ; syscall number for open

    mov rsi, O_RDONLY           ; Open for reading only
    mov rdx, 0                  ; Mode (not used for O_RDONLY)
    syscall
    
    cmp rax, 0                  ; Check if open succeeded
    jl error_exit               ; If negative, there was an error
    
    mov rdi, rax                ; Move file descriptor to rdi for cat_fd
    push r12                    ; Save r12 (argument counter)
    call cat_fd                 ; Process the opened file
    pop r12                     ; Restore r12

    mov rax, SYS_CLOSE          ; syscall number for close

    syscall
    
    ret
    
cat_fd:
    push rdi                    ; Save the file descriptor
    
read_loop:
    mov rax, SYS_READ           ; syscall number for read
    pop rdi                     ; Restore file descriptor
    push rdi                    ; Save it again for the next iteration
    mov rsi, buffer             ; Buffer to read into
    mov rdx, buffer_size        ; Number of bytes to read
    syscall
    
    cmp rax, 0                  ; Check if read returned 0 (EOF)
    jle read_done               ; If <= 0, we're done or there was an error

    mov rdx, rax                ; Number of bytes to write (from read)
    mov rax, SYS_WRITE          ; syscall number for write
    mov rdi, STDOUT_FILENO      ; File descriptor for stdout
    mov rsi, buffer             ; Buffer to write from
    syscall
    
    jmp read_loop               ; Continue reading
    
read_done:
    pop rdi                     ; Clean up the stack
    ret
    
error_exit:
    exit 1                      ; Exit with error code 1
    
exit_success:
    exit 0                      ; Exit with success code 0