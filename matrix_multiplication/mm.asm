BITS 64

%define ROWS  5
%define COLS  5

section .text
    global _start
_start:

    ; SETUP matrices
    mov rbx, mat_a
    call f_rand_mat

    mov rbx, mat_b
    call f_rand_mat

    mov rbx, mat_r
    call f_zero_mat
    ; ---------- 
    nop


    ; FILL matrix, base addr in RBX with random numbers
f_rand_mat:
    mov rcx, ROWS*COLS ; counter

l_rand:
    ; rdrand rax
    mov qword [rbx], rcx ; CHANGE later to use RDRAND rax
    add rbx, 8     ; next address += quad word (8 byte)
    loop l_rand

    ret
    ; ---------- 

    ; ZERO matrix, base addr in RBX 
f_zero_mat:
    mov rcx, ROWS*COLS ; counter
    mov rax, 0

l_zero:
    mov qword [rbx], rax
    add rbx, 8     ; next address += quad word (8 byte)
    loop l_zero

    ret
    ; ---------- 
    

section .data

section .bss
mat_a: resq ROWS*COLS ; 5 x 5 x quad-word (4*2 byte == 8 byte == 64 bit) == 25 * 64 bit
mat_b: resq ROWS*COLS ; 5 x 5 x quad-word (4*2 byte == 8 byte == 64 bit) == 25 * 64 bit
mat_r: resq ROWS*COLS ; 5 x 5 x quad-word (4*2 byte == 8 byte == 64 bit) == 25 * 64 bit
