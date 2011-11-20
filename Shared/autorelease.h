
#ifndef LiveReload_automem_h
#define LiveReload_automem_h

#include "common.h"

void *autorelease(void *ptr);
void autorelease_cleanup();

#ifdef __MSC_VER
template <typename T>
inline T *AU(T *val) {
    return (T) autorelease(val);
}
#else
#define AU(val) ((__typeof(val)) autorelease(val))
#endif

#endif
