[org 0x7c00] ; global memory offset (because the boot sector is loaded into memory at location 0x7C00)
[bits 16]    ; Tell Assembler to emit 16-Bit Code

; https://de.wikipedia.org/wiki/File_Allocation_Table#FAT12

; ===== Bios Parameter Block:

jmp short start
nop

bdb_oem: db "MSWIN4.1" ; 8 Bytes, Content irrelevant
bdb_bytes_per_sector: dw 512
bdb_sectors_per_cluster: db 1
bdb_reserved_sectors: dw 1
bdb_fat_count: db 2
bdb_dir_entries_count: dw 0x00E0 ; 224 entries
bdb_total_sectors: dw 2880 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type: db 0x00F0
bdb_num_sectors_per_fat: dw 9
bdb_sectors_per_track: dw 18
bdb_heads: dw 2
bdb_hidden_sectors: dd 0
bdb_large_sectors: dd 0

; ===== Extended Boot Record:

ebr_drive_number: db 0
db 0 ; reserved:
ebr_signature: db 29h ; extended boot signature
ebr_volume_id: db 12h, 34h, 56h, 78h ; arbitrary 4 byte id
ebr_volume_label: db "Volume     " ; arbitrary String padded to 11 bytes
ebr_system_id: db "FAT12   " ; FAT-variant, padded to 8 bytes


start: jmp main


%include "print.asm"
%include "disk.asm"


msg_hello:			db "Hello, World", CRLF, 0



main:
	mov ah, 0x0e ; tty mode

	; ; read something from floppy:
	; mov [ebr_drive_number], dl ; Bios should set dl to drive number
	; mov ax, 1 ; LBA = 1, second sector from disk
	; mov cl, 1 ; read 1 sector
	; mov bx, 0x7E00 ; data should be after the bootloader
	; call disk_read
	

	; jmp $


	; ; Setup Data Segments:
	; mov ax, 0 ; can't write ds / es directly
	; mov ds, ax
	; mov es, ax

	mov bp, 0x0400 ; this is an address far away from the loaded boot sector at 0x7c00 so that we don't get overwritten
	mov sp, bp ; if the stack is empty then sp points to bp

	; Stack grows downward (sp gets decremented)

	push 'A'
	push 'B'
	push 'C'

	; to show how the stack grows downwards
	mov al, [bp - 2] ;  => 'A'
	int 0x10
	mov al, [bp - 4] ;  => 'B'
	int 0x10
	mov al, [bp - 6] ;  => 'C'
	int 0x10


	mov al, ' '
	int 0x10


	; recover our characters using the standard procedure: 'pop'
	; We can only pop full words so we need an auxiliary register to manipulate
	; the lower byte
	pop bx
	mov al, bl
	int 0x10 ; prints C

	pop bx
	mov al, bl
	int 0x10 ; prints B

	pop bx
	mov al, bl
	int 0x10 ; prints A

.halt:
	cli   ; disable interrupts so cpu cannot exit halted state
	hlt   ; halt execution

wait_key_and_reboot:
	mov ah, 0
	int 0x16 ; wait for keypress
	jmp 0x0FFFF:0 ; jump to start of BIOS, basically rebooting









SectorEnd:
	; Make Sector bootable:

	times 510 - ($-$$) db 0 ; Padding ($ is the current position before emitting this line, $$ is the startposition of the current sector)

	dw 0xaa55 ; Magic Number
