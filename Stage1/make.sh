#!/bin/bash

export PATH="$(realpath ../toolchain/bin):$PATH"

echo "===== Assembling BootSector ====="

nasm -f bin boot_sector.asm -o sector.bin

echo "-- Done."
echo ""