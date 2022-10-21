#pragma once

// #include "x86.hpp"

#include "stdint.hpp"


constexpr inline uint8_t color(const uint8_t foreground, const uint8_t background) { // 4 bits per color
    return background << 4 | foreground;
}

constexpr uint8_t COLOR_BLACK = 0;
constexpr uint8_t COLOR_BLUE = 1;
constexpr uint8_t COLOR_GREEN = 2;
constexpr uint8_t COLOR_CYAN = 3;
constexpr uint8_t COLOR_RED = 4;
constexpr uint8_t COLOR_PINK = 5;
constexpr uint8_t COLOR_YELLOW = 6;
constexpr uint8_t COLOR_WHITE = 7;

constexpr uint8_t COLOR_GRAY = 8;
constexpr uint8_t COLOR_BRIGHT_BLUE = 9;
constexpr uint8_t COLOR_BRIGHT_GREEN = 10;
constexpr uint8_t COLOR_BRIGHT_CYAN = 11;
constexpr uint8_t COLOR_BRIGHT_RED = 12;
constexpr uint8_t COLOR_BRIGHT_PINK = 13;
constexpr uint8_t COLOR_BRIGHT_YELLOW = 14;
constexpr uint8_t COLOR_BRIGHT_WHITE = 15;

constexpr uint8_t COLOR_DEFAULT = color(COLOR_WHITE, COLOR_BLACK);
constexpr uint8_t COLOR_SOVIET = color(COLOR_BRIGHT_YELLOW, COLOR_RED);

void putchar(const uint32_t x, const uint32_t y, const char c);
void putcolor(const uint32_t x, const uint32_t y, const uint8_t color);

void fillSymbols(const char symbol = ' ');
void fillColor(const uint8_t color = COLOR_DEFAULT);
void cls(const uint8_t color = COLOR_DEFAULT);
void putc(const char c);
void puts(const char* str);

// void cls(const uint8_t color);
void putc(const char c, const uint8_t color);
void puts(const char* str, const uint8_t color);

void printf(const char *fmt, ...);
// void __attribute__((cdecl)) printf(const char *fmt, ...);

