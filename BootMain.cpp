#include <inttypes.h>
#include "memory_map.h"

// static void start_app(uint32_t pc, uint32_t sp) __attribute__((naked)) {
//     __asm("           \n\
//           msr msp, r1 /* load r1 into MSP */\n\
//           bx r0       /* branch to the address at r0 */\n\
//     ");
// }

void ClearScreen() {
	__asm("\n\
		mov al, 02  /* here you set the 80x25 graphical mode (text) */\n\
		mov ah, 00  /* this is the code of the function that allows us to change the video mode */\n\
		int 10      /* here you call the interrupt */\n\
	");
} // It was originally published on https://www.apriorit.com/

extern "C" void BootMain() {
	uint32_t *app_code = (uint32_t *)__approm_start__;
	uint32_t app_sp = app_code[0];
	uint32_t app_start = app_code[1];
	// start_app(app_start, app_sp);
	/* Not Reached */

	for(;;);
	return;
}