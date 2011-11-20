
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

#endif
