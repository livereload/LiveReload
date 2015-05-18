# FSEventsFix

Works around a long-standing bug in realpath() that prevents FSEvents API from monitoring certain folders on a wide range of OS X releases (10.6-10.10 at least).


## The Bug

The underlying issue is that for some folders, realpath() call starts returning a path with incorrect casing (e.g. "/users/smt" instead of "/Users/smt"). FSEvents is case-sensitive and calls realpath() on the paths you pass in, so an incorrect value returned by realpath() prevents FSEvents from seeing any change events.

See [@bdkjone's Wiki page about this bug](https://github.com/bdkjones/fseventsbug/wiki/realpath()-And-FSEvents) and the discussion at [thibaudgg/rb-fsevent#10](https://github.com/thibaudgg/rb-fsevent/issues/10).


## Usage


### Enabling and disabling the workaround

After adding `FSEventsFix.h` and `FSEventsFix.c` to your project, you have a choice of three approaches.

1. Call `FSEventsFixEnable()` on startup.

2. Call `FSEventsFixEnable()` before `FSEventStreamCreate` the first time you detect that the workaround is required.

    The suggested way to detect if a workaround is required is to attempt to repair the folder using `FSEventsFixRepairIfNeeded`.

    In Objective-C, this looks something like this:

        FSEventsFixRepairStatus status = FSEventsFixRepairIfNeeded(_path.fileSystemRepresentation);
        BOOL needWorkaround = (status == FSEventsFixRepairStatusFailed);
        if (needWorkaround) {
            FSEventsFixEnable();
        }
        _streamRef = FSEventStreamCreate(...);

3. Use `FSEventsFixEnable()` and `FSEventsFixDisable()` to only enable the workaround for the duration of `FSEventStreamCreate` call, and only if you detect that the workaround is required.

    This is the least intrusive method and seems to work as of OS X 10.10, but the potential downside is that we cannot guarantee that `FSEventStreamCreate` is the only part of FSEvents that needs the workaround.

    In Objective-C, this looks something like this:

        FSEventsFixRepairStatus status = FSEventsFixRepairIfNeeded(_path.fileSystemRepresentation);
        BOOL needWorkaround = (status == FSEventsFixRepairStatusFailed);
        if (needWorkaround) {
            FSEventsFixEnable();
        }
        _streamRef = FSEventStreamCreate(...);
        if (needWorkaround) {
            FSEventsFixDisable();
        }

Note that `FSEventsFixEnable` and `FSEventsFixDisable` calls are ‘reference-counted’, incrementing and decrementing an internal use count. If you want the workaround to be disabled, you need to balance every call to `FSEventsFixEnable` with a call to `FSEventsFixDisable`.

(Note also that these functions return void and there's no such thing as a failed `FSEventsFixEnable` call.)


### Checking the status of the workaround

You can use `FSEventsFixIsOperational` to check if the workaround has been installed successfully. It is expected to return true after a call to `FSEventsFixEnable()`, and to return false after a call to `FSEventsFixDisable`. The intended use is to alert or log an analytics event the user if the workaround is required, but couldn't be applied.

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

    }

Note that even if the workaround isn't operational, it does not necessarily mean it hasn't been installed. A call to `FSEventsFixDisable` is still required to uninstall the workaround (if desired).


### Checking and repairing the broken state

See `FSEventsFixIsBroken` and `FSEventsFixRepairIfNeeded` in the header file for the (straightforward) details.

`FSEventsFixRepairIfNeeded` implements a workaround suggested by Apple, but there's no guarantee that it works.


## Implementation

FSEventsFix uses a heavily modified version of Facebook's fishhook to replace the system `realpath()` function with a custom implementation that does not screw up directory names; FSEvents will then invoke our custom implementation and work correctly.

Our implementation of realpath is based on the open-source implementation from OS X 10.10, with a single change applied (enclosed in `BEGIN WORKAROUND FOR OS X BUG` ... `END WORKAROUND FOR OS X BUG`).


## Acknowledgments

Thanks go to:

* Travis Tilley, for spending many hours researching this bug with me

* Bryan Jones, for finally getting Apple to reveal a critical piece of information (that FSEvents calls realpath) that sparkled the idea for this approach, and for testing its feasibility, and generally for persisting in trying to resolve it and getting our lazy asses to move

* countless users of LiveReload, CodeKit and Guard who suffered this bug for years, sent us bug reports, tested builds and allowed us to poke in their machines


## License

See [FSEventsFix.c](FSEventsFix.c) file for license & copyrights, but basically this library is available under a mix of MIT and BSD licenses.


## Version History

0.10.0 (May 18, 2015) - a rewrite of the API with disable and repair functions.

0.9.0 (May 16, 2015) - initial beta release with a version number.
