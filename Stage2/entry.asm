; [org 0x7c00] ; global memory offset (because the boot sector is loaded into memory at location 0x7C00)
[org 0x2000] ; global memory offset (because Stage 2 is loaded into memory at location 0x2000)
[bits 16]    ; Tell Assembler to emit 16-Bit Code

; jmp start

db "Entry Start"
times 510 - ($-$$) db '9' ; Padding


KERNEL_LOAD_SEGMENT equ 0x2000
KERNEL_LOAD_OFFSET  equ 0x00

boot_drive_number: db 0


start:
	mov [boot_drive_number], dl ; store drive number provided by boot sector


	mov bx, msg_hello
	call print

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





; SectorEnd:
; 	; Make Sector bootable:

; 	times 510 - ($-$$) db 0 ; Padding ($ is the current position before emitting this line, $$ is the startposition of the current sector)

; 	dw 0xaa55 ; Magic Number


; buffer: