#!/bin/bash


# ===== Assemble Boot Sector:
(cd Stage1 && ./make.sh)&
wait # wait for Bootsector assembly to finish


# ===== Build Stage 2:
(cd Stage2 && ./make.sh)&
wait # wait for Stage 2 sssembly to finish


# ===== Create Bootable Medium:
echo "===== Creating boot Drive ====="

# Create empty file:
echo "-- creating drive file"
dd if=/dev/zero of=build/floppy.img bs=512 count=2880

# Create FAT-12 Filesystem inside File:
echo "-- creating file system"
mkfs.fat -F 12 -n "NBOS" build/floppy.img

# Write Bootsector into File:
echo "-- writing bootsector into filesystem"
dd if=build/stage1.bin of=build/floppy.img conv=notrunc


# Write Stage2 into File:
echo "-- copying Stage 2 into file system"
mcopy -i build/floppy.img build/stage2.bin "::stage2.bin"

# Print image contents:
# mdir -i floppy.img

echo "-- done."
echo ""