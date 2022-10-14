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


; ===== Not part of File system
root_directory_end: dw 0 ; gets set when reading root directory
kernel_cluster: db 0     ; gets set when reading root directory

KERNEL_LOAD_SEGMENT equ 0x2000
KERNEL_LOAD_OFFSET  equ 0x00


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


	; ===== read drive parameters (more secure than relying on data from the disk):
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
	; ===== done reading drive parameters



	; ===== read FAT root directory:
	; --- Compute Root directory start LBA:
	; ax = lba = fatCount * sectorsPerFat + reservedSectors
	mov ax, [bdb_fat_count] ; lba = fatCount
	mov bl, [bdb_sectors_per_fat] ; bl = sectorsPerFat
	mul bl     ; lba = fat_count * sectorsPerFat
	add ax, [bdb_reserved_sectors] ; lba = fatCount * sectorsPerFat + reservedSectors
	push ax           ;  save lba

	; --- Compute size of root directory:
	; ax = sizeBytes = dirEntriesCount * sizeof(DirEntry)
	mov ax, [bdb_dir_entries_count] ; ax = dirEntries
	shl ax, 5 ;   ax = dirEntries * sizeof(DirEntry)

	; --- Compute size of root directory in sectors:
	; ax = sizeBlocks = roundUp(directorySize / bytesPerSector)
	xor dx, dx ; clear dx
	div word [bdb_bytes_per_sector] ; ax /= bytePerSector

	; increment sector count if division had remainder:
	test dx, dx
	jz .dont_increment_num_sectors
	inc ax  ; ax += 1 if (ax % bytesPerSector != 0)
	.dont_increment_num_sectors:


	; --- read root directory:
	mov cl, al ; number of sectors to read = size of root directory
	pop ax     ; pop lba
	mov dl, [ebr_drive_number] ; drive number
	mov bx, buffer ; es:bx = buffer

	; push ax
	; push cx
	call disk_read
	; pop cx
	; pop ax

	; save end of root directory for later:
	mov ch, 0
	add ax, cx ; root_directory_end = lba + numRootDirSectors
	mov [root_directory_end], ax
	; ===== done reading Root directory




; 	; ==== Print root directory:
; 	mov bx, buffer
; 	mov ah, 0x0E ;    [enable tty mode]
; 	mov cl, 0 ; y = 0

; .printLine:
; 	mov ch, 0 ; x = 0

; .printChar:
; 	mov al, [bx] ; al = *bx
; 	; mov al, '#'
; 	int 0x10     ;    printChar(al);
; 	inc bx

; 	inc ch ; x++
; 	cmp ch, 32 ; x < 32
; 	jl .printChar

; 	mov al, 13 ; \r
; 	int 0x10
; 	mov al, 10 ; \n
; 	int 0x10

; 	inc cl ; y++
; 	cmp cl, 16 ; y < 16
; 	jl .printLine

; 	call wait_key_and_reboot
; 	; ==== done printing root directory



	; Search for Kernel.bin:
	; bx = i  (0 -> dir_entries_count)
	; di = rootDir + i
	; al = j  (0 -> 11)

	xor bx, bx ; i = 0
	mov di, buffer ; pointer to dirEntry (and filename)

.root_loop_start:  ; while (i < numDirEntries):
	cmp bx, [bdb_dir_entries_count] ; if (i == numDirEntries)
	je .kernel_file_not_found       ;   break;

	; Compare filenames:
	push di ; cmpsb will increment di and si
	mov si, kernel_file_name ; si = kernelFileName
	mov cx, 11 ; compare 11 bytes
	repe cmpsb ; "repeat while equal" "compare single byte"
	pop di

	je .kernel_file_found

	inc bx                        ; i++
	add di, 32                    ; move pointer to next directory
	jmp .root_loop_start


.kernel_file_not_found:
	mov bx, msg_kernel_not_found_error
	call print
	call wait_key_and_reboot


