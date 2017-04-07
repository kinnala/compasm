format ELF64 executable 3
entry start

include 'import64.inc'

interpreter '/lib64/ld-linux-x86-64.so.2'
needed 'libc.so.6'
import printf

segment readable executable

; macros
macro print_double_rax
{
    push rbp
    mov rbp, rsp
    sub rsp, 8
    movq xmm0, rax 
    mov rdi, pf
    mov rax, 1
    call [printf] 
}

start:
    ; newton's method

    ; load coefficients
    fld qword [a] ; st5
    fld qword [b] ; st4
    fld qword [c] ; st3

    ; load initial guess
    fld qword [x] ; st2
    fld qword [x] ; st1
    fld qword [x] ; st0

    rept 5 {
        ; evaluate derivative at x
        fmul st0, st5 ; a*x
        fadd st0, st0 ; 2*a*x
        fadd st0, st4 ; 2*a*x+b
        fxch st1

        ; evaluate polynomial at x
        fmul st0, st5 ; a*x
        fadd st0, st4 ; a*x+b
        fmul st0, st2 ; (a*x+b)*x
        fadd st0, st3 ; (a*x+b)*x+c

        ; division and minus
        fdiv st0, st1
        fxch st2
        fsub st0, st2

        fst st1
        fst st2
    }

    ; store and print result from st0
    fst qword [a]
    mov rax, [a]

    print_double_rax

    ; exit
    mov rax, 60
    mov rdi, 0
    syscall

segment readable writeable 

pf db '%f', 0xa, 0 
a dq -5.0
b dq 2.0
c dq 1.0
x dq 1.0

