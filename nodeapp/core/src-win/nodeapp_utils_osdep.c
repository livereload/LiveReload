
#include "nodeapp.h"

#include <string.h>

char *stpcpy(char *dest, const char *source) {
  strcpy(dest, source);
  return dest + strlen(dest);
}

char *w2u(WCHAR *string) {
  DWORD cb = WideCharToMultiByte(CP_UTF8, 0, string, -1, NULL, 0, NULL, NULL);
  char *result = (char *) malloc(cb);
  WideCharToMultiByte(CP_UTF8, 0, string, -1, result, cb, NULL, NULL);
  return result;
}

const char *basename(const char *path) {
    if (!*path)
        return path;

    const char *p1 = strrchr(path, '\\');
    const char *p2 = strrchr(path, '/');
    if (p1 && p2) {
        return (p1 > p2 ? p1 : p2) + 1;
    } else if (p1) {
        return p1 + 1;
    } else if (p2) {
        return p2 + 1;
    } else {
        return path;
    }
}

int vasprintf(char **sptr, const char *fmt, va_list argv) {
    *sptr = NULL;
    int wanted = vsnprintf(NULL, 0, fmt, argv );
    if ((wanted > 0) && ((*sptr = (char *)malloc(1 + wanted)) != NULL))
        return vsprintf( *sptr, fmt, argv );
    return -1;
}

int asprintf(char **sptr, const char *fmt, ... ) {
    va_list va;
    va_start(va, fmt);
    int retval = vasprintf(sptr, fmt, va);
    va_end(va);
    return retval;
}
