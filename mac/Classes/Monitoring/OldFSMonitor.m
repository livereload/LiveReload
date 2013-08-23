
#import "OldFSMonitor.h"
#import "OldFSTreeDiffer.h"
#import "OldFSTreeFilter.h"
#import "OldFSTree.h"

#import "Preferences.h"


static void FSMonitorEventStreamCallback(ConstFSEventStreamRef streamRef, FSMonitor *monitor, size_t numEvents, NSArray *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]);

@interface FSMonitor ()

- (void)start;
- (void)stop;

@property (nonatomic, readonly, strong) NSMutableSet * eventCache;
@property (nonatomic, assign) NSTimeInterval cacheWaitingTime;
@end


@implementation FSMonitor

@synthesize path=_path;
@synthesize delegate=_delegate;
@synthesize filter=_filter;

@synthesize eventCache = _eventCache;
@synthesize cacheWaitingTime = _cacheWaitingTime;
@synthesize eventProcessingDelay=_eventProcessingDelay;


#pragma mark -
#pragma mark Init/dealloc

- (id)initWithPath:(NSString *)path {
    if ((self = [super init])) {
        _cacheWaitingTime = 0.1;
        _eventCache = [[NSMutableSet alloc] init];
        _path = [path copy];
        _filter = [[FSTreeFilter alloc] init];
    }
    return self;
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (_running) {
        [self stop];
    }
}


#pragma mark - Adjustments

- (void)filterUpdated {
    if (_running) {
        [self stop];
        [self start];
    }
}

- (void)setFilter:(FSTreeFilter *)filter {
    if (filter != _filter) {
        _filter = filter;

        [self filterUpdated];
    }
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
    _treeDiffer = [[FSTreeDiffer alloc] initWithPath:_path filter:_filter];
    NSArray *paths = [NSArray arrayWithObject:_path];

    FSEventStreamContext context;
    context.version = 0;
    context.info = (__bridge void *)(self);
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;

    _streamRef = FSEventStreamCreate(nil,
                                     (FSEventStreamCallback)FSMonitorEventStreamCallback,
                                     &context,
                                     (__bridge CFArrayRef)paths,
                                     kFSEventStreamEventIdSinceNow,
                                     0.05,
                                     kFSEventStreamCreateFlagUseCFTypes);
    if (!_streamRef) {
        NSLog(@"Failed to start monitoring of %@ (FSEventStreamCreate error)", _path);
    }

    FSEventStreamScheduleWithRunLoop(_streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    if (!FSEventStreamStart(_streamRef)) {
        NSLog(@"Failed to start monitoring of %@ (FSEventStreamStart error)", _path);
    }
}

- (void)stop {
    FSEventStreamStop(_streamRef);
    FSEventStreamInvalidate(_streamRef);
    FSEventStreamRelease(_streamRef);
    _streamRef = nil;
    _treeDiffer = nil;
}


#pragma mark -
#pragma mark Event Processing

- (void)sendChangeEventsFromCache {
    NSMutableSet * cachedPaths;

    @synchronized(self){
        cachedPaths = [self.eventCache copy];
        [self.eventCache removeAllObjects];
        NSTimeInterval lastRebuildTime = _treeDiffer.savedTree.buildTime;

        NSTimeInterval minDelay = [[NSUserDefaults standardUserDefaults] integerForKey:EventProcessingDelayKey] / 1000.0;
        _cacheWaitingTime = MAX(lastRebuildTime, minDelay);
    }

    FSChange *change = [_treeDiffer changedPathsByRescanningSubfolders:cachedPaths];
    if (change.isNonEmpty) {
        [self.delegate fileSystemMonitor:self detectedChange:change];
    }
}

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

    [self.eventCache addObject:path];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(sendChangeEventsFromCache) withObject:nil afterDelay:MAX(_eventProcessingDelay, self.cacheWaitingTime)];

}

- (void)rescan {
    @synchronized(self) {
        [_eventCache addObject:@"/"];
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self sendChangeEventsFromCache];
}


#pragma mark - Tree access

- (FSTree *)tree {
    return _treeDiffer.savedTree;
}

- (FSTree *)obtainTree {
    if (_treeDiffer)
        return _treeDiffer.savedTree;
    else
        return [[FSTree alloc] initWithPath:_path filter:_filter];
}

@end


static void FSMonitorEventStreamCallback(ConstFSEventStreamRef streamRef, FSMonitor *monitor, size_t numEvents, NSArray *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
    for (size_t i = 0; i < numEvents; i++) {
        [monitor sendChangeEventWithPath:[eventPaths objectAtIndex:i] flags:eventFlags[i]];
    }
}
