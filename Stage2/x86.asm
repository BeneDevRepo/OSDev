
%macro x86_EnterRealMode 0
    [bits 32]
    jmp word 18h:.pmode16         ; 1 - jump to 16-bit protected mode segment

.pmode16:
    [bits 16]
    ; 2 - disable protected mode bit in cr0
    mov eax, cr0
    and al, ~1
    mov cr0, eax

    ; 3 - jump to real mode
    jmp word 00h:.rmode

.rmode:
    ; 4 - setup segments
    mov ax, 0
    mov ds, ax
    mov ss, ax

    ; 5 - enable interrupts
    sti
%endmacro


%macro x86_EnterProtectedMode 0
    cli

    ; 4 - set protection enable flag in CR0
    mov eax, cr0
    or al, 1
    mov cr0, eax

    ; 5 - far jump into protected mode
    jmp dword 08h:.pmode


.pmode:
    ; we are now in protected mode!
    [bits 32]
    
    ; 6 - setup segment registers
    mov ax, 0x10
    mov ds, ax
    mov ss, ax

%endmacro


;    ====== void _cdecl putc (const char c) ======
global _putc
_putc:
	[bits 16]
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
	[bits 16]
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