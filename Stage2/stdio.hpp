#pragma once

// #include "x86.hpp"

#include "stdint.hpp"

void putchar(const uint32_t x, const uint32_t y, const char c);
void putcolor(const uint32_t x, const uint32_t y, const uint8_t color);
uint8_t color(const uint8_t foreground, const uint8_t background); // 4 bits per color

void cls();
void putc(const char c);
void puts(const char* str);

void printf(const char *fmt, ...);
// void __attribute__((cdecl)) printf(const char *fmt, ...);

