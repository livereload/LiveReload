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

#ifndef __FSEventsFix__
#define __FSEventsFix__

#include <stdbool.h>

/// A library version string (e.g. 1.2.3) for displaying and logging purposes
extern const char *const FSEventsFixVersionString;

bool FSEventsFixEnable(char **error);
void FSEventsFixDisable();

/// Returns if the letter casing of the given path is suitable for case-sensitive
/// matching against kernel change events. Give it a path returned by
/// FSEventStreamCopyPathsBeingWatched to predict if FSEvents will work.
bool FSEventsFixIsCorrectPathToWatch(const char *pathBeingWatched);

/// Returns whether the given path will reports change events via FSEvents API
/// without this workaround applied.
bool FSEventsFixIsBroken(const char *path);

/// If the path is broken, returns a string identifying the root broken folder,
/// otherwise returns NULL. You need to free() the returned string.
char *FSEventsFixCopyRootBrokenFolderPath(const char *path);

#endif
