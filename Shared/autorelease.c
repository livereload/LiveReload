
#include "autorelease.h"

#include <assert.h>
#include <stdlib.h>


#define MAX_AUTORELEASE 10000

// can support nested pools in the future by pushing NULL as a boundary marker
// (the very first NULL remains here forever btw)
static void *pool[MAX_AUTORELEASE] = { NULL };
static void **last = pool;
static void **end = pool + MAX_AUTORELEASE;

void *autorelease(void *ptr) {
    if (ptr) {
        assert(last < end);
        *++last = ptr;
    }
    return ptr;
}

void autorelease_cleanup() {
//    while (*last) {
//        free(*last);
//        --last;
//    }
}
