%include "include/sysdefs.inc" ; Include definitions and macros

section .data
    utmp_file db "/var/run/utmp", 0 ; Path to the utmp file
    errmsg_open db "Error: Cannot open /var/run/utmp", 10 ; Error message + newline
    errmsg_open_len equ $ - errmsg_open                  ; Length of open error message
    errmsg_read db "Error: Cannot read /var/run/utmp", 10 ; Error message + newline
    errmsg_read_len equ $ - errmsg_read                  ; Length of read error message
    newline db 10 ; ASCII code for newline character
    tab db 9     ; ASCII code for tab character

section .bss
    utmp_buf resb UTMP_SIZE ; Reserve buffer space for one utmp record
    ; No need for a .bss buffer for itoa if we use the stack

section .text
    global _start ; Make _start symbol globally visible for the linker

_start:
    ; --- Open /var/run/utmp ---
    mov rax, SYS_OPEN      ; syscall number for open
    mov rdi, utmp_file     ; pointer to filename string
    mov rsi, O_RDONLY      ; flags: read-only
    mov rdx, 0             ; mode (not used when opening existing file read-only)
    syscall                ; rax = file descriptor (>= 0) or negative error code

    cmp rax, 0             ; Check if syscall returned an error (< 0)
    jl .open_error         ; If rax < 0, jump to open error handler

    mov r12, rax           ; Save file descriptor in r12 (callee-saved register)

.read_loop:
    ; --- Read one utmp record from the file ---
    mov rax, SYS_READ      ; syscall number for read
    mov rdi, r12           ; file descriptor from r12
    mov rsi, utmp_buf      ; buffer address to read into
    mov rdx, UTMP_SIZE     ; number of bytes to read (size of one record)
    syscall                ; rax = bytes read, 0 for EOF, < 0 for error

    cmp rax, 0             ; Check if EOF (0) or error (< 0)
    jle .done              ; If rax <= 0, jump to done section (handles EOF and errors)

    cmp rax, UTMP_SIZE     ; Check if the number of bytes read is correct
    jne .read_error        ; If not equal (partial read?), jump to read error handler

    ; --- Record read successfully (rax == UTMP_SIZE) ---

    ; --- Check ut_type field ---
    mov ax, word [utmp_buf + UT_TYPE_OFF] ; Load ut_type into ax (lower 16 bits of rax)

    ; --- Skip only EMPTY records ---
    cmp ax, EMPTY          ; Check if the type is EMPTY (0)
    je .read_loop          ; If it's an empty record, skip it and read the next

    ; --- Record is not EMPTY, proceed to print ---

    ; --- Print username ---
    mov rdi, utmp_buf + UT_USER_OFF ; Address of username field in buffer
    mov rsi, UT_NAMESIZE            ; Max size of the field
    call print_field_padded         ; Call helper function to print it

    ; --- Print tab separator ---
    mov rax, SYS_WRITE
    mov rdi, STDOUT_FILENO
    mov rsi, tab
    mov rdx, 1
    syscall

    ; --- Print tty line ---
    mov rdi, utmp_buf + UT_LINE_OFF ; Address of line field in buffer
    mov rsi, UT_LINESIZE            ; Max size of the field
    call print_field_padded         ; Call helper function to print it

    ; --- Print tab separator before timestamp ---
    mov rax, SYS_WRITE
    mov rdi, STDOUT_FILENO
    mov rsi, tab
    mov rdx, 1
    syscall

    ; --- Print Timestamp ---
    mov eax, dword [utmp_buf + UT_TV_OFF] ; Load 32-bit tv_sec into eax
    call print_uint32_dec                 ; Call helper to print unsigned int in eax

    ; --- Print newline ---
    mov rax, SYS_WRITE
    mov rdi, STDOUT_FILENO
    mov rsi, newline
    mov rdx, 1
    syscall

    jmp .read_loop         ; Go back to read the next record

.done:
    ; --- Finished reading or error occurred ---
    cmp rax, 0             ; Check rax from the last SYS_READ call
    jl .read_error         ; If rax < 0, it was a read error, jump to handler

.close_and_exit_ok:
    ; --- Close file and exit normally ---
    mov rax, SYS_CLOSE     ; syscall number for close
    mov rdi, r12           ; file descriptor to close
    syscall                ; Ignore close errors for simplicity
    exit 0                 ; Exit program with success status (0)

