format ELF64 executable 3
entry start

include 'import64.inc'

interpreter '/lib64/ld-linux-x86-64.so.2'
needed 'libc.so.6'
import printf

segment readable executable

; low level printing
macro init_print
{
    push rbp
    mov rbp, rsp
    sub rsp, 8
}
macro print_double_rax
{
    movq xmm0, rax 
    mov rdi, pf
    mov rax, 1
    call [printf] 
}
macro s_print scalar
{
    mov rax, [scalar]
    push rbx
    push rcx
    print_double_rax
    pop rbx
    pop rcx
}

; high level vector and operations
struc vector [data]
{
    common
        . dq data
        .size = ($ - .)/8
}
macro v_print vec
{
    local for
    mov rcx, vec#.size
    xor rbx, rbx
    for:
        mov rax, [vec + rbx*8]
        push rbx
        push rcx
        print_double_rax
        pop rcx
        pop rbx
        inc rbx
        dec rcx
        jnz for
}
macro vector_elementwise vec1, vec2, flop
{
    local for
    mov rcx, vec1#.size
    xor rbx, rbx
    for:
        ; load to fpu
        fld qword [vec2 + rbx*8]
        fld qword [vec1 + rbx*8]
        ; perform operation
        flop st0, st1
        ; store back to vec1
        fstp qword [vec1 + rbx*8]
        fstp st0
        ; loop end
        inc rbx
        dec rcx
        jnz for
}
macro vector_elementwise_single vec, flop
{
    local for
    mov rcx, vec#.size
    xor rbx, rbx
    for:
        ; load to fpu
        fld qword [vec + rbx*8]
        ; perform operation
        flop
        ; store back to vec
        fstp qword [vec + rbx*8]
        ; loop end
        inc rbx
        dec rcx
        jnz for
}
macro vector_fold scalar, vec, flop
{
    local for
    fld qword [scalar]
    mov rcx, vec#.size
    xor rbx, rbx
    for:
        ; load entry to fpu
        fld qword [vec + rbx*8]
        flop st1, st0
        fstp st0
        ; loop end
        inc rbx
        dec rcx
        jnz for
    fstp qword [scalar]
}
; end user ops
macro v_dotp scalar, vec1, vec2
{
    vector_elementwise vec1, vec2, fmul
    vector_fold scalar, vec1, fadd
}
macro v_plus vec1, vec2
{
    vector_elementwise vec1, vec2, fadd
}

start:
    init_print
    vector_elementwise a, a, fadd
    vector_elementwise_single a, fsqrt
    ;vector_fold b, a, fadd
    v_print a
    ;s_print b

    ; exit
    mov rax, 60
    mov rdi, 0
    syscall

segment readable writeable 

pf db '%f', 0xa, 0 

a vector 1.0,1.0,1.0
b dq 0.0
