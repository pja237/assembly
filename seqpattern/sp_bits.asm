BITS 64

%define ROWS  10
%define COLS  10

%define PATTERN_SIZE 4
%define SUBPATTERN_SIZE PATTERN_SIZE-1

section .text
    global _start
_start:

    ; SETUP
    ; SCASW - compare WORD from AX with WORD @ ES:DI
    ; After the comparison, the (E)DI register is incremented or decremented automatically according to the setting of
    ; the DF flag in the EFLAGS register. If the DF flag is 0, the (E)DI register is incremented; if the DF flag is 1, the (E)DI
    ; register is decremented. The register is incremented or decremented by 1 for byte operations, by 2 for word oper-
    ; ations, and by 4 for doubleword operations.

    mov r15, hits ; address of hits, to be used as DI later 
    mov rdi, matrix
    mov rcx, [matrix_size]
    
    mov al, [pattern] ; put 1st character of pattern in AL to be used with SCASW

    ; we need a loop here
MAINLOOP:
    repne scasb ; compare matrix byte-by-byte with AL character until equal
    jz hit
    ; and here

    nop

    mov rax,60 ; exit(int status)
    ; User-level applications use as integer registers for passing the sequence %rdi, %rsi, %rdx, %rcx, %r8 and %r9. 
    ; The kernel interface uses %rdi, %rsi, %rdx, %r10, %r8 and %r9.
    mov rdi,0 ; int status
    syscall

hit:
    nop
    ; save CX, DI for later
    mov r8, rcx
    mov r9, rdi
    ; compare rest of pattern 
    mov rcx, SUBPATTERN_SIZE
    mov rsi, pattern+1
    repe cmpsb
    jz match
    ; NO MATCH, restore RAX, RCX & RDI and go back to continue from there
    mov rcx, r8
    mov rdi, r9
    mov al, [pattern]
    ; OR... CONTINUE FROM HERE!?
    jmp eohit
match:
    ; rewrite this to return RDI & RCX saved in hit above, not after full match, because in case:
    ; matrix: AAA AAA
    ; pattern: AAA
    ; must return 111100 result, not: 100100
    inc r10 ; hits counter register
    mov r14, rdi ; tmp save DI
    mov rdi, r15 ; put hits in DI
    mov rax, r8  ; prepare HIT position for STOSQ 
    inc rax
    stosq ; save RAX to DI
    ; save HITS DI to R15 for later, restore regs
    mov r15, rdi ; new hits DI
    mov rdi, r14 ; matrix DI
    mov rcx, r8  ; counter how much of matrix is left
    sub rcx, SUBPATTERN_SIZE
    ; mov rax, 0x0000000000000000
    mov al, [pattern]
eohit:
    nop
    jmp MAINLOOP


section .data
;           0987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321
matrix: db 'ACATATACGACAAAACATAAAAATAAAATAGAATATAAAAACAATATACCGACATATAACGAAAATAACACGCGTACGAAACATACGACGCGAAACGAAC'
matrix_size: dq 100
;pattern: db 'TA'
pattern: db 'AAAA'

section .bss
hits: resq 100 ; record 10 hits
