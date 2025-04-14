section .bss
    cpuset resb 128         ; Buffer for cpu_set_t (1024 bits)
    num_buffer resb 20      ; Buffer for integer to string conversion
    num_end resb 1          ; Marks end of num_buffer

section .data
    newline db 10           ; Newline character

section .text
    global _start

_start:
    ; Get affinity mask using sched_getaffinity(pid=0, cpusetsize, *mask)
    mov rax, 204            ; syscall number for sched_getaffinity
    mov rdi, 0              ; pid = 0 (current process)
    mov rsi, 128            ; size of the cpuset buffer (1024 bits / 8 bits/byte)
    lea rdx, [rel cpuset]   ; address of the buffer
    syscall
    ; rax holds result, should be >= 0 on success

    test rax, rax           ; Check if rax is negative (error)
    js .exit_error          ; Jump if sign flag is set (error)

    ; Count set bits (CPUs) in the mask
    mov rbx, 0              ; rbx will hold the total count
    mov rcx, 16             ; Loop 16 times (16 * 64 bits = 1024 bits)
    lea rsi, [rel cpuset]   ; Point rsi to the start of the mask

.count_loop:
    mov rax, [rsi]          ; Load 64 bits from the mask
    popcnt rax, rax         ; Count set bits in rax
    add rbx, rax            ; Add to total count
    add rsi, 8              ; Move to next 64 bits
    loop .count_loop        ; Decrement rcx and loop if not zero

    ; Convert the count (rbx) to ASCII string
    mov rax, rbx            ; Number to convert
    lea rdi, [rel num_end]  ; Point to the end of the number buffer
    mov byte [rdi], 10      ; Place newline at the very end
    mov r10, 10             ; Divisor

.to_ascii_loop:
    xor rdx, rdx            ; Clear rdx for division
    div r10                 ; rax = rax / 10, rdx = rax % 10
    add dl, '0'             ; Convert remainder (digit) to ASCII
    dec rdi                 ; Move buffer pointer back
    mov [rdi], dl           ; Store ASCII digit
    test rax, rax           ; Is quotient zero?
    jnz .to_ascii_loop      ; If not, continue loop

    ; rdi now points to the start of the number string

    ; Calculate string length
    lea rdx, [rel num_end]  ; Point rdx to the end marker (newline)
    sub rdx, rdi            ; rdx = end_ptr - start_ptr = length

    ; Write the number string to stdout
    mov rax, 1              ; syscall number for write
    mov rsi, rdi            ; address of the string to write (start)
    mov rdi, 1              ; file descriptor 1 = stdout
    ; rdx already contains the length
    syscall

.exit_success:
    mov rax, 60             ; syscall number for exit
    xor rdi, rdi            ; exit code 0
    syscall

.exit_error:
    mov rax, 60             ; syscall number for exit
    mov rdi, 1              ; exit code 1
    syscall