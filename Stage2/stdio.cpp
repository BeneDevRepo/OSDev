#include "stdio.hpp"
#include <stdarg.h>

constexpr uint32_t SCREEN_WIDTH = 80;
constexpr uint32_t SCREEN_HEIGHT = 25;
constexpr uint8_t DEFAULT_COLOR = 0x7;
uint8_t *const screenBuffer = (uint8_t*)0xB8000;
uint32_t cursorX=0, cursorY=0;

void putchar(const uint32_t x, const uint32_t y, const char c) {
	screenBuffer[(y * SCREEN_WIDTH + x) * 2] = c;
}

void putcolor(const uint32_t x, const uint32_t y, const uint8_t color) {
	screenBuffer[(y * SCREEN_WIDTH + x) * 2 + 1] = color;
}

uint8_t color(const uint8_t foreground, const uint8_t background) {
	return background << 4 | foreground;
}


void cls() {
	for(uint32_t i = 0; i < SCREEN_WIDTH * SCREEN_HEIGHT; i++) {
		screenBuffer[i * 2] = 0;
		screenBuffer[i * 2 + 1] = DEFAULT_COLOR;
	}
}

void putc(const char c) {
	switch(c) {
		case '\r':
			cursorX = 0;
			break;

		case '\n':
			cursorX = 0;
			cursorY++;
			break;

		default:
			putchar(cursorX, cursorY, c);
			cursorX++;
			break;
	}

	if(cursorX >= SCREEN_WIDTH) {
		cursorX = 0;
		cursorY++;
	}

	// if(cursorY >= SCREEN_HEIGHT)
	// 	scrollBack();

	// setCursor(cursorX, cursorY);
}

void puts(const char* str) {
    while(*str)
        putc(*str++);
}


enum State {
	NORMAL,
	EXPRESSION,
};


void printf(const char *fmt, ...) {
	constexpr char HEX[] = {
		'0', '1', '2', '3', '4', '5', '6', '7',
		'8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

	va_list args;
    va_start(args, fmt);

	State state = NORMAL;

	uint8_t bytes; // size of integer parameter in bytes

	// bool pad; // pad numbers / strings
	// char padding; // char to pad numbers / strings with

	// argp ++;

	while(*fmt) {
		const char c = *fmt;

		switch(state) {
			case NORMAL:
				if(c == '%') {
					state = EXPRESSION;
					bytes = 4; // default: %d = 32bit integer
					// pad = false; // default: no padding
					// padding = ' '; // default: pad with spaces
				} else {
					putc(c);
				}
				break;

			case EXPRESSION:
				switch(c) {
					case '%':
						putc(c);
						state = NORMAL;
						break;

					case 'h':
						bytes /= 2;
						break;

					case 'l':
						bytes *= 2; // TODO: long int is still 32 bit
						break;

					case 'x': {
						const uint32_t val = va_arg(args, uint32_t);

						int8_t nibble = (bytes - 1) * 2;

						// skip 0-nibbles:
						for(;;) {
							if(nibble <= 1)
								break;
							const uint8_t b = (val >> (nibble * 4)) & 0xF;
							if(b != 0)
								break;
							nibble--;
						}

						// print hex-characters:
						for(; nibble >= 0; nibble--) {
							const uint8_t b = (val >> (nibble * 4)) & 0xF;
							putc(HEX[b]);
						}

						state = NORMAL;
					} break;

					// case 'd': {
					// 	int32_t val = 0;
					// 	int byte = 0;
					// 	int32_t pos = 1000000000; // maximum number: 2,147,483,647  (10 digits)
					// 	// int64_t pos = 1000000000000000000; // maximum number: 9,223,372,036,854,775,807  (19 digits)
					// 	for(; byte < bytes; byte++) {
					// 		val |= (*argp) << (byte * 8);
					// 		argp++;
					// 	}
					// 	if(bytes == 1)
					// 		argp++; // all arguments on stack are aligned to 1 word boundary

					// 	// print sign:
					// 	if(val < 0) {
					// 		putc('-');
					// 		val = -val;
					// 	}

					// 	// for(; val; val /= 10)
					// 	// 	putc('0' + (val % 10));
					// 	for(; !(value / pos); pos /= 10);
					// 	for(; pos; pos /= 10) {
					// 		// if(val / pos) {
					// 			putc('0' + (val / pos % 10));
					// 		// }
					// 		val -= ((val / pos) * pos); // clear digit
					// 	}
					// 	state = NORMAL;
					// } break;
				}

				break;
		}

		fmt++;
	}
}



