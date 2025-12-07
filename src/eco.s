.intel_syntax noprefix
.global eco_switch

/*
  Windows x64 Calling Convention:
  Arg 1 (old): rcx
  Arg 2 (new): rdx
  Callee-saved: rbx, rbp, rdi, rsi, r12, r13, r14, r15
*/

eco_switch:
    mov [rcx + 0], rsp
    mov [rcx + 8], r15
    mov [rcx + 16], r14
    mov [rcx + 24], r13
    mov [rcx + 32], r12
    mov [rcx + 40], rbx
    mov [rcx + 48], rbp
    mov [rcx + 56], rdi
    mov [rcx + 64], rsi

    mov rsp, [rdx + 0]
    mov r15, [rdx + 8]
    mov r14, [rdx + 16]
    mov r13, [rdx + 24]
    mov r12, [rdx + 32]
    mov rbx, [rdx + 40]
    mov rbp, [rdx + 48]
    mov rdi, [rdx + 56]
    mov rsi, [rdx + 64]

    ret
