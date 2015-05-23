# FSEventsFix

Works around a HFS+ file system corruption bug that prevents FSEvents API from monitoring certain folders on a wide range of OS X releases (10.6-10.10 at least).


## The Bug

As explained by Apple Developer Technical Support, HFS+ stores two copies of each file name:

* one of them is used by readdir (and so is visible in Finder, is printed by ls, etc) and by realpath;

* another is used when getting a path by inode, e.g. by `CFURLCreateFilePathURL` after `CFURLCreateFileReferenceURL`, by `FSCopyAliasInfo`, and by the kernel when reporting file change events.

An OS X HFS+ driver bug sometimes causes one of these two copies to become lowercased; for example, you may see `/Users` in Finder and ls, but if you create an alias and resolve it, you'd get lowercase `/users`, and the FS change events reported by the kernel will also say `/users`.

FSEvents implementation is case-sensitive, so if you ask it to monitor `/Users`, it will not report any change events under `/users`. Normally, this is not a problem; FSEvents is smart and uses `realpath` to normalize the path you pass in, so regardless of whether you ask it to monitor `/users`, `/Users` or `/USERS`, it will internally normalize it into the correct case (`/Users`).

Unfortunately, when the mentioned HFS+ bug occurs, the case returned by `realpath` differs from the case used for kernel events, so FSEvents ends up monitoring `/Users`, while the kernel reports changes for `/users`, or vise versa. (The bug may cause _either_ — or, we have to assume, both — copies of the name to get lowercased. Pretty weird stuff.)

See also:

