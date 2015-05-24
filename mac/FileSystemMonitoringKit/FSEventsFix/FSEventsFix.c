/*
 * FSEventsFix - http://github.com/andreyvit/FSEventsFix
 *
 * Works around a HFS+ file system corruption bug that prevents FSEvents API from
 * monitoring certain folders on a wide range of OS X releases (10.6-10.10 at least).
 *
 * Copyright (c) 2015, Andrey Tarantsov <andrey@tarantsov.com>
 * Copyright (c) 2015, Travis Tilley <ttilley@gmail.com>
 * Copyright (c) 2013, Facebook, Inc.
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
 */


#define FSEVENTSFIX_DEBUG_SIMULATE_FAILURE 0
#define FSEVENTSFIX_DEBUG_LOG_CALLS 0
#define FSEVENTSFIX_DEBUG_REALPATH_RETURNS_UPPERCASE 0


#include "FSEventsFix.h"

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <dlfcn.h>
#include <errno.h>
#include <sys/syslimits.h>


const char *const FSEventsFixVersionString = "1.0.0";


#pragma mark - Forward declarations

static char *(*orig_realpath)(const char *restrict file_name, char *resolved_name);
static char *CFURL_realpath(const char *restrict file_name, char *resolved_name);
static char *FSEventsFix_realpath_wrapper(const char *restrict src, char *restrict dst);

static bool _FSEventsFixHookUpdate();


#pragma mark - Internal state

static bool g_hook_installed = false;
static char *g_orig_reapath_error = NULL;

#if FSEVENTSFIX_DEBUG_SIMULATE_FAILURE
#define kRealpathSymbolName "_realpath$SimulatedFailure"
#else
#define kRealpathSymbolName "_realpath$DARWIN_EXTSN"
#endif


__attribute__((constructor))
static void _FSEventsFixInitialize() {
    orig_realpath = dlsym(RTLD_DEFAULT, kRealpathSymbolName+1);
    if (orig_realpath == NULL) {
        const char *error = dlerror();
        if (error) {
            g_orig_reapath_error = strdup(error);
        }
    }
}


#pragma mark - API

bool FSEventsFixEnable(char **outerror) {
    if (orig_realpath == NULL) {
        if (outerror) {
            *outerror = NULL;
            asprintf(outerror, "Cannot find symbol %s, dlsym says: %s", kRealpathSymbolName+1, g_orig_reapath_error);
        }
        return false;
    }

    g_hook_installed = true;
    if (!_FSEventsFixHookUpdate()) {
        g_hook_installed = false;
        if (outerror) {
            *outerror = NULL;
            asprintf(outerror, "Cannot find imports of symbol %s in FSEvents binary", kRealpathSymbolName);
        }
        return false;
    }
    return true;
}

void FSEventsFixDisable() {
    g_hook_installed = false;
    _FSEventsFixHookUpdate();
}

bool FSEventsFixIsCorrectPathToWatch(const char *pathBeingWatched) {
    char *reresolved = CFURL_realpath(pathBeingWatched, NULL);
    if (reresolved) {
        bool correct = (0 == strcmp(pathBeingWatched, reresolved));
        free(reresolved);
        return correct;
    } else {
        return true;
    }
}

bool FSEventsFixIsBroken(const char *path) {
    char *resolved = realpath(path, NULL);
    if (!resolved) {
        return true;
    }
    bool broken = !FSEventsFixIsCorrectPathToWatch(resolved);
    free(resolved);
    return broken;
}

char *FSEventsFixCopyRootBrokenFolderPath(const char *inpath) {
    if (!FSEventsFixIsBroken(inpath)) {
        return NULL;
    }

    // get a mutable copy of an absolute path
    char *path = CFURL_realpath(inpath, NULL);
    if (!path) {
        return NULL;
    }

    for (;;) {
        char *sep = strrchr(path, '/');
        if ((sep == NULL) || (sep == path)) {
            break;
        }
        *sep = 0;
        if (!FSEventsFixIsBroken(path)) {
            *sep = '/';
            break;
        }
    }

    return path;
}


