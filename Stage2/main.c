#include "stdint.h"
#include "x86.h"
#include "stdio.h"

void _cdecl cstart_(uint16_t bootDrive) {
	// printf("Hello World %% %x from C Bootloader!\r\n", 0x1234);
	puts("Hello World from C Bootloader!\r\n");
	(void)bootDrive;
	for(;;);
}
