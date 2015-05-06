; COMPILE:
; nasm -g -f elf64 geteuid.asm  
; gcc -o geteuid.out geteuid.o

BITS 64
section .text
    global main
    extern printf

main:

    ; /usr/src/linux-source-3.16/arch/x86/syscalls
    ; syscall_32.tbl : 49=geteuid, 20=getpid
    ; syscall_64.tbl : 107=geteuid, 39=getpid
    ;
    ; - 32 bit:
    ; mov eax,49
    ; int 80h
    ; - 64 bit call:
    mov rax,107 ; geteuid(void)
    syscall

    ; http://www.x86-64.org/documentation/abi.pdf
    ; 3.2.3 Parameter Passing
    ; page 21:  If the class is INTEGER, the next available register of the sequence %rdi, %rsi, %rdx, %rcx, %r8 and %r9 is used.
    mov rdi, printmsg 
    mov rsi, rax ; return value from syscall above is in rax
    ; %rax temporary register; with variable arguments passes information about the number of vector registers used; 1st return register
    ; SEGFAULTS unless rax is zeroed 
    ; still not quite clear why? because of the above: variable arguments?
    mov rax,0 
    call printf

    mov rax,60 ; exit(int status)
    ; User-level applications use as integer registers for passing the sequence %rdi, %rsi, %rdx, %rcx, %r8 and %r9. 
    ; The kernel interface uses %rdi, %rsi, %rdx, %r10, %r8 and %r9.
    mov rdi,0 ; int status
    syscall

section .data
printmsg: db 'geteuid() = %d',10,0 ; msg + LINEFEED + 0

