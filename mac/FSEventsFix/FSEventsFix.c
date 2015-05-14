/*
 * Copyright (c) 2015 Andrey Tarantsov <andrey@tarantsov.com>
 * Copyright (c) 2003 Constantin S. Svintsoff <kostik@iclub.nsu.ru>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Based on a realpath implementation from Apple libc 498.1.7, taken from
 * http://www.opensource.apple.com/source/Libc/Libc-498.1.7/stdlib/FreeBSD/realpath.c
 * and provided under the following license:
 *
 * Copyright (c) 2003 Constantin S. Svintsoff <kostik@iclub.nsu.ru>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The names of the authors may not be used to endorse or promote
 *    products derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */


#include "FSEventsFix.h"

#define FSEVENTSFIX_METHOD_MACH_OVERRIDE 1
#define FSEVENTSFIX_METHOD_FISHHOOK 2
#define FSEVENTSFIX_METHOD_DYLD_INTERPOSE 3

#define FSEVENTSFIX_METHOD FSEVENTSFIX_METHOD_FISHHOOK

#if FSEVENTSFIX_METHOD == FSEVENTSFIX_METHOD_MACH_OVERRIDE
#include "mach_override.h"
#elif FSEVENTSFIX_METHOD == FSEVENTSFIX_METHOD_FISHHOOK
#include "fishhook.h"
#endif

#define FSEVENTSFIX_DUMP_CALLS 0
#define FSEVENTSFIX_RETURN_UPPERCASE_RESULT_FOR_TESTING 0

#include <sys/cdefs.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int realpath_called = 0;

#if FSEVENTSFIX_DUMP_CALLS
#include <stdio.h>
#endif

static char *fixed_realpath(const char * __restrict src, char * __restrict dst) {
    realpath_called = 1;

    char *rv = FSEventsFix_realpath(src, dst);
#if FSEVENTSFIX_DUMP_CALLS
    printf("realpath(%s) => %s\n", src, dst);
#endif

#if FSEVENTSFIX_RETURN_UPPERCASE_RESULT_FOR_TESTING
    if (dst) {
        for (char *pch = dst; *pch; ++pch) {
            *pch = toupper(*pch);
        }
    }
#endif
    
    return rv;
}

#if FSEVENTSFIX_METHOD == FSEVENTSFIX_METHOD_DYLD_INTERPOSE

#define DYLD_INTERPOSE(_replacment,_replacee) \
  __attribute__((used)) static struct{ const void* replacment; const void* replacee; } _interpose_##_replacee \
  __attribute__ ((section ("__DATA,__interpose"))) = { (const void*)(unsigned long)&_replacment, (const void*)(unsigned long)&_replacee }; 

DYLD_INTERPOSE(fixed_realpath, realpath)
#endif

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>

#if FSEVENTSFIX_METHOD == FSEVENTSFIX_METHOD_FISHHOOK
static struct rebinding rebindings[] = {
    { "realpath$DARWIN_EXTSN", (void *) &fixed_realpath }
};
#endif


void FSEventsFixApply() {
    char *skip_flag = getenv("FSEventsFix");
    if (skip_flag && (0 == strcasecmp(skip_flag, "NO"))) {
        return;
    }

    static char src[1024];
    static char dst[1024];
    
#if FSEVENTSFIX_METHOD == FSEVENTSFIX_METHOD_MACH_OVERRIDE
    if (mach_override_ptr(&realpath, &fixed_realpath, NULL)) {
        fprintf(stderr, "** FSEventsFix: mach_override failed.\n");
        return;
    }
#elif FSEVENTSFIX_METHOD == FSEVENTSFIX_METHOD_FISHHOOK
    rebind_symbols(rebindings, sizeof(rebindings) / sizeof(rebindings[0]));
#endif
    
    struct passwd *pw = getpwuid(getuid());
    assert(pw);
    
    strcpy(src, pw->pw_dir);
    strcat(src, "/./foo/./../bar");
    for (char *pch = src; *pch; ++pch) {
        *pch = toupper(*pch);
    }

    // this call sets realpath_called, which signals a successful hooking operation
    realpath(src, dst);
    
    if (!realpath_called) {
        fprintf(stderr, "** FSEventsFix: realpath not overriden.\n");
    }
}

int FSEventsFixIsApplied() {
    return !!realpath_called;
}
