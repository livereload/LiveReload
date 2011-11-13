
#include "osdep.h"
#include "autorelease.h"

#import <Cocoa/Cocoa.h>


//----------------------------------

static int run_loop_depth = 0;
void os_autorelease_run_loop_callback (CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    switch (activity) {
        case kCFRunLoopEntry:
            ++run_loop_depth;
            break;
        case kCFRunLoopExit:
            --run_loop_depth;
            // fall-thru
        case kCFRunLoopBeforeWaiting:
            if (run_loop_depth == 1) {
                autorelease_cleanup();
            }
            break;
    }
}

//----------------------------------

void os_init() {
    CFRunLoopObserverCreate(NULL, kCFRunLoopEntry | kCFRunLoopExit | kCFRunLoopBeforeWaiting, YES, 0, os_autorelease_run_loop_callback, NULL);
}

const char *os_bundled_resources_path() {
    return [[[NSBundle mainBundle] resourcePath] UTF8String];
}
