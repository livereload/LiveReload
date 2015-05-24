# FSEventsFix

Works around a HFS+ file system corruption bug that prevents FSEvents API from monitoring certain folders on a wide range of OS X releases (10.6-10.10 at least).


## The Bug

As explained by Apple Developer Technical Support, HFS+ stores two copies of each file name:

* one of them is used by `readdir()` (and so is visible in Finder, is printed by ls, etc) and by `realpath()`;

* another is used when getting a path by inode, e.g. by `CFURLCreateFilePathURL` after `CFURLCreateFileReferenceURL`, by `FSCopyAliasInfo`, and by the kernel when reporting file change events.

An OS X HFS+ driver bug sometimes causes one of these two copies to become lowercased; for example, you may see `/Users` in Finder and ls, but if you create an alias and resolve it, you'd get lowercase `/users`, and the FS change events reported by the kernel will also say `/users`.

FSEvents implementation is case-sensitive, so if you ask it to monitor `/Users`, it will not report any change events under `/users`. Normally, this is not a problem; FSEvents is smart and uses `realpath` to normalize the path you pass in, so regardless of whether you ask it to monitor `/users`, `/Users` or `/USERS`, it will internally normalize it into the correct case (`/Users`).

Unfortunately, when the mentioned HFS+ bug occurs, the case returned by `realpath` differs from the case used for kernel events, so FSEvents ends up monitoring `/Users`, while the kernel reports changes for `/users`, or vise versa. (The bug may cause _either_ — or, we have to assume, both — copies of the name to get lowercased. Pretty weird stuff.)

See also:

* [@bdkjone's Wiki page about this bug](https://github.com/bdkjones/fseventsbug/wiki/realpath()-And-FSEvents)
* the discussion at [thibaudgg/rb-fsevent#10](https://github.com/thibaudgg/rb-fsevent/issues/10), the primary communication channel used while investigating this bug


## The Workaround

Apple Developer Technical Support has confirmed that the kernel always uses the same case as the one returned by `CFURLCreateFilePathURL(CFURLCreateFileReferenceURL(...))`, so we replace `realpath` with our custom implementation based on those APIs. When FSEvents library calls `realpath` to normalize the path, it actually invokes our replacement implementation that returns the ‘correct’ path, so that monitoring works normally.

Further notes:

* We take care to only replace `realpath` for FSEvents. However, we still recommend you to only enable the fix before calling `FSEventStreamCreate` and to disable the fix right after. (The only call to `realpath` that we care about is in `FSEventStreamCreate`.)

* We use a heavily modified version of Facebook's fishhook to perform the replacement.

* Our implementation of realpath uses CoreFoundation class CFURL to convert the path to a (volume id / inode id) pair, then ask the filesystem what the correct path for that inode is. Since this implementation doesn't implement all the features of realpath, the original implementation is called first so that it can correctly fill the dst buffer with where the resolution failed and set errno to the correct value. Only if the original realpath succeeds is the custom implementation run.

* While our custom implementation will output a path that matches what the kernel reports to FSEvents, it may not necessarily be “correct”, i.e. the capitalization might not match what you deliberately set the filename to be. You may have named a file `SomeFile` but the kernel is reporting events using `somefile` (even though Finder and ls both show `SomeFile`).


## Usage

Add `FSEventsFix.h` and `FSEventsFix.c` to your project.

Then, before each call to `FSEventStreamCreate`:

1. Use `FSEventsFixIsBroken(path)` to check if a given folder is broken (i.e. requires the workaround).

2. If the folder is broken, call `FSEventsFixEnable()` before `FSEventStreamCreate`. If it returns false, it will give you an error message to report, but otherwise the failure can be ignored.

After a call to `FSEventStreamCreate`:

1. Call `FSEventsFixDisable()`.

2. Use `FSEventStreamCopyPathsBeingWatched()` to get the actual path watched by FSEvents, and check whether its capitalization is correct using `FSEventsFixIsCorrectPathToWatch()`. If the function returns false, the workaround didn't work and FSEvents probably won't report any events.


### Concurrency

FSEventsFix is not thread-safe; use locks or serial dispatch queues if you need to call it from multiple threads.


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

1.1.0 (May 24, 2015) - a radical simplification of the API and internals; realpath replacement has been limited to the FSEvents binary, and `_dyld_register_func_for_add_image` is no longer used.

0.10.0 (May 18, 2015) - a rewrite of the API with disable and repair functions.

0.9.0 (May 16, 2015) - initial beta release with a version number.
