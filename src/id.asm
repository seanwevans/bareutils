; src/id.asm

%include "include/sysdefs.inc"

section .bss
    groups_buf resd 32        ; 32 * 4 = 128 bytes, 32-bit group IDs
    numbuf resb 16            ; for printing numbers

section .data
    newline db 10
    uid_prefix db "uid=", 0
    gid_prefix db " gid=", 0
    groups_prefix db " groups=", 0
    comma db ",", 0
    space db " ", 0

section .text
    global _start

_start:
    ; --- UID ---
    mov rax, 102              ; syscall: getuid
    syscall
    mov rdi, uid_prefix
    call write_str
    mov rdi, rax
    call print_num
    call write_space

    ; --- GID ---
    mov rax, 104              ; syscall: getgid
    syscall
    mov rdi, gid_prefix
    call write_str
    mov rdi, rax
    call print_num
    call write_space

    ; --- GROUPS ---
    mov rax, 115              ; syscall: getgroups
    mov rdi, 32               ; max count we can hold
    mov rsi, groups_buf
    syscall

    cmp rax, 32
    jg .too_many_groups
    mov rcx, rax
    jmp .check_count

.too_many_groups:
    mov rcx, 32               ; clamp to safe max

.check_count:
    cmp rcx, 0
    je .done

    call write_groups_prefix

    xor rbx, rbx

.group_loop:
    mov edi, [groups_buf + rbx*4]
    test edi, edi
    je .done
    call print_num
    
    mov eax, [groups_buf + rbx*4 + 4]
    test eax, eax
    je .newline_and_exit

    call write_comma
    inc rbx
    jmp .group_loop

.newline_and_exit:
    write 1, newline, 1
    exit 0

.done:
    write 1, newline, 1
    exit 0

print_num:
    ; rdi = value to print
    mov rax, rdi
    mov rsi, numbuf + 15
    mov byte [rsi], 0
    mov rcx, 10
.next_digit:
    xor rdx, rdx
    div rcx
    dec rsi
    add dl, '0'
    mov [rsi], dl
    test rax, rax
    jnz .next_digit
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rdx, numbuf + 16
    sub rdx, rsi
    syscall
    ret


write_str:
    ; rdi = null-terminated string
    mov rsi, rdi
    call strlen
    write 1, rsi, rbx
    ret

write_comma:
    write 1, comma, 1
    ret

write_space:
    write 1, space, 1
    ret

write_groups_prefix:
    mov rdi, groups_prefix
    call write_str
    ret

strlen:
    xor rbx, rbx
.loop:
    cmp byte [rsi + rbx], 0
    je .done
    inc rbx
    jmp .loop
.done:
    ret
