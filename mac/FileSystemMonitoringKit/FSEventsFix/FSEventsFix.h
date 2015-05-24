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

#include <CoreFoundation/CoreFoundation.h>

/// A library version string (e.g. 1.2.3) for displaying and logging purposes
extern const char *const FSEventsFixVersionString;

/// See FSEventsFixDebugOptionSimulateBroken
#define FSEventsFixSimulatedBrokenFolderMarker  "__!FSEventsBroken!__"

typedef CF_OPTIONS(unsigned, FSEventsFixDebugOptions) {
    /// Always return an uppercase string from realpath
    FSEventsFixDebugOptionUppercaseReturn  = 0x01,
    
    /// Log all calls to realpath using the logger configured via FSEventsFixConfigure
    FSEventsFixDebugOptionLogCalls         = 0x02,

    /// In addition to the logging block (if any), log everything to stderr
    FSEventsFixDebugOptionLogToStderr      = 0x08,
    
    /// Report paths containing FSEventsFixSimulatedBrokenFolderMarker as broken
    FSEventsFixDebugOptionSimulateBroken   = 0x10,
};

typedef CF_ENUM(int, FSEventsFixMessageType) {
    /// Call logging requested via FSEventsFixDebugOptionLogCalls
    FSEventsFixMessageTypeCall,
    
    /// Results of actions like repair, and other pretty verbose, but notable, stuff.
    FSEventsFixMessageTypeResult,

    /// Enabled/disabled status change
    FSEventsFixMessageTypeStatusChange,

    /// Expected failure (treat as a warning)
    FSEventsFixMessageTypeExpectedFailure,

    /// Severe failure that most likely means that the library won't work
    FSEventsFixMessageTypeFatalError
};


/// Note that the logging block can be called on any dispatch queue.
void FSEventsFixConfigure(FSEventsFixDebugOptions debugOptions, void(^loggingBlock)(FSEventsFixMessageType type, const char *message));

bool FSEventsFixEnable();
void FSEventsFixDisable();

bool FSEventsFixIsBroken(const char *path);

/// If the path is broken, returns a string identifying the root broken folder,
/// otherwise, returns NULL. You need to free() the returned string.
char *FSEventsFixCopyRootBrokenFolderPath(const char *path);

#endif