* [@bdkjone's Wiki page about this bug](https://github.com/bdkjones/fseventsbug/wiki/realpath()-And-FSEvents)
* the discussion at [thibaudgg/rb-fsevent#10](https://github.com/thibaudgg/rb-fsevent/issues/10), the primary communication channel used while investigating this bug


## The Workaround

Apple Developer Technical Support has confirmed that the kernel always uses the same case as the one returned by `CFURLCreateFilePathURL(CFURLCreateFileReferenceURL(...))`, so we replace `realpath` with our custom implementation based on those APIs. When FSEvents library calls `realpath` to normalize the path, it actually invokes our replacement implementation that returns the ‘correct’ path, so that monitoring works normally.

Note that we don't just replace realpath for FSEvents, we replace it for the entire process. Fortunately, you don't need to keep it that way for long; the only call we care about happens inside `FSEventStreamCreate`, so you only need to enable the fix before calling `FSEventStreamCreate`, and disable the fix immediately after.

We use a heavily modified version of Facebook's fishhook to perform the replacement of `realpath`.

Our implementation of realpath uses CoreFoundation class CFURL to convert the path to a (volume id / inode id) pair, then ask the filesystem what the correct path for that inode is. Since this implementation doesn't implement all the features of realpath, the original implementation is called first so that it can correctly fill the dst buffer with where the resolution failed and set errno to the correct value. Only if the original realpath succeeds is the custom implementation run.

Please note that while our custom implementation will output a path that matches what the kernel reports to fsevents, it may not necessarily be "correct". The capitalization might not match what you deliberately set the filename to be. You may have named a file "SomeFile" but the kernel is reporting events using "somefile" (even though Finder and ls both show "SomeFile"). As such, please use caution when globally replacing realpath.


## Usage


### Enabling and disabling the workaround

After adding `FSEventsFix.h` and `FSEventsFix.c` to your project, you have a choice of three integration methods:

1. Call `FSEventsFixEnable()` on startup.

2. Call `FSEventsFixEnable()` before `FSEventStreamCreate` if you detect that the workaround is required.

    The suggested way to detect if a workaround is required is to attempt to repair the folder using `FSEventsFixRepairIfNeeded` and check the result.

    In Objective-C:

        FSEventsFixRepairStatus status = FSEventsFixRepairIfNeeded(_path.fileSystemRepresentation);
        BOOL needWorkaround = (status == FSEventsFixRepairStatusFailed);
        if (needWorkaround) {
            FSEventsFixEnable();
        }
        _streamRef = FSEventStreamCreate(...);

3. Use `FSEventsFixEnable()` and `FSEventsFixDisable()` to only enable the workaround for the duration of `FSEventStreamCreate` call, and only if you detect that the workaround is required.

    This is the least intrusive method and seems to work as of OS X 10.10, but the potential downside is that we cannot guarantee that `FSEventStreamCreate` is the only part of FSEvents that needs the workaround.

    In Objective-C:

        FSEventsFixRepairStatus status = FSEventsFixRepairIfNeeded(_path.fileSystemRepresentation);
        BOOL needWorkaround = (status == FSEventsFixRepairStatusFailed);
        if (needWorkaround) {
            FSEventsFixEnable();
        }
        _streamRef = FSEventStreamCreate(...);
        if (needWorkaround) {
            FSEventsFixDisable();
        }

Note that `FSEventsFixEnable` and `FSEventsFixDisable` calls are ‘reference-counted’, incrementing and decrementing an internal use count. If you want to disable the workaround, balance every call to `FSEventsFixEnable` with a call to `FSEventsFixDisable`.

(Note also that these functions return void and there's no such thing as a failed `FSEventsFixEnable` call.)


### Checking the status of the workaround

You can use `FSEventsFixIsOperational` to check if the workaround has been installed successfully. It is expected to return true after a call to `FSEventsFixEnable()`, and to return false after all calls to `FSEventsFixEnable` have been balanced by a call to `FSEventsFixDisable()`.

The intended use is to alert or log an analytics event the user if the workaround is required, but couldn't be applied.

Combining the approach 3 above with `FSEventsFixIsOperational` check, we get the recommended usage pattern:

    FSEventsFixRepairStatus status = FSEventsFixRepairIfNeeded(_path.fileSystemRepresentation);
    BOOL needWorkaround = (status == FSEventsFixRepairStatusFailed);
    BOOL alertAboutFSEventsBug = NO;
    if (needWorkaround) {
        FSEventsFixEnable();
        if (!FSEventsFixIsOperational()) {
            alertAboutFSEventsBug = YES;
        }
    }
    _streamRef = FSEventStreamCreate(...);
    if (needWorkaround) {
        FSEventsFixDisable();
    }
    if (alertAboutFSEventsBug) {
        // ... show alert, once per folder or maybe once per app launch ...
    }

Note that even if the workaround isn't operational, it does not necessarily mean it hasn't been installed. A call to `FSEventsFixDisable` is still required to uninstall the workaround if so desired.


### Checking and repairing the broken state

See `FSEventsFixIsBroken` and `FSEventsFixRepairIfNeeded` in the header file for the (straightforward) details.

`FSEventsFixRepairIfNeeded` implements the rename method suggested by Apple, but at this point there's no confirmation that it actually works.


### Debug options and logging

You can use `FSEventsFixConfigure` to enable a bunch of useful debug options, and to provide a logging block.

The options are documented in the header file. A notable one is `FSEventsFixDebugOptionSimulateBroken` that, when enabled, treats all folders containing `__!FSEventsBroken!__` in their name as broken. Similarly, `FSEventsFixDebugOptionSimulateRepair` will simulate a successful repair by renaming such folders to exclude `__!FSEventsBroken!__` from the name. This allows you to test the relevant code paths without access to a machine with an actual broken folder.

`FSEventsFixConfigure`, if called, must be called before any other method of the library.


### Concurrency

All public API methods are thread-safe and can be called from any thread/queue. However, to avoid race conditions, you must guarantee that a call to `FSEventsFixConfigure` (if any) returns before any other FSEventsFix call is performed.


## Multiple instances of FSEventsFix

FSEventsFix only supports a single copy of the library per process. This can be a concern if using multiple monitoring libraries, or when shipping as part of a library.


## Acknowledgments

Thanks go to:

* Travis Tilley, for spending many hours researching this bug with me and contributing CFURL_realpath implementation

* Bryan Jones, for finally getting Apple to reveal a critical piece of information (that FSEvents calls realpath) that sparkled the idea for this approach, and for testing its feasibility, and generally for persisting in trying to resolve it and getting our lazy asses to move

* countless users of LiveReload, CodeKit and Guard who suffered this bug for years, sent us bug reports, tested builds and allowed us to poke in their machines


## License

Copyright 2015, [Andrey Tarantsov](https://github.com/andreyvit) and [Travis Tilley](https://github.com/ttilley).
Portions copyright 2013, Facebook, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



## Version History

0.10.0 (May 18, 2015) - a rewrite of the API with disable and repair functions.

0.9.0 (May 16, 2015) - initial beta release with a version number.
