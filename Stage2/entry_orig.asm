[bits 16]    ; Tell Assembler to emit 16-Bit Code

section .entry ; this code gets written into section .entry

; constants defined in link.ld:
extern __bss_start
extern __end
extern _init

extern start ; start is the name of the c entry point

global entry
entry:
	cli ; disable interrupts

	mov [boot_drive_number], dl ; store drive number provided by boot sector
    mov [boot_partition_seg], di
	mov [boot_partition_off], si

	; setup stack:
    mov ax, ds
    mov ss, ax
    ; mov sp, 0
    ; mov sp, 0xFFF0
    mov sp, 0x8FF0
    mov bp, sp

	mov bx, msg_hello
	call print


	; disable legacy 20-bit address line wrapping (enable A20 gate):
	call enableA20
	call loadGDT

	; switch to protected mode (set protection enable flag in CR0):
    mov eax, cr0
    or al, 1
    mov cr0, eax

	; sti ; re-enable interrupts

    ; far jump into protected mode:
    jmp dword 08h:.pmode

	cli
	hlt

.pmode:
	[bits 32]

	; setup segment registers
	mov ax, 0x10
	mov ds, ax
	mov ss, ax

	; clear bss ("memset 0" uninitialized data)
    mov edi, __bss_start
    mov ecx, __end
    sub ecx, edi
    mov al, 0
    cld
    rep stosb

	call _init

	mov dx, [boot_partition_seg]
    shl edx, 16
    mov dx, [boot_partition_off]
    push edx

	; send boot drive as argument to cstart function
    xor edx, edx
    mov dl, [boot_drive_number]
    push edx
    call start

.done:
	cli
	hlt


enableA20:
    [bits 16]
    ; disable keyboard
    call A20WaitInput
    mov al, KbdControllerDisableKeyboard
    out KbdControllerCommandPort, al

    ; read control output port
    call A20WaitInput
    mov al, KbdControllerReadCtrlOutputPort
    out KbdControllerCommandPort, al

    call A20WaitOutput
    in al, KbdControllerDataPort
    push eax

    ; write control output port
    call A20WaitInput
    mov al, KbdControllerWriteCtrlOutputPort
    out KbdControllerCommandPort, al
    
    call A20WaitInput
    pop eax
    or al, 2                                    ; bit 2 = A20 bit
    out KbdControllerDataPort, al

    ; enable keyboard
    call A20WaitInput
    mov al, KbdControllerEnableKeyboard
    out KbdControllerCommandPort, al

    call A20WaitInput
    ret


A20WaitInput:
    [bits 16]
    ; wait until status bit 2 (input buffer) is 0
    ; by reading from command port, we read status byte
    in al, KbdControllerCommandPort
    test al, 2
    jnz A20WaitInput
    ret

A20WaitOutput:
    [bits 16]
    ; wait until status bit 1 (output buffer) is 1 so it can be read
    in al, KbdControllerCommandPort
    test al, 1
    jz A20WaitOutput
    ret



KbdControllerDataPort               equ 0x60
KbdControllerCommandPort            equ 0x64
KbdControllerDisableKeyboard        equ 0xAD
KbdControllerEnableKeyboard         equ 0xAE
KbdControllerReadCtrlOutputPort     equ 0xD0
KbdControllerWriteCtrlOutputPort    equ 0xD1

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


boot_drive_number: db 0
boot_partition_seg: dw 0
boot_partition_off: dw 0


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





%include "../Stage1/print.asm"
; ; %include "disk.asm"

; %define CR 0x0D
; %define LF 0x0A
; %define CRLF CR, LF

msg_hello: db "Executing Stage 2", 0
; msg_hello: db CRLF, "Executing Stage 2", CRLF, 0
; msg_bye: db "Done.", CRLF, 0