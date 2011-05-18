
#import "FSMonitor.h"


static void FSMonitorEventStreamCallback(ConstFSEventStreamRef streamRef, FSMonitor *monitor, size_t numEvents, NSArray *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]);

@interface FSMonitor ()

- (void)start;
- (void)stop;

@end


@implementation FSMonitor

@synthesize path=_path;
@synthesize delegate=_delegate;


#pragma mark -
#pragma mark Init/dealloc

- (id)initWithPath:(NSString *)path {
    if ((self = [super init])) {
        _path = [path copy];
    }
    return self;
}

- (void)dealloc {
    if (_running) {
        [self stop];
    }
    [_path release], _path = nil;
    _delegate = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Start/stop

- (BOOL)isRunning {
    return _running;
}

- (void)setRunning:(BOOL)wannaRun {
    if (_running != wannaRun) {
        _running = wannaRun;
        if (wannaRun) {
            [self start];
        } else {
            [self stop];
        }
    }
}

- (void)start {
    NSArray *paths = [NSArray arrayWithObject:_path];

    FSEventStreamContext context;
    context.version = 0;
    context.info = self;
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;

    _streamRef = FSEventStreamCreate(nil,
                                     (FSEventStreamCallback)FSMonitorEventStreamCallback,
                                     &context,
                                     (CFArrayRef)paths,
                                     kFSEventStreamEventIdSinceNow,
                                     0.25,
                                     kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagWatchRoot);
    FSEventStreamScheduleWithRunLoop(_streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(_streamRef);
}

- (void)stop {
    FSEventStreamStop(_streamRef);
    FSEventStreamRelease(_streamRef);
    _streamRef = nil;
}


#pragma mark -
#pragma mark Event Processing

- (void)sendChangeEventWithPath:(NSString *)path flags:(FSEventStreamEventFlags)flags {
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
    NSLog(@"Change event at %@%@", path, flagsStr);
    [self.delegate fileSystemMonitor:self detectedChangeAtPathes:[NSSet setWithObject:path]];
}


@end


static void FSMonitorEventStreamCallback(ConstFSEventStreamRef streamRef, FSMonitor *monitor, size_t numEvents, NSArray *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
    for (int i = 0; i < numEvents; i++) {
        NSString *path = [eventPaths objectAtIndex:i];
        FSEventStreamEventFlags flags = eventFlags[i];
        [monitor sendChangeEventWithPath:path flags:flags];
    }
}
