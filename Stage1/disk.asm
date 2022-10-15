[bits 16]    ; Tell Assembler to emit 16-Bit Code

; ===== Read Sectors from a disk
; inputs:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - esbx: memory address where to store read data

disk_read:
	; pusha
	; more precise:
	push ax
	push bx
	push cx
	push dx
	push di

	push cx ; save cl (number of sectors to read)
	call .lba_to_chs
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
	call .disk_reset
	dec di ; retries--
	test di, di
	jnz .retry

.fail:
	; after all retries failed:
	jmp .floppy_error

.done:
	popa

	; popa
	; more precise:
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

; Input: drive number in dl
.disk_reset:
	pusha
	mov ah, 0
	stc
	int 0x13
	jc .floppy_error
	popa
	ret

.floppy_error:
	mov bx, .msg_read_failed
	call print
	call wait_key_and_reboot




; ===== LBA to CHS Address Conversion
; in:
;   - ax = LBA Address
; out:
;   - cx [bits 0-5]: sector number
;   - cx [bits 6-15]: cylinder
;   - dh: head

.lba_to_chs:
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

	pop ax
	mov dl, al ; restore dl
	pop ax

	ret


; div word (value): simultaneous division and modulo
; dx = ax % value
; ax = ax / value


.msg_read_failed: db "EF", CRLF, 0 ; Read from disk failed



