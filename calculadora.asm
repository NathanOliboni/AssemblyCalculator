; nasm -f elf64 calculadora.asm ; gcc -m64 -no-pie calculadora.o -o calculadora.x

extern printf
extern scanf
extern fopen
extern fprintf
extern fclose
%define _exit 60

section .data
	eq : db "Equação : ", 0
	ctrl : db "%f %c %f", 0
	modoAberturaArquivo : db "a", 0
	nomeArquivo : db "saida.txt", 0
	ctrlArquivo : db "%.2lf %c %.2lf = %.2lf", 10, 0
	ctrlArquivoNaoDisponivel : db "%.2lf %c %.2lf = funcionalidade não disponível", 10, 0
    ctrlEntradaInvalida : db "Operando de entrada inválido = %c", 10 , 0
	elevadoAZero : dd 1.0, 0

	
section .bss
	op1 : resd 1
	operacao: resd 1	
	op2 : resd 1
	resultado : resd 1
	arq : resd 1

section .text 
	global main
	
main:
	push rbp
	mov rbp, rsp ; StackFrame
	
	; Abrindo o arquivo
	xor rax, rax
	mov rdi, nomeArquivo
	mov rsi, modoAberturaArquivo
	call fopen ; resultado do fopen está em rax
	mov [arq], rax

	; "Equação: "
	xor rax, rax
	mov rdi, eq
	mov esi, 1
	call printf

	; %f %c %f
	xor rax, rax
	mov rdi, ctrl
	lea rsi, [op1] 		; %f
	lea rdx, [operacao] 	; %c
	lea rcx, [op2] 		; %f
	call scanf
	
	; Move a operação para r9b e compara
	mov r9b, [operacao]


	movss xmm0, [op1]
	movss xmm1, [op2]

	cmp r9b, "a" 
	je callSoma
	
	cmp r9b, "s"
	je callSub
	 	
	cmp r9b, "m"
	je callMult
	
	cmp r9b, "d"
	je callDiv
	
	cmp r9b, "e"
	movss xmm3, [op1] ; Para a exponenciação
	je callExp

    call entradaInvalida 
	
_fim:
	mov rdi, qword[arq]
	call fclose
	
	mov rsp, rbp
	pop rbp
	
	mov rax, _exit
	mov rdi, 0
	syscall
	
callSoma:
	call soma
	jmp _fim
callSub:
	call sub
	; Trocar valores de xmm1 e xmm0 para escrever, pois é op2 - op1
	; op1 -> receber valor de op2
	; op2 -> receber valor de op1
	movss xmm4, [op1]
	movss xmm5, [op2] 
	movss [op1], xmm5
	movss [op2], xmm4
	call disponivel
	jmp _fim
	
callMult:
	call mult
	jmp _fim
	
callDiv:
	call div
	jmp _fim
callExp:
	call exp
	jmp _fim

soma:
	push rbp
	mov rbp, rsp
	
	mov r9b, "+"
	mov [operacao], r9b
		
	; xmm2 = xmm0+xmm1
	vaddss xmm2, xmm0, xmm1
	
	call disponivel
	
	mov rsp, rbp
	pop rbp
	ret

sub:
	push rbp
	mov rbp, rsp

	mov r9b, "-"
	mov [operacao], r9b
	
	; xmm2 = xmm1-xmm0
	vsubss xmm2, xmm1, xmm0

	mov rsp, rbp
	pop rbp
	ret

mult:
	push rbp
	mov rbp, rsp
	
	mov r9b, "*"
	mov [operacao], r9b
	
	;xmm2 = xmm0*xmm1
	vmulss xmm2, xmm0, xmm1
		
	mov rsp, rbp
	pop rbp
	ret
	
div:
	push rbp
	mov rbp, rsp
	
	mov r9b, "/"
	mov [operacao], r9b
	
	cvtss2si r10, xmm1
	mov r11, 0
	cmp r10, r11
	je divPorZero
	
	;xmm2 = xmm0*xmm1
	vdivss xmm2, xmm0, xmm1
	call disponivel
	
	mov rsp, rbp
	pop rbp
	ret
	
	divPorZero:
    		call naoDisponivel
    
    		mov rsp, rbp
    		pop rbp
    		ret
exp:
	push rbp
    	mov rbp, rsp
    	
    	; xmm3 = op1
	; r8 = xmm1 inteiro
    	cvtss2si r8, xmm1

	; Compara para ver se op2 não é negativo
    	mov r11, 0
    	cmp r8, r11
	jl indisponivel

	mov r10, 1
	cmp r10, r8
	je igual ; Se for igual a 1
   	jg zero ; se for igual a zero

    for:
        mulss xmm0, xmm3
        inc r10
        cmp r10, r8
        jl for

	movss xmm2, xmm0
	call disponivel
	
        mov rsp, rbp
        pop rbp
        ret
        
    zero:
    	movss xmm2, [elevadoAZero] ; Caso seja elevado a zero -> sempre será 1
    	call disponivel
    	
    	mov rsp, rbp
    	pop rbp
    	ret
    	
    igual:
    	movss xmm2, xmm0 ; Caso seja igual a 1, será o mesmo número, sem ser multiplicado
    	call disponivel
    	
    	mov rsp, rbp
    	pop rbp
    	ret
    	
    indisponivel:
    	call naoDisponivel
    
    	mov rsp, rbp
    	pop rbp
    	ret
    	
disponivel:	
	push rbp
	mov rbp, rsp
	
	movss [resultado], xmm2
	mov rax, 2
	mov rdi, qword[arq]
	mov rsi, ctrlArquivo
	cvtss2sd xmm0, [op1]
	mov rdx, [operacao]
	cvtss2sd xmm1, [op2]
	cvtss2sd xmm2, [resultado]
	call fprintf
	
	mov rsp, rbp
	pop rbp
	ret
		
naoDisponivel:
	push rbp
	mov rbp, rsp
	
	movss [resultado], xmm2
	mov rax, 2
	mov rdi, qword[arq]
	mov rsi, ctrlArquivoNaoDisponivel
	cvtss2sd xmm0, [op1]
	mov rdx, [operacao]
	cvtss2sd xmm1, [op2]
	call fprintf
	
	mov rsp, rbp
	pop rbp
	ret

entradaInvalida:
	push rbp
	mov rbp, rsp
	
        mov rdi, qword[arq]
        mov rax, 2
        mov rsi, ctrlEntradaInvalida
        mov rdx, [operacao]
        call fprintf
        
        mov rsp, rbp
        pop rbp
        ret
