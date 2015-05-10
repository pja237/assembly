BITS 64

%define INPUT_LEN 51
%define PATTERN_LEN 2

%define INNER_LOOP 32-PATTERN_LEN
%define OUTER_LOOP (INPUT_LEN-PATTERN_LEN)/(INNER_LOOP)
;%define REST INPUT_LEN - PATTERN_LEN - OUTER_LOOP*32
%define REST INPUT_LEN - PATTERN_LEN - (OUTER_LOOP*INNER_LOOP)

section .text
    global _start
_start:
    nop
    ; encode input into 4 bits, why not 3? because.

    ; load input
    ;
    ; LODSQ load SI -> RAX
    ;mov rsi, matrix_a
    ;lodsq
    ;mov rcx, 8

    ; DEBUG
    ;mov rax, INNER_LOOP
    ;mov rbx, OUTER_LOOP
    ;mov rcx, REST

    ; SETUP:
    ; 
    mov rdi, hits
    mov rcx, INNER_LOOP
    mov rdx, OUTER_LOOP
    mov r8, 0 ; OUTER_LOOP counter

    vzeroall
    ; VPADDUSB ymm1, ymm2, ymm3/m256
    ; Add packed unsigned byte integers from
    ; ymm2, and ymm3/m256 and store the
    ; saturated results in ymm1.
    ;VPADDUSB ymm0, ymm15, [matrix_256]
    VPADDUSB ymm1, ymm15, [pattern]
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
    VXORPD ymm3, ymm3, ymm3 ; tmp


    ; IF OUTER_LOOP=0: SET RCX (INNER_LOOP) TO BE REST
    ; ELSE RCX=INNER_LOOP (32-pattern_len)
    CMP rdx, 0
    jne NOTEQ
    ; rdx == 0
    mov rcx, REST
    jmp ENDIF
NOTEQ:
    mov rcx, INNER_LOOP
ENDIF:

    ; because of inner loop LOOP directive (exits loop @ 1)
    ;inc rcx
    ; load registers
    ; VPADDUSB ymm0, ymm15, [matrix_256+[r8]]
    VPADDUSB ymm0, ymm15, [matrix_256+r8]
    add r8, rcx
    ;add r8, 1

    nop

LOOP:
    ; TEST IF HIT
    VPAND ymm2, ymm0, ymm1
    ; if equal, ymm3 will be all-0
    VPXOR ymm3, ymm1, ymm2
    ; then test if it is
    VPTEST ymm3, ymm3

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
    VPERM2F128 ymm0, ymm0, ymm0, 1

    ; get byte
    VPEXTRB rbx, xmm0, 0

    ; return things back
    VPERM2F128 ymm0, ymm0, ymm0, 1

    ; shift <<
    ; VPSLLDQ ymm0, ymm0, 1
    VPSRLDQ ymm0, ymm0, 1

    ; but byte back in at the end
    ; VPINSRB xmm1, xmm2, r32/m8, imm8
    ; THIS SHITMADERFUCKERSUCKDICKCOCKBITCHFUCKFUCKFUCK CLEARS UP THE OTHER HALF ><
    ; VPINSRB xmm0, xmm0, bl, 15
    ; trick it using sse op? :D
    PINSRB xmm0, bl, 15
    ; yes... :)

    ; VPINSRB xmm0, xmm0, bl, 17

    ; shift & return 
    ; we're not shifting pattern anymore, we're shifting matrix now, pattern stays fixed...
    ; VPSLLDQ ymm1, ymm1, 1
    ;jmp LOOP
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
    mov rax,60 ; exit(int status)
    ; User-level applications use as integer registers for passing the sequence %rdi, %rsi, %rdx, %rcx, %r8 and %r9. 
    ; The kernel interface uses %rdi, %rsi, %rdx, %r10, %r8 and %r9.
    mov rdi,0 ; int status
    syscall

section .data
; A=1
; C=2
; T=3
; G=4
; N=5
; matrix_256: db 5,1,2,3,4,3,2,1,5,5,1,1,2,2,3,4,5,2,5,1,2,5,3,5,2,1,5,3,3,4,5,1
; matrix_256: db 32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
;                                               . 32 + 19 = 51
matrix_256: db 'ATCNNTCAAATCANGTCGCATATBGCATCACXCCATCACNTCNGGCTATCN'
; matrix_shuffle: db 5,4,3,2,1,0,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
; matrix_shuffle: db 32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
; matrix_shuffle: db 1000001b,0000000b,0000010b,0000011b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,

; pattern NCT
; pattern: db 5,1,2
; pattern: db 32,31,30
pattern: db 'TC'

section .bss
hits: resq 100 ; record 10 hits
