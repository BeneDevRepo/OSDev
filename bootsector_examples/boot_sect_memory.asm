[org 0x7c00] ; global memory offset (because the boot sector is loaded into memory at location 0x7C00)

mov ah, 0x0e ; tty mode

mov al, [the_secret]
int 0x10



jmp $ ; jump to current address = infinite loop

the_secret:
    ; ASCII code 0x58 ('X') is stored just before the zero-padding.
    ; On this code that is at byte 0x2d (check it out using 'xxd file.bin')
    db "X"

; Make Sector bootable:

times 510 - ($-$$) db 0 ; Padding ($ is the current position before emitting this line, $$ is the startposition of the current sector)

dw 0xaa55 ; Magic Number