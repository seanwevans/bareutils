; src/chown.asm

section .data
    usage_msg db "Usage: chown_numeric UID[:GID] file", 10
    usage_len equ $ - usage_msg
    error_chown db "chown failed", 10
    error_chown_len equ $ - error_chown
    error_format db "Invalid UID/GID format", 10
    error_format_len equ $ - error_format
    error_argv db "Argument error", 10       ; Generic argument error
    error_argv_len equ $ - error_argv
    colon db ":"

section .bss

section .text
    global _start

_start:
    mov r12, [rsp]          ; r12 = argc
    cmp r12, 3
    jne .print_usage        ; Must have 3 args: prog, owner:group, file

    mov r13, [rsp+16]       ; r13 = argv[1] (owner/group spec)
    mov r14, [rsp+24]       ; r14 = argv[2] (file path)

    mov r8d, -1             ; r8d = target UID (using r8d for esi later)
    mov r9d, -1             ; r9d = target GID (using r9d for edx later)

    mov rdi, r13            ; String to parse
    xor rcx, rcx            ; Use rcx as index/pointer within spec string
    xor r10, r10            ; r10 = pointer to colon, 0 if not found

.find_colon_loop:
    mov al, [rdi+rcx]
    cmp al, 0
    je .colon_search_done
    cmp al, ':'
    je .found_colon
    inc rcx
    jmp .find_colon_loop

.found_colon:
    lea r10, [rdi+rcx]      ; Store address of colon in r10

.colon_search_done:
    cmp r10, 0              ; Was colon found?
    je .no_colon            ; No colon, parse entire string as UID

    cmp r10, rdi            ; Is colon the first character? (e.g., ":1000")
    je .colon_is_first

    mov byte [r10], 0       ; Temporarily null-terminate UID part
    call parse_uint         ; Parse string at rdi (UID part)
    jc .print_format_error  ; Jump if carry set (parse error)
    mov r8d, eax            ; Store parsed UID in r8d (low 32 bits of rax)
    mov byte [r10], ':'     ; Restore colon

.colon_is_first:            ; Handles ":GID" or continues after "UID:"/"UID:GID"
    inc r10                 ; Move past the colon
    cmp byte [r10], 0       ; Is there anything after the colon?
    je .parse_done          ; No, GID remains -1 (e.g., "1000:")
    
    mov rdi, r10            ; String to parse (GID part)
    call parse_uint         ; Parse string at r10 (GID part)
    jc .print_format_error  ; Jump if carry set (parse error)
    mov r9d, eax            ; Store parsed GID in r9d
    jmp .parse_done

.no_colon:                  ; No colon found, parse whole string as UID
    call parse_uint         ; Parse string at rdi (UID)
    jc .print_format_error  ; Jump if carry set (parse error)
    mov r8d, eax            ; Store parsed UID in r8d


.parse_done:
    mov rax, 92             ; syscall number for chown
    mov rdi, r14            ; pathname (argv[2])
    mov esi, r8d            ; owner (UID)
    mov edx, r9d            ; group (GID)
    syscall

    test rax, rax           ; Checks if rax is 0 or negative
    jns .exit_success       ; Jump if not sign (>= 0) -> success
    
    mov rax, 1              ; syscall write
    mov rdi, 2              ; fd stderr
    lea rsi, [rel error_chown]
    mov rdx, error_chown_len
    syscall
    jmp .exit_error

.print_usage:
    mov rax, 1              ; syscall write
    mov rdi, 2              ; fd stderr
    lea rsi, [rel usage_msg]
    mov rdx, usage_len
    syscall
    jmp .exit_error_args

.print_format_error:
    mov rax, 1              ; syscall write
    mov rdi, 2              ; fd stderr
    lea rsi, [rel error_format]
    mov rdx, error_format_len
    syscall
    jmp .exit_error

.exit_success:
    mov rax, 60             ; syscall exit
    xor rdi, rdi            ; exit code 0
    syscall

.exit_error:                ; General error exit
    mov rax, 60             ; syscall exit
    mov rdi, 1              ; exit code 1
    syscall

.exit_error_args:           ; Specific exit code for arg errors (optional)
    mov rax, 60             ; syscall exit
    mov rdi, 2              ; exit code 2 (example)
    syscall


parse_uint:
    xor rax, rax            ; Accumulator (result)
    xor rcx, rcx            ; Pointer/index within string
    mov edx, eax            ; Use edx temporarily to check for leading char
.loop:
    mov dl, [rdi+rcx]       ; Get character
    cmp dl, 0
    je .done                ; End of string

    cmp dl, '0'
    jl .error               ; Not a digit
    cmp dl, '9'
    jg .error               ; Not a digit

    sub dl, '0'             ; Convert char to integer value

    mov r11, 0xFFFFFFFF     ; Max 32-bit unsigned value
    shr r11, 3              ; Roughly MAX_UINT / 8 - quick check boundary
    cmp rax, r11            ; If rax is already large, multiplying by 10 might overflow
    ja .error               ; Likely overflow

    imul rax, rax, 10       ; Multiply accumulator by 10
    jo .error               ; Check overflow flag after multiplication

    add al, dl              ; Add the new digit (only low 8 bits needed)
    jnc .digit_added        ; Check carry after addition
    
    test rax, 0xFFFFFFFF00000000 ; Did it overflow 32 bits?
    jnz .error              ; Overflow into high 32 bits

.digit_added:
    inc rcx
    jmp .loop

.done:
    cmp rcx, 0
    je .error
    
    test rax, 0xFFFFFFFF00000000
    jnz .error
    
    clc
    ret

.error:
    stc
    ret