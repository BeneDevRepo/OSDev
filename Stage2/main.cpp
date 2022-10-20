#include "stdint.h"
// #include "x86.h"
#include "stdio.h"

// #include <stdarg.h>

// uint8_t* KernelLoadBuffer = (uint8_t*)MEMORY_LOAD_KERNEL;
// uint8_t* Kernel = (uint8_t*)MEMORY_KERNEL_ADDR;

// typedef void (*KernelStart)(BootParams* bootParams);


extern "C" void __attribute__((cdecl)) start(uint16_t bootDrive) {
	for(uint32_t y = 0; y < 16; y++) {
		for(uint32_t x = 0; x < 16; x++) {
			putchar(x * 2,     y, '@');
			putchar(x * 2 + 1, y, '@');
			putcolor(x * 2,     y, color(y, x));
			putcolor(x * 2 + 1, y, color(x, y));
		}
	}
}
