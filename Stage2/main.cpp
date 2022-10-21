#include "stdint.hpp"
#include "stdio.hpp"

// #include <stdarg.h>

// uint8_t* KernelLoadBuffer = (uint8_t*)MEMORY_LOAD_KERNEL;
// uint8_t* Kernel = (uint8_t*)MEMORY_KERNEL_ADDR;

// typedef void (*KernelStart)(BootParams* bootParams);


extern "C" void __attribute__((cdecl)) start(uint16_t bootDrive) {
	cls();

	// fillColor(COLOR_SOVIET);

	puts("Hello, World!\n");

	printf("0x42069: %x\n", 0x42069);
	printf("-42069: %d\n", -42069);

	float f = 5;
	printf("5: %d\n", (int)f);

}
