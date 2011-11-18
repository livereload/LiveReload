
#include "autorelease.h"

#include <assert.h>
#include <stdlib.h>

// #define DEBUG_AUTORELEASE

#ifdef DEBUG_AUTORELEASE
#include <stdio.h>
#endif


#define MAX_AUTORELEASE 10000

// can support nested pools in the future by pushing NULL as a boundary marker
// (the very first NULL remains here forever btw)
static void *pool[MAX_AUTORELEASE] = { NULL };
static void **last = pool;
static void **end = pool + MAX_AUTORELEASE;

#ifdef __APPLE__
extern void autorelease_pool_activate();
#endif

void *autorelease(void *ptr) {
    if (ptr) {
#ifdef DEBUG_AUTORELEASE
        if (!*last) {
            fprintf(stderr, "===> Autorelease pool activated.\n");
        }
#endif
#ifdef __APPLE__
        if (!*last) {
            autorelease_pool_activate();
        }
#endif
        assert(last < end);
        *++last = ptr;
    }
    return ptr;
}

void autorelease_cleanup() {
#ifdef DEBUG_AUTORELEASE
    if (*last) {
        fprintf(stderr, "===> Autorelease pool draining.\n");
        fflush(stderr);
    }
#endif
    while (*last) {
        free(*last);
        --last;
    }
}
