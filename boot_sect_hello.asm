mov ah, 0x0e ; tty mode

mov al, 'H'
int 0x10
mov al, 'e'
int 0x10
mov al, 'l'
int 0x10
int 0x10
mov al, 'o'
int 0x10

mov al, ','
int 0x10
mov al, ' '
int 0x10

mov al, 'W'
int 0x10
mov al, 'o'
int 0x10
mov al, 'r'
int 0x10
mov al, 'l'
int 0x10
mov al, 'd'
int 0x10

jmp $ ; jump to current address = infinite loop



; Make Sector bootable:

times 510 - ($-$$) db 0 ; Padding ($ is the current position before emitting this line, $$ is the startposition of the current sector)

dw 0xaa55 ; Magic Number