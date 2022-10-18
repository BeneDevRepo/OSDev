#!/bin/bash -li

echo "===== Building Stage 2 ====="

echo "-- assembling entry point..."
# nasm -f bin entry.asm -o stage2.bin # output bare binary file
nasm -f obj entry.asm -o entry.o # output object file

echo "-- assembling libraries..."
nasm -f obj x86.asm -o x86.o

echo "-- compiling c code..."
# -d3: include debug symbols into object file
# -s: no stack overflow protection (which requires runtime support)
# -wx: all warnings enabled
# -ms: small memory model
# -zl: no references to standard library
# -zq: no output except warnings and errors
# wcc -d3 -s -wx -ms -zl -zq main.c
# wcc -d3 -s -wx -ms -zl -zq stdio.c
../toolchain/bin/i686-elf-gcc -ffreestanding -mno-red-zone -fno-exceptions -c main.c
../toolchain/bin/i686-elf-gcc -ffreestanding -mno-red-zone -fno-exceptions -c stdio.c

echo "-- linking stage 2..."
# wlink NAME stage2.bin FILE \{ entry.obj main.obj x86.obj stdio.obj \} OPTION MAP=stage2.map @linker.lnk
# wlink NAME stage2.bin FILE \{ entry.obj \} OPTION MAP=stage2.map @linker.lnk
../toolchain/bin/i686-elf-ld \
    -T link.ld \
    entry.obj \
    -o stage2.bin \
    -nostdlib \
    -lgcc \
    --oformat binary \
    -Map=stage2.map

# (rm *.err > /dev/null 2>&1)& # remove error files produced by wcc compiler

echo "-- Done."
echo ""
