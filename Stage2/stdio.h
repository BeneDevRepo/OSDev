#pragma once

#include "x86.h"

#include "stdint.h"

void putchar(const uint32_t x, const uint32_t y, const char c);
void putcolor(const uint32_t x, const uint32_t y, const uint8_t color);
uint8_t color(const uint8_t foreground, const uint8_t background); // 4 bits per color

// void __attribute__((cdecl)) printf(const char *fmt, ...);

