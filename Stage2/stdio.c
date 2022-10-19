#include "stdio.h"

// #include "stdint.h"

// const unsigned SCREEN_WIDTH = 80;
// const unsigned SCREEN_HEIGHT = 25;
// uint8_t *const screenBuffer = (uint8_t*)0xB8000;

// void putchar(const uint32_t x, const uint32_t y, const char c) {
// 	screenBuffer[(y * SCREEN_WIDTH + x) * 2] = c;
// }

// void putcolor(const uint32_t x, const uint32_t y, const uint8_t color) {
// 	screenBuffer[(y * SCREEN_WIDTH + x) * 2 + 1] = color;
// }

// uint8_t color(const uint8_t foreground, const uint8_t background) {
// 	return background << 4 | foreground;
// }

// typedef enum {
// 	NORMAL,
// 	EXPRESSION,
// } State;


// void _cdecl printf(const char *fmt, ...) {
// 	int *argp = (int*)&fmt;

// 	State state = NORMAL;

// 	uint8_t bytes; // size of integer parameter in bytes

// 	bool pad; // pad numbers / strings
// 	char padding; // char to pad numbers / strings with

// 	argp ++;

// 	while(*fmt) {
// 		const char c = *fmt;

// 		switch(state) {
// 			case NORMAL:
// 				if(c == '%') {
// 					state = EXPRESSION;
// 					bytes = 4; // default: %d = 32bit integer
// 					pad = false; // default: no padding
// 					padding = ' '; // default: pad with spaces
// 				} else {
// 					putc(*fmt);
// 				}
// 				break;

// 			case EXPRESSION:
// 				switch(c) {
// 					case '%':
// 						putc(c);
// 						state = NORMAL;
// 						break;

// 					case 'h':
// 						bytes /= 2;
// 						break;

// 					// case 'l':
// 					// 	bytes *= 2; // TODO: long int is still 32 bit
// 					// 	break;
					
// 					case 'x': {
// 						const char HEX[] = {
// 							'0', '1', '2', '3', '4', '5', '6', '7',
// 							'8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};
// 						uint32_t val = 0;
// 						uint8_t byte = 0;

// 						char buffer[32];
						
// 						uint8_t nibble;
// 						for(; byte < bytes; byte++) {
// 							val |= (*argp) << (byte * 8);
// 							argp++;
// 						}
// 						// if(bytes == 1) argp++; // all arguments on stack are aligned to 1 word boundary
// 						// if(bytes % 4 != 0) argp += 4 - (bytes % 4); // all arguments on stack are aligned to 1 word boundary

// 						// val = *argp;
// 						// argp++;

// 						// nibble = bytes * 2;
// 						byte = bytes;

// 						// for(;;) {
// 						// 	int mask;
// 						// 	if(nibble <= 2) break;
// 						// 	mask = 0xFF << ((nibble - 2) * 8);
// 						// 	if(val & mask == 0) break;
// 						// 	nibble -= 2;
// 						// }

// 						// for(; byte > 1; ) {
// 						// 	// uint32_t mask = 0xFF << ((byte - 1) * 8);
// 						// 	// if(val & mask) break;


// 						// 	// uint32_t mask = 0xFF << ((byte - 1) * 8);
							
// 						// 	// uint32_t mask = 0xFF *  (byte * 8 * 256);

// 						// 	byte--;
// 						// }
// 						// byte = 1;

// 						for(byte = 0; byte < 4; byte++) {
// 							const uint32_t shr = byte * 8;
// 							const uint8_t b = (val >> shr) & 0xFF;
// 							// HEX[b >> 4];
// 							// buffer[byte * 2 + 1] = HEX[b & 0xF];
// 							putc(HEX[byte * 2]);
// 							putc(HEX[byte * 2 + 1]);
// 						}
// 						// for(; byte > -1; byte++) {
// 						// 	putc(buffer[byte * 2]);
// 						// 	putc(buffer[byte * 2 + 1]);
// 						// }
// 						// for(byte = 0; byte < 4; byte++) {
// 						// 	const uint32_t shr = byte;
// 						// for(; byte; byte--) {
// 						// 	const uint32_t shr = (byte - 1) * 8;
// 						// 	const uint8_t b = (val >> shr) & 0xFF;
// 						// 	putc(HEX[b >> 4]);
// 						// 	putc(HEX[b & 0xF]);
// 						// 	// val &= 0x00FFFFFF;
// 						// 	// val <<= 8;
// 						// }
// 						// for(; nibble; nibble--) {
// 						// 	putc(HEX[(val >> ((nibble - 1) * 4)) & 0xF]);
// 						// }
// 						state = NORMAL;
// 					} break;
// 					// case 'd': {
// 					// 	int32_t val = 0;
// 					// 	int byte = 0;
// 					// 	int32_t pos = 1000000000; // maximum number: 2,147,483,647  (10 digits)
// 					// 	// int64_t pos = 1000000000000000000; // maximum number: 9,223,372,036,854,775,807  (19 digits)
// 					// 	for(; byte < bytes; byte++) {
// 					// 		val |= (*argp) << (byte * 8);
// 					// 		argp++;
// 					// 	}
// 					// 	if(bytes == 1)
// 					// 		argp++; // all arguments on stack are aligned to 1 word boundary

// 					// 	// print sign:
// 					// 	if(val < 0) {
// 					// 		putc('-');
// 					// 		val = -val;
// 					// 	}

// 					// 	// for(; val; val /= 10)
// 					// 	// 	putc('0' + (val % 10));
// 					// 	for(; !(value / pos); pos /= 10);
// 					// 	for(; pos; pos /= 10) {
// 					// 		// if(val / pos) {
// 					// 			putc('0' + (val / pos % 10));
// 					// 		// }
// 					// 		val -= ((val / pos) * pos); // clear digit
// 					// 	}
// 					// 	state = NORMAL;
// 					// } break;
// 				}

// 				break;
// 		}

// 		fmt++;
// 	}
// }



