#include "stdint.h"
// #include "x86.h"
// #include "stdio.h"

// #include <stdarg.h>

// uint8_t* KernelLoadBuffer = (uint8_t*)MEMORY_LOAD_KERNEL;
// uint8_t* Kernel = (uint8_t*)MEMORY_KERNEL_ADDR;

// typedef void (*KernelStart)(BootParams* bootParams);

	
	// int A[5]{1,2};
	// int b = A[1];
// extern "C"

const unsigned SCREEN_WIDTH = 80;
const unsigned SCREEN_HEIGHT = 25;
uint8_t *const screenBuffer = (uint8_t*)0xB8000;

void putchar(const uint32_t x, const uint32_t y, const char c) {
	screenBuffer[(y * SCREEN_WIDTH + x) * 2] = c;
}

void putcolor(const uint32_t x, const uint32_t y, const uint8_t color) {
	screenBuffer[(y * SCREEN_WIDTH + x) * 2 + 1] = color;
}

uint8_t color(const uint8_t foreground, const uint8_t background) {
	return background << 4 | foreground;
}

void __attribute__((cdecl)) start(uint16_t bootDrive) {
	// int A[5]{1,2};
	// int b = A[1];
	for(uint32_t y = 0; y < 16; y++) {
		for(uint32_t x = 0; x < 16; x++) {
			putchar(x * 2,     y, '@');
			putchar(x * 2,     y, '@');
			// putchar(x * 2 + 1, y, '@');
			// putcolor(x * 2,     y, color(y, x));
			// putcolor(x * 2 + 1, y, color(x, y));
		}
	}
}
