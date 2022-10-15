#include "stdint.h"

extern void _cdecl puts(const char *str);

void _cdecl cstart_(uint16_t bootDrive) {
	puts("Hello World from C Bootloader!");
}
