
#include "nodeapp_private.h"

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

void autorelease_custom(autorelease_func_t func, void *data) {
    assert(func);
    if (data) {
#ifdef DEBUG_AUTORELEASE
        if (!*last) {
            fprintf(stderr, "===> Autorelease pool activated.\n");
        }
#endif
        if (!*last) {
            nodeapp_autorelease_pool_activate();
        }
        assert(last < end);
        *++last = (void *)func;
        assert(last < end);
        *++last = data;
    }
}

void nodeapp_autorelease_cleanup() {
#ifdef DEBUG_AUTORELEASE
    if (*last) {
        fprintf(stderr, "===> Autorelease pool draining.\n");
        fflush(stderr);
    }
#endif
    while (*last) {
        void *data = *last--;
        autorelease_func_t func = (autorelease_func_t) *last--;
        assert(data);
        assert(func);
        func(data);
    }
}


void _autorelease_malloced_impl(void *ptr) {
    autorelease_custom(free, ptr);
}

json_t *json_autodecref(json_t *json) {
    autorelease_custom((autorelease_func_t)json_decref, json);
    return json;
}
