#!/bin/bash

# ===== Assemble Boot Sector:
(cd Stage1 && ./make.sh)&

# ===== Create Bootable Medium:
# Create empty file:
dd if=/dev/zero of=floppy.img bs=512 count=2880

# Create FAT-12 Filesystem inside File:
mkfs.fat -F 12 -n "NBOS" floppy.img

# Write Bootsector into File:
dd if=Stage1/sector.bin of=floppy.img conv=notrunc

# Write Kernel into File:
mcopy -i floppy.img kernel.bin "::kernel.bin"

# Print image contents:
# mdir -i floppy.img