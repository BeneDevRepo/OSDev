#!/bin/bash

# Assemble:
nasm -f bin $1 -o sector.bin

# Execute:
qemu-system-x86_64 \
	-m 4G \
	-cpu max \
	-smp cores=4,threads=1 \
	-drive file=sector.bin,format=raw \