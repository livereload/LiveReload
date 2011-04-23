
#import "LiveReloadAppDelegate.h"


void LiveReloadFSEventStreamCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, NSArray *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
    for (int i = 0; i < numEvents; i++) {
        NSString *path = [eventPaths objectAtIndex:i];
        FSEventStreamEventFlags flags = eventFlags[i];
        NSString *flagsStr = @"";
        if ((flags & kFSEventStreamEventFlagMustScanSubDirs)) {
            flagsStr = [flagsStr stringByAppendingString:@"MustScanSubDirs"];
        }
        if ((flags & kFSEventStreamEventFlagRootChanged)) {
            flagsStr = [flagsStr stringByAppendingString:@"RootChanged"];
        }
        if ([flagsStr length]) {
            flagsStr = [NSString stringWithFormat:@" [%@]", flagsStr];
        }
        NSLog(@"Event #%d at %@%@", i, path, flagsStr);
    }
}


@implementation LiveReloadAppDelegate

@synthesize window;

// just to make XDry happy; won't ever be deallocated
- (void)dealloc {
	[window release], window = nil;
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSArray *paths = [NSArray arrayWithObject:@"/Users/andreyvit"];
    FSEventStreamRef streamRef = FSEventStreamCreate(nil,
                                                  (FSEventStreamCallback)LiveReloadFSEventStreamCallback,
                                                  nil,
                                                  (CFArrayRef)paths,
                                                  kFSEventStreamEventIdSinceNow,
                                                  0.25,
                                                  kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagWatchRoot);
    FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(streamRef);
}

@end
