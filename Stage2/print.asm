[bits 16]    ; Tell Assembler to emit 16-Bit Code

;    ====== void print (const char* bx) ======
print:
	pusha        ; save registers

.p_start:
	mov al, [bx] ;    char al = *bx;
	cmp al, 0    ;    if (al == 0)
	je .p_done    ;        goto p_donw;

	mov ah, 0x0E ;    [enable tty mode]
	int 0x10     ;    printChar(al);
	inc bx       ;    bx++;
	jmp .p_start  ;    goto p_start;

.p_done:
	popa         ; restore registers
	ret