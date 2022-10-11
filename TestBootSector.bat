@echo off

nasm -f bin %1 -o bootSector.bin

qemu-system-x86_64 -drive file=bootSector.bin,format=raw -m 4G -cpu max -smp cores=4,threads=1

@REM del bootSector.bin