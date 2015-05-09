BITS 64

%define ROWS  10
%define COLS  10

%define PATTERN_SIZE 4
%define SUBPATTERN_SIZE PATTERN_SIZE-1

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

    vzeroall
    ; VPADDUSB ymm1, ymm2, ymm3/m256
    ; Add packed unsigned byte integers from
    ; ymm2, and ymm3/m256 and store the
    ; saturated results in ymm1.
    VPADDUSB ymm0, ymm15, [matrix_256]
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

LOOP:
    ; TEST IF HIT
    VPAND ymm2, ymm0, ymm1
    ; if equal, ymm3 will be all-0
    VPXOR ymm3, ymm1, ymm2
    ; then test if it is
    VPTEST ymm3, ymm3
    jz HIT

    ; if not: shift and return
    mov rbx, 0 ; hit flag down
    VPSLLDQ ymm1, ymm1, 1
    jmp LOOP

    ; TO CHECK: >>> PCMPESTRI <<<

    nop

    ; EXIT
    mov rax,60 ; exit(int status)
    ; User-level applications use as integer registers for passing the sequence %rdi, %rsi, %rdx, %rcx, %r8 and %r9. 
    ; The kernel interface uses %rdi, %rsi, %rdx, %r10, %r8 and %r9.
    mov rdi,0 ; int status
    syscall

HIT:
    ; we must manually clear CARRY & ZERO flags
    ; CLC ; clear CARRY
    mov rbx, 1 ; hit flag up
    ; VPSHUFB ymm1, ymm2, ymm3/m256
    ; VPSHUFB ymm0, ymm0, [matrix_shuffle]
    ;
    ; VPSRLDQ|VPSLLDQ ymm1, ymm2, imm8
    ; Shift ymm1 right|left by imm8 bytes while shifting in 0s.
    ; VPSRLDQ ymm1, ymm1, 1
    VPSLLDQ ymm1, ymm1, 1
    jmp LOOP

section .data
; A=1
; C=2
; T=3
; G=4
; N=5
; matrix_256: db 5,1,2,3,4,3,2,1,5,5,1,1,2,2,3,4,5,2,5,1,2,5,3,5,2,1,5,3,3,4,5,1
; matrix_256: db 32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
matrix_256: db 'ATCNNTCAAATCANGGCGCATATBGCATCACG'
; matrix_shuffle: db 5,4,3,2,1,0,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
; matrix_shuffle: db 32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
; matrix_shuffle: db 1000001b,0000000b,0000010b,0000011b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,0000000b,

; pattern NCT
; pattern: db 5,1,2
; pattern: db 32,31,30
pattern: db 'TC'

section .bss
hits: resq 100 ; record 10 hits
