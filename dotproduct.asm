format ELF64 executable 3
entry start

include 'import64.inc'

interpreter '/lib64/ld-linux-x86-64.so.2'
needed 'libc.so.6'
import printf

segment readable executable

; macros
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
macro print_scalar scal
{
    mov rax, [scal]
    push rbx
    push rcx
    print_double_rax
    pop rbx
    pop rcx
}
macro print_vector vec,vecsize
{
    local for
    mov rcx, vecsize
    mov rbx, 0
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
macro vector_elemwise_flop vec1,vec2,vecsize,flop
{
    local for
    mov rcx, vecsize
    mov rbx, 0
    for:
        ; load to fpu
        fld qword [vec2 + rbx*8]
        fld qword [vec1 + rbx*8]
        ; perform operation
        flop st0,st1
        ; store back to vec1
        fstp qword [vec1 + rbx*8]
        fstp st0
        ; loop end
        inc rbx
        dec rcx
        jnz for
}
macro vector_fold vec,vecsize,output,flop
{
    local for
    fld qword [output]
    mov rcx, vecsize
    mov rbx, 0
    for:
        ; load entry to fpu
        fld qword [vec + rbx*8]
        flop st1,st0
        fstp st0
        ; loop end
        inc rbx
        dec rcx
        jnz for
    fstp qword [output]
}
macro vector_dotproduct vec1,vec2,vecsize,output
{
    vector_elemwise_flop vec1,vec2,vecsize,fmul
    vector_fold vec1,vecsize,output,fadd
}

start:
    init_print
    vector_dotproduct a,a,asize,b
    print_scalar b

    ; exit
    mov rax, 60
    mov rdi, 0
    syscall

segment readable writeable 

pf db '%f', 0xa, 0 

a dq -1.0
  dq 2.0
  dq 2.0
  dq 1.0
asize = ($-a)/8

b dq 0.0

