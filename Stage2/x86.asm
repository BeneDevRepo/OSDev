[bits 16]    ; Tell Assembler to emit 16-Bit Code

;    ====== void _cdecl putc (const char c) ======
global _putc
_putc:
	push bp       ; save old stack frame
	mov bp, sp    ; create new call frame

	pusha
	; push bx       ; save bx

	mov ah, 0x0E  ;    [enable tty mode]
	mov al, [bp + 4]  ;    char al = c
	mov bh, 0
	int 0x10

	; pop bx        ; restore bx
	popa

	mov sp, bp    ; restore old stack pointer
	pop bp        ; restore old stack base
	ret



;    ====== void _cdecl puts (const char* str) ======
global _puts
_puts:
	push bp       ; save old stack frame
	mov bp, sp    ; create new call frame

	push bx       ; save bx

	mov bx, [bp + 4] ; bx = str (str lies under bp and ret_addr on the old stack)

	mov ah, 0x0E  ;    [enable tty mode]

.loop:
	mov al, [bx]  ;    char al = *bx;
	cmp al, 0     ;    if (al == 0)
	je .end       ;        goto end;

	push bx
	mov bh, 0
	int 0x10      ;    printChar(al);
	pop bx

	inc bx        ;    bx++;
	jmp .loop     ;    goto loop;

.end:
	pop bx        ; restore bx

	mov sp, bp    ; restore old stack pointer
	pop bp        ; restore old stack base
	ret