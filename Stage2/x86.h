#pragma once

extern void __attribute__((cdecl)) putc(char c);
extern void __attribute__((cdecl)) puts(const char *str); // print null-terminated string (does not append \n)
