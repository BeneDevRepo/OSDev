[bits 16]    ; Tell Assembler to emit 16-Bit Code

section _ENTRY class=CODE

; extern _cstart_

global entry
entry:
	cli ; disable interrupts

	; setup stack:
    mov ax, ds
    mov ss, ax
    mov sp, 0
    ; mov sp, 0xFFF0
    mov bp, sp

	; disable legacy 20-bit address line wrapping (enable A20 gate):
	call enableA20
	call loadGDT

	; set protection enable flag in CR0:
    mov eax, cr0
    or al, 1
    mov cr0, eax

	; sti ; re-enable interrupts

    ; far jump into protected mode:
    jmp dword 08h:.pmode

.pmode:
	[bits 32]

	; setup segment registers
	mov ax, 0x10
	mov ds, ax
	mov ss, ax


	; xor dh, dh ; boot drive is passed in dl, so dh should be 0 before pushing to stack
	; push dx    ; push boot drive to stack as parameter for _cstart_
	; call _cstart_ ; call c entry point

	; mov bx, msg_hello
	; call print

	mov esi, msg_hello
	mov edi, screenBuffer
	cld

.loop:
	lodsb
	or al, al
	jz .done

	mov [edi], al
	inc edi

	mov [edi], byte 0x2
	inc edi

	jmp .loop
	
.done:
	jmp $
	cli
	hlt





enableA20:
	[bits 16]
    ; disable keyboard
    call .waitInput
    mov al, kbdControllerDisableKeyboard
    out kbdControllerCommandPort, al

    ; read control output port
    call .waitInput
    mov al, kbdControllerReadCtrlOutputPort
    out kbdControllerCommandPort, al

    call .waitOutput
    in al, kbdControllerDataPort
    push eax

    ; write control output port
    call .waitInput
    mov al, kbdControllerWriteCtrlOutputPort
    out kbdControllerCommandPort, al
    
    call .waitInput
    pop eax
    or al, 2                                    ; bit 2 = A20 bit
    out kbdControllerDataPort, al

    ; enable keyboard
    call .waitInput
    mov al, kbdControllerEnableKeyboard
    out kbdControllerCommandPort, al

    call .waitInput
    ret

.waitInput: ; wait for bit 2 to become 0
	[bits 16]
	in al, kbdControllerCommandPort
	test al, 2 ; bitwise and
	jnz .waitInput
	ret

.waitOutput: ; wait for bit 1 to become 1
	[bits 16]
	in al, kbdControllerCommandPort
	test al, 1 ; bitwise and
	jz .waitOutput
	ret


kbdControllerDataPort               equ 0x60
kbdControllerCommandPort            equ 0x64
kbdControllerDisableKeyboard        equ 0xAD
kbdControllerEnableKeyboard         equ 0xAE
kbdControllerReadCtrlOutputPort     equ 0xD0
kbdControllerWriteCtrlOutputPort    equ 0xD1

screenBuffer: equ 0xB8000


loadGDT:
    [bits 16]
    lgdt [g_GDTDesc]
    ret



g_GDT:      ; NULL descriptor
            dq 0

            ; 32-bit code segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
            db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 32-bit data segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
            db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 16-bit code segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
            db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 16-bit data segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
            db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

g_GDTDesc:  dw g_GDTDesc - g_GDT - 1    ; limit = size of GDT
            dd g_GDT                    ; address of GDT




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

; %define CR 0x0D
; %define LF 0x0A
; %define CRLF CR, LF

msg_hello: db "Executing Stage 2", 0
; msg_hello: db CRLF, "Executing Stage 2", CRLF, 0
; msg_bye: db "Done.", CRLF, 0