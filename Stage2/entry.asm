; [bits 16]    ; Tell Assembler to emit 16-Bit Code
bits 16    ; Tell Assembler to emit 16-Bit Code

section _ENTRY class=CODE

extern _cstart_
global entry

entry:
	; setup stack:
	cli ; disable interrupts
    mov ax, ds
    mov ss, ax
    mov sp, 0
    mov bp, sp
	sti ; re-enable interrupts

	xor dh, dh ; boot drive is passed in dl, so dh should be 0 before pushing to stack
	push dx    ; push boot drive to stack as parameter for _cstart_
	call _cstart_ ; call c entry point

	; mov [boot_drive_number], dl ; store drive number provided by boot sector

	; mov bx, msg_hello
	; call print

	cli
	hlt

; ; global entry:
; jmp start

; boot_drive_number: db 0


; KERNEL_LOAD_SEGMENT equ 0x2000
; KERNEL_LOAD_OFFSET  equ 0x00



; start:
; 	mov [boot_drive_number], dl ; store drive number provided by boot sector

; 	mov bx, msg_hello
; 	call print

; 	; setup stack
;     mov ax, ds
;     mov ss, ax
;     mov sp, 0xFFF0
;     mov bp, sp

; .halt:
; 	cli   ; disable interrupts so cpu cannot get out of halted state
; 	hlt   ; halt execution


; wait_key_and_reboot:
; 	mov ah, 0
; 	int 0x16 ; wait for keypress
; 	jmp 0x0FFFF:0 ; jump to start of BIOS, basically rebooting





; %include "print.asm"
; ; %include "disk.asm"


; msg_hello: db CRLF, "Executing Stage 2", CRLF, 0
; msg_bye: db "Done.", CRLF, 0