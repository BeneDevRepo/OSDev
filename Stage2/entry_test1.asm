; [org 0x0000] ; global memory offset (code is loaded at offset 0)
[bits 16]    ; Tell Assembler to emit 16-Bit Code

; global entry:
jmp start

boot_drive_number: db 0


KERNEL_LOAD_SEGMENT equ 0x2000
KERNEL_LOAD_OFFSET  equ 0x00



start:
	mov [boot_drive_number], dl ; store drive number provided by boot sector

	mov bx, msg_hello
	call print

	; setup stack
    mov ax, ds
    mov ss, ax
    mov sp, 0xFFF0
    mov bp, sp

.halt:
	cli   ; disable interrupts so cpu cannot get out of halted state
	hlt   ; halt execution


wait_key_and_reboot:
	mov ah, 0
	int 0x16 ; wait for keypress
	jmp 0x0FFFF:0 ; jump to start of BIOS, basically rebooting





%include "print.asm"
; %include "disk.asm"


msg_hello: db CRLF, "Executing Stage 2", CRLF, 0
msg_bye: db "Done.", CRLF, 0