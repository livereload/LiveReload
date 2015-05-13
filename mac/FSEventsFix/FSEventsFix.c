#include "FSEventsFix.h"
#include "mach_override.h"
#include <stdio.h>
#include <stdlib.h>

#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>

static char *(*original_realpath)(const char * __restrict src, char * __restrict dst);

static char *fixed_realpath(const char * __restrict src, char * __restrict dst) {
    char *rv = (*original_realpath)(src, dst);
    printf("realpath(%s) => %s\n", src, dst);
    return rv;
}

void FixFSEvents() {
    static char src[1024];
    static char dst[1024];
    if (mach_override("_realpath$DARWIN_EXTSN", NULL, &fixed_realpath, (void**) &original_realpath)) {
        fprintf(stderr, "** mach_override failed.\n");
        exit(42);
    }
    
    struct passwd *pw = getpwuid(getuid());
    assert(pw);
    
    strcpy(src, pw->pw_dir);
    for (char *pch = src; *pch; ++pch) {
        *pch = toupper(*pch);
    }
    
    realpath(src, dst);
    printf("realpath(%s) returned %s", src, dst);
}

