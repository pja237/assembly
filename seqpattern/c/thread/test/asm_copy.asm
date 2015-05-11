BITS 64

section .text
    global _asm_copy
_asm_copy:

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
    ;asm_ret=_asm_search(input, output, input_len)

    mov r8, rdi ; input
    mov rdi, rsi ; output
    mov rcx, rdx ; INPUT_LEN
    mov r9, 0   ; offset

    xor rax,rax
COPY_LOOP:

    mov al, [r8+r9]
    ; For 64-bit mode store AL at address RDI or EDI.
    STOSB
    inc r9

    loop COPY_LOOP

    mov rsp, rbp
    pop rsi
    pop rdi
    pop rbx
    pop rbp

    mov rax, 0
    ret

section .data

section .bss