#pragma mark - FSEventsFix realpath wrapper

static char *FSEventsFix_realpath_wrapper(const char * __restrict src, char * __restrict dst) {
    // CFURL_realpath doesn't support putting where resolution failed into the
    // dst buffer, so we call the original realpath here first and if it gets a
    // result, replace that with the output of CFURL_realpath. that way all the
    // features of the original realpath are available.
    char *rv = NULL;
    char *orv = orig_realpath(src, dst);
    if (orv != NULL) { rv = CFURL_realpath(src, dst); }

#if FSEVENTSFIX_DEBUG_LOG_CALLS
    {
        char *result = rv ?: dst;
        fprintf(stderr, "FSEventsFix: realpath(%s) => %s\n", src, result);
    }
#endif

#if FSEVENTSFIX_DEBUG_REALPATH_RETURNS_UPPERCASE
    {
        char *result = rv ?: dst;
        if (result) {
            for (char *pch = result; *pch; ++pch) {
                *pch = (char)toupper(*pch);
            }
        }
    }
#endif

    return rv;
}


#pragma mark - realpath

// naive implementation of realpath on top of CFURL
// NOTE: doesn't quite support the full range of errno results one would
// expect here, in part because some of these functions just return a boolean,
// and in part because i'm not dealing with messy CFErrorRef objects and
// attempting to translate those to sane errno values.
// NOTE: the OSX realpath will return _where_ resolution failed in resolved_name
// if passed in and return NULL. we can't properly support that extension here
// since the resolution happens entirely behind the scenes to us in CFURL.
static char* CFURL_realpath(const char *file_name, char resolved_name[PATH_MAX])
{
    char* resolved;
    CFURLRef url1;
    CFURLRef url2;
    CFStringRef path;

    if (file_name == NULL) {
        errno = EINVAL;
        return (NULL);
    }

#if __DARWIN_UNIX03
    if (*file_name == 0) {
        errno = ENOENT;
        return (NULL);
    }
#endif

    // create a buffer to store our result if we weren't passed one
    if (!resolved_name) {
        if ((resolved = malloc(PATH_MAX)) == NULL) return (NULL);
    } else {
        resolved = resolved_name;
    }

    url1 = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8*)file_name, (CFIndex)strlen(file_name), false);
    if (url1 == NULL) { goto error_return; }

    url2 = CFURLCopyAbsoluteURL(url1);
    CFRelease(url1);
    if (url2 == NULL) { goto error_return; }

    url1 = CFURLCreateFileReferenceURL(NULL, url2, NULL);
    CFRelease(url2);
    if (url1 == NULL) { goto error_return; }

    // if there are multiple hard links to the original path, this may end up
    // being _completely_ different from what was intended
    url2 = CFURLCreateFilePathURL(NULL, url1, NULL);
    CFRelease(url1);
    if (url2 == NULL) { goto error_return; }

    path = CFURLCopyFileSystemPath(url2, kCFURLPOSIXPathStyle);
    CFRelease(url2);
    if (path == NULL) { goto error_return; }

    bool success = CFStringGetCString(path, resolved, PATH_MAX, kCFStringEncodingUTF8);
    CFRelease(path);
    if (!success) { goto error_return; }

    return resolved;

error_return:
    if (!resolved_name) {
        // we weren't passed in an output buffer and created our own. free it
        int e = errno;
        free(resolved);
        errno = e;
    }
    return (NULL);
}


#pragma mark - fishhook

// Copyright (c) 2013, Facebook, Inc.
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//   * Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//   * Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//   * Neither the name Facebook nor the names of its contributors may be used to
//     endorse or promote products derived from this software without specific
//     prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <stdlib.h>
#import <string.h>
#import <sys/types.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif

