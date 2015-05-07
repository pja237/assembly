;
; COMPILE:
; nasm -g -f elf64 fib.asm  
; ld -o fib.out fib.o
;
; RUN & DEBUG:
;
; pja@twoflower:~/WORK/src/assembly/fibonacci$ gdb fib.out
; ...
; (gdb) break 15
; Breakpoint 1 at 0x400085: file fib.asm, line 15.
; (gdb) run
; Starting program: /home/pja/WORK/src/assembly/fibonacci/fib.out 
; 
; Breakpoint 1, 0x0000000000400085 in _start ()
; (gdb) info r
; rax            0x1cfa62f21  7778742049
; rbx            0x2ee333961  12586269025 <- RESULT
; ---------------------------------------
; Result is found in rbx register.


BITS 64
section .text
    ;global main
    global _start
    extern printf

;main:
_start:

    call f_fib

    mov rax,60 ; exit(int status)
    ; User-level applications use as integer registers for passing the sequence %rdi, %rsi, %rdx, %rcx, %r8 and %r9. 
    ; The kernel interface uses %rdi, %rsi, %rdx, %r10, %r8 and %r9.
    mov rdi,0 ; int status
    syscall

f_fib:
; Performs a loop operation using the RCX, ECX or CX register as a counter (depending on whether address size is 64
; bits, 32 bits, or 16 bits). Note that the LOOP instruction ignores REX.W; but 64-bit address size can be over-ridden
; using a 67H prefix.
; Each time the LOOP instruction is executed, the count register is decremented, then checked for 0. If the count is
; 0, the loop is terminated and program execution continues with the instruction following the LOOP instruction. If
; the count is not zero, a near jump is performed to the destination (target) operand, which is presumably the
; instruction at the beginning of the loop.
    ; mov rcx, 4  ; counter ( n-fib - 1 )
    mov rcx, 49  ; counter ( n-fib - 1 )
    mov rax, 0  ; A 
    mov rbx, 1  ; B

loop_start:

    mov rdx, rbx ; tmp holder for B
    add rbx, rax ; B = B + A
    mov rax, rdx ; A = ex. B (tmp D)

    loop loop_start

    ret