.kernel_file_found:
	; di still points to the directory entry

	mov ax, [di + 26] ; read first cluster index
	mov [kernel_cluster], ax

	; read FAT:
	mov ax, [bdb_reserved_sectors]
	mov bx, buffer
	mov cl, [bdb_sectors_per_fat]
	mov dl, [ebr_drive_number]
	call disk_read
	
	; read kernel file FAT chain:
	mov bx, KERNEL_LOAD_SEGMENT
	mov es, bx
	mov bx, KERNEL_LOAD_OFFSET

.load_kernel_loop: ; do {
	mov ax, [kernel_cluster] ; ax = cluster number
	sub ax, 2 ; ax = cluster_number - 2  (first two clusters are reserved)

	mov cx, [bdb_sectors_per_cluster]
	mul cx; ax = lba = (cluster_number - 2) * sectors_per_cluster

	add ax, [root_directory_end] ; ax = first sector of FAT

	mov cl, 1 ; read 1 sector
	mov dl, [ebr_drive_number] ; drive number
	call disk_read

	; ; DEBUG:
	; jmp .read_finish

	add bx, [bdb_bytes_per_sector] ; #############   MIGHT OVERFLOW, should increment sector register at times, too

	; compute location of next cluster
	mov ax, [kernel_cluster]
	mov cx, 3
	mul cx
	mov cx, 2
	div cx ; ax = FAT_index = kernel_cluster * 3 / 2

	mov si, buffer
	add si, ax
	mov ax, [ds:si] ; get FAT table entry (2 full bytes)

	; } while (currentCluster < 0xFF8);
	or dx, dx
	jz .even

.odd:
	shr ax, 4
	jmp .after_fat_entry_decoding

.even:
	and ax, 0x0FFF

.after_fat_entry_decoding:
	cmp ax, 0x0FF8
	jae .read_finish ; entry >= 0xFF8

	mov [kernel_cluster], ax ; not done yet. FAT entry is the next cluster to be read
	jmp .load_kernel_loop

.read_finish:

	; ==== Print stage2:
	mov bx, KERNEL_LOAD_OFFSET
	; add bx, 512*2

	mov ah, 0x0E ;    [enable tty mode]
	mov cl, 0 ; y = 0

.printLine:
	mov ch, 0 ; x = 0

.printChar:
	mov al, [bx] ; al = *bx
	; mov al, '#'
	int 0x10     ;    printChar(al);
	inc bx

	inc ch ; x++
	cmp ch, 32 ; x < 32
	jl .printChar

	mov al, 13 ; \r
	int 0x10
	mov al, 10 ; \n
	int 0x10

	inc cl ; y++
	cmp cl, 16 ; y < 16
	jl .printLine

	call wait_key_and_reboot
	; ==== done printing stage2








	
	; mov dl, [ebr_drive_number] ; pass boot device in dl

	; mov ax, KERNEL_LOAD_SEGMENT ; set segment registers
	; mov ds, ax
	; mov es, ax

	; jmp KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET
	
	; mov bx, msg_bye
	; call print  ; print "Done."





	; jmp $

	; mov bp, 0x0400 ; this is an address far away from the loaded boot sector at 0x7c00 so that we don't get overwritten
	; mov sp, bp ; if the stack is empty then sp points to bp

.halt:
	cli   ; disable interrupts so cpu cannot get out of halted state
	hlt   ; halt execution

.driveParameterReadError:
	mov bx, msg_drive_parameter_read_error
	call print
	jmp wait_key_and_reboot

wait_key_and_reboot:
	mov ah, 0
	int 0x16 ; wait for keypress
	jmp 0x0FFFF:0 ; jump to start of BIOS, basically rebooting






%include "print.asm"
%include "disk.asm"


kernel_file_name: db "KERNEL  BIN"

msg_hello: db CRLF, "Booting", CRLF, 0
msg_bye: db "Done.", CRLF, 0
msg_drive_parameter_read_error: db "EP", CRLF, 0 ; Error retrieving drive Parameters
msg_kernel_not_found_error:     db "EK", CRLF, 0 ; could not find kernel file





SectorEnd:
	; Make Sector bootable:

	times 510 - ($-$$) db 0 ; Padding ($ is the current position before emitting this line, $$ is the startposition of the current sector)

	dw 0xaa55 ; Magic Number


buffer: