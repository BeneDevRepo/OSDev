#!/bin/bash

./makeIso.sh

qemu-system-x86_64 \
	-m 4G \
	-cpu max \
	-smp cores=4,threads=1 \
	-drive file=floppy.img,format=raw \