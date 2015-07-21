BITS 64

%define INNER_LOOP 28

section .text
    global _asm_search_standard
_asm_search_standard:

; Registers %rbp, %rbx and %r12 through %r15 belong to the calling function and the called function is
; required to preserve their values. In other words, a called function must preserve
; these registers values for its caller. Remaining registers belong to the called
; function.5 If a calling function wants to preserve such a register value across a
; function call, it must save the value in its local stack frame.
    push rbp
    push rbx
    push rdi
    push rsi
    mov rbp, rsp
; 

    ; GET VALUES FROM CALLING FUNCTION
    ; abi says: 
    ; If the class is INTEGER, the next available register of the sequence %rdi, %rsi, %rdx, %rcx, %r8 and %r9 is used

    ;                    rdi     rsi     rdx        rcx         r8       r9
    ;asm_ret=_asm_search(input, pattern, output , input_len )
    ;

    ; SETUP
    ; SCASW - compare WORD from AX with WORD @ ES:DI
    ; After the comparison, the (E)DI register is incremented or decremented automatically according to the setting of
    ; the DF flag in the EFLAGS register. If the DF flag is 0, the (E)DI register is incremented; if the DF flag is 1, the (E)DI
    ; register is decremented. The register is incremented or decremented by 1 for byte operations, by 2 for word oper-
    ; ations, and by 4 for doubleword operations.

    ; rdx = output, save to r8 for later
    mov r8, rdx
    ; rdi == input , save to r9 for later
    mov r9, rdi
    ; rcx == input_len, save to r10 for later
    mov r10, rcx
    ; rsi == pattern, save to r11 for later
    mov r11, rcx

    mov al, [r11] ; put 1st character of pattern in AL to be used with SCASW

    ; prepare main loop
    mov rdi, r9 ; input start in rdi

MAINLOOP:

    repne scasb ; compare matrix byte-by-byte of [RDI] with [AL] character until equal
    jz hit

    ; rcx--; if rcx==0: goto MAINLOOP
    loop MAINLOOP

    ; return(0)
    mov rax,0 
    ret

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



THE_END:

    mov rsp, rbp
    pop rsi
    pop rdi
    pop rbx
    pop rbp

    mov rax, 0
    ret

section .data

section .bss
