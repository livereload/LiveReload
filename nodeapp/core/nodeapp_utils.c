
#include "nodeapp.h"

#include <string.h>

char *str_printf(const char *fmt, ...) {
    char *buf;
    va_list va;
    va_start(va, fmt);
    vasprintf(&buf, fmt, va);
    va_end(va);

    return buf;
}
