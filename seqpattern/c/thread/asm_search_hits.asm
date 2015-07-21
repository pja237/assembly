BITS 64

%define INNER_LOOP 28

section .text
    global _asm_search_hits
_asm_search_hits:

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
    ;asm_ret=_asm_search(input, pattern, hitmask, output , OUTER_LOOP, REST)
    ;
    ; NEW: INNER_LOOP IS NOW CONST. == 30
    ; instead of inner loop, we're now getting pointers to output lines

    ; SETUP:
    ; 
    ;VPADDUSB ymm1, ymm15, [rsi] ; pattern in ymm1
    VMOVUPS ymm1, [rsi] ; pattern in ymm1
    ;VPADDUSB ymm14, ymm15, [rdx] ; hitmask in ymm14
    VMOVUPS ymm14, [rdx] ; hitmask in ymm14
    mov r11, INNER_LOOP ; INNER_LOOP, old: r11, rcx new: r11,30
    mov rdx, r8 ; OUTER_LOOP

    mov r10, rdi ; save input here for now, we need rdi for hits
    mov rdi, rcx ; old: rdi, hits , new: rdi, 
    mov r8, 0 ; OUTER_LOOP counter

OUT_LOOP:
    ; zero registers
    VXORPD ymm0, ymm0, ymm0 ; input
    VXORPD ymm2, ymm2, ymm2 ; tmp

    ; IF OUTER_LOOP=0: SET RCX (INNER_LOOP) TO BE REST
    ; ELSE RCX=INNER_LOOP (32-pattern_len)
    CMP rdx, 0
    jne NOTEQ
    ; rdx == 0, so this is the last round, only REST is remaining
    ; >>>>>>>> BUG 302! if REST==0 => SEGFAULT BECAUSE WE'RE DONE, NO MORE PULLING MEMORY <<<<<<<<<<<<<
    ;mov rcx, REST ; standalone before
    cmp r9, 0 ; if REST==0, we're done, go to end, otherwise, shit happens with LOOP below
    je THE_END
    mov rcx, r9 ; now arriving via r9 from caller.c
    jmp ENDIF
NOTEQ:
    mov rcx, INNER_LOOP ; r11 == INNER_LOOP (now const)
ENDIF:

    ; because of inner loop LOOP directive (exits loop @ 1)
    ; FIX: last-position pattern miss
    inc rcx
    ;
    ;prefetchnta [r10+r8+X ] prostudirati u x86 manualu tocno koliko moze utjecati

    ; load registers
    ;VPADDUSB ymm0, ymm15, [r10+r8] ; input + offset
    VMOVUPS ymm0, [r10+r8] ; input + offset
    add r8, rcx
    ;add r8, 1

    ; keep the 'flipped' input for faster over-the-lane byte shift
    VPERM2F128 ymm13, ymm0, ymm0, 1

LOOP:

; -------------------------------------------------------------------------------- 
;  ORIGINAL TEST
; -------------------------------------------------------------------------------- 
;    ; new test, using predefined bitmask of a hit: ymm14
;    VPCMPEQB ymm2, ymm0, ymm1
;    VPXOR ymm2, ymm2, ymm14
;
;    ; if HIT, ymm2 == 0
;    VPTEST ymm2, ymm2
;    ; jz HIT
;    ;
;    ; IF ZF==1 then it's a hit, avoid jmp and do SETcc
;    SETZ AL
;    ; For legacy mode, store AL at address ES:(E)DI;
;    ; For 64-bit mode store AL at address RDI or EDI.
;    STOSB
; -------------------------------------------------------------------------------- 
;  NEW TEST, remove the VPXOR op, and go straight to VTEST to check CF
; -------------------------------------------------------------------------------- 
    ; new test, using predefined bitmask of a hit: ymm14
    VPCMPEQB ymm2, ymm0, ymm1
    ; not needed, VPTEST does this for us
    ;VPXOR ymm2, ymm2, ymm14

    ; if HIT, ymm2 == ymm14
    VPTEST ymm2, ymm14
    ; jz HIT
    ;
    ; IF CF==1 then it's a hit (ymm2==ymm14), avoid jmp and do SETcc
    ;SETZ AL
    SETC AL
    ; For legacy mode, store AL at address ES:(E)DI;
    ; For 64-bit mode store AL at address RDI or EDI.
    STOSB
; -------------------------------------------------------------------------------- 
    ; now, try:
    ; 1 - fetch last byte of ymm1[upper], put in some temp space (reg)
    ; 2 - carry it over and put in 1st place of ymm1[lower]
    ; 3 - do shift left

    ; step 1.
    ; 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
    ;                                        ^ GET this one and ten shift everything left
    ; swap hi-lo
    ; get byte from xmm0
    ; swap back
    ; shift <<
    ; fill byte 

    ; TODO: keep swapped ymm0 in ymm10, when byte is needed, take from the swapped version, cost: 1 swap, +1 shift/pass
    ; now cost: +2 swaps/pass

    ; SWAP
    ; VPERM2F128 ymm1, ymm2, ymm3/m256, imm8
    ; Permute 128-bit floating-point fields in ymm2 and ymm3/mem using controls from imm8 and store result in ymm1.
    ;VPERM2F128 ymm0, ymm0, ymm0, 1

    ; get byte
    VPEXTRB rbx, xmm13, 0

    ; shift <<
    VPSRLDQ ymm0, ymm0, 1
    ; shift the shift-temp helper also
    VPSRLDQ ymm13, ymm13, 1

    ; but byte back in at the end
    ; VPINSRB xmm1, xmm2, r32/m8, imm8
    ; THIS SHITMADERFUCKERSUCKDICKCOCKBITCHFUCKFUCKFUCK CLEARS UP THE OTHER HALF ><
    ; VPINSRB xmm0, xmm0, bl, 15
    ; trick it using sse op? :D
    PINSRB xmm0, bl, 15
    ; yes... :)

    ; Each time the LOOP instruction is executed, the count register is decremented, then checked for 0. If the count is
    ; 0, the loop is terminated and program execution continues with the instruction following the LOOP instruction. If
    ; the count is not zero, a near jump is performed to the destination (target) operand, which is presumably the
    ; instruction at the beginning of the loop.
    ; >>> 302 <<<
    ; IF RCX == 0 here, we DON'T EXIT LOOP, we go on forever, i.e. until segfault
    loop LOOP
; -------------------------------------------------------------------------------- 
    ; TO CHECK: >>> PCMPESTRI <<<

    ; IF OUTER_LOOP==0: THE_END
    ; ELSE DECREMENT RDX; GOTO: OUTER_LOOP
    dec rdx
    cmp rdx, -1
    je THE_END

    jmp OUT_LOOP

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
