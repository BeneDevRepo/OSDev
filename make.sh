#!/bin/bash

# ===== Assemble Boot Sector:
nasm -f bin $1 -o bootSector.bin

# ===== Create Bootable Medium:
# Create empty file:
dd if=/dev/zero of=floppy.img bs=512 count=2880

# Create FAT-12 Filesystem inside File:
mkfs.fat -F 12 -n "NBOS" floppy.img

# Write Bootsector into File:
dd if=bootSector.bin of=floppy.img conv=notrunc

# Write Kernel into File:
mcopy -i floppy.img kernel.bin "::kernel.bin"

# Print image contents:
mdir -i floppy.img

# ===== Run System in Virtual Machine:
qemu-system-x86_64.exe \
	-m 4G \
	-cpu max \
	-smp cores=4,threads=1 \
	-drive file=floppy.img,format=raw \

# del bootSector.bin
