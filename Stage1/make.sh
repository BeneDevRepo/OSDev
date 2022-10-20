#!/bin/bash


echo "===== Assembling BootSector ====="

# add toolchain to path:
export PATH="$(realpath ../toolchain/bin):$PATH"

# create build directory:
mkdir -p ../build

nasm -f bin boot_sector.asm -o ../build/stage1.bin

echo "-- Done."
echo ""