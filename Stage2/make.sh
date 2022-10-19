#!/bin/bash -li

export PATH="$(realpath ../toolchain/bin):$PATH"
# export PATH="$(realpath ../toolchain/lib/gcc/i686-elf/12.2.0):$PATH"

echo "===== Building Stage 2 ====="

echo "-- assembling entry point..."
# nasm -f bin entry.asm -o stage2.bin # output bare binary file
# nasm -f obj entry.asm -o entry.o # output object file
nasm -f elf entry.asm -o entry.o # output object file

echo "-- assembling libraries..."
# nasm -f obj x86.asm -o x86.o
nasm -f elf x86.asm -o x86.o
nasm -f elf crti.asm -o crti.o
nasm -f elf crtn.asm -o crtn.o


echo "-- compiling c code..."
# -g: debug symbols
# i686-elf-gcc -ffreestanding -mno-red-zone -fno-exceptions -fno-rtti -c  main.c -o  main.o
# i686-elf-gcc -ffreestanding -mno-red-zone -fno-exceptions -fno-rtti -c stdio.c -o stdio.o
i686-elf-gcc -ffreestanding -mno-red-zone -fno-exceptions -c  main.c -o  main.o
# i686-elf-gcc -ffreestanding -mno-red-zone -fno-exceptions -c stdio.c -o stdio.o

echo "-- linking stage 2..."
i686-elf-gcc \
    -T link.ld \
    -o stage2.bin \
	-ffreestanding \
	-nostdlib \
    -Wl,-Map=stage2.map \
    crti.o entry.o main.o crtn.o \
    -lgcc
    # crti.o crtbegin.o entry.o main.o crtend.o crtn.o \
    # entry.o main.o stdio.o crti.o crtbegin.o crtend.o crtn.o \

# (rm *.err > /dev/null 2>&1)& # remove error files produced by wcc compiler

echo "-- Done."
echo ""
