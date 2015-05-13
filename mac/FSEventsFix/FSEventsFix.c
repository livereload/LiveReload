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
#include "mach_override.h"

#include <sys/cdefs.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int realpath_called = 0;

static char *bsd_realpath(const char *path, char resolved[PATH_MAX])
{
    struct stat sb;
    char *p, *q, *s;
    size_t left_len, resolved_len;
    unsigned symlinks;
    int serrno, slen;
    char left[PATH_MAX], next_token[PATH_MAX], symlink[PATH_MAX];
    
    serrno = errno;
    symlinks = 0;
    if (path[0] == '/') {
        resolved[0] = '/';
        resolved[1] = '\0';
        if (path[1] == '\0')
            return (resolved);
        resolved_len = 1;
        left_len = strlcpy(left, path + 1, sizeof(left));
    } else {
        if (getcwd(resolved, PATH_MAX) == NULL) {
            strlcpy(resolved, ".", PATH_MAX);
            return (NULL);
        }
        resolved_len = strlen(resolved);
        left_len = strlcpy(left, path, sizeof(left));
    }
    if (left_len >= sizeof(left) || resolved_len >= PATH_MAX) {
        errno = ENAMETOOLONG;
        return (NULL);
    }
    
    /*
     * Iterate over path components in `left'.
     */
    while (left_len != 0) {
        /*
         * Extract the next path component and adjust `left'
         * and its length.
         */
        p = strchr(left, '/');
        s = p ? p : left + left_len;
        if (s - left >= sizeof(next_token)) {
            errno = ENAMETOOLONG;
            return (NULL);
        }
        memcpy(next_token, left, s - left);
        next_token[s - left] = '\0';
        left_len -= s - left;
        if (p != NULL)
            memmove(left, s + 1, left_len + 1);
        if (resolved[resolved_len - 1] != '/') {
            if (resolved_len + 1 >= PATH_MAX) {
                errno = ENAMETOOLONG;
                return (NULL);
            }
            resolved[resolved_len++] = '/';
            resolved[resolved_len] = '\0';
        }
        if (next_token[0] == '\0')
            continue;
        else if (strcmp(next_token, ".") == 0)
            continue;
        else if (strcmp(next_token, "..") == 0) {
            /*
             * Strip the last path component except when we have
             * single "/"
             */
            if (resolved_len > 1) {
                resolved[resolved_len - 1] = '\0';
                q = strrchr(resolved, '/') + 1;
                *q = '\0';
                resolved_len = q - resolved;
            }
            continue;
        }
        
        /*
         * Append the next path component and lstat() it. If
         * lstat() fails we still can return successfully if
         * there are no more path components left.
         */
        resolved_len = strlcat(resolved, next_token, PATH_MAX);
        if (resolved_len >= PATH_MAX) {
            errno = ENAMETOOLONG;
            return (NULL);
        }
        if (lstat(resolved, &sb) != 0) {
            if (errno == ENOENT && p == NULL) {
                errno = serrno;
                return (resolved);
            }
            return (NULL);
        }
        if (S_ISLNK(sb.st_mode)) {
            if (symlinks++ > MAXSYMLINKS) {
                errno = ELOOP;
                return (NULL);
            }
            slen = readlink(resolved, symlink, sizeof(symlink) - 1);
            if (slen < 0)
                return (NULL);
            symlink[slen] = '\0';
            if (symlink[0] == '/') {
                resolved[1] = 0;
                resolved_len = 1;
            } else if (resolved_len > 1) {
                /* Strip the last path component. */
                resolved[resolved_len - 1] = '\0';
                q = strrchr(resolved, '/') + 1;
                *q = '\0';
                resolved_len = q - resolved;
            }
            
            /*
             * If there are any path components left, then
             * append them to symlink. The result is placed
             * in `left'.
             */
            if (p != NULL) {
                if (symlink[slen - 1] != '/') {
                    if (slen + 1 >= sizeof(symlink)) {
                        errno = ENAMETOOLONG;
                        return (NULL);
                    }
                    symlink[slen] = '/';
                    symlink[slen + 1] = 0;
                }
                left_len = strlcat(symlink, left, sizeof(left));
                if (left_len >= sizeof(left)) {
                    errno = ENAMETOOLONG;
                    return (NULL);
                }
            }
            left_len = strlcpy(left, symlink, sizeof(left));
        }
    }
    
    /*
     * Remove trailing slash except when the resolved pathname
     * is a single "/".
     */
    if (resolved_len > 1 && resolved[resolved_len - 1] == '/')
        resolved[resolved_len - 1] = '\0';
    return (resolved);
}

#include <stdio.h>

static char *fixed_realpath(const char * __restrict src, char * __restrict dst) {
    // "As a permitted extension to the standard, if resolved_name is NULL,
    // memory is allocated for the resulting absolute pathname, and is returned by
    // realpath().  This memory should be freed by a call to free(3) when no longer needed."
    // -- Mac OS X man page for realpath(3)
    if (!dst) {
        // behavior based on realpath() impl from libc 1044.1.2 (OS X 10.10),
        // see http://www.opensource.apple.com/source/Libc/Libc-1044.1.2/stdlib/FreeBSD/realpath.c
        dst = malloc(PATH_MAX);
        if (!dst) {
            return NULL;
        }
    }
    
    realpath_called = 1;

    char *rv = bsd_realpath(src, dst);
    //printf("realpath(%s) => %s\n", src, dst);

#if 0
    for (char *pch = dst; *pch; ++pch) {
        *pch = toupper(*pch);
    }
#endif
    
    return rv;
}

#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>

void FSEventsFixApply() {
    char *skip_flag = getenv("FSEventsFix");
    if (skip_flag && (0 == strcasecmp(skip_flag, "NO"))) {
        return;
    }

    static char src[1024];
    static char dst[1024];
    if (mach_override("_realpath$DARWIN_EXTSN", NULL, &fixed_realpath, NULL)) {
        fprintf(stderr, "** FSEventsFix: mach_override failed.\n");
        return;
    }
    
    struct passwd *pw = getpwuid(getuid());
    assert(pw);
    
    strcpy(src, pw->pw_dir);
    strcat(src, "/./foo/./../bar");
    for (char *pch = src; *pch; ++pch) {
        *pch = toupper(*pch);
    }

    // this call sets realpath_called, which signals a successful hooking operation
    realpath(src, dst);
}

int FSEventsFixIsApplied() {
    return !!realpath_called;
}
