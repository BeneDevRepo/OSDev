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
bdb_dir_entries_count: dw 0E0h
bdb_total_sectors: dw 2880 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type: db 0F0h
bdb_num_sectors_per_fat: dw 9
bdb_sectors_per_track: dw 18
bdb_heads: dw 2
bdb_hidden_sectors: dd 0
bdb_large_sectors: dd 0

; ===== Extended Boot Record:

ebr_drive_number: db 0
db 0 ; reserved:
ebr_signature: db 29h
ebr_volume_id: db 12h, 34h, 56h, 78h ; arbitrary 4 byte id
ebr_volume_label: db "Volume     " ; arbitrary String padded to 11 bytes
ebr_system_id: db "FAT12   " ; padded to 8 bytes






%define CR 0x0D
%define LF 0x0A
%define CRLF CR, LF

start:
	jmp main


msg_hello:			db "Hello, World", CRLF, 0
msg_read_failed:	db "Read from disk failed!", CRLF, 0


main:
	mov ah, 0x0e ; tty mode

	; read something from floppy:
	mov [ebr_drive_number], dl ; Bios should set dl to drive number
	mov ax, 1 ; LBA = 1, second sector from disk
	mov cl, 1 ; read 1 sector
	mov bx, 0x7E00 ; data should be after the bootloader
	call disk_read

	mov bx, msg_hello
	call print

	mov bx, msg_hello
	call print

	mov bx, msg_hello
	call print

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


	hlt   ; halt execution
	jmp $ ; jump to current address (infinite loop) just to be safe


floppy_error:
	mov bx, msg_read_failed
	call print
	call wait_key_and_reboot

wait_key_and_reboot:
	mov ah, 0
	int 0x16 ; wait for keypress
	jmp 0x0FFFF:0 ; jump to start of BIOS, basically rebooting


;    ====== void print (const char* bx) ======
print:
	pusha        ; save registers

p_start:
	mov al, [bx] ;    char al = *bx;
	cmp al, 0    ;    if (al == 0)
	je p_done    ;        goto p_donw;

	mov ah, 0x0E ;    [enable tty mode]
	int 0x10     ;    printChar(al);
	inc bx       ;    bx++;
	jmp p_start  ;    goto p_start;

p_done:
	popa         ; restore registers
	ret


;    ====== void println (const char* bx) ======
println:
	pusha       ;    save registers

	call print  ;    print normally

	mov al, CR ;    put '\r' into al as ascii
	int 0x10    ;    print char

	mov al, LF ;    put '\n' into al as ascii
	int 0x10    ;    print char

	popa        ;    restore registers
	ret



; ===== LBA to CHS Address Conversion
; in:
;   - ax = LBA Address
; out:
;   - cx [bits 0-5]: sector number
;   - cx [bits 6-15]: cylinder
;   - dh: head

lba_to_chs:
	push ax
	push dx
	
	xor dx, dx ; dx = 0
	div word [bdb_sectors_per_track] ; ax = LBA / sectorsPerTrack
                                     ; dx = LBA % sectorsPerTrack

	inc dx ; dx = (LBA % sectorsPerTrack + 1) = sector
	mov cx, dx ; cx = sector

	xor dx, dx ; dx = 0
	div word [bdb_heads] ; ax = (LBA / sectorsPerTrack) / heads = cylinder
                         ; dx = (LBA / sectorsPerTrack) % heads = head

	mov dh, dl ; dh = head

	mov ch, al ; ch = cylinder (lower 8 bits)
	shl ah, 6  ; ah <<= 6
	or  cl, ah ; cl |= ah   (put upper 2 bits of cylinder into cl)
	
	pop dx
	pop ax

	ret

; div word (value): simultaneous division and modulo
; dx = ax % value
; ax = ax / value



; ===== Read Sectors from a disk
; inputs:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - esbx: memory address where to store read data

disk_read:
	push ax
	push bx
	push cx
	push dx
	push di

	push cx ; save cl (number of sectors to read)
	call lba_to_chs
	pop ax ; al = number of sectors to read

	mov ah, 0x02
	mov di, 3 ; retries = 3

.retry:
	pusha
	stc ; set carry flag in case BIOS didn't
	int 0x13

	jnc .done

	; read failed
	popa
	call disk_reset
	dec di ; retries--
	test di, di
	jnz .retry

.fail:
	; after all retries failed:
	jmp floppy_error

.done:
	popa

	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

# Input: drive number in dl
disk_reset:
	pusha
	mov ah, 0
	stc
	int 0x13
	jc floppy_error
	popa
	ret


SectorEnd:
	; Make Sector bootable:

	times 510 - ($-$$) db 0 ; Padding ($ is the current position before emitting this line, $$ is the startposition of the current sector)

	dw 0xaa55 ; Magic Number