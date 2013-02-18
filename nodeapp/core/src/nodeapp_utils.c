
#include "nodeapp.h"

#include <string.h>

#ifdef __APPLE__
#pragma clang diagnostic ignored "-Wformat-nonliteral"
#endif

char *str_printf(const char *fmt, ...) {
    char *buf;
    va_list va;
    va_start(va, fmt);
    vasprintf(&buf, fmt, va);
    va_end(va);

    return buf;
}
