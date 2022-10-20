#!/bin/bash -li

echo "===== Building Stage 2 ====="

# add toolchain to path:
export PATH="$(realpath ../toolchain/bin):$PATH"

# create build directory:
mkdir -p ../build/stage2

# add build folder to path:
export PATH="$(realpath ../build/stage2):$PATH"

echo "-- assembling entry point..."
# nasm -f bin entry.asm -o stage2.bin # output bare binary file
# nasm -f obj entry.asm -o entry.o # output object file
nasm -f elf entry.asm -o ../build/stage2/entry.o # output object file

echo "-- assembling libraries..."
# nasm -f obj x86.asm -o x86.o
nasm -f elf x86.asm  -o ../build/stage2/x86.o
nasm -f elf crti.asm -o ../build/stage2/crti.o
nasm -f elf crtn.asm -o ../build/stage2/crtn.o


echo "-- compiling c code..."
# -g: debug symbols
i686-elf-g++ -g -ffreestanding -mno-red-zone -fno-exceptions -fno-rtti -c  main.cpp -o ../build/stage2/main.o
i686-elf-gcc -g -ffreestanding -mno-red-zone -fno-exceptions -fno-rtti -c stdio.cpp -o ../build/stage2/stdio.o

echo "-- linking stage 2..."
i686-elf-g++ \
    -T link.ld \
    -o ../build/stage2.bin \
	-ffreestanding \
	-nostdlib \
    -Wl,-Map=../build/stage2.map \
    ../build/stage2/crti.o \
	../build/stage2/entry.o \
	../build/stage2/main.o \
	../build/stage2/stdio.o \
	../build/stage2/crtn.o \
    -lgcc
    # crti.o entry.o main.o stdio.o crtn.o \
    # crti.o crtbegin.o entry.o main.o crtend.o crtn.o \

	# -L $(realpath ../toolchain/lib/gcc/i686-elf/12.2.0) \
    # crti.o crtbegin.o entry.o main.o crtend.o crtn.o \
    # entry.o main.o stdio.o crti.o crtbegin.o crtend.o crtn.o \

# (rm *.err > /dev/null 2>&1)& # remove error files produced by wcc compiler

echo "-- Done."
echo ""