static bool _FSEventsFixHookUpdateSection(section_t *section, intptr_t slide, nlist_t *symtab, char *strtab, uint32_t *indirect_symtab)
{
    uint32_t *indirect_symbol_indices = indirect_symtab + section->reserved1;
    void **indirect_symbol_bindings = (void **)((uintptr_t)slide + section->addr);
    bool found = false;
    for (uint i = 0; i < section->size / sizeof(void *); i++) {
        uint32_t symtab_index = indirect_symbol_indices[i];
        if (symtab_index == INDIRECT_SYMBOL_ABS || symtab_index == INDIRECT_SYMBOL_LOCAL ||
            symtab_index == (INDIRECT_SYMBOL_LOCAL   | INDIRECT_SYMBOL_ABS)) {
            continue;
        }
        uint32_t strtab_offset = symtab[symtab_index].n_un.n_strx;
        char *symbol_name = strtab + strtab_offset;
        if (strcmp(symbol_name, kRealpathSymbolName) == 0) {
            found = true;
            if (g_hook_installed) {
                if (indirect_symbol_bindings[i] != FSEventsFix_realpath_wrapper) {
                    indirect_symbol_bindings[i] = FSEventsFix_realpath_wrapper;
                }
            } else if (orig_realpath != NULL) {
                if (indirect_symbol_bindings[i] == FSEventsFix_realpath_wrapper) {
                    indirect_symbol_bindings[i] = orig_realpath;
                }
            }
        }
    }
    return found;
}

static bool _FSEventsFixHookUpdateImage(const struct mach_header *header, intptr_t slide) {
    Dl_info info;
    if (dladdr(header, &info) == 0) {
        return false;
    }

    segment_command_t *cur_seg_cmd;
    segment_command_t *linkedit_segment = NULL;
    struct symtab_command* symtab_cmd = NULL;
    struct dysymtab_command* dysymtab_cmd = NULL;

    uintptr_t cur = (uintptr_t)header + sizeof(mach_header_t);
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *)cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_LINKEDIT) == 0) {
                linkedit_segment = cur_seg_cmd;
            }
        } else if (cur_seg_cmd->cmd == LC_SYMTAB) {
            symtab_cmd = (struct symtab_command*)cur_seg_cmd;
        } else if (cur_seg_cmd->cmd == LC_DYSYMTAB) {
            dysymtab_cmd = (struct dysymtab_command*)cur_seg_cmd;
        }
    }

    if (!symtab_cmd || !dysymtab_cmd || !linkedit_segment ||
        !dysymtab_cmd->nindirectsyms) {
        return false;
    }

    // Find base symbol/string table addresses
    uintptr_t linkedit_base = (uintptr_t)slide + linkedit_segment->vmaddr - linkedit_segment->fileoff;
    nlist_t *symtab = (nlist_t *)(linkedit_base + symtab_cmd->symoff);
    char *strtab = (char *)(linkedit_base + symtab_cmd->stroff);

    // Get indirect symbol table (array of uint32_t indices into symbol table)
    uint32_t *indirect_symtab = (uint32_t *)(linkedit_base + dysymtab_cmd->indirectsymoff);

    bool found = false;
    cur = (uintptr_t)header + sizeof(mach_header_t);
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *)cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_DATA) != 0) {
                continue;
            }
            for (uint j = 0; j < cur_seg_cmd->nsects; j++) {
                section_t *sect =
                (section_t *)(cur + sizeof(segment_command_t)) + j;
                if ((sect->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS) {
                    if (_FSEventsFixHookUpdateSection(sect, slide, symtab, strtab, indirect_symtab)) {
                        found = true;
                    }
                }
                if ((sect->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS) {
                    if (_FSEventsFixHookUpdateSection(sect, slide, symtab, strtab, indirect_symtab)) {
                        found = true;
                    }
                }
            }
        }
    }
    return found;
}

static bool _FSEventsFixHookUpdate() {
    Dl_info info;
    if (!dladdr(FSEventStreamCreate, &info)) {
        return false;
    }
    void *FSEventsDylibBase = info.dli_fbase;

    bool found = false;
    uint32_t c = _dyld_image_count();
    for (uint32_t i = 0; i < c; i++) {
        if (_dyld_get_image_header(i) == FSEventsDylibBase) {
            if (_FSEventsFixHookUpdateImage(FSEventsDylibBase, _dyld_get_image_vmaddr_slide(i))) {
                found = true;
            }
        }
    }
    return found;
}
