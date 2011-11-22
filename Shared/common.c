
#include "common.h"
#include "string.h"

#ifdef _MSC_VER

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

#endif
