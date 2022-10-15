[bits 16]    ; Tell Assembler to emit 16-Bit Code

;    ====== void _cdecl puts (const char* str) ======
global _puts
_puts:
	; pop cx       ; store return address in cx
	; pop bx       ; bx = str
	push bp
	mov bp, sp

	mov bx, [bp + 4]

.p_start:
	mov al, [bx] ;    char al = *bx;
	cmp al, 0    ;    if (al == 0)
	je .p_done    ;        goto p_donw;

	mov ah, 0x0E ;    [enable tty mode]
	int 0x10     ;    printChar(al);
	inc bx       ;    bx++;
	jmp .p_start  ;    goto p_start;

.p_done:
	; push bx
	; push cx
	pop bp
	ret