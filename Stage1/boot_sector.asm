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
bdb_sectors_per_fat: dw 9
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


start:
	; Setup Data Segments:
	mov ax, 0 ; can't write ds / es directly
	mov ds, ax ; ds = 0
	mov es, ax ; es = 0

	; Setup Stack:
	mov ss, ax
	mov sp, 0x7C00

	; Correct for any Bios that might load the boot sector into 07C0:0000 instead of 0000:7C00
	push es
	push word .after
	retf    ;  "far return" to .after

.after:
	mov bx, msg_hello
	call print

	; store drive number provided by bios
	mov [ebr_drive_number], dl


	; read drive parameters (more secure than relying on data from the disk):
	push es
	mov ah, 0x08
	int 0x13
	jc .driveParameterReadError
	pop es

	and cl, 0x3F ; clear 2 most significant bits
	xor ch, ch   ; clear higher byte
	mov [bdb_sectors_per_track], cx ; overwrite value provided by FAT

	inc dh
	mov [bdb_heads], dh ; overwrite value provided by FAT
	; done reading drive parameters


	; read FAT root directory:
	; ax = lba = fatCount * sectorsPerFat + reservedSectors
	; bx = sectorsPerFat
	mov ax, [bdb_fat_count]
	mov bl, [bdb_sectors_per_fat]
	mov bl, 0
	xor bh, bh
	mul bx     ; ax *= bx
	add ax, [bdb_reserved_sectors]
	push ax           ;  ax = lba

	; compute size of root directory:
	; ax = size = roundUp(dirEntriesCount * sizeof(DirectoryEntry) / bytesPerSector)
	mov ax, [bdb_dir_entries_count]
	shl ax, 5 ;   ax *= 32
	xor dx, dx ; clear dx
	div word [bdb_bytes_per_sector] ; ax /= bytePerSector

	test dx, dx
	jz .root_dir_after
	inc ax  ; ax += 1 if (ax % bytesPerSector != 0)

.root_dir_after:
	; read root directory:
	mov cl, al ; number of sectors to read = size of root directory
	pop ax     ; pop lba
	mov dl, [ebr_drive_number] ; drive number
	mov bx, buffer ; es:bx = buffer
	call disk_read




	; Search for Kernel.bin:

	xor bx, bx ; i = bx = 0

.root_loop_start: ; while (i < numDirEntries):
	inc bx ; i++

	mov di, buffer
	add di, bx


	cmp bx, bdb_dir_entries_count ; if i == numDirEntries
	je .root_loop_done ; break;
	jmp .root_loop_start

.root_loop_done:



	mov bx, msg_bye
	call print  ; print "Done."


	; jmp $

	; mov bp, 0x0400 ; this is an address far away from the loaded boot sector at 0x7c00 so that we don't get overwritten
	; mov sp, bp ; if the stack is empty then sp points to bp

.halt:
	cli   ; disable interrupts so cpu cannot get out of halted state
	hlt   ; halt execution

.driveParameterReadError:
	mov bx, msg_driveParameterReadError
	call print
	jmp wait_key_and_reboot

wait_key_and_reboot:
	mov ah, 0
	int 0x16 ; wait for keypress
	jmp 0x0FFFF:0 ; jump to start of BIOS, basically rebooting



%include "print.asm"
%include "disk.asm"


msg_hello: db CRLF, "Hello, World!", CRLF, "Booting into BeneOS...", CRLF, 0
msg_bye: db "Done.", CRLF, 0
msg_driveParameterReadError: db "Error retrieving drive Parameters", CRLF, 0





SectorEnd:
	; Make Sector bootable:

	times 510 - ($-$$) db 0 ; Padding ($ is the current position before emitting this line, $$ is the startposition of the current sector)

	dw 0xaa55 ; Magic Number


buffer: