BITS 64

%define INPUT_LEN 51
%define PATTERN_LEN 2

%define INNER_LOOP 32-PATTERN_LEN
%define OUTER_LOOP (INPUT_LEN-PATTERN_LEN)/(INNER_LOOP)
;%define REST INPUT_LEN - PATTERN_LEN - OUTER_LOOP*32
%define REST INPUT_LEN - PATTERN_LEN - (OUTER_LOOP*INNER_LOOP)

section .text
    global _asm_search
    global hits
_asm_search:

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

    nop

    ; GET VALUES FROM CALLING FUNCTION
    ; abi says: 
    ; If the class is INTEGER, the next available register of the sequence %rdi, %rsi, %rdx, %rcx, %r8 and %r9 is used

    nop

    ;                    rdi     rsi     rdx        rcx         r8       r9
    ;asm_ret=_asm_search(input, pattern, hitmask, INNER_LOOP, OUTER_LOOP, REST)

    ;VPADDUSB ymm0, ymm15, [rdi]
    VPADDUSB ymm1, ymm15, [rsi] ; pattern in ymm1
    VPADDUSB ymm14, ymm15, [rdx] ; hitmask in ymm14
    mov r11, rcx ; INNER_LOOP
    mov rdx, r8 ; OUTER_LOOP
    ;mov r12, r9 

    nop

    ; encode input into 4 bits, why not 3? because.

    ; DEBUG
    ;mov rax, INNER_LOOP
    ;mov rbx, OUTER_LOOP
    ;mov rcx, REST

    ; SETUP:
    ; 
    mov r10, rdi ; save input here for now, we need rdi for hits
    mov rdi, hits
    ;mov rcx, INNER_LOOP
    ;mov rdx, OUTER_LOOP
    mov r8, 0 ; OUTER_LOOP counter

    ; not needed anymore
    ;vzeroall

    ; VPADDUSB ymm1, ymm2, ymm3/m256
    ; Add packed unsigned byte integers from
    ; ymm2, and ymm3/m256 and store the
    ; saturated results in ymm1.
    ;
    ;VPADDUSB ymm1, ymm15, [pattern]
    ;VPADDUSB ymm14, ymm15, [hitmask]

    ;vinserti128 ymm0, ymm1, [matrix_a], 0
    ;vinserti128 ymm2, ymm3, [matrix_x], 0
    ;
    ; ymm2 = v32_int8 = {0, 0, 0, 3, 4, 3, 2, 1, 5, 5, 1, 1, 2, 2, 3, 4, 5, 2, 5, 1, 2, 5, 3, 5, 2, 1, 5, 3, 3, 4, 5, 1}
    ; VXORPS ymm2, ymm0, ymm1

    ; ymm2 = v32_int8 = {0, 0, 0, 3, 4, 3, 2, 1, 5, 5, 1, 1, 2, 2, 3, 4, 5, 2, 5, 1, 2, 5, 3, 5, 2, 1, 5, 3, 3, 4, 5, 1}
    ; VPXOR ymm2, ymm0, ymm1

    ; ymm2 = v32_int8 = {5, 1, 2, 0 <repeats 29 times>}
    ; ymm1 = v32_int8 = {5, 1, 2, 0 <repeats 29 times>}

    ; ymm2 = v32_int8 = {-1, -1, -1, 0 <repeats 29 times>}
    ; VPCMPEQB  ymm2, ymm0, ymm1
OUT_LOOP:
    nop

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
    mov rcx, r11 ; r11 == INNER_LOOP
ENDIF:

    ; because of inner loop LOOP directive (exits loop @ 1)
    ; FIX: last-position pattern miss
    inc rcx
    ; load registers
    ; VPADDUSB ymm0, ymm15, [matrix_256+[r8]]
    ;VPADDUSB ymm0, ymm15, [matrix_256+r8]
    VPADDUSB ymm0, ymm15, [r10+r8]
    add r8, rcx
    ;add r8, 1

    ; keep the 'flipped' input for faster over-the-lane byte shift
    VPERM2F128 ymm13, ymm0, ymm0, 1

    nop

LOOP:
    nop

    ; new test, using predefined bitmask of a hit: ymm14
    VPCMPEQB ymm2, ymm0, ymm1
    VPXOR ymm2, ymm2, ymm14
    ; if hit, ymm4==0

; this doesn't work, try packed byte compare
; -------------------------------------
    ; TEST IF HIT
    ;VPAND ymm2, ymm0, ymm1
    ; if equal, ymm3 will be all-0
    ;VPXOR ymm3, ymm1, ymm2
; -------------------------------------

    ; if HIT, ymm2 == 0
    VPTEST ymm2, ymm2
    ; jz HIT
    ;
    ; IF ZF==1 then it's a hit, avoid jmp and do SETcc
    SETZ AL
    ; For legacy mode, store AL at address ES:(E)DI;
    ; For 64-bit mode store AL at address RDI or EDI.
    STOSB

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
    ;VPEXTRB rbx, xmm0, 0
    VPEXTRB rbx, xmm13, 0

    ; return things back
    ;VPERM2F128 ymm0, ymm0, ymm0, 1

    ; shift <<
    ; VPSLLDQ ymm0, ymm0, 1
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

    ; shift & return 
    ; we're not shifting pattern anymore, we're shifting matrix now, pattern stays fixed...
    ; VPSLLDQ ymm1, ymm1, 1
    ;jmp LOOP

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
    ;TEST RDX, -1
    ;JZ THE_END
    cmp rdx, -1
    je THE_END

    jmp OUT_LOOP

THE_END:

    nop

    ; EXIT
    ;mov rax,60 ; exit(int status)
    ; User-level applications use as integer registers for passing the sequence %rdi, %rsi, %rdx, %rcx, %r8 and %r9. 
    ; The kernel interface uses %rdi, %rsi, %rdx, %r10, %r8 and %r9.
    ;mov rdi,0 ; int status
    ;syscall
    
    mov rsp, rbp
    pop rsi
    pop rdi
    pop rbx
    pop rbp

    mov rax, hits
    ret

section .data
;                                               . 32 + 19 = 51
;matrix_256: db 'ATCNNTCAAATCANGTCGCATATBGCATCACXCCATCACNTCNGGCTATCN'
;blank_256: db 0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b

; 2 6 11 16 28 36 41 49
;pattern: db 'TC',1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b
;hitmask: db 11111111b,11111111b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b

; 6 11 28 36
;pattern: db 'TCA',1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b
;hitmask: db 11111111b,11111111b,11111111b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b,0b

section .bss
;hits: resq 100 ; record 10 hits
hits: resb 100000000 ; record 10 hits
