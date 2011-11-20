
#include "common.h"
#include "string.h"

#ifdef _MSC_VER
char *stpcpy(char *dest, const char *source) {
  strcpy(dest, source);
  return dest + strlen(dest);
}
#endif