.open_error:
    ; --- Handle error during file opening ---
    mov rax, SYS_WRITE
    mov rdi, STDERR_FILENO
    mov rsi, errmsg_open
    mov rdx, errmsg_open_len
    syscall
    exit 1                 ; Exit program with error status (1)

.read_error:
    ; --- Handle error during file reading ---
    mov rax, SYS_WRITE
    mov rdi, STDERR_FILENO
    mov rsi, errmsg_read
    mov rdx, errmsg_read_len
    syscall
    ; --- Close the file descriptor before exiting ---
    mov rax, SYS_CLOSE     ; syscall number for close
    mov rdi, r12           ; file descriptor to close
    syscall                ; Ignore close errors
    exit 1                 ; Exit program with error status (1)

; -----------------------------------------------------
; Helper function: print_field_padded
; (Same as before - uses raw syscall for write)
; -----------------------------------------------------
print_field_padded:
    mov rdx, 0             ; Initialize length counter (rdx) to 0
    mov rcx, rsi           ; Copy max size to counter (rcx)
    mov rsi, rdi           ; Use rsi as the scanning pointer, starting at buffer address (rdi)
.scan_loop:
    cmp rcx, 0             ; Check if we have scanned max number of bytes
    je .do_write           ; If counter is 0, jump to write
    cmp byte [rsi], 0      ; Check if the current byte is a null terminator
    je .do_write           ; If null byte found, jump to write
    inc rsi                ; Move scan pointer to the next byte
    inc rdx                ; Increment the length count
    dec rcx                ; Decrement the max size counter
    jmp .scan_loop         ; Continue scanning

.do_write:
    cmp rdx, 0             ; Don't syscall if length is 0
    jle .skip_write
    mov rax, SYS_WRITE     ; syscall number for write
    mov rsi, rdi           ; arg1 = buffer address (from original rdi)
    ; rdx already holds length (arg2)
    mov rdi, STDOUT_FILENO ; arg0 = fd (stdout = 1)
    syscall
.skip_write:
    ret

; -----------------------------------------------------
; Helper function: print_uint32_dec
; Description: Converts unsigned 32-bit integer in EAX to decimal string
;              and prints it to STDOUT_FILENO.
; Input:
;   eax = Unsigned 32-bit integer
; Output:
;   Writes decimal string to STDOUT_FILENO
; Clobbers: rax, rbx, rcx, rdx, rdi, rsi + stack space
; -----------------------------------------------------
print_uint32_dec:
    ; Allocate buffer space on the stack (10 digits max for u32 + 1 for safety/null = 11 -> 16 for alignment)
    sub rsp, 16
    mov rdi, rsp           ; rdi points to the start of the buffer space
    add rdi, 10            ; Move pointer towards the end (to store digits backwards)
    mov byte [rdi], 0      ; Null-terminate (optional, we use length) - use byte after buffer end
    mov rcx, rdi           ; Save pointer to end of digits (for length calculation)

    mov ebx, 10            ; Divisor for decimal conversion

    ; Handle zero case explicitly
    test eax, eax
    jnz .conversion_loop   ; If eax is not zero, start conversion
    ; EAX is zero
    dec rdi                ; Move pointer back one position
    mov byte [rdi], '0'    ; Store '0'
    jmp .print_number

.conversion_loop:
    xor edx, edx           ; Clear edx for 32-bit division (edx:eax / ebx)
    div ebx                ; eax = quotient, edx = remainder
    add dl, '0'            ; Convert remainder (0-9) to ASCII ('0'-'9')
    dec rdi                ; Move buffer pointer back
    mov [rdi], dl          ; Store ASCII digit in buffer
    test eax, eax          ; Check if quotient is zero
    jnz .conversion_loop   ; If not zero, continue loop

.print_number:
    ; Now, rdi points to the first digit in the buffer
    ; rcx points to the byte after the last digit
    ; Calculate length: rcx - rdi
    sub rcx, rdi
    mov rdx, rcx           ; rdx = length of the string

    ; Print the number string using raw syscall
    mov rax, SYS_WRITE
    mov rsi, rdi           ; rsi = buffer address (start of digits)
    mov rdi, STDOUT_FILENO ; rdi = fd (stdout)
    ; rdx already holds length
    syscall

    ; Deallocate stack space
    add rsp, 16
    ret
